-- use prod_KNStudent;
-- use KNStudent;
/**
* 获取所有学生签完到的上课记录和课费记录
* 此处UNION临时课与课费关联的记录，目的在于，不要遗漏空月课费已支付情况下的课费统计。
*/
DROP VIEW IF EXISTS v_info_lesson_fee_connect_lsn_and_extraToScheDataCorrect;
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_info_lesson_fee_connect_lsn_and_extraToScheDataCorrect AS
    SELECT 
        fee.lsn_fee_id AS lsn_fee_id,
        fee.lesson_id AS lesson_id,
        lsn.lesson_type AS lesson_type,
        ( CAST(lsn.class_duration AS DECIMAL(10,4))/ doc.minutes_per_lsn) AS lsn_count, -- 乘以1.0，就能强制MySQL进行浮点数运算，保证15/60就会得到0.25的正确结果。
        doc.stu_id AS stu_id,
        CASE 
            WHEN doc.del_flg = 1 THEN CONCAT(doc.stu_name, '(已退学)')
            ELSE doc.stu_name
        END AS stu_name,
        CASE 
            WHEN doc.del_flg = 1 THEN 
                CASE 
                    WHEN doc.nik_name IS NOT NULL AND doc.nik_name != '' THEN CONCAT(doc.nik_name, '(已退学)')
                    ELSE CONCAT(COALESCE(doc.nik_name, '未知姓名'), '(已退学)')
                END              
            ELSE doc.nik_name
        END AS nik_name,
        doc.subject_id AS subject_id,
        doc.subject_name AS subject_name,
        doc.pay_style AS pay_style,
        lsn.subject_sub_id AS subject_sub_id,
        doc.subject_sub_name AS subject_sub_name,
        (CASE
            WHEN (doc.lesson_fee_adjusted > 0) THEN doc.lesson_fee_adjusted
            ELSE CASE 
                    WHEN fee.extra2sche_flg = 1 THEN fee.lsn_fee  -- 如果是加课换正课记录，就是用换正课后的课程价格
                    ELSE doc.lesson_fee 
                 END
        END) AS subject_price,
        (fee.lsn_fee * (lsn.class_duration / doc.minutes_per_lsn)) AS lsn_fee, -- 这是学生实际上课的费用值，不是学费的值
        fee.lsn_month AS lsn_month,
        fee.own_flg AS own_flg,
        fee.del_flg AS del_flg,
        fee.extra2sche_flg, -- 加课换正课标识
        fee.bad_debt_flg AS bad_debt_flg, -- 坏账标记
        fee.create_date AS create_date,
        fee.update_date AS update_date
    FROM
        ((v_info_lesson_fee_and_extraToScheDataCorrect fee  -- 包含了加课换正课后的记录
        JOIN v_info_lesson_and_extraToScheDataCorrect lsn   -- 包含了加课换正课后的记录
        ON (((fee.lesson_id = lsn.lesson_id)
            AND (fee.del_flg = 0)
            )))
        -- LEFT JOIN v_info_student_document doc ON (((lsn.stu_id = doc.stu_id)
        INNER JOIN v_info_student_document doc ON (((lsn.stu_id = doc.stu_id)
            AND (lsn.subject_id = doc.subject_id)
            AND (lsn.subject_sub_id = doc.subject_sub_id)
            AND (doc.adjusted_date = (SELECT 
                MAX(studoc.adjusted_date)
            FROM
                v_info_student_document studoc
            WHERE
                ((studoc.stu_id = doc.stu_id)
                    AND (studoc.subject_id = doc.subject_id)
                    AND (studoc.subject_sub_id = doc.subject_sub_id)
                    AND (DATE_FORMAT(studoc.adjusted_date, '%Y/%m/%d') <= DATE_FORMAT(lsn.schedual_date, '%Y/%m/%d'))))))))

    UNION ALL

    -- 临时课程（空月课费）的课费数据
    SELECT
        fee.lsn_fee_id AS lsn_fee_id,
        fee.lesson_id AS lesson_id,
        1 AS lesson_type,                        -- 临时课=月计划
        0 AS lsn_count,                          -- 固定值0（因为是虚课）
        tmp.stu_id AS stu_id,
        tmp.stu_name AS stu_name,                -- 不需要判断退学
        tmp.nik_name AS nik_name,                -- 不需要判断退学
        tmp.subject_id AS subject_id,
        tmp.subject_name AS subject_name,
        1 AS pay_style,                          -- 月计划=1
        tmp.subject_sub_id AS subject_sub_id,
        tmp.subject_sub_name AS subject_sub_name,
        fee.lsn_fee AS subject_price,            -- 课程单价（75）
        fee.lsn_fee * 4 AS lsn_fee,              -- 课费金额（75 * 4 = 300）
        fee.lsn_month AS lsn_month,
        fee.own_flg AS own_flg,
        fee.del_flg AS del_flg,
        0 AS extra2sche_flg,                     -- 临时课不是加课换正课
        fee.bad_debt_flg AS bad_debt_flg,        -- 坏账标记
        fee.create_date AS create_date,
        fee.update_date AS update_date
    FROM t_info_lesson_fee fee
    INNER JOIN v_info_lesson_tmp tmp ON fee.lesson_id = tmp.lsn_tmp_id
    WHERE fee.del_flg = 0

    ORDER BY lsn_month;