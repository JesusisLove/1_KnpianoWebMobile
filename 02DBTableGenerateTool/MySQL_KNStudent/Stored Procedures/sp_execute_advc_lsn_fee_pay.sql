DELIMITER //

DROP PROCEDURE IF EXISTS sp_execute_advc_lsn_fee_pay //

CREATE PROCEDURE sp_execute_advc_lsn_fee_pay(
    IN p_stu_id VARCHAR(32),
    IN p_subject_id VARCHAR(32),
    IN p_subject_sub_id VARCHAR(32),
    IN p_lesson_type INT,
    IN p_minutes_per_lsn INT,
    IN p_subject_price DECIMAL(10,2),
    IN p_schedual_datetime DATETIME,
    IN p_bank_id VARCHAR(32),
    IN p_lsn_seq_code VARCHAR(20),
    IN p_fee_seq_code VARCHAR(20),
    IN p_pay_seq_code VARCHAR(20),
    OUT p_result INT
)
BEGIN
    -- 声明常量
    DECLARE PROCEDURE_NAME VARCHAR(100) DEFAULT 'sp_execute_advc_lsn_fee_pay';
    DECLARE PROCEDURE_ALIAS_NAME VARCHAR(100) DEFAULT '执行课费预支付处理';

    DECLARE v_lesson_id VARCHAR(50);
    DECLARE v_lsn_fee_id VARCHAR(50);
    DECLARE v_lsn_pay_id VARCHAR(50);
    DECLARE v_count INT;
    DECLARE v_lsn_month VARCHAR(7);
    DECLARE v_schedual_date DATETIME;
    DECLARE v_step_result VARCHAR(255);
    DECLARE v_current_step VARCHAR(100) DEFAULT '初始化';
    DECLARE v_error_message TEXT;
    DECLARE v_is_new_lesson BOOLEAN;

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

    SET v_current_step = '初始化日期和时间';
    SET v_schedual_date = p_schedual_datetime;

    -- 步骤 1: 检查 v_info_lesson 表
    SET v_current_step = '1 检查 v_info_lesson';
    SELECT COUNT(*) INTO v_count
    FROM v_info_lesson
    WHERE stu_id = p_stu_id
    AND subject_id = p_subject_id
    AND subject_sub_id = p_subject_sub_id
    AND lesson_type = p_lesson_type
    AND class_duration = p_minutes_per_lsn
    AND schedual_date = v_schedual_date;

    IF v_count > 0 THEN
        SELECT lesson_id INTO v_lesson_id
        FROM v_info_lesson
        WHERE stu_id = p_stu_id
        AND subject_id = p_subject_id
        AND subject_sub_id = p_subject_sub_id
        AND lesson_type = p_lesson_type
        AND class_duration = p_minutes_per_lsn
        AND schedual_date = v_schedual_date
        LIMIT 1;
        SET v_step_result = CONCAT('本月既存的lesson_id: ', v_lesson_id);
        SET v_is_new_lesson = FALSE;
    ELSE
        SET v_lesson_id = CONCAT(p_lsn_seq_code, nextval(p_lsn_seq_code));
        SET v_step_result = CONCAT('自动采番的lesson_id: ', v_lesson_id);
        SET v_is_new_lesson = TRUE;
    END IF;

    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, v_step_result);

    -- 步骤 2: 插入到 t_info_lesson（仅对新lesson执行）
    IF v_is_new_lesson THEN
        SET v_current_step = '2 插入到 t_info_lesson';
        INSERT INTO t_info_lesson (
            lesson_id, stu_id, subject_id, subject_sub_id, 
            class_duration, lesson_type, schedual_type, schedual_date
        ) VALUES (
            v_lesson_id, p_stu_id, p_subject_id, p_subject_sub_id,
            p_minutes_per_lsn, p_lesson_type, 0, v_schedual_date
        );

        SET v_step_result = IF(ROW_COUNT() > 0, '成功', '插入失败');
        INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
        VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, v_step_result);
    END IF;

    -- 步骤 3: 插入到 t_info_lesson_fee
    SET v_current_step = '3 插入到 t_info_lesson_fee';
    SET v_lsn_fee_id = CONCAT(p_fee_seq_code, nextval(p_fee_seq_code));
    SET v_lsn_month = DATE_FORMAT(v_schedual_date, '%Y-%m');

    INSERT INTO t_info_lesson_fee (
        lsn_fee_id, lesson_id, pay_style, lsn_fee, lsn_month, own_flg
    ) VALUES (
        v_lsn_fee_id, v_lesson_id, 1, p_subject_price, v_lsn_month, 1
    );

    SET v_step_result = IF(ROW_COUNT() > 0, '成功', '插入失败');
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, v_step_result);

    -- 步骤 4: 插入到 t_info_lesson_pay
    SET v_current_step = '4 插入到 t_info_lesson_pay';
    SET v_lsn_pay_id = CONCAT(p_pay_seq_code, nextval(p_pay_seq_code));

    INSERT INTO t_info_lesson_pay (
        lsn_pay_id, lsn_fee_id, lsn_pay, bank_id, pay_month, pay_date
    ) VALUES (
        v_lsn_pay_id,
        v_lsn_fee_id,
        p_subject_price * 4, -- 月计划课程是按月缴费，所以应缴纳4节课的价钱
        p_bank_id,
        v_lsn_month,
        CURDATE()
    );

    SET v_step_result = IF(ROW_COUNT() > 0, '成功', '插入失败');
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, v_step_result);

    -- 步骤 5: 插入到 t_info_lsn_fee_advc_pay
    SET v_current_step = '5 插入到 t_info_lsn_fee_advc_pay';
    INSERT INTO t_info_lsn_fee_advc_pay (
        lesson_id, lsn_fee_id, lsn_pay_id, advance_pay_date
    ) VALUES (
        v_lesson_id,
        v_lsn_fee_id,
        v_lsn_pay_id,
        CURDATE()
    );

    SET v_step_result = IF(ROW_COUNT() > 0, '成功', '插入失败');
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, v_step_result);

    COMMIT;
    SET p_result = 1;

    SET v_current_step = '6 存储过程完成';
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, '成功');

END //

DELIMITER ;