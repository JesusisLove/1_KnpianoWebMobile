-- ///// FUNCTION ///////////////////////////////////////////////////////////////////////////////
-- USE prod_KNStudent;
DROP FUNCTION IF EXISTS `currval`;
DELIMITER //
CREATE DEFINER = `root`@`%` FUNCTION `currval`(seq_id VARCHAR(50))
RETURNS int
DETERMINISTIC
BEGIN
    DECLARE value INTEGER;
    SET value = 0;
    SELECT current_value INTO value
        FROM sequence
        WHERE seqid = seq_id;
    RETURN value;
END//
DELIMITER ;

-- USE prod_KNStudent;
DROP FUNCTION IF EXISTS `nextval`;
DELIMITER //
CREATE DEFINER = `root`@`%` FUNCTION `nextval`(seq_id VARCHAR(50)) RETURNS int
    DETERMINISTIC
BEGIN
    UPDATE sequence
    SET current_value = current_value + increment
    WHERE seqid = seq_id;
    RETURN currval(seq_id);
END//
DELIMITER ;

-- USE prod_KNStudent;
DROP FUNCTION IF EXISTS `setval`;
DELIMITER //
CREATE DEFINER = `root`@`%` FUNCTION `setval`(seq_id VARCHAR(50), value INTEGER) RETURNS int
    DETERMINISTIC
BEGIN
    UPDATE sequence
    SET current_value = value
    WHERE seqid = seq_id;
    RETURN currval(seq_id);
END//
DELIMITER ;


-- ///// TRIGGER ///////////////////////////////////////////////////////////////////////////////
-- 01学生基本情報マスタ：创建更新日触发器
-- USE prod_KNStudent;
DROP TRIGGER IF EXISTS `before_update_t_mst_student`;
-- 更新t_mst_student表update_date字段的触发器
DELIMITER $$
CREATE DEFINER = `root`@`%` TRIGGER before_update_t_mst_student
BEFORE UPDATE ON t_mst_student
FOR EACH ROW
BEGIN
   SET NEW.update_date = CURRENT_TIMESTAMP;
END$$
DELIMITER ;

-- 02学科基本情報マスタ：创建更新日触发器
-- USE prod_KNStudent;
DROP TRIGGER IF EXISTS `before_update_t_mst_subject`;
-- 更新t_mst_subject表update_date字段的触发器
DELIMITER $$
CREATE DEFINER = `root`@`%` TRIGGER before_update_t_mst_subject
BEFORE UPDATE ON t_mst_subject
FOR EACH ROW
BEGIN
   SET NEW.update_date = CURRENT_TIMESTAMP;
END$$
DELIMITER ;


-- USE prod_KNStudent;
DROP TRIGGER IF EXISTS `before_update_t_info_subject_edaban`;
-- 更新t_info_subject_edaban表update_date字段的触发器
DELIMITER $$
CREATE DEFINER = `root`@`%` TRIGGER before_update_t_info_subject_edaban
BEFORE UPDATE ON t_info_subject_edaban
FOR EACH ROW
BEGIN
   SET NEW.update_date = CURRENT_TIMESTAMP;
END$$
DELIMITER ;


-- 03銀行基本情報マスタ：创建更新日触发器
-- USE prod_KNStudent;
DROP TRIGGER IF EXISTS `before_update_t_mst_bank`;
-- 更新t_mst_bank表update_date字段的触发器
DELIMITER $$
CREATE DEFINER = `root`@`%` TRIGGER before_update_t_mst_bank
BEFORE UPDATE ON t_mst_bank
FOR EACH ROW
BEGIN
   SET NEW.update_date = CURRENT_TIMESTAMP;
END$$
DELIMITER ;


-- USE prod_KNStudent;
DROP TRIGGER IF EXISTS `before_update_t_info_student_bank`;
-- 更新t_info_student_bank表update_date字段的触发器
DELIMITER $$
CREATE DEFINER = `root`@`%` TRIGGER before_update_t_info_student_bank
BEFORE UPDATE ON t_info_student_bank
FOR EACH ROW
BEGIN
   SET NEW.update_date = CURRENT_TIMESTAMP;
END$$
DELIMITER ;


-- 11学生歴史ドキュメント情報：创建更新日触发器
-- USE prod_KNStudent;
DROP TRIGGER IF EXISTS `before_update_t_info_student_document`;
-- 更新t_info_student_document表update_date字段的触发器
DELIMITER $$
CREATE DEFINER = `root`@`%` TRIGGER before_update_t_info_student_document
BEFORE UPDATE ON t_info_student_document
FOR EACH ROW
BEGIN
   SET NEW.update_date = CURRENT_TIMESTAMP;
END$$
DELIMITER ;


-- 12学生授業情報管理：创建更新日触发器
-- USE prod_KNStudent;
DROP TRIGGER IF EXISTS `before_update_t_info_lesson`;
-- 更新t_info_lesson表update_date字段的触发器
DELIMITER $$
CREATE DEFINER = `root`@`%` TRIGGER before_update_t_info_lesson
BEFORE UPDATE ON t_info_lesson
FOR EACH ROW
BEGIN
   SET NEW.update_date = CURRENT_TIMESTAMP;
END$$
DELIMITER ;

-- 21授業料金情報管理：创建更新日触发器
-- USE prod_KNStudent;
DROP TRIGGER IF EXISTS `before_update_t_info_lesson_fee`;
-- 更新t_info_lesson_fee表update_date字段的触发器
DELIMITER $$
CREATE DEFINER = `root`@`%` TRIGGER before_update_t_info_lesson_fee
BEFORE UPDATE ON t_info_lesson_fee
FOR EACH ROW
BEGIN
   SET NEW.update_date = CURRENT_TIMESTAMP;
END$$
DELIMITER ;


-- 22授業課費精算管理
-- USE prod_KNStudent;
DROP TRIGGER IF EXISTS `before_update_t_info_lesson_pay`;
-- 更新t_info_lesson_pay表update_date字段的触发器
DELIMITER $$
CREATE DEFINER = `root`@`%` TRIGGER before_update_t_info_lesson_pay
BEFORE UPDATE ON t_info_lesson_pay
FOR EACH ROW
BEGIN
   SET NEW.update_date = CURRENT_TIMESTAMP;
END$$
DELIMITER ;

-- 23虚拟课程表管理（假如该生10月已经上满43节课，后续的11，12月需要虚拟课程ID产生11月，12月的按月缴纳的课费而设立的虚拟课程表管理）
-- USE prod_KNStudent;
DROP TRIGGER IF EXISTS `before_update_t_info_lesson_pay`;
-- 更新t_info_lesson_pay表update_date字段的触发器
DELIMITER $$
CREATE DEFINER = `root`@`%` TRIGGER before_update_t_info_lesson_tmp
BEFORE UPDATE ON t_info_lesson_tmp
FOR EACH ROW
BEGIN
   SET NEW.update_date = CURRENT_TIMESTAMP;
END$$
DELIMITER ;

-- ///// PROCEDURE ///////////////////////////////////////////////////////////////////////////////
-- 1.年利用度星期生成表结合学生固定排课表，对学生进行一星期自动化排课
-- USE prod_KNStudent;
DROP FUNCTION IF EXISTS `generate_weekly_date_series`;
-- 保持日期序列生成函数不变只要一周的表数据信息
DELIMITER //
CREATE DEFINER = `root`@`%` FUNCTION generate_weekly_date_series(start_date_str VARCHAR(10), end_date_str VARCHAR(10))
RETURNS VARCHAR(4000)
DETERMINISTIC
BEGIN
    DECLARE date_list VARCHAR(4000);
    DECLARE curr_date DATE;
    DECLARE start_date DATE;
    DECLARE end_date DATE;
    
    SET start_date = STR_TO_DATE(start_date_str, '%Y-%m-%d');
    SET end_date = STR_TO_DATE(end_date_str, '%Y-%m-%d');
    
    SET date_list = '';
    SET curr_date = start_date;
    
    WHILE curr_date <= end_date DO
        SET date_list = CONCAT(date_list, DATE_FORMAT(curr_date, '%Y-%m-%d'), ',');
        SET curr_date = DATE_ADD(curr_date, INTERVAL 1 DAY);
    END WHILE;
    
    RETURN TRIM(TRAILING ',' FROM date_list);
END //
DELIMITER ;

-- 创建一个存储过程来生成日期范围
-- USE prod_KNStudent;
DROP PROCEDURE IF EXISTS `sp_weekly_batch_lsn_schedule_process`;
/**
INPUT：一周的开始日期和一周的结束日期
OUTPUT：生成要插入到上课信息表的一周的结果集
*/
DELIMITER //
CREATE DEFINER = `root`@`%` PROCEDURE sp_weekly_batch_lsn_schedule_process(IN start_date_str VARCHAR(10), IN end_date_str VARCHAR(10), IN SEQCode VARCHAR(20))
BEGIN
    -- 创建临时表
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_date_range (
        date_column DATE,
        weekday_column VARCHAR(20)
    );

    -- 清空临时表
    TRUNCATE TABLE temp_date_range;

    -- 插入数据
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

    -- 显示结果
    -- SELECT * FROM temp_date_range;
    -- 根据关联表，将制定日期范围的学生排课信息直接插入到上课信息表【t_info_lesson】的数据
	INSERT INTO t_info_lesson (lesson_id,subject_id,subject_sub_id,stu_id,class_duration,lesson_type,schedual_type,schedual_date)
    SELECT 
		CONCAT(SEQCode, nextval(SEQCode)) as lesson_id,
        fix.subject_id,
        doc.subject_sub_id,
		fix.stu_id,
		doc.minutes_per_lsn as class_duration,
		CASE 
			WHEN doc.pay_style = 0 THEN 0
			WHEN doc.pay_style = 1 THEN 1
		END AS lesson_type,
        1 AS schedual_type,
		CONCAT(cdr.date_column, ' ', LPAD(fix.fixed_hour, 2, '0'), ':', LPAD(fix.fixed_minute, 2, '0')) as schedual_date
	FROM 
		t_info_fixedlesson fix -- 一周排课的日期范围
	LEFT JOIN 
		v_latest_subject_info_from_student_document doc -- 学生档案最新正在上课的科目信息
		ON fix.stu_id = doc.stu_id AND fix.subject_id = doc.subject_id
	INNER JOIN 
		temp_date_range cdr
		ON cdr.weekday_column = fix.fixed_week; -- 学生固定排课表
END //
DELIMITER ;
-- 使用示例
-- CALL create_date_range('2024-08-12', '2024-08-18');


