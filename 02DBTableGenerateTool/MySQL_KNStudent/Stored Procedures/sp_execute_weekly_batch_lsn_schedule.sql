DELIMITER //

DROP PROCEDURE IF EXISTS sp_execute_weekly_batch_lsn_schedule //

CREATE DEFINER=`root`@`%` PROCEDURE `sp_execute_weekly_batch_lsn_schedule`(IN start_date_str VARCHAR(10), IN end_date_str VARCHAR(10), IN SEQCode VARCHAR(20))
BEGIN
    -- 声明常量
    DECLARE PROCEDURE_NAME VARCHAR(100) DEFAULT 'sp_execute_weekly_batch_lsn_schedule';
    DECLARE PROCEDURE_ALIAS_NAME VARCHAR(100) DEFAULT '执行周计划排课处理';

    -- 声明变量用于日志记录
    DECLARE v_step_result VARCHAR(255);
    DECLARE v_current_step VARCHAR(100) DEFAULT '初始化';
    DECLARE v_error_message TEXT;
    DECLARE v_affected_rows INT;

    -- 定义异常处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_message = MESSAGE_TEXT;
        
        INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
        VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, 
                CONCAT('发生错误: ', v_error_message));
        
        -- 重新抛出错误
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END;

    -- 创建临时表
    SET v_current_step = '创建临时表';
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_date_range (
        date_column DATE,
        weekday_column VARCHAR(20)
    );
    
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, '成功');

    -- 清空临时表
    SET v_current_step = '清空临时表';
    TRUNCATE TABLE temp_date_range;
    
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, '成功');

    -- 插入数据
    SET v_current_step = '生成日期和星期关系数据';
    INSERT INTO temp_date_range (date_column, weekday_column)
    SELECT 
        STR_TO_DATE(date_column, '%Y-%m-%d') AS date_column,
        DATE_FORMAT(STR_TO_DATE(date_column, '%Y-%m-%d'), '%a') AS weekday_column
    FROM (
        SELECT DISTINCT
            SUBSTRING_INDEX(SUBSTRING_INDEX(generate_weekly_date_series(start_date_str, end_date_str), ',', numbers.n), ',', -1) AS date_column
        FROM (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
            UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
            UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
        ) numbers
    ) date_range;

    SET v_affected_rows = ROW_COUNT();
    SET v_step_result = IF(v_affected_rows > 0, CONCAT('成功: 插入 ', v_affected_rows, ' 行'), '未插入任何行');
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, v_step_result);

    -- 创建临时表存储新的课程安排
    SET v_current_step = '创建临时表存储新的课程安排';
    -- 创建了一个临时表 temp_new_lessons 来存储所有可能的新课程安排。
    CREATE TEMPORARY TABLE temp_new_lessons AS
    SELECT 
        fix.subject_id,
        doc.subject_sub_id,
        fix.stu_id,
        doc.minutes_per_lsn as class_duration,
        CASE 
            WHEN doc.pay_style = 0 THEN 0
            WHEN doc.pay_style = 1 THEN 1
        END AS lesson_type,
        1 as schedual_type,
        CONCAT(cdr.date_column, ' ', LPAD(fix.fixed_hour, 2, '0'), ':', LPAD(fix.fixed_minute, 2, '0')) as schedual_date
    FROM 
        v_info_fixedlesson fix
    LEFT JOIN 
        v_latest_subject_info_from_student_document doc
        ON fix.stu_id = doc.stu_id AND fix.subject_id = doc.subject_id
	   -- AND fix.del_flg = 0 -- 已暂时停课的学生除外(目前该表无此字段)
    INNER JOIN 
        temp_date_range cdr
        ON cdr.weekday_column = fix.fixed_week;

    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, '成功');

    -- 插入新的课程安排，排除已存在的课程 ：使用了 NOT EXISTS 子查询来确保只插入尚未存在的课程。
    --
    -- [BUG修复 2026-01-28] 重复排课问题
    -- 问题: 原代码只检查 schedual_type = 1 (Batch排课)，忽略了 schedual_type = 0 (手动排课)
    --       导致老师手动排课后，自动排课仍会在同一时间点重复排课
    -- 修复: 改为检查 schedual_type IN (0, 1)，同时检查手动排课和Batch排课
    --       schedual_type = 0: 手动排课（老师通过界面手动添加）
    --       schedual_type = 1: Batch排课（自动排课批处理生成）
    --
    SET v_current_step = '向t_info_lesson表插入新的课程安排';
    INSERT INTO t_info_lesson (lesson_id, subject_id, subject_sub_id, stu_id, class_duration, lesson_type, schedual_type, schedual_date)
    SELECT
        CONCAT(SEQCode, nextval(SEQCode)) as lesson_id,
        tnl.subject_id,
        tnl.subject_sub_id,
        tnl.stu_id,
        tnl.class_duration,
        tnl.lesson_type,
        tnl.schedual_type,
        tnl.schedual_date
    FROM
        temp_new_lessons tnl
    WHERE NOT EXISTS (
        SELECT 1
        FROM t_info_lesson til
        WHERE til.stu_id = tnl.stu_id
        AND til.subject_id = tnl.subject_id
        AND til.subject_sub_id = tnl.subject_sub_id
        AND til.schedual_date = tnl.schedual_date
        AND til.schedual_type IN (0, 1)  -- 检查手动排课(0)和Batch排课(1)，避免重复排课
    );

    SET v_affected_rows = ROW_COUNT();
    SET v_step_result = IF(v_affected_rows > 0, CONCAT('成功: 插入 ', v_affected_rows, ' 行'), '未插入任何行');
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, v_step_result);

    -- 删除临时表
    SET v_current_step = '删除临时表';
    DROP TEMPORARY TABLE IF EXISTS temp_date_range;
    DROP TEMPORARY TABLE IF EXISTS temp_new_lessons;
    
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, '成功');

    -- 存储过程完成
    SET v_current_step = '存储过程完成';
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, '成功');

END //

DELIMITER ;