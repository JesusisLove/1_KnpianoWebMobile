-- ==========================================
-- 存储过程: sp_insert_tmp_lesson_info
-- 功能: 从学生档案视图查询最新课程信息并插入到临时课程表
-- 参数:
--   p_stu_id: 学生学号
--   p_subject_id: 科目编号
--   p_target_date: 目标日期（格式: yyyy-mm-dd）
-- 创建日期: 2025-12-22
-- ==========================================

DELIMITER //

DROP PROCEDURE IF EXISTS sp_insert_tmp_lesson_info//

CREATE PROCEDURE sp_insert_tmp_lesson_info(
    IN p_stu_id VARCHAR(32),
    IN p_subject_id VARCHAR(32),
    IN p_target_date VARCHAR(10)
)
BEGIN
    DECLARE v_lsn_tmp_id VARCHAR(32);
    DECLARE v_lsn_fee_id VARCHAR(32);
    DECLARE v_stu_id VARCHAR(32);
    DECLARE v_subject_id VARCHAR(32);
    DECLARE v_subject_sub_id VARCHAR(32);
    DECLARE v_lesson_fee FLOAT;
    DECLARE v_lesson_fee_adjusted FLOAT;
    DECLARE v_lsn_fee FLOAT;
    DECLARE v_record_count INT DEFAULT 0;
    DECLARE v_generated_count INT DEFAULT 0;

    -- 异常处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- 发生错误时回滚
        ROLLBACK;
        -- 可以选择抛出错误信息
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 防重复：同一学生、同一科目、同一月份已生成时不再写入
    SELECT COUNT(*) INTO v_generated_count
    FROM t_info_lesson_tmp
    WHERE stu_id = p_stu_id
      AND subject_id = p_subject_id
      AND DATE_FORMAT(schedual_date, '%Y-%m') = SUBSTRING(p_target_date, 1, 7);

    IF v_generated_count > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '该月的空月课费已生成，不能重复生成';
    END IF;

    -- 生成主键ID（前缀 + 数字）
    SET v_lsn_tmp_id = CONCAT('kn-lsn-tmp-', nextval('kn-lsn-tmp-'));

    -- 从学生档案视图查询最新的课程信息
    -- 1. 查询价格调整日期 <= 当前日期的记录
    -- 2. 使用窗口函数按调整日期降序排序
    -- 3. 按调整日期倒序排列后 LIMIT 1 取最新记录（窗口函数只编号、不决定输出顺序，必须显式排序）
    -- 4. 只查询 t_info_lesson_tmp 表需要的字段
    SELECT
        vDoc.stu_id,
        vDoc.subject_id,
        vDoc.subject_sub_id,
        vDoc.lesson_fee,
        vDoc.lesson_fee_adjusted,
        row_number() OVER (
            PARTITION BY vDoc.stu_id, vDoc.subject_id
            ORDER BY vDoc.adjusted_date DESC
        ) AS rn
    INTO
        v_stu_id,
        v_subject_id,
        v_subject_sub_id,
        v_lesson_fee,
        v_lesson_fee_adjusted,
        v_record_count  -- 复用该变量存储 rn 值
    FROM v_info_student_document vDoc
    WHERE vDoc.adjusted_date <= CURDATE()
      AND vDoc.stu_id = p_stu_id
      AND vDoc.subject_id = p_subject_id
    ORDER BY vDoc.adjusted_date DESC
    LIMIT 1;

    -- 检查是否找到记录
    IF v_stu_id IS NULL THEN
        -- 没有找到符合条件的记录
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '未找到符合条件的学生课程档案记录';
    END IF;

    -- 计算课程费用：lesson_fee_adjusted 大于 0 时优先使用，为 0 或 NULL 时使用 lesson_fee
    SET v_lsn_fee = CASE WHEN v_lesson_fee_adjusted > 0
                         THEN v_lesson_fee_adjusted
                         ELSE v_lesson_fee END;

    -- 插入到临时课程表（del_flg, create_date, update_date 使用默认值）
    INSERT INTO t_info_lesson_tmp (
        lsn_tmp_id,
        stu_id,
        subject_id,
        subject_sub_id,
        schedual_date,
        scanqr_date
    ) VALUES (
        v_lsn_tmp_id,                               -- 主键（采番）
        v_stu_id,                                   -- 学生ID（从视图查询）
        v_subject_id,                               -- 科目ID（从视图查询）
        v_subject_sub_id,                           -- 子科目ID（从视图查询）
        STR_TO_DATE(p_target_date, '%Y-%m-%d'),     -- 计划日期（参数传入，转换为DATETIME）
        STR_TO_DATE(p_target_date, '%Y-%m-%d')      -- 扫码日期（参数传入，转换为DATETIME）
    );

    -- 生成课费表主键ID
    SET v_lsn_fee_id = CONCAT('kn-fee-', nextval('kn-fee-'));

    -- 插入到课费表（del_flg, create_date, update_date 使用默认值）
    -- 注意：如果外键约束导致插入失败，需要禁用约束检查或修改外键定义
    INSERT INTO t_info_lesson_fee (
        lsn_fee_id,
        lesson_id,
        pay_style,
        lsn_fee,
        lsn_month,
        own_flg
    ) VALUES (
        v_lsn_fee_id,                               -- 主键（采番）
        v_lsn_tmp_id,                               -- 课程ID（引用临时课程表）
        1,                                          -- 支付方式（固定值1）
        v_lsn_fee,                                  -- 课程费用（COALESCE结果）
        SUBSTRING(p_target_date, 1, 7),             -- 课程月份（yyyy-mm格式）
        0                                           -- own_flg（固定值0）
    );

    COMMIT;

    -- 可选：返回插入的记录ID
    SELECT v_lsn_tmp_id AS inserted_lsn_tmp_id;

END//

DELIMITER ;
