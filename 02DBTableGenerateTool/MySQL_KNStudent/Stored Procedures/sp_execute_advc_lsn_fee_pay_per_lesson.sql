DELIMITER //

DROP PROCEDURE IF EXISTS sp_execute_advc_lsn_fee_pay_per_lesson //

CREATE PROCEDURE sp_execute_advc_lsn_fee_pay_per_lesson(
    IN p_stu_id VARCHAR(32),
    IN p_subject_id VARCHAR(32),
    IN p_subject_sub_id VARCHAR(32),
    IN p_lesson_type INT,
    IN p_minutes_per_lsn INT,
    IN p_subject_price DECIMAL(10,2),
    IN p_bank_id VARCHAR(32),
    IN p_lsn_seq_code VARCHAR(20),
    IN p_fee_seq_code VARCHAR(20),
    IN p_pay_seq_code VARCHAR(20),
    IN p_preview_json JSON,
    OUT p_result INT
)
BEGIN
    -- ============================================================
    -- 执行按课时预支付处理（简化版）
    --
    -- 直接按照 Preview SP 返回的结果执行，不再重新计算。
    -- Preview 结果以 JSON 数组传入，包含每条记录的：
    --   - schedual_date: 排课日期时间
    --   - processing_mode: 处理模式 A/B/C（D模式在Preview阶段已过滤）
    --   - existing_lesson_id: 既存课程ID（模式B/C时非NULL）
    --   - existing_fee_id: 既存课费ID（模式C时非NULL）
    --
    -- 处理模式：
    --   A = 无既存课程 → INSERT lesson + fee + pay + advc_pay
    --   B = 未签到既存课程 → 复用lesson，INSERT fee + pay
    --   C = 已签到未支付既存课程 → 复用lesson+fee，INSERT pay
    -- ============================================================

    -- 声明常量
    DECLARE PROCEDURE_NAME VARCHAR(100) DEFAULT 'sp_execute_advc_lsn_fee_pay_per_lesson';
    DECLARE PROCEDURE_ALIAS_NAME VARCHAR(100) DEFAULT '执行按课时预支付处理';

    DECLARE v_lesson_id VARCHAR(50);
    DECLARE v_lsn_fee_id VARCHAR(50);
    DECLARE v_lsn_pay_id VARCHAR(50);
    DECLARE v_lsn_month VARCHAR(7);
    DECLARE v_step_result VARCHAR(255);
    DECLARE v_current_step VARCHAR(100) DEFAULT '初始化';
    DECLARE v_error_message TEXT;

    -- 循环控制
    DECLARE v_processed_count INT DEFAULT 0;
    DECLARE v_total_count INT DEFAULT 0;
    DECLARE v_idx INT DEFAULT 0;

    -- 每条记录的数据
    DECLARE v_schedual_date DATETIME;
    DECLARE v_mode VARCHAR(1);
    DECLARE v_existing_lesson_id VARCHAR(50);
    DECLARE v_existing_fee_id VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_message = MESSAGE_TEXT;

        SET p_result = 0;
        ROLLBACK;

        INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
        VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step,
                CONCAT('发生错误: ', v_error_message));
    END;

    START TRANSACTION;

    -- 获取 JSON 数组长度
    SET v_total_count = JSON_LENGTH(p_preview_json);

    SET v_current_step = '初始化：按课时预支付循环';
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step,
            CONCAT('学生:', p_stu_id, ' 科目:', p_subject_id, ' 预览记录数:', v_total_count));

    -- ============================
    -- 遍历 JSON 数组，按 Preview 结果执行
    -- ============================
    WHILE v_idx < v_total_count DO

        -- 从 JSON 数组中提取当前记录
        SET v_schedual_date = JSON_UNQUOTE(JSON_EXTRACT(p_preview_json, CONCAT('$[', v_idx, '].schedualDate')));
        SET v_mode = JSON_UNQUOTE(JSON_EXTRACT(p_preview_json, CONCAT('$[', v_idx, '].processingMode')));
        SET v_existing_lesson_id = JSON_UNQUOTE(JSON_EXTRACT(p_preview_json, CONCAT('$[', v_idx, '].existingLessonId')));
        SET v_existing_fee_id = JSON_UNQUOTE(JSON_EXTRACT(p_preview_json, CONCAT('$[', v_idx, '].existingFeeId')));

        -- 处理 null 值
        IF v_existing_lesson_id = 'null' THEN SET v_existing_lesson_id = NULL; END IF;
        IF v_existing_fee_id = 'null' THEN SET v_existing_fee_id = NULL; END IF;

        SET v_lsn_month = DATE_FORMAT(v_schedual_date, '%Y-%m');
        SET v_processed_count = v_processed_count + 1;

        SET v_current_step = CONCAT('第', v_processed_count, '条 日期:', DATE_FORMAT(v_schedual_date, '%Y-%m-%d %H:%i'), ' 模式:', v_mode);

        -- ============================================
        -- 根据模式执行操作
        -- ============================================

        IF v_mode = 'A' THEN
            -- ===== 模式A：全新创建 lesson + fee + pay + advc_pay =====

            -- A-1: 新建lesson
            SET v_lesson_id = CONCAT(p_lsn_seq_code, nextval(p_lsn_seq_code));
            INSERT INTO t_info_lesson (
                lesson_id, stu_id, subject_id, subject_sub_id,
                class_duration, lesson_type, schedual_type, schedual_date
            ) VALUES (
                v_lesson_id, p_stu_id, p_subject_id, p_subject_sub_id,
                p_minutes_per_lsn, p_lesson_type, 0, v_schedual_date
            );

            -- A-2: 新建fee
            SET v_lsn_fee_id = CONCAT(p_fee_seq_code, nextval(p_fee_seq_code));
            INSERT INTO t_info_lesson_fee (
                lsn_fee_id, lesson_id, pay_style, lsn_fee, lsn_month, own_flg
            ) VALUES (
                v_lsn_fee_id, v_lesson_id, 0, p_subject_price, v_lsn_month, 1
            );

            -- A-3: 新建pay
            SET v_lsn_pay_id = CONCAT(p_pay_seq_code, nextval(p_pay_seq_code));
            INSERT INTO t_info_lesson_pay (
                lsn_pay_id, lsn_fee_id, lsn_pay, bank_id, pay_month, pay_date
            ) VALUES (
                v_lsn_pay_id, v_lsn_fee_id, p_subject_price, p_bank_id, v_lsn_month, CURDATE()
            );

            -- A-4: 新建advc_pay（仅A模式记录到预支付关联表）
            INSERT INTO t_info_lsn_fee_advc_pay (
                lesson_id, lsn_fee_id, lsn_pay_id, advance_pay_date
            ) VALUES (
                v_lesson_id, v_lsn_fee_id, v_lsn_pay_id, CURDATE()
            );

            SET v_step_result = CONCAT('A模式完成 lesson:', v_lesson_id);

        ELSEIF v_mode = 'B' THEN
            -- ===== 模式B：复用lesson，新建 fee + pay =====
            SET v_lesson_id = v_existing_lesson_id;

            -- B-1: 新建fee
            SET v_lsn_fee_id = CONCAT(p_fee_seq_code, nextval(p_fee_seq_code));
            INSERT INTO t_info_lesson_fee (
                lsn_fee_id, lesson_id, pay_style, lsn_fee, lsn_month, own_flg
            ) VALUES (
                v_lsn_fee_id, v_lesson_id, 0, p_subject_price, v_lsn_month, 1
            );

            -- B-2: 新建pay
            SET v_lsn_pay_id = CONCAT(p_pay_seq_code, nextval(p_pay_seq_code));
            INSERT INTO t_info_lesson_pay (
                lsn_pay_id, lsn_fee_id, lsn_pay, bank_id, pay_month, pay_date
            ) VALUES (
                v_lsn_pay_id, v_lsn_fee_id, p_subject_price, p_bank_id, v_lsn_month, CURDATE()
            );

            SET v_step_result = CONCAT('B模式完成 复用lesson:', v_lesson_id);

        ELSEIF v_mode = 'C' THEN
            -- ===== 模式C：复用lesson+fee，新建 pay =====
            SET v_lesson_id = v_existing_lesson_id;
            SET v_lsn_fee_id = v_existing_fee_id;

            -- C-1: 新建pay
            SET v_lsn_pay_id = CONCAT(p_pay_seq_code, nextval(p_pay_seq_code));
            INSERT INTO t_info_lesson_pay (
                lsn_pay_id, lsn_fee_id, lsn_pay, bank_id, pay_month, pay_date
            ) VALUES (
                v_lsn_pay_id, v_lsn_fee_id, p_subject_price, p_bank_id, v_lsn_month, CURDATE()
            );

            -- C-2: 更新fee的own_flg为已支付（关键步骤！）
            -- 注：update_date由触发器before_update_t_info_lesson_fee自动更新
            UPDATE t_info_lesson_fee
            SET own_flg = 1
            WHERE lsn_fee_id = v_lsn_fee_id;

            SET v_step_result = CONCAT('C模式完成 复用lesson:', v_lesson_id, ' fee:', v_lsn_fee_id);

        ELSE
            -- 未知模式（不应该发生，Preview阶段已过滤D模式）
            SET v_step_result = CONCAT('未知模式:', v_mode, ' - 跳过');

        END IF;

        -- 记录执行日志
        INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
        VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, v_step_result);

        SET v_idx = v_idx + 1;

    END WHILE;

    COMMIT;
    SET p_result = 1;

    SET v_current_step = '存储过程完成';
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step,
            CONCAT('成功：共处理', v_processed_count, '条记录'));

END //

DELIMITER ;