-- 2.在课学生课程费用按照学生和月的分组合计
-- USE prod_KNStudent;
DROP PROCEDURE IF EXISTS `sp_sum_unpaid_lsnfee_by_stu_and_month`;
DELIMITER //
-- 每个学生每个月未支付状况的分组合计 sp_sum_unpaid_lsnfee_by_stu_and_month
CREATE DEFINER = `root`@`%` PROCEDURE sp_sum_unpaid_lsnfee_by_stu_and_month (IN currentYear VARCHAR(4))
BEGIN
    SET @sql = CONCAT('
        SELECT 
            stu_id,
            stu_name,
            SUM(CASE 
                    WHEN lesson_type = 1 THEN subject_price * 4
                    ELSE lsn_fee
                END) AS lsn_fee,
            lsn_month
        FROM v_info_lesson_sum_fee_unpaid_yet
        WHERE SUBSTRING(lsn_month, 1, 4) = ', currentYear, '
        GROUP BY stu_id, stu_name, lsn_month
        ORDER BY lsn_month, CAST(SUBSTRING_INDEX(stu_id, ''-'', -1) AS UNSIGNED);
    ');

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

-- 推算预支付课程的排课日期
-- USE prod_KNStudent;
DELIMITER //
DROP PROCEDURE IF EXISTS sp_get_advance_pay_subjects_and_lsnschedual_info //
CREATE DEFINER = `root`@`%` PROCEDURE `sp_get_advance_pay_subjects_and_lsnschedual_info`(IN p_stuId VARCHAR(32), IN p_yearMonth VARCHAR(7))
BEGIN
    DECLARE v_first_day DATE;
    -- 临时禁用安全更新模式，以允许不使用主键的更新操作
    SET SQL_SAFE_UPDATES = 0;
    
    -- 确保临时表不存在，防止重复创建错误
    DROP TEMPORARY TABLE IF EXISTS temp_result;

    -- 创建临时表来存储计算后的结果
    CREATE TEMPORARY TABLE temp_result AS
	-- 第一部分：获取学生档案中存在但在课程信息表中不存在的科目数据
	WITH MaxSubIds AS (
	 -- 取得学生们各科目中截止到目前学过的或正在学的最大子科目（即，子科目id值最大的那个科目） 
		SELECT 
			t.*
		FROM v_latest_subject_info_from_student_document t
		INNER JOIN (
			SELECT 
				stu_id,
				subject_id,
				MAX(CAST(SUBSTRING_INDEX(subject_sub_id, '-', -1) AS UNSIGNED)) as max_num
			FROM v_latest_subject_info_from_student_document
			WHERE 1 = 1
            AND pay_style = 1 -- 仅限于按月交费的科目
			-- 价格调整日期小于系统当前日期，目的是防止未来准备要上，目前还没有开始上的科目不出现在当前的预支付中
			AND adjusted_date <= CURDATE()
			GROUP BY stu_id, subject_id
		) m ON t.stu_id = m.stu_id 
			AND t.subject_id = m.subject_id
			-- 学科子科目（例如：钢琴1级，2级等）的最大值
			AND CAST(SUBSTRING_INDEX(t.subject_sub_id, '-', -1) AS UNSIGNED) = m.max_num
			-- 只限于当前在课的学生
			AND t.stu_id in (select stu_id from t_mst_student where del_flg = 0)
	)
	(SELECT 
		doc.stu_id,
		doc.stu_name,
		doc.subject_id,
		doc.subject_name,
		doc.subject_sub_id,
		doc.subject_sub_name,
		CASE 
			WHEN doc.pay_style = 1 THEN 1
		END as lesson_type,
		NULL AS schedual_date
	FROM (
		SELECT 
			stu_id,
			stu_name,
			subject_id,
			subject_name,
			subject_sub_id,
			subject_sub_name,
			lesson_type,
			MAX(schedual_date) AS schedual_date
		FROM v_info_lesson
		WHERE scanQR_date IS NOT NULL and lesson_type = 1
		GROUP BY 
			stu_id,
			stu_name,
			subject_id,
			subject_name,
			subject_sub_id,
			lesson_type,
			subject_sub_name
	) lsn
	RIGHT JOIN MaxSubIds doc
	ON lsn.stu_id = doc.stu_id 
	AND lsn.subject_id = doc.subject_id
	AND lsn.subject_sub_id = doc.subject_sub_id
	WHERE lsn.stu_id IS NULL
	  AND doc.stu_id = p_stuId
      -- 价格调整日期小于系统当前日期，目的是防止未来准备要上，目前还没有开始上的科目不出现在当前的预支付中
	  AND doc.adjusted_date <= CURDATE()
	  AND LEFT(lsn.schedual_date,4) = LEFT(CURDATE(),4))
	UNION ALL
	-- 第二部分：获取学生在课程信息表中的现有课程数据
	SELECT 
		t1.stu_id,
		t1.stu_name,
		t1.subject_id,
		t1.subject_name,
		t1.subject_sub_id,
		t1.subject_sub_name,
		t1.lesson_type,
		t1.schedual_date
	FROM (
		SELECT 
			v.*,
			MAX(schedual_date) OVER (PARTITION BY stu_id, subject_id) as max_date
		FROM v_info_lesson v
		WHERE v.stu_id = p_stuId
		  AND v.scanQR_date IS NOT NULL 
		  AND v.lesson_type = 1
          -- 排课日期只参考去年到现在的排课日期
          AND LEFT(v.schedual_date,4) >= LEFT(CURDATE(),4) - 1
	) t1
	INNER JOIN (
		SELECT 
			stu_id,
			subject_id,
			MAX(CAST(SUBSTRING_INDEX(subject_sub_id, '-', -1) AS UNSIGNED)) as max_num
		FROM v_info_lesson
		WHERE stu_id = p_stuId
		  AND scanQR_date IS NOT NULL 
		  AND lesson_type = 1
		GROUP BY stu_id, subject_id
	) t2 ON t1.stu_id = t2.stu_id 
		AND t1.subject_id = t2.subject_id
		AND CAST(SUBSTRING_INDEX(t1.subject_sub_id, '-', -1) AS UNSIGNED) = t2.max_num
	WHERE t1.schedual_date = t1.max_date;

	-- 创建临时表来存储统计p_yearMonth月里里签到的课程数量
    DROP TEMPORARY TABLE IF EXISTS temp_scaned_count;
	CREATE TEMPORARY TABLE IF NOT EXISTS temp_scaned_count AS
	SELECT subject_id, COUNT(subject_sub_id) as subject_sub_id_count 
	FROM t_info_lesson
	WHERE stu_id = p_stuId
		AND LEFT(schedual_date,7) = p_yearMonth
		AND scanqr_date IS NOT NULL
	GROUP BY subject_id;

	-- 根据签到的统计结果进行判断：如果subject_sub_id_count大于0，预支付的对象月是下一个月，没有签到记录，就是当前月
	IF EXISTS (SELECT 1 FROM temp_scaned_count WHERE subject_sub_id_count > 0) THEN
		-- 如果有签到记录，取下个月的第一天
		SET v_first_day = DATE(DATE_FORMAT(DATE_ADD(CONCAT(p_yearMonth, '-01'), INTERVAL 1 MONTH), '%Y-%m-01'));
	ELSE
		-- 如果没有签到记录，取当前传入月份的第一天
		SET v_first_day = DATE(CONCAT(p_yearMonth, '-01'));
	END IF;
	
    
    -- 更新临时表中的排课计划日期(因为临时表存放的是过去最新的排课参考用的信息，现在要把它的排课日期更新成要预支付的排课日期)
    UPDATE temp_result tr
    LEFT JOIN v_earliest_fixed_week_info AS vefw
    ON tr.stu_id = vefw.stu_id AND tr.subject_id = vefw.subject_id
    SET tr.schedual_date = 
        CASE 
            WHEN vefw.stu_id IS NOT NULL THEN
                -- 复杂的日期计算逻辑，用于确定给定月份中每个课程的第一个上课日期
                DATE_FORMAT(
                    DATE_ADD(
                        v_first_day,
                        INTERVAL (
                            CASE 
                                WHEN DAYOFWEEK(v_first_day) > CASE vefw.fixed_week
                                                                WHEN 'Mon' THEN 2
                                                                WHEN 'Tue' THEN 3
                                                                WHEN 'Wed' THEN 4
                                                                WHEN 'Thu' THEN 5
                                                                WHEN 'Fri' THEN 6
                                                                WHEN 'Sat' THEN 7
                                                                WHEN 'Sun' THEN 1
                                                              END
                                THEN 7 + CASE vefw.fixed_week
                                            WHEN 'Mon' THEN 0
                                            WHEN 'Tue' THEN 1
                                            WHEN 'Wed' THEN 2
                                            WHEN 'Thu' THEN 3
                                            WHEN 'Fri' THEN 4
                                            WHEN 'Sat' THEN 5
                                            WHEN 'Sun' THEN 6
                                          END - DAYOFWEEK(v_first_day) + 2
                                ELSE CASE vefw.fixed_week
                                        WHEN 'Mon' THEN 0
                                        WHEN 'Tue' THEN 1
                                        WHEN 'Wed' THEN 2
                                        WHEN 'Thu' THEN 3
                                        WHEN 'Fri' THEN 4
                                        WHEN 'Sat' THEN 5
                                        WHEN 'Sun' THEN 6
                                     END - DAYOFWEEK(v_first_day) + 2
                            END
                        ) DAY
                    ),
                    CONCAT('%Y-%m-%d ', LPAD(vefw.fixed_hour, 2, '0'), ':', LPAD(vefw.fixed_minute, 2, '0'))
                )
            ELSE tr.schedual_date
        END
    WHERE tr.stu_id = p_stuId;

    -- 返回计算后结果:以该生目前最后一次的签到月份为基准，预支付该月以后月份的预支付课费
    -- 如果adv.schedual_date有值，表示该科目在固定排课表里有固定的排课记录
    -- 如果adv.schedual_date为空，表示该科目在固定排课表里还没有固定排课记录，仅此而已
   
    -- 把temp_result更新后的结果集再做JOIN关联，将新的结果存放到temp_result_updated临时表里
	DROP TEMPORARY TABLE IF EXISTS temp_result_updated;
	CREATE TEMPORARY TABLE temp_result_updated AS
	SELECT 
		adv.stu_id,
		adv.stu_name,
		adv.subject_id,
		adv.subject_name,
		adv.subject_sub_id,
		adv.subject_sub_name,
		adv.lesson_type,
		adv.schedual_date,
		case when vldoc.lesson_fee_adjusted > 0 then vldoc.lesson_fee_adjusted
             else vldoc.lesson_fee
        end as subject_price,
		vldoc.minutes_per_lsn
	FROM temp_result adv
	INNER JOIN v_latest_subject_info_from_student_document vldoc
	ON adv.stu_id = vldoc.stu_id
	AND adv.subject_id = vldoc.subject_id
	AND adv.subject_sub_id = vldoc.subject_sub_id;
    
    -- 创建临时的学生档案表
    DROP TEMPORARY TABLE IF EXISTS temp_stu_doc;
    CREATE TEMPORARY TABLE temp_stu_doc AS
		SELECT 
		stu_id,
		stu_name,
		subject_id,
		subject_name,
		subject_sub_id,
		subject_sub_name,
		1 as lesson_type,
		null as schedual_date,
		case when lesson_fee_adjusted > 0 then lesson_fee_adjusted
             else lesson_fee
        end as subject_price,
		minutes_per_lsn
	FROM v_latest_subject_info_from_student_document
	WHERE stu_id = p_stuId AND pay_style = 1;

    SET @count = (SELECT COUNT(*) FROM temp_result_updated);
	IF @count = 0 THEN
		SELECT * FROM temp_stu_doc;
	ELSE
		-- 存储第一个查询的结果到一个中间表（课程表里已有的科目）
		DROP TEMPORARY TABLE IF EXISTS temp_base_result;
		CREATE TEMPORARY TABLE temp_base_result AS
		SELECT * FROM temp_result_updated;
		
		-- 在同一个临时表中插入第二部分数据 （课程表里没有的科目）
		INSERT INTO temp_base_result
		SELECT * FROM temp_stu_doc 
		WHERE subject_id NOT IN (SELECT subject_id FROM temp_result_updated);
		
		-- 返回结果
		SELECT * FROM temp_base_result;
		
		-- 清理临时表
		DROP TEMPORARY TABLE IF EXISTS temp_base_result;
	END IF;

    -- 清理：删除临时表
	DROP TEMPORARY TABLE IF EXISTS temp_result_updated; 
    DROP TEMPORARY TABLE IF EXISTS temp_stu_doc;
	DROP TEMPORARY TABLE IF EXISTS temp_scaned_count;
	DROP TEMPORARY TABLE IF EXISTS temp_result;
    
    -- 重新启用安全更新模式
    SET SQL_SAFE_UPDATES = 1;
END //

DELIMITER ;


-- USE prod_KNStudent;
DROP PROCEDURE IF EXISTS `sp_execute_weekly_batch_lsn_schedule`;
DELIMITER //
CREATE DEFINER = `root`@`%` PROCEDURE `sp_execute_weekly_batch_lsn_schedule`(IN start_date_str VARCHAR(10), IN end_date_str VARCHAR(10), IN SEQCode VARCHAR(20))
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


-- USE prod_KNStudent;
DROP PROCEDURE IF EXISTS `sp_execute_advc_lsn_fee_pay`;
DELIMITER //
CREATE DEFINER = `root`@`%` PROCEDURE sp_execute_advc_lsn_fee_pay(
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

CREATE DEFINER = `root`@`%` PROCEDURE sp_insert_tmp_lesson_info(
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

    -- 异常处理
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- 发生错误时回滚
        ROLLBACK;
        -- 可以选择抛出错误信息
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 生成主键ID（前缀 + 数字）
    SET v_lsn_tmp_id = CONCAT('kn-lsn-tmp-', nextval('kn-lsn-tmp-'));

    -- 从学生档案视图查询最新的课程信息
    -- 1. 查询价格调整日期 <= 当前日期的记录
    -- 2. 使用窗口函数按调整日期降序排序
    -- 3. LIMIT 1 在窗口函数基础上取最新记录
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
    LIMIT 1;

    -- 检查是否找到记录
    IF v_stu_id IS NULL THEN
        -- 没有找到符合条件的记录
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '未找到符合条件的学生课程档案记录';
    END IF;

    -- 计算课程费用：优先使用 lesson_fee_adjusted，如无则使用 lesson_fee
    SET v_lsn_fee = COALESCE(v_lesson_fee_adjusted, v_lesson_fee);

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

DELIMITER //

DROP PROCEDURE IF EXISTS sp_cancel_tmp_lesson_info//

CREATE DEFINER = `root`@`%` PROCEDURE sp_cancel_tmp_lesson_info(
    IN p_lsn_tmp_id VARCHAR(32),
    IN p_lsn_fee_id VARCHAR(32)
)
BEGIN
    DECLARE v_own_flg CHAR(1);
    DECLARE v_count INT;

    -- 异常处理：如果发生错误则回滚
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- 检查课费记录是否存在并获取结算状态
    SELECT own_flg INTO v_own_flg
    FROM t_info_lesson_fee
    WHERE lsn_fee_id = p_lsn_fee_id;

    -- 如果课费记录不存在
    IF v_own_flg IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '未找到对应的课费记录！';
    END IF;

    -- 如果课费已结算，不允许撤销
    IF v_own_flg = '1' THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '该课费已结算，无法撤销！';
    END IF;

    -- 删除课费表记录
    DELETE FROM t_info_lesson_fee
    WHERE lsn_fee_id = p_lsn_fee_id;

    -- 删除临时课程表记录
    DELETE FROM t_info_lesson_tmp
    WHERE lsn_tmp_id = p_lsn_tmp_id;

    COMMIT;

    -- 返回成功标识
    SELECT 'SUCCESS' AS result;

END//

DELIMITER ;


-- 按课时预支付：推算预支付课程的排课日期
-- USE prod_KNStudent;
DELIMITER //

DROP PROCEDURE IF EXISTS sp_get_advc_pay_per_lsn_subjects_and_schedual_info //

CREATE DEFINER=`root`@`%` PROCEDURE `sp_get_advc_pay_per_lsn_subjects_and_schedual_info`(IN p_stuId VARCHAR(32), IN p_yearMonth VARCHAR(7))
BEGIN

    DECLARE v_first_day DATE;
    -- 临時禁用安全更新模式，以允许不使用主键的更新操作
    SET SQL_SAFE_UPDATES = 0;

    -- 确保临时表不存在，防止重复创建错误
    DROP TEMPORARY TABLE IF EXISTS temp_result;

    -- 创建临时表来存储计算后的结果
    CREATE TEMPORARY TABLE temp_result AS
	-- 第一部分：获取学生档案中存在但在课程信息表中不存在的科目数据
	WITH MaxSubIds AS (
	 -- 取得学生们各科目中截止到目前学过的或正在学的最大子科目（即，子科目id值最大的那个科目）
		SELECT
			t.*
		FROM v_latest_subject_info_from_student_document t
		INNER JOIN (
			SELECT
				stu_id,
				subject_id,
				MAX(CAST(SUBSTRING_INDEX(subject_sub_id, '-', -1) AS UNSIGNED)) as max_num
			FROM v_latest_subject_info_from_student_document
			WHERE 1 = 1
            AND pay_style = 0 -- 仅限于按课时交费的科目
			-- 价格调整日期小于系统当前日期，目的是防止未来准备要上，目前还没有开始上的科目不出现在当前的预支付中
			AND adjusted_date <= CURDATE()
			GROUP BY stu_id, subject_id
		) m ON t.stu_id = m.stu_id
			AND t.subject_id = m.subject_id
			-- 学科子科目（例如：钢琴1级，2级等）的最大值
			AND CAST(SUBSTRING_INDEX(t.subject_sub_id, '-', -1) AS UNSIGNED) = m.max_num
			-- 只限于当前在课的学生
			AND t.stu_id in (select stu_id from t_mst_student where del_flg = 0)
	)
	(SELECT
		doc.stu_id,
		doc.stu_name,
		doc.subject_id,
		doc.subject_name,
		doc.subject_sub_id,
		doc.subject_sub_name,
		CASE
			WHEN doc.pay_style = 0 THEN 0
		END as lesson_type,
		NULL AS schedual_date
	FROM (
		SELECT
			stu_id,
			stu_name,
			subject_id,
			subject_name,
			subject_sub_id,
			subject_sub_name,
			lesson_type,
			MAX(schedual_date) AS schedual_date
		FROM v_info_lesson
		WHERE scanQR_date IS NOT NULL and lesson_type = 0
		GROUP BY
			stu_id,
			stu_name,
			subject_id,
			subject_name,
			subject_sub_id,
			lesson_type,
			subject_sub_name
	) lsn
	RIGHT JOIN MaxSubIds doc
	ON lsn.stu_id = doc.stu_id
	AND lsn.subject_id = doc.subject_id
	AND lsn.subject_sub_id = doc.subject_sub_id
	WHERE lsn.stu_id IS NULL
	  AND doc.stu_id = p_stuId
      -- 价格调整日期小于系统当前日期，目的是防止未来准备要上，目前还没有开始上的科目不出现在当前的预支付中
	  AND doc.adjusted_date <= CURDATE()
	  AND LEFT(lsn.schedual_date,4) = LEFT(CURDATE(),4))
	UNION ALL
	-- 第二部分：获取学生在课程信息表中的现有课程数据
	SELECT
		t1.stu_id,
		t1.stu_name,
		t1.subject_id,
		t1.subject_name,
		t1.subject_sub_id,
		t1.subject_sub_name,
		t1.lesson_type,
		t1.schedual_date
	FROM (
		SELECT
			v.*,
			MAX(schedual_date) OVER (PARTITION BY stu_id, subject_id) as max_date
		FROM v_info_lesson v
		WHERE v.stu_id = p_stuId
		  AND v.scanQR_date IS NOT NULL
		  AND v.lesson_type = 0
          -- 排课日期只参考去年到现在的排课日期
          AND LEFT(v.schedual_date,4) >= LEFT(CURDATE(),4) - 1
	) t1
	INNER JOIN (
		SELECT
			stu_id,
			subject_id,
			MAX(CAST(SUBSTRING_INDEX(subject_sub_id, '-', -1) AS UNSIGNED)) as max_num
		FROM v_info_lesson
		WHERE stu_id = p_stuId
		  AND scanQR_date IS NOT NULL
		  AND lesson_type = 0
		GROUP BY stu_id, subject_id
	) t2 ON t1.stu_id = t2.stu_id
		AND t1.subject_id = t2.subject_id
		AND CAST(SUBSTRING_INDEX(t1.subject_sub_id, '-', -1) AS UNSIGNED) = t2.max_num
	WHERE t1.schedual_date = t1.max_date;

	-- 按课时预支付：始终以选定月份的第一天作为基准日起点
	-- （与按月预支付不同，按课时预支付不需要根据签到记录跳到下个月）
	SET v_first_day = DATE(CONCAT(p_yearMonth, '-01'));


    -- 更新临时表中的排课计划日期(因为临时表存放的是过去最新的排课参考用的信息，现在要把它的排课日期更新成要预支付的排课日期)
    UPDATE temp_result tr
    LEFT JOIN v_earliest_fixed_week_info AS vefw
    ON tr.stu_id = vefw.stu_id AND tr.subject_id = vefw.subject_id
    SET tr.schedual_date =
        CASE
            WHEN vefw.stu_id IS NOT NULL THEN
                -- 复杂的日期计算逻辑，用于确定给定月份中每个课程的第一个上课日期
                DATE_FORMAT(
                    DATE_ADD(
                        v_first_day,
                        INTERVAL (
                            CASE
                                WHEN DAYOFWEEK(v_first_day) > CASE vefw.fixed_week
                                                                WHEN 'Mon' THEN 2
                                                                WHEN 'Tue' THEN 3
                                                                WHEN 'Wed' THEN 4
                                                                WHEN 'Thu' THEN 5
                                                                WHEN 'Fri' THEN 6
                                                                WHEN 'Sat' THEN 7
                                                                WHEN 'Sun' THEN 1
                                                              END
                                THEN 7 + CASE vefw.fixed_week
                                            WHEN 'Mon' THEN 0
                                            WHEN 'Tue' THEN 1
                                            WHEN 'Wed' THEN 2
                                            WHEN 'Thu' THEN 3
                                            WHEN 'Fri' THEN 4
                                            WHEN 'Sat' THEN 5
                                            WHEN 'Sun' THEN 6
                                          END - DAYOFWEEK(v_first_day) + 2
                                ELSE CASE vefw.fixed_week
                                        WHEN 'Mon' THEN 0
                                        WHEN 'Tue' THEN 1
                                        WHEN 'Wed' THEN 2
                                        WHEN 'Thu' THEN 3
                                        WHEN 'Fri' THEN 4
                                        WHEN 'Sat' THEN 5
                                        WHEN 'Sun' THEN 6
                                     END - DAYOFWEEK(v_first_day) + 2
                            END
                        ) DAY
                    ),
                    CONCAT('%Y-%m-%d ', LPAD(vefw.fixed_hour, 2, '0'), ':', LPAD(vefw.fixed_minute, 2, '0'))
                )
            ELSE tr.schedual_date
        END
    WHERE tr.stu_id = p_stuId;

    -- 按课时预支付：跳过已有排课记录的日期，找到第一个空闲的排课日
    -- 例如：3-Test固定周一9:15上课，如果2月2日9:15已有排课，则推到2月9日9:15
    -- 重复5次以覆盖最多5周的连续已排课情况（一个月最多4-5个同一星期几）
    UPDATE temp_result tr
    SET tr.schedual_date = DATE_ADD(tr.schedual_date, INTERVAL 7 DAY)
    WHERE tr.stu_id = p_stuId AND tr.schedual_date IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM t_info_lesson til
        WHERE til.stu_id = tr.stu_id AND til.subject_id = tr.subject_id
        AND til.subject_sub_id = tr.subject_sub_id AND til.schedual_date = tr.schedual_date
    );
    -- 第2次跳过
    UPDATE temp_result tr
    SET tr.schedual_date = DATE_ADD(tr.schedual_date, INTERVAL 7 DAY)
    WHERE tr.stu_id = p_stuId AND tr.schedual_date IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM t_info_lesson til
        WHERE til.stu_id = tr.stu_id AND til.subject_id = tr.subject_id
        AND til.subject_sub_id = tr.subject_sub_id AND til.schedual_date = tr.schedual_date
    );
    -- 第3次跳过
    UPDATE temp_result tr
    SET tr.schedual_date = DATE_ADD(tr.schedual_date, INTERVAL 7 DAY)
    WHERE tr.stu_id = p_stuId AND tr.schedual_date IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM t_info_lesson til
        WHERE til.stu_id = tr.stu_id AND til.subject_id = tr.subject_id
        AND til.subject_sub_id = tr.subject_sub_id AND til.schedual_date = tr.schedual_date
    );
    -- 第4次跳过
    UPDATE temp_result tr
    SET tr.schedual_date = DATE_ADD(tr.schedual_date, INTERVAL 7 DAY)
    WHERE tr.stu_id = p_stuId AND tr.schedual_date IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM t_info_lesson til
        WHERE til.stu_id = tr.stu_id AND til.subject_id = tr.subject_id
        AND til.subject_sub_id = tr.subject_sub_id AND til.schedual_date = tr.schedual_date
    );
    -- 第5次跳过
    UPDATE temp_result tr
    SET tr.schedual_date = DATE_ADD(tr.schedual_date, INTERVAL 7 DAY)
    WHERE tr.stu_id = p_stuId AND tr.schedual_date IS NOT NULL
    AND EXISTS (
        SELECT 1 FROM t_info_lesson til
        WHERE til.stu_id = tr.stu_id AND til.subject_id = tr.subject_id
        AND til.subject_sub_id = tr.subject_sub_id AND til.schedual_date = tr.schedual_date
    );

    -- 返回计算后结果
    -- 把temp_result更新后的结果集再做JOIN关联，将新的结果存放到temp_result_updated临时表里
	DROP TEMPORARY TABLE IF EXISTS temp_result_updated;
	CREATE TEMPORARY TABLE temp_result_updated AS
	SELECT
		adv.stu_id,
		adv.stu_name,
		adv.subject_id,
		adv.subject_name,
		adv.subject_sub_id,
		adv.subject_sub_name,
		adv.lesson_type,
		adv.schedual_date,
		case when vldoc.lesson_fee_adjusted > 0 then vldoc.lesson_fee_adjusted
             else vldoc.lesson_fee
        end as subject_price,
		vldoc.minutes_per_lsn
	FROM temp_result adv
	INNER JOIN v_latest_subject_info_from_student_document vldoc
	ON adv.stu_id = vldoc.stu_id
	AND adv.subject_id = vldoc.subject_id
	AND adv.subject_sub_id = vldoc.subject_sub_id;

    -- 创建临时的学生档案表
    DROP TEMPORARY TABLE IF EXISTS temp_stu_doc;
    CREATE TEMPORARY TABLE temp_stu_doc AS
		SELECT
		stu_id,
		stu_name,
		subject_id,
		subject_name,
		subject_sub_id,
		subject_sub_name,
		0 as lesson_type,
		null as schedual_date,
		case when lesson_fee_adjusted > 0 then lesson_fee_adjusted
             else lesson_fee
        end as subject_price,
		minutes_per_lsn
	FROM v_latest_subject_info_from_student_document
	WHERE stu_id = p_stuId AND pay_style = 0;

    SET @count = (SELECT COUNT(*) FROM temp_result_updated);
	IF @count = 0 THEN
		SELECT * FROM temp_stu_doc;
	ELSE
		-- 存储第一个查询的结果到一个中间表（课程表里已有的科目）
		DROP TEMPORARY TABLE IF EXISTS temp_base_result;
		CREATE TEMPORARY TABLE temp_base_result AS
		SELECT * FROM temp_result_updated;

		-- 在同一个临时表中插入第二部分数据 （课程表里没有的科目）
		INSERT INTO temp_base_result
		SELECT * FROM temp_stu_doc
		WHERE subject_id NOT IN (SELECT subject_id FROM temp_result_updated);

		-- 返回结果
		SELECT * FROM temp_base_result;

		-- 清理临时表
		DROP TEMPORARY TABLE IF EXISTS temp_base_result;
	END IF;

    -- 清理：删除临时表
	DROP TEMPORARY TABLE IF EXISTS temp_result_updated;
    DROP TEMPORARY TABLE IF EXISTS temp_stu_doc;
	DROP TEMPORARY TABLE IF EXISTS temp_result;

    -- 重新启用安全更新模式
    SET SQL_SAFE_UPDATES = 1;
