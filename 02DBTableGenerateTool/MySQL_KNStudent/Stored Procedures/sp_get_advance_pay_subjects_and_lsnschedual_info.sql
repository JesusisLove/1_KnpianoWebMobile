-- use prod_KNStudent;
DELIMITER //

DROP PROCEDURE IF EXISTS sp_get_advance_pay_subjects_and_lsnschedual_info //
-- root@localhost表示root权限指定localhost用户来执行当前的存储过程。可以运行这个查询看看你的MySQL中有哪些root用户：SELECT User, Host FROM mysql.user WHERE User = 'root';
CREATE DEFINER=`root`@`%` PROCEDURE `sp_get_advance_pay_subjects_and_lsnschedual_info`(IN p_stuId VARCHAR(32), IN p_yearMonth VARCHAR(7))
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

-- 调用存储过程的示例
-- CALL sp_get_advance_pay_subjects_and_lsnschedual_info('kn-stu-3', '2024-08');