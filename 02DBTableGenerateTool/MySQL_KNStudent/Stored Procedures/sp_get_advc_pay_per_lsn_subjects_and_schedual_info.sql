DELIMITER //

DROP PROCEDURE IF EXISTS sp_get_advc_pay_per_lsn_subjects_and_schedual_info //

CREATE DEFINER=`root`@`%` PROCEDURE `sp_get_advc_pay_per_lsn_subjects_and_schedual_info`(
    IN p_stuId VARCHAR(32),
    IN p_yearMonth VARCHAR(7),
    IN p_lessonCount INT,
    IN p_subjectId VARCHAR(32),
    IN p_subjectSubId VARCHAR(32)
)
BEGIN
    -- ============================================================
    -- 按课时预支付：推算排课日期（Preview）
    --
    -- 双指针合并遍历：
    --   数据源1: 固定排课候选日期（每周+7天推算）
    --   数据源2: 既存非固定课程（CURSOR按日期升序）
    -- 按日期顺序合并处理，返回N条有效记录。
    --
    -- 处理模式：
    --   A = 无既存课程 → 全新创建
    --   B = 未签到既存课程 → 复用lesson
    --   C = 已签到未支付既存课程 → 复用lesson+fee
    --   D = 已签到已支付 或 已有预支付记录 → 跳过（不计入N）
    -- ============================================================

    DECLARE v_first_day DATE;
    DECLARE v_next_fixed_date DATETIME;
    DECLARE v_fixed_week VARCHAR(3);
    DECLARE v_fixed_hour INT;
    DECLARE v_fixed_minute INT;
    DECLARE v_target_weekday INT;
    DECLARE v_processed_count INT DEFAULT 0;
    DECLARE v_iteration INT DEFAULT 0;
    DECLARE v_max_iteration INT DEFAULT 100;

    -- 每次迭代用到的变量
    DECLARE v_current_date DATETIME;
    DECLARE v_current_lesson_id VARCHAR(50);
    DECLARE v_current_fee_id VARCHAR(50);
    DECLARE v_exist_count INT;
    DECLARE v_fee_count INT;
    DECLARE v_pay_count INT;
    DECLARE v_advc_count INT;
    DECLARE v_mode VARCHAR(1);

    -- 学生档案信息
    DECLARE v_stu_name VARCHAR(100);
    DECLARE v_subject_name VARCHAR(100);
    DECLARE v_subject_sub_name VARCHAR(100);
    DECLARE v_subject_price DECIMAL(10,2);
    DECLARE v_minutes_per_lsn INT;

    -- ============================
    -- 1. 获取固定排课信息
    -- ============================
    SELECT fixed_week, fixed_hour, fixed_minute
    INTO v_fixed_week, v_fixed_hour, v_fixed_minute
    FROM v_earliest_fixed_week_info
    WHERE stu_id = p_stuId AND subject_id = p_subjectId
    LIMIT 1;

    -- 如果没有固定排课信息，返回空结果集
    IF v_fixed_week IS NULL THEN
        SELECT NULL AS stu_id, NULL AS stu_name,
               NULL AS subject_id, NULL AS subject_name,
               NULL AS subject_sub_id, NULL AS subject_sub_name,
               NULL AS lesson_type, NULL AS schedual_date,
               NULL AS subject_price, NULL AS minutes_per_lsn,
               NULL AS processing_mode, NULL AS existing_lesson_id,
               NULL AS existing_fee_id, NULL AS sequence_no
        WHERE 1 = 0;
        -- 直接退出，不做后续处理
    ELSE
        -- ============================
        -- 2. 获取学生档案的科目信息
        -- ============================
        SELECT
            stu_name,
            subject_name,
            subject_sub_name,
            CASE WHEN lesson_fee_adjusted > 0 THEN lesson_fee_adjusted
                 ELSE lesson_fee
            END,
            minutes_per_lsn
        INTO v_stu_name, v_subject_name, v_subject_sub_name, v_subject_price, v_minutes_per_lsn
        FROM v_latest_subject_info_from_student_document
        WHERE stu_id = p_stuId
          AND subject_id = p_subjectId
          AND subject_sub_id = p_subjectSubId
        LIMIT 1;

        -- ============================
        -- 3. 计算对象月第一个固定排课日
        -- ============================
        SET v_first_day = DATE(CONCAT(p_yearMonth, '-01'));

        -- 将固定星期转换为MySQL的DAYOFWEEK值（1=Sun, 2=Mon, ..., 7=Sat）
        SET v_target_weekday = CASE v_fixed_week
            WHEN 'Sun' THEN 1
            WHEN 'Mon' THEN 2
            WHEN 'Tue' THEN 3
            WHEN 'Wed' THEN 4
            WHEN 'Thu' THEN 5
            WHEN 'Fri' THEN 6
            WHEN 'Sat' THEN 7
        END;

        -- 计算对象月的第一个固定排课日期
        IF DAYOFWEEK(v_first_day) <= v_target_weekday THEN
            SET v_next_fixed_date = DATE_ADD(v_first_day, INTERVAL (v_target_weekday - DAYOFWEEK(v_first_day)) DAY);
        ELSE
            SET v_next_fixed_date = DATE_ADD(v_first_day, INTERVAL (7 - DAYOFWEEK(v_first_day) + v_target_weekday) DAY);
        END IF;

        -- 加上时间部分（时:分）
        SET v_next_fixed_date = CAST(CONCAT(DATE(v_next_fixed_date), ' ',
            LPAD(v_fixed_hour, 2, '0'), ':', LPAD(v_fixed_minute, 2, '0'), ':00') AS DATETIME);

        -- ============================
        -- 4. 创建结果临时表
        -- ============================
        DROP TEMPORARY TABLE IF EXISTS temp_preview_result;
        CREATE TEMPORARY TABLE temp_preview_result (
            stu_id VARCHAR(32),
            stu_name VARCHAR(100),
            subject_id VARCHAR(32),
            subject_name VARCHAR(100),
            subject_sub_id VARCHAR(32),
            subject_sub_name VARCHAR(100),
            lesson_type INT,
            schedual_date DATETIME,
            subject_price DECIMAL(10,2),
            minutes_per_lsn INT,
            processing_mode VARCHAR(1),
            existing_lesson_id VARCHAR(50),
            existing_fee_id VARCHAR(50),
            sequence_no INT
        );

        -- ============================
        -- 5. 双指针合并遍历循环
        --    使用嵌套BEGIN...END块隔离CURSOR和CONTINUE HANDLER的作用域，
        --    防止影响外层的SELECT INTO语句。
        -- ============================
        BEGIN
            DECLARE v_nfix_done INT DEFAULT 0;
            DECLARE v_nfix_lesson_id VARCHAR(50);
            DECLARE v_nfix_date DATETIME;

            -- 非固定课程游标：查询该学生该科目在第一个固定排课日之后的
            -- 非固定时间点的既存课程，按日期升序
            DECLARE cur_nfix CURSOR FOR
                SELECT lesson_id, schedual_date
                FROM t_info_lesson
                WHERE stu_id = p_stuId
                  AND subject_id = p_subjectId
                  AND subject_sub_id = p_subjectSubId
                  AND schedual_date >= v_next_fixed_date
                  AND del_flg = 0
                  AND NOT (
                      DAYOFWEEK(schedual_date) = v_target_weekday
                      AND HOUR(schedual_date) = v_fixed_hour
                      AND MINUTE(schedual_date) = v_fixed_minute
                  )
                ORDER BY schedual_date;

            DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_nfix_done = 1;

            -- 打开游标，取出第一条非固定课程
            OPEN cur_nfix;
            FETCH cur_nfix INTO v_nfix_lesson_id, v_nfix_date;

            -- 主循环：双指针合并遍历
            WHILE v_processed_count < p_lessonCount AND v_iteration < v_max_iteration DO

                -- 初始化每次迭代的变量
                SET v_current_lesson_id = NULL;
                SET v_current_fee_id = NULL;
                SET v_current_date = NULL;
                SET v_mode = NULL;

                -- ============================================
                -- 5.1 双指针选择下一个要处理的日期
                -- ============================================
                IF v_nfix_done = 0 AND v_nfix_date < v_next_fixed_date THEN
                    -- ─── 非固定课程日期更早 → 先处理非固定课程 ───
                    SET v_current_date = v_nfix_date;
                    SET v_current_lesson_id = v_nfix_lesson_id;

                    -- 预取下一条非固定课程（为下次循环做准备）
                    FETCH cur_nfix INTO v_nfix_lesson_id, v_nfix_date;

                ELSE
                    -- ─── 固定候选日期更早（或非固定已耗尽）→ 处理固定日期 ───
                    SET v_current_date = v_next_fixed_date;

                    -- 检查该固定日期是否有既存课程
                    SELECT COUNT(*) INTO v_exist_count
                    FROM t_info_lesson
                    WHERE stu_id = p_stuId
                      AND subject_id = p_subjectId
                      AND subject_sub_id = p_subjectSubId
                      AND schedual_date = v_next_fixed_date
                      AND del_flg = 0;

                    IF v_exist_count > 0 THEN
                        -- 固定日期有既存课程 → 获取lesson_id
                        SELECT lesson_id INTO v_current_lesson_id
                        FROM t_info_lesson
                        WHERE stu_id = p_stuId
                          AND subject_id = p_subjectId
                          AND subject_sub_id = p_subjectSubId
                          AND schedual_date = v_next_fixed_date
                          AND del_flg = 0
                        LIMIT 1;
                    END IF;
                    -- 如果v_exist_count = 0，则v_current_lesson_id仍为NULL → 模式A

                    -- 固定日期指针前进+7天
                    SET v_next_fixed_date = DATE_ADD(v_next_fixed_date, INTERVAL 7 DAY);
                END IF;

                -- ============================================
                -- 5.2 判定处理模式（A/B/C/D）
                -- ============================================
                IF v_current_lesson_id IS NULL THEN
                    -- 无既存课程（仅固定候选日期会出现此情况）
                    SET v_mode = 'A';
                ELSE
                    -- 有既存课程 → 进一步判定

                    -- 5.2.1 检查是否已有预支付记录
                    SELECT COUNT(*) INTO v_advc_count
                    FROM t_info_lsn_fee_advc_pay
                    WHERE lesson_id = v_current_lesson_id
                      AND del_flg = 0;

                    IF v_advc_count > 0 THEN
                        -- 已有预支付记录 → 跳过（模式D）
                        SET v_mode = 'D';
                    ELSE
                        -- 5.2.2 检查课费记录
                        SELECT COUNT(*) INTO v_fee_count
                        FROM t_info_lesson_fee
                        WHERE lesson_id = v_current_lesson_id
                          AND pay_style = 0
                          AND del_flg = 0;

                        IF v_fee_count = 0 THEN
                            -- 无课费记录 → 模式B（未签到或已签到但无fee的异常情况）
                            SET v_mode = 'B';
                        ELSE
                            -- 有课费记录，获取fee_id
                            SELECT lsn_fee_id INTO v_current_fee_id
                            FROM t_info_lesson_fee
                            WHERE lesson_id = v_current_lesson_id
                              AND pay_style = 0
                              AND del_flg = 0
                            LIMIT 1;

                            -- 5.2.3 检查支付记录
                            SELECT COUNT(*) INTO v_pay_count
                            FROM t_info_lesson_pay
                            WHERE lsn_fee_id = v_current_fee_id
                              AND del_flg = 0;

                            IF v_pay_count = 0 THEN
                                -- 有fee无pay → 模式C（已签到未支付）
                                SET v_mode = 'C';
                            ELSE
                                -- 有fee有pay → 模式D（已签到已支付 → 跳过）
                                SET v_mode = 'D';
                            END IF;
                        END IF;
                    END IF;
                END IF;

                -- ============================================
                -- 5.3 根据模式写入结果
                -- ============================================
                IF v_mode IN ('A', 'B', 'C') THEN
                    SET v_processed_count = v_processed_count + 1;

                    INSERT INTO temp_preview_result VALUES (
                        p_stuId,
                        v_stu_name,
                        p_subjectId,
                        v_subject_name,
                        p_subjectSubId,
                        v_subject_sub_name,
                        0,  -- lesson_type = 0 (按课时)
                        v_current_date,
                        v_subject_price,
                        v_minutes_per_lsn,
                        v_mode,
                        v_current_lesson_id,  -- NULL if mode A
                        v_current_fee_id,     -- NULL if mode A or B
                        v_processed_count     -- sequence_no
                    );
                END IF;
                -- 模式D不插入结果表，不增加processed_count

                SET v_iteration = v_iteration + 1;

            END WHILE;

            CLOSE cur_nfix;
        END;

        -- ============================
        -- 6. 返回结果
        -- ============================
        SELECT * FROM temp_preview_result ORDER BY sequence_no;

        -- ============================
        -- 7. 清理临时表
        -- ============================
        DROP TEMPORARY TABLE IF EXISTS temp_preview_result;

    END IF;

END //

DELIMITER ;

-- 调用存储过程的示例
-- CALL sp_get_advc_pay_per_lsn_subjects_and_schedual_info('kn-stu-82', '2026-02', 7, 'kn-sub-6', 'kn-sub-6-1');