END //

DELIMITER ;


-- 按课时预支付：执行按课时预支付处理
-- USE prod_KNStudent;
DELIMITER //

DROP PROCEDURE IF EXISTS sp_execute_advc_lsn_fee_pay_per_lesson //

CREATE DEFINER=`root`@`%` PROCEDURE sp_execute_advc_lsn_fee_pay_per_lesson(
    IN p_stu_id VARCHAR(32),
    IN p_subject_id VARCHAR(32),
    IN p_subject_sub_id VARCHAR(32),
    IN p_lesson_type INT,
    IN p_minutes_per_lsn INT,
    IN p_subject_price DECIMAL(10,2),
    IN p_first_schedual_datetime DATETIME,
    IN p_lesson_count INT,
    IN p_bank_id VARCHAR(32),
    IN p_lsn_seq_code VARCHAR(20),
    IN p_fee_seq_code VARCHAR(20),
    IN p_pay_seq_code VARCHAR(20),
    OUT p_result INT
)
BEGIN
    -- 声明常量
    DECLARE PROCEDURE_NAME VARCHAR(100) DEFAULT 'sp_execute_advc_lsn_fee_pay_per_lesson';
    DECLARE PROCEDURE_ALIAS_NAME VARCHAR(100) DEFAULT '执行按课时预支付处理';

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
    DECLARE v_counter INT DEFAULT 0;

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

    SET v_current_step = '初始化：按课时预支付循环';
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step,
            CONCAT('学生:', p_stu_id, ' 科目:', p_subject_id, ' 课时数:', p_lesson_count));

    -- 循环N次，每次创建一节课的 lesson → fee → pay → advc_pay 记录
    WHILE v_counter < p_lesson_count DO

        -- 计算当前迭代的排课日期（第一次为传入日期，之后每次加7天）
        SET v_schedual_date = DATE_ADD(p_first_schedual_datetime, INTERVAL (v_counter * 7) DAY);
        SET v_lsn_month = DATE_FORMAT(v_schedual_date, '%Y-%m');

        -- 步骤 1: 检查 v_info_lesson 表（该日期是否已有课程记录）
        SET v_current_step = CONCAT('第', v_counter + 1, '节课 - 1 检查 v_info_lesson');
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
            SET v_step_result = CONCAT('既存的lesson_id: ', v_lesson_id);
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
            SET v_current_step = CONCAT('第', v_counter + 1, '节课 - 2 插入到 t_info_lesson');
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

        -- 步骤 3: 插入到 t_info_lesson_fee（pay_style = 0 表示按课时计费）
        SET v_current_step = CONCAT('第', v_counter + 1, '节课 - 3 插入到 t_info_lesson_fee');
        SET v_lsn_fee_id = CONCAT(p_fee_seq_code, nextval(p_fee_seq_code));

        INSERT INTO t_info_lesson_fee (
            lsn_fee_id, lesson_id, pay_style, lsn_fee, lsn_month, own_flg
        ) VALUES (
            v_lsn_fee_id, v_lesson_id, 0, p_subject_price, v_lsn_month, 1
        );

        SET v_step_result = IF(ROW_COUNT() > 0, '成功', '插入失败');
        INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
        VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, v_step_result);

        -- 步骤 4: 插入到 t_info_lesson_pay（按课时：lsn_pay = 课时单价，不乘4）
        SET v_current_step = CONCAT('第', v_counter + 1, '节课 - 4 插入到 t_info_lesson_pay');
        SET v_lsn_pay_id = CONCAT(p_pay_seq_code, nextval(p_pay_seq_code));

        INSERT INTO t_info_lesson_pay (
            lsn_pay_id, lsn_fee_id, lsn_pay, bank_id, pay_month, pay_date
        ) VALUES (
            v_lsn_pay_id,
            v_lsn_fee_id,
            p_subject_price, -- 按课时计费：每节课的费用 = 课时单价
            p_bank_id,
            v_lsn_month,
            CURDATE()
        );

        SET v_step_result = IF(ROW_COUNT() > 0, '成功', '插入失败');
        INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
        VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step, v_step_result);

        -- 步骤 5: 插入到 t_info_lsn_fee_advc_pay
        SET v_current_step = CONCAT('第', v_counter + 1, '节课 - 5 插入到 t_info_lsn_fee_advc_pay');
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

        SET v_counter = v_counter + 1;
    END WHILE;

    COMMIT;
    SET p_result = 1;

    SET v_current_step = '存储过程完成';
    INSERT INTO t_sp_execution_log (procedure_name, procedure_alias_name, step_name, result)
    VALUES (PROCEDURE_NAME, PROCEDURE_ALIAS_NAME, v_current_step,
            CONCAT('成功：共处理', p_lesson_count, '节课'));

END //

DELIMITER ;
