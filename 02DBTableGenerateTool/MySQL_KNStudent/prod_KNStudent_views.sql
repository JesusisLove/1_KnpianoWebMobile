-- 学科基本情報マスタ
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_subject_edaban`;
-- 视图-- 不要做驼峰命名变更，为了java程序处理的统一性。
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW `v_info_subject_edaban` AS
		select eda.subject_id
			  ,sub.subject_name
		      ,eda.subject_sub_id
		      ,eda.subject_sub_name
		      ,eda.subject_price
		      ,eda.del_flg
		      ,eda.create_date
		      ,eda.update_date
		from 
			t_info_subject_edaban eda
		left join
			t_mst_subject sub
		on eda.subject_id = sub.subject_id
		and eda.del_flg = 0
		and sub.del_flg = 0
		;

-- 銀行基本情報マスタ
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_student_bank`;
-- 视图
CREATE 
	ALGORITHM = UNDEFINED 
	DEFINER = `root`@`%` 
	SQL SECURITY DEFINER 
VIEW `v_info_student_bank` 
AS 
select 
	stubnk.stu_id
   ,stu.stu_name
   ,stubnk.bank_id
   ,bnk.bank_name
   ,stubnk.del_flg
   ,stubnk.create_date
   ,stubnk.update_date
from t_info_student_bank stubnk
left join
t_mst_bank bnk
on stubnk.bank_id = bnk.bank_id 
and bnk.del_flg = 0
left join
t_mst_student stu
on stubnk.stu_id = stu.stu_id
and stu.del_flg = 0
;

-- 学生固定授業計画管理
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_fixedlesson`;
-- 不要做驼峰命名变更，为了java程序处理的统一性。
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_info_fixedlesson AS
        SELECT 
        a.stu_id AS stu_id,
        case when b.del_flg = 1 then  CONCAT(b.stu_name, '(已退学)')
             else b.stu_name
        end AS stu_name,
        a.subject_id AS subject_id,
        c.subject_name AS subject_name,
        a.fixed_week AS fixed_week,
        a.fixed_hour AS fixed_hour,
        a.fixed_minute AS fixed_minute,
        b.del_flg as del_flg
    FROM
        ((t_info_fixedlesson a
        JOIN t_mst_student b ON ((a.stu_id = b.stu_id)))
        JOIN t_mst_subject c ON ((a.subject_id = c.subject_id)))
;

-- 学生歴史ドキュメント情報
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_student_document`;
-- 视图 不要做驼峰命名变更，为了java程序处理的统一性。
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW `v_info_student_document` AS
    SELECT 
        `doc`.`stu_id` AS `stu_id`,
        `stu`.`stu_name` AS `stu_name`,
        `stu`.`nik_name` AS `nik_name`,
        `doc`.`subject_id` AS `subject_id`,
        `jct`.`subject_name` AS `subject_name`,
        `doc`.`subject_sub_id` AS `subject_sub_id`,
        `sub`.`subject_sub_name` AS `subject_sub_name`,
        `doc`.`adjusted_date` AS `adjusted_date`,
        `doc`.`pay_style` AS `pay_style`,
        `doc`.`minutes_per_lsn` AS `minutes_per_lsn`,
        `doc`.`lesson_fee` AS `lesson_fee`,
        `doc`.`lesson_fee_adjusted` AS `lesson_fee_adjusted`,
        `doc`.`year_lsn_cnt` AS `year_lsn_cnt`,
        `stu`.`del_flg` AS `del_flg`,
        `doc`.`create_date` AS `create_date`,
        `doc`.`update_date` AS `update_date`
    FROM
        (((`t_info_student_document` `doc`
        LEFT JOIN `t_mst_student` `stu` ON ((`doc`.`stu_id` = `stu`.`stu_id`)))
        LEFT JOIN `t_mst_subject` `jct` ON ((`doc`.`subject_id` = `jct`.`subject_id`)))
        LEFT JOIN `v_info_subject_edaban` `sub` ON (((`doc`.`subject_sub_id` = `sub`.`subject_sub_id`)
            AND (`doc`.`subject_id` = `sub`.`subject_id`))))
    ;

-- 临时课程信息视图
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_lesson_tmp`;
CREATE
    ALGORITHM = UNDEFINED
    DEFINER = `root`@`%`
    SQL SECURITY DEFINER
VIEW v_info_lesson_tmp AS
    SELECT
        a.lsn_tmp_id AS lsn_tmp_id,
        a.subject_id AS subject_id,
        c.subject_name AS subject_name,
        a.subject_sub_id AS subject_sub_id,
        c.subject_sub_name AS subject_sub_name,
        a.stu_id AS stu_id,
        CASE
            WHEN b.del_flg = 1 THEN CONCAT(b.stu_name, '(已退学)')
            ELSE b.stu_name
        END AS stu_name,
        CASE
            WHEN b.del_flg = 1 THEN
                CASE
                    WHEN b.nik_name IS NOT NULL AND b.nik_name != '' THEN CONCAT(b.nik_name, '(已退学)')
                    ELSE CONCAT(COALESCE(b.stu_name, '未知姓名'), '(已退学)')
                END
            ELSE b.nik_name
        END AS nik_name,
        a.schedual_date AS schedual_date,
        a.scanqr_date AS scanQR_date,
        a.del_flg AS del_flg,
        a.create_date AS create_date,
        a.update_date AS update_date
    FROM
        ((t_info_lesson_tmp a
        INNER JOIN t_mst_student b ON ((a.stu_id = b.stu_id)))
        INNER JOIN v_info_subject_edaban c ON (((a.subject_id = c.subject_id)
            AND (a.subject_sub_id = c.subject_sub_id))))
;

-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_earliest_fixed_week_info`;
/* 给AI的提示词：
这是t_info_fixedlesson中stu_id是，'kn-stu-3'的结果集，这个条件下的结果集里，
你看kn-sub-20的记录，有2条记录，从fixed_week字段上看有“Fri”和“Thu”，因为Thu比Fri早，所以kn-sub-20的记录中“Thu”的这条记录是我要的记录，同理，
你看kn-sub-22的记录，有2条记录，从fixed_week字段上看有“Tue”和“Wed”，因为Tue比Wed早，所以kn-sub-22的记录中“Tue”的这条记录是我要的记录，同理，
你看kn-sub-6的记录，有3条记录，从fixed_week字段上看有“Mon”和“Tue”和“Thu”，因为这三个星期中“Mon”是最早的，所以kn-sub-6的记录中“Mon”的这条记录是我要的记录，
同样道理，如果换成stu_id是其他的学生编号，也是按照这个要求，在他的当前科目中找出星期最早的那个记录显示出来。
理解了我的要求了吗？请你按照我的要求给我写一个Mysql的Sql语句。
*/
CREATE VIEW v_earliest_fixed_week_info AS
SELECT 
    t1.stu_id AS stu_id,
    t1.subject_id AS subject_id,
    t1.fixed_week AS fixed_week,
    t1.fixed_hour AS fixed_hour,
    t1.fixed_minute AS fixed_minute
FROM
    (t_info_fixedlesson t1
    JOIN 
    (SELECT 
			stu_id AS stu_id,
            subject_id AS subject_id,
            MIN((CASE
                WHEN (fixed_week = 'Mon') THEN 1
                WHEN (fixed_week = 'Tue') THEN 2
                WHEN (fixed_week = 'Wed') THEN 3
                WHEN (fixed_week = 'Thu') THEN 4
                WHEN (fixed_week = 'Fri') THEN 5
                WHEN (fixed_week = 'Sat') THEN 6
                WHEN (fixed_week = 'Sun') THEN 7
            END)) AS min_day_num
    FROM
        t_info_fixedlesson
    WHERE
        subject_id IS NOT NULL
    GROUP BY stu_id , subject_id
    ) t2 
    ON t1.stu_id = t2.stu_id AND t1.subject_id = t2.subject_id)
WHERE
    (CASE
        WHEN (t1.fixed_week = 'Mon') THEN 1
        WHEN (t1.fixed_week = 'Tue') THEN 2
        WHEN (t1.fixed_week = 'Wed') THEN 3
        WHEN (t1.fixed_week = 'Thu') THEN 4
        WHEN (t1.fixed_week = 'Fri') THEN 5
        WHEN (t1.fixed_week = 'Sat') THEN 6
        WHEN (t1.fixed_week = 'Sun') THEN 7
    END) = t2.min_day_num
ORDER BY t1.stu_id , t1.subject_id
;


-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_latest_subject_info_from_student_document`;
-- 视图 从v_info_student_document里抽出学生最新正在上课的科目信息且
-- 不包括预先调整的科目信息（即大于系统当前日期yyyy-MM-dd的预设科目，比如，A学生目前在学习钢琴3级，下月进入钢琴4级，所以下月的4级的科目信息不应该抽出来）
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER 
VIEW v_latest_subject_info_from_student_document AS 
select subquery.stu_id AS stu_id,
       case when subquery.del_flg = 1 then  CONCAT(subquery.stu_name, '(已退学)')
            else subquery.stu_name
       end AS stu_name,
       case when subquery.del_flg = 1 then  CONCAT(subquery.nik_name, '(已退学)')
            else subquery.nik_name
       end AS nik_name,
       subquery.subject_id AS subject_id,
       subquery.subject_name AS subject_name,
       subquery.subject_sub_id AS subject_sub_id,
       subquery.subject_sub_name AS subject_sub_name,
       subquery.lesson_fee AS lesson_fee,
       subquery.lesson_fee_adjusted AS lesson_fee_adjusted,
       subquery.year_lsn_cnt AS year_lsn_cnt,
       subquery.minutes_per_lsn AS minutes_per_lsn,
       subquery.pay_style AS pay_style, 
       subquery.adjusted_date AS adjusted_date
from (
    select vDoc.stu_id AS stu_id,
            vDoc.stu_name AS stu_name,
            vDoc.nik_name AS nik_name,
            vDoc.subject_id AS subject_id,
            vDoc.subject_name AS subject_name,
            vDoc.subject_sub_id AS subject_sub_id,
            vDoc.subject_sub_name AS subject_sub_name,
            vDoc.adjusted_date AS adjusted_date,
            vDoc.pay_style AS pay_style,
            vDoc.minutes_per_lsn AS minutes_per_lsn,
            vDoc.lesson_fee AS lesson_fee,
            vDoc.lesson_fee_adjusted AS lesson_fee_adjusted,
            vDoc.year_lsn_cnt AS year_lsn_cnt,
            vDoc.del_flg AS del_flg,
            vDoc.create_date AS create_date,
            vDoc.update_date AS update_date,
            row_number() OVER (
                                PARTITION BY vDoc.stu_id,
                                            vDoc.subject_id 
                                            ORDER BY vDoc.adjusted_date desc 
                            )  AS rn 
    from v_info_student_document vDoc
        -- 价格调整日期小于系统当前日期，防止学生下一学期调整的科目不合时机的出现
    where adjusted_date <= CURDATE()
    ) subquery 
where subquery.rn = 1
;


-- 学生授業情報管理
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_lesson`;
-- 视图
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_info_lesson AS
    SELECT 
        a.lesson_id AS lesson_id,
        a.subject_id AS subject_id,
        c.subject_name AS subject_name,
        a.subject_sub_id AS subject_sub_id,
        c.subject_sub_name AS subject_sub_name,
        a.stu_id AS stu_id,
        CASE 
            WHEN b.del_flg = 1 THEN CONCAT(b.stu_name, '(已退学)')
            ELSE b.stu_name
        END AS stu_name,
        CASE 
            WHEN b.del_flg = 1 THEN 
                CASE 
                    WHEN b.nik_name IS NOT NULL AND b.nik_name != '' THEN CONCAT(b.nik_name, '(已退学)')
                    ELSE CONCAT(COALESCE(b.stu_name, '未知姓名'), '(已退学)')
                END              
            ELSE b.nik_name         
        END AS nik_name,
        a.class_duration AS class_duration,
        a.lesson_type AS lesson_type,
        a.schedual_type AS schedual_type,
        a.schedual_date AS schedual_date,
        a.scanqr_date AS scanQR_date,
        a.lsn_adjusted_date AS lsn_adjusted_date,
        a.extra_to_dur_date AS extra_to_dur_date,
        a.del_flg AS del_flg,
        a.memo AS memo,
        a.create_date AS create_date,
        a.update_date AS update_date
    FROM
        ((t_info_lesson a
        INNER JOIN t_mst_student b ON ((a.stu_id = b.stu_id)))
        INNER JOIN v_info_subject_edaban c ON (((a.subject_id = c.subject_id)
            AND (a.subject_sub_id = c.subject_sub_id))))
;


/**
*视图v_info_lesson_include_extra2sche是在v_info_lesson视图的代码基础上作成的，该视图
*只针对加课换成了正课后，对加课换正课的那个记录进行了处理，
*执行视图v_info_lesson，可以看到换正课之前,该月加课记录的真实样貌（相当于姑娘结婚前在娘家的样貌）
*执行v_info_lesson_include_extra2sche，只能看到加课换成正课之后，变成正课的样貌（相当于姑娘结婚后在婆家的样貌）
*该视图只针对加课换正课的数据处理，对其调课记录，正课记录没有影响。
*/
DROP VIEW IF EXISTS v_info_lesson_include_extra2sche;
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_info_lesson_include_extra2sche AS
    SELECT 
        lsn.lesson_id AS lesson_id,
        lsn.subject_id AS subject_id,
        eda.subject_name AS subject_name,
        lsn.subject_sub_id AS subject_sub_id,
        eda.subject_sub_name AS subject_sub_name,
        lsn.stu_id AS stu_id,
        case when mst.del_flg = 1 then  CONCAT(mst.stu_name, '(已退学)')
             else mst.stu_name
        end AS stu_name,
        lsn.class_duration AS class_duration,
        lsn.schedual_type AS schedual_type,
        case 
			when lsn.extra_to_dur_date is not null -- 如果该记录是加课换正课记录
            then  lsn.extra_to_dur_date
            else lsn.schedual_date
        end as schedual_date,
        case 
			when lsn.extra_to_dur_date is not null -- 如果该记录是加课换正课记录
            then null -- 成了正课记录的情况下，就让调课日期为null，这样手机页面的加课换正课记录就不会再显示调课日期了👍
            else lsn.lsn_adjusted_date
		end AS lsn_adjusted_date,
        lsn.scanqr_date,
		case 
			when lsn.extra_to_dur_date is not null  -- 如果该记录是加课换正课记录 -- 加课换正课的场合，记住原来真正签到的日期
            then 
				case
					when lsn.lsn_adjusted_date is not null
                    then lsn.lsn_adjusted_date -- 调课日期是原来实际的上课日期
                    else lsn.schedual_date     -- 计划日期是原来实际的上课日期
				end
        end as original_schedual_date,
        case 
			when extra_to_dur_date is not null  -- 如果该记录是加课换正课记录
            then 1 -- 加课换正课的场合，因为已经成为其他日期的正课，所以强行成为正课区分
            else lsn.lesson_type -- 上记以外的场合
        end AS lesson_type,
        lsn.memo,
        -- mst.del_flg AS del_flg,
        lsn.create_date AS create_date,
        lsn.update_date AS update_date
    FROM
        ((t_info_lesson lsn
        INNER JOIN t_mst_student mst ON ((lsn.stu_id = mst.stu_id)))
        INNER JOIN v_info_subject_edaban eda ON (((lsn.subject_id = eda.subject_id)
            AND (lsn.subject_sub_id = eda.subject_sub_id)
            AND lsn.del_flg = 0)))
;


-- USE prod_KNStudent;
-- 前提条件，加课换正课执行完了，换正课的lesson_id会将t_info_lesson_fee表中的该记录的del_flg更新为0
-- 同时，会在t_info_lesson_extra_to_sche中记录原来的lsn_fee_id和换正课后所在月份的新的lsn_fee_id
-- 该视图就是将原来的课费信息和换正课后的课费信息进行了重新整合。
DROP VIEW IF EXISTS v_info_lesson_fee_include_extra2sche;
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW  v_info_lesson_fee_include_extra2sche AS 
select 
	lsn_fee_id,
    lesson_id,
    pay_style,
    lsn_fee,
    lsn_month,
    own_flg,
    0 as del_flg,
    0 as extra2sche_flg, -- 正常课程标识
    create_date,
    update_date
from t_info_lesson_fee 
where del_flg = 0
union all
select 
	ext.new_lsn_fee_id as lsn_fee_id,
    fee.lesson_id,
    fee.pay_style,
    ext.new_lsn_fee as lsn_fee, -- 如果遇上换正课的那个月份的子科目和该加课的子科目不一致（例如，2024年12月是钢琴5级的课程，换正课到2025年1月，但是1月份开始学6级的课程，那么加课的课程属性就随换正课的课程属性走（即，换正课后的级别就是6级，课费按6级课费走）
    substring(ext.new_scanqr_date,1,7) as lsn_month,
    ext.new_own_flg as own_flg,
    0 as del_flg,
    1 as extra2sche_flg, -- 加课换正课标识
    fee.create_date,
    fee.update_date
from 
t_info_lesson_fee fee
inner join
t_info_lesson_extra_to_sche ext
on fee.lesson_id = ext.lesson_id
and fee.del_flg = 1
;


/**
*视图v_info_lesson_include_extra2sche是在v_info_lesson视图的代码基础上作成的，该视图
*只针对加课换成了正课后，对加课换正课的那个记录进行了处理，
*执行视图v_info_lesson，可以看到换正课之前,该月加课记录的真实样貌（相当于姑娘结婚前在娘家的样貌）
*执行v_info_lesson_include_extra2sche，只能看到加课换成正课之后，变成正课的样貌（相当于姑娘结婚后在婆家的样貌）
*该视图只针对加课换正课的数据处理，对其调课记录，正课记录没有影响。
*/
-- use prod_KNStudent;
-- USE KNStudent;
DROP VIEW IF EXISTS v_info_lesson_and_extraToScheDataCorrectBefore;
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_info_lesson_and_extraToScheDataCorrectBefore AS
    SELECT 
        lsn.lesson_id AS lesson_id,
        lsn.subject_id AS subject_id,
        eda.subject_name AS subject_name,
        lsn.subject_sub_id AS subject_sub_id,
        eda.subject_sub_name AS subject_sub_name,
        lsn.stu_id AS stu_id,
        CASE 
            WHEN mst.del_flg = 1 THEN CONCAT(mst.stu_name, '(已退学)')
            ELSE mst.stu_name
        END AS stu_name,
        lsn.class_duration AS class_duration,
        lsn.schedual_type AS schedual_type,
        CASE 
            WHEN lsn.extra_to_dur_date IS NOT NULL THEN lsn.extra_to_dur_date -- 该记录是加课换正课记录
            ELSE lsn.schedual_date
        END as schedual_date,
        CASE 
            WHEN lsn.extra_to_dur_date IS NOT NULL THEN NULL -- 该记录是加课换正课记录，就让调课日期为null，这样手机页面的加课换正课记录就不会再显示调课日期了👍
            ELSE lsn.lsn_adjusted_date
        END AS lsn_adjusted_date,
        lsn.scanqr_date,
        CASE 
            WHEN lsn.extra_to_dur_date IS NOT NULL THEN  -- 该记录是加课换正课记录，记住原来真正签到的日期
                CASE
                    WHEN lsn.lsn_adjusted_date IS NOT NULL THEN lsn.lsn_adjusted_date  -- 调课日期是原来实际的上课日期
                    ELSE lsn.schedual_date -- 计划日期是原来实际的上课日期
                END
        END as original_schedual_date,
        CASE 
            WHEN extra_to_dur_date IS NOT NULL THEN 1 -- 该记录是加课换正课记录，因为已经成为其他日期的正课，所以强行成为正课区分
            ELSE lsn.lesson_type
        END AS lesson_type,
        mst.del_flg AS del_flg,
        lsn.create_date AS create_date,
        lsn.update_date AS update_date
    FROM
        ((t_info_lesson lsn
        INNER JOIN t_mst_student mst ON ((lsn.stu_id = mst.stu_id)))
        INNER JOIN v_info_subject_edaban eda ON (((lsn.subject_id = eda.subject_id)
            AND (lsn.subject_sub_id = eda.subject_sub_id))))
;
/**
*视图v_info_lesson_include_extra2sche是在v_info_lesson视图的代码基础上作成的，该视图
*只针对加课换成了正课后，对加课换正课的记录进行了处理，
*执行v_info_lesson，可以看到换正课之前,该月加课记录的真实记录（相当于姑娘化妆前的样貌）
*执行v_info_lesson_include_extra2sche，只能看到加课换成正课之后，变成正课的样貌（相当于姑娘化妆后的样貌）
*如果加课换正课赶上了课程升级（比如，去年12月份学的5级的加课换成今年1月份正课，但是，1月份开始进入6级的课程，
*那么，换到1月正课的那个加课将被视为6级课程）。t_info_lesson_extra_to_sche表里
*会记录该加课的课程级别和换正课后的课程级别。
*该视图只针对加课换正课的数据处理，对其调课记录，正课记录没有影响。
*/
-- use prod_KNStudent;
-- USE KNStudent;
DROP VIEW IF EXISTS v_info_lesson_and_extraToScheDataCorrect;
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_info_lesson_and_extraToScheDataCorrect AS
    SELECT 
        lsn.lesson_id AS lesson_id,
        lsn.subject_id AS subject_id,
        eda.subject_name AS subject_name,
        lsn.subject_sub_id AS subject_sub_id,
        eda.subject_sub_name AS subject_sub_name,
        lsn.stu_id AS stu_id,
        CASE 
            WHEN mst.del_flg = 1 THEN CONCAT(mst.stu_name, '(已退学)')
            ELSE mst.stu_name
        END AS stu_name,
        lsn.class_duration AS class_duration,
        lsn.schedual_type AS schedual_type,
        lsn.schedual_date,
        lsn.lsn_adjusted_date,
        lsn.scanqr_date,
        lsn.original_schedual_date,
        lsn.lesson_type,
        mst.del_flg AS del_flg,
        lsn.create_date AS create_date,
        lsn.update_date AS update_date
    FROM
        (
            SELECT 
                lsn.lesson_id AS lesson_id,
                lsn.subject_id AS subject_id,
                lsn.subject_sub_id AS subject_sub_id,
                lsn.stu_id AS stu_id,
                lsn.class_duration AS class_duration,
                lsn.schedual_type AS schedual_type,
                lsn.schedual_date,
                lsn.lsn_adjusted_date,
                lsn.scanqr_date,
                NULL as original_schedual_date,
                lsn.lesson_type,
                lsn.create_date AS create_date,
                lsn.update_date AS update_date
            FROM
                t_info_lesson lsn 
            WHERE 
                extra_to_dur_date IS NULL -- 非加课换正课记录
            UNION ALL
            SELECT 
                lsn.lesson_id AS lesson_id,
                lsn.subject_id AS subject_id,
                extr.new_subject_sub_id AS subject_sub_id,
                lsn.stu_id as stu_id,
                lsn.class_duration AS class_duration,
                lsn.schedual_type AS schedual_type,
                extra_to_dur_date as schedual_date,
                NULL AS lsn_adjusted_date, -- 成了正课记录的情况下，就让调课日期为null，这样手机页面的加课换正课记录就不会再显示调课日期了👍
                lsn.scanqr_date,
                lsn.schedual_date as original_schedual_date,
                1 AS lesson_type, -- 加课换正课的场合，因为已经成为其他日期的正课，所以强行成为正课区分
                lsn.create_date AS create_date,
                lsn.update_date AS update_date 
            FROM 
                t_info_lesson lsn
            INNER JOIN 
                t_info_lesson_extra_to_sche extr 
            ON 
                extr.lesson_id = lsn.lesson_id 
                AND lsn.extra_to_dur_date IS NOT NULL
        ) lsn
        INNER JOIN t_mst_student mst ON lsn.stu_id = mst.stu_id
        INNER JOIN v_info_subject_edaban eda ON lsn.subject_id = eda.subject_id
                                            AND lsn.subject_sub_id = eda.subject_sub_id;

-- 前提条件，加课换正课执行完了，换正课的lesson_id会将t_info_lesson_fee表中的该记录的del_flg更新为0
-- 同时，会在t_info_lesson_extra_to_sche中,记录原来的lsn_fee_id和换正课后所在月份的新的lsn_fee_id
-- 该视图就是将原来的课费信息和换正课后的课费信息进行了重新整合。
DROP VIEW IF EXISTS v_info_lesson_fee_and_extraToScheDataCorrectBefore;
CREATE VIEW v_info_lesson_fee_and_extraToScheDataCorrectBefore AS 
    select 
        lsn_fee_id,
        lesson_id,
        pay_style,
        lsn_fee,
        lsn_month,
        own_flg,
        0 as del_flg,
        0 as extra2sche_flg, -- 正常课程标识
        create_date,
        update_date
    from t_info_lesson_fee 
    where del_flg = 0
    union all
    select 
        ext.new_lsn_fee_id as lsn_fee_id,
        fee.lesson_id,
        fee.pay_style,
        fee.lsn_fee,
        substring(ext.new_scanqr_date,1,7) as lsn_month,
        ext.new_own_flg as own_flg,
        0 as del_flg,
        1 as extra2sche_flg, -- 加课换正课标识
        fee.create_date,
        fee.update_date
    from 
    t_info_lesson_fee fee
    inner join
    t_info_lesson_extra_to_sche ext
    on fee.lesson_id = ext.lesson_id
    and fee.del_flg = 1
    ;

/**
* 前提条件，加课换正课执行完了，换正课的lesson_id会将t_info_lesson_fee表中的该记录的del_flg更新为1(表示换正课之前计算的这个课费记录不要了)
*同时，会在t_info_lesson_extra_to_sche中,记录原来的lsn_fee_id和换正课后所在月份的新的lsn_fee_id
*如果加课换正课赶上了课程升级（比如，去年12月份学的5级的加课换成今年1月份正课，如果1月份开始已经进入6级的课程，
*那么，换到1月正课的那个加课将被视为6级课程，课程价格也将按照6级的价格记录在会在t_info_lesson_extra_to_sche中。
* 该视图就是将原来的课费信息和换正课后的课费信息进行了重新整合。
*/
DROP VIEW IF EXISTS v_info_lesson_fee_and_extraToScheDataCorrect;
CREATE VIEW v_info_lesson_fee_and_extraToScheDataCorrect AS 
    -- 未换正课的课费信息
    SELECT 
        lsn_fee_id,
        lesson_id,
        pay_style,
        lsn_fee,
        lsn_month,
        own_flg,
        0 as del_flg,
        0 as extra2sche_flg, -- 正常课程标识
        create_date,
        update_date
    FROM 
        t_info_lesson_fee 
    WHERE 
        del_flg = 0
    UNION ALL
     -- 已换正课的课费信息
    SELECT 
        ext.new_lsn_fee_id as lsn_fee_id,
        fee.lesson_id,
        fee.pay_style,
        ext.new_lsn_fee as lsn_fee, -- 如果遇上换正课的那个月份的子科目和该加课的子科目不一致（例如，2024年12月是钢琴5级的课程，换正课到2025年1月，但是1月份开始学6级的课程，那么加课的课程属性就随换正课的课程属性走（即，换正课后的级别就是6级，课费按6级课费走）
        SUBSTRING(ext.new_scanqr_date,1,7) as lsn_month,
        ext.new_own_flg as own_flg,
        0 as del_flg,
        1 as extra2sche_flg, -- 加课换正课标识
        fee.create_date,
        fee.update_date
    FROM 
        t_info_lesson_fee fee
    INNER JOIN
        t_info_lesson_extra_to_sche ext
    ON 
        fee.lesson_id = ext.lesson_id
        AND fee.del_flg = 1
;


/**
* 获取所有学生签完到的上课记录和课费记录
*/
-- use prod_KNStudent;
-- use KNStudent;
DROP VIEW IF EXISTS v_info_lesson_fee_connect_lsn_and_extraToScheDataCorrectBefore;
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_info_lesson_fee_connect_lsn_and_extraToScheDataCorrectBefore AS
    SELECT 
        fee.lsn_fee_id AS lsn_fee_id,
        fee.lesson_id AS lesson_id,
        lsn.lesson_type AS lesson_type,
        (lsn.class_duration / doc.minutes_per_lsn) AS lsn_count,
        doc.stu_id AS stu_id,
        case when doc.del_flg = 1 then  CONCAT(doc.stu_name, '(已退学)')
             else doc.stu_name
        end AS stu_name,
        doc.subject_id AS subject_id,
        doc.subject_name AS subject_name,
        doc.pay_style AS pay_style,
        lsn.subject_sub_id AS subject_sub_id,
        doc.subject_sub_name AS subject_sub_name,
        (CASE
            WHEN (doc.lesson_fee_adjusted > 0) THEN doc.lesson_fee_adjusted
            ELSE doc.lesson_fee
        END) AS subject_price,
        (fee.lsn_fee * (lsn.class_duration / doc.minutes_per_lsn)) AS lsn_fee,
        fee.lsn_month AS lsn_month,
        fee.own_flg AS own_flg,
        fee.del_flg AS del_flg,
        fee.extra2sche_flg,
        fee.create_date AS create_date,
        fee.update_date AS update_date
    FROM
        ((v_info_lesson_fee_and_extraToScheDataCorrectBefore fee -- 包含了加课换正课后的记录
        JOIN v_info_lesson_and_extraToScheDataCorrectBefore lsn   -- 包含了加课换正课后的记录
        ON (((fee.lesson_id = lsn.lesson_id)
            AND (fee.del_flg = 0)
            AND (lsn.del_flg = 0))))
        LEFT JOIN v_info_student_document doc ON (((lsn.stu_id = doc.stu_id)
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
    ORDER BY fee.lsn_month
;
-- use prod_KNStudent;
-- use KNStudent;
/**
* 获取所有学生签完到的上课记录和课费记录
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
        fee.create_date AS create_date,
        fee.update_date AS update_date
    FROM
        ((v_info_lesson_fee_and_extraToScheDataCorrect fee -- 包含了加课换正课后的记录
        JOIN v_info_lesson_and_extraToScheDataCorrect lsn  -- 包含了加课换正课后的记录
        ON (((fee.lesson_id = lsn.lesson_id)
            AND (fee.del_flg = 0))))
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
        0 AS lsn_count,                          -- 固定值0
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
        fee.create_date AS create_date,
        fee.update_date AS update_date
    FROM t_info_lesson_fee fee
    INNER JOIN v_info_lesson_tmp tmp ON fee.lesson_id = tmp.lsn_tmp_id
    WHERE fee.del_flg = 0

    ORDER BY lsn_month
;

-- 21授業料金情報管理
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_lesson_fee_connect_lsn`;
-- 视图 从t_info_lesson_fee表里抽出学生各自科目的费用信息
-- 这里的课程都是已经签到完了的课程记录
-- 月计划的情况下（lesson_type=1),4个lesson_id对应1个lsn_fee_id
-- 月加课和课结算的情况下（lesson_type=0，1),1个lesson_id对应1个lsn_fee_id
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_info_lesson_fee_connect_lsn AS
    SELECT 
        fee.lsn_fee_id AS lsn_fee_id,
        fee.lesson_id AS lesson_id,
        lsn.lesson_type AS lesson_type,
        (lsn.class_duration / doc.minutes_per_lsn) AS lsn_count,
        doc.stu_id AS stu_id,
        case when doc.del_flg = 1 then  CONCAT(doc.stu_name, '(已退学)')
             else doc.stu_name
        end AS stu_name,
        doc.subject_id AS subject_id,
        doc.subject_name AS subject_name,
        doc.pay_style AS pay_style,
        lsn.subject_sub_id AS subject_sub_id,
        doc.subject_sub_name AS subject_sub_name,
        (CASE
            WHEN (doc.lesson_fee_adjusted > 0) THEN doc.lesson_fee_adjusted
            ELSE doc.lesson_fee
        END) AS subject_price,
        (fee.lsn_fee * (lsn.class_duration / doc.minutes_per_lsn)) AS lsn_fee,
        fee.lsn_month AS lsn_month,
        fee.own_flg AS own_flg,
        fee.del_flg AS del_flg,
        fee.extra2sche_flg,
        fee.create_date AS create_date,
        fee.update_date AS update_date
    FROM
        ((v_info_lesson_fee_include_extra2sche fee -- 包含了加课换正课后的记录
        JOIN v_info_lesson_include_extra2sche lsn   -- 包含了加课换正课后的记录
        ON (((fee.lesson_id = lsn.lesson_id)
            AND (fee.del_flg = 0)
            -- AND (lsn.del_flg = 0) -- 此处的del_flg=0 不是课程的理论删除值，而是学生表的理论删除，这样的处理是不合理的。
            )))
        LEFT JOIN v_info_student_document doc ON (((lsn.stu_id = doc.stu_id)
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
    ORDER BY fee.lsn_month
;
-- 📱手机端用视图 课程进度统计，用该视图取出的数据初期化手机页面的graph图
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_lsn_statistics_by_stuid`;
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%`
    SQL SECURITY DEFINER
VIEW v_info_lsn_statistics_by_stuid AS
SELECT 
        stu_id AS stu_id,
        stu_name AS stu_name,
        subject_name AS subject_name,
        subject_id AS subject_id,
        subject_sub_id AS subject_sub_id,
        subject_sub_name AS subject_sub_name,
        lesson_type AS lesson_type,
        SUM(lsn_count) AS lsn_count,
        lsn_month AS lsn_month
    FROM
        v_info_lesson_fee_connect_lsn_and_extraToScheDataCorrect
    GROUP BY stu_id , 
	         stu_name , 
             subject_name , 
             subject_id , 
             subject_sub_id , 
             subject_sub_name , 
             lesson_type , 
             lsn_month
    ORDER BY lsn_month , 
			 subject_id , 
             subject_sub_id
;


-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_lesson_sum_fee_unpaid_yet`;
-- 📱视图 从v_info_lesson_fee_connect_lsn表里每个每月上完每个科目的课数和未支付课费做统计
-- 手机前端页面使用
/* 该视图被下列视图给调用了
		v_sum_unpaid_lsnfee_by_stu_and_month
 */
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER 
VIEW v_info_lesson_sum_fee_unpaid_yet AS 
/* 
把按月交费的科目做一个统计，月交费场合下的lsn_fee_id lesson_id是1:n的关系，
此视图是将n个lesson的课时和课费做一个求和统计，
使得lsn_pay_id,lsn_fee_id能清楚地表达出这两个字段的1:1关系
*/
SELECT
    '' as lsn_pay_id,
    newtmptbl.lsn_fee_id,    -- 明确指定来源
    newtmptbl.stu_id,
    newtmptbl.stu_name,
    newtmptbl.nik_name,
    newtmptbl.subject_id,
    newtmptbl.subject_name,
    newtmptbl.subject_sub_id,
    newtmptbl.subject_sub_name,
    newtmptbl.subject_price,
    newtmptbl.pay_style,
    SUM(newtmptbl.lsn_count) AS lsn_count,
    SUM(CASE 
            WHEN newtmptbl.lesson_type = 1 THEN newtmptbl.subject_price * 4
            ELSE newtmptbl.lsn_fee 
        END) as lsn_fee,
    NULL as pay_date,
    newtmptbl.lesson_type,
    newtmptbl.lsn_month,
    newtmptbl.own_flg 
FROM (
    SELECT 
        lsn_fee_id,
        stu_id,
        stu_name,
        nik_name,
        subject_id,
        subject_name,
        subject_sub_id,
        subject_sub_name,
        subject_price,
        pay_style,
        SUM(lsn_count) AS lsn_count,
        SUM(lsn_fee) as lsn_fee,
        lesson_type,
        lsn_month,
        own_flg 
    FROM 
        v_info_lesson_fee_connect_lsn_and_extraToScheDataCorrect
    WHERE 
        own_flg = 0
        AND del_flg = 0
    GROUP BY 
        lsn_fee_id,
        stu_id,
        stu_name,
        nik_name,
        subject_id,
        subject_name,
        subject_sub_id,
        subject_sub_name,
        subject_price,
        pay_style,
        lesson_type,
        lsn_month,
        own_flg
) newtmptbl
GROUP BY 
    newtmptbl.lsn_fee_id,
    newtmptbl.stu_id,
    newtmptbl.stu_name,
    newtmptbl.nik_name,
    newtmptbl.subject_id,
    newtmptbl.subject_name,
    newtmptbl.subject_sub_id,
    newtmptbl.subject_sub_name,
    newtmptbl.subject_price,
    newtmptbl.pay_style,
    newtmptbl.lesson_type,
    newtmptbl.lsn_month,
    newtmptbl.own_flg
;

-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_lesson_sum_fee_pay_over`;
-- 视图 从v_info_lesson_fee_connect_lsn表里每月上完的课数和已支付课费做统计
-- 手机前端页面使用
/* 该视图也被下列视图调用：
		v_info_lesson_pay_over、
		v_sum_haspaid_lsnfee_by_stu_and_month */ 
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER 
VIEW v_info_lesson_sum_fee_pay_over AS
/* 
把按月交费的科目做一个统计，月交费场合下的lsn_fee_id lesson_id是1:n的关系，
此视图是将n个lesson的课时和课费做一个求和统计，
使得lsn_pay_id,lsn_fee_id能清楚地表达出这两个字段的1:1关系
*/
SELECT 
    pay.lsn_pay_id,
    fee.lsn_fee_id,
    fee.stu_id,
    fee.stu_name,
    fee.nik_name,
    fee.subject_id,
    fee.subject_name,
    fee.subject_sub_id,
    fee.subject_sub_name,
    fee.subject_price,
    fee.pay_style,
    SUM(fee.lsn_count) AS lsn_count,
    SUM(fee.lsn_fee) AS lsn_fee, -- 应支付
    SUM(pay.lsn_pay) AS lsn_pay, -- 已支付
    pay.pay_date,
    pay.bank_id,
    fee.lsn_month,
    fee.lsn_month as pay_month,
    fee.lesson_type
FROM 
    (
        SELECT
            lsn_fee_id,
            stu_id,
            stu_name,
            nik_name,
            subject_id,
            subject_name,
            subject_sub_id,
            subject_sub_name,
            subject_price,
            pay_style,
            lesson_type,
            CASE 
                WHEN lesson_type = 1 THEN subject_price * 4
                ELSE SUM(lsn_fee)
            END AS lsn_fee,
            lsn_count,
            lsn_month
        FROM (
            SELECT 
                lsn_fee_id,
                stu_id,
                stu_name,
                nik_name,
                subject_id,
                subject_name,
                subject_sub_id,
                subject_sub_name,
                subject_price,
                pay_style,
                lesson_type,
                SUM(lsn_count) as lsn_count,
                SUM(lsn_fee) as lsn_fee,
                lsn_month
            FROM 
                v_info_lesson_fee_connect_lsn_and_extraToScheDataCorrect
            WHERE 
                own_flg = 1
            GROUP BY 
                lsn_fee_id, stu_id, stu_name, nik_name, subject_id, subject_name, 
                subject_sub_id, subject_sub_name, lsn_month, subject_price, 
                pay_style, lesson_type
        ) aa
        GROUP BY 
            lsn_fee_id, stu_id, stu_name, nik_name, subject_id, subject_name, 
            subject_sub_id, subject_sub_name, lsn_month, subject_price, 
            pay_style, lesson_type, lsn_count
    ) fee
    INNER JOIN
        t_info_lesson_pay pay
    ON
        fee.lsn_fee_id = pay.lsn_fee_id
GROUP BY 
    pay.lsn_pay_id,
    fee.lsn_fee_id,
    fee.stu_id,
    fee.stu_name,
    fee.nik_name,
    fee.subject_id,
    fee.subject_name,
    fee.subject_sub_id,
    fee.subject_sub_name,
    fee.subject_price,
    fee.pay_style,
    fee.lsn_month,
    pay.pay_date,
    pay.bank_id,
    fee.lesson_type
;

-- 授業課費精算管理
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_lesson_pay_over`;
-- 视图 从t_info_lesson_pay表里抽取精算完了的学生课程信息
-- 后台维护用
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_info_lesson_pay_over AS
    SELECT 
        vsumfee.lsn_pay_id AS lsn_pay_id,
        vsumfee.lsn_fee_id AS lsn_fee_id,
        vsumfee.stu_id AS stu_id,
        vsumfee.stu_name AS stu_name,
        vsumfee.subject_id AS subject_id,
        vsumfee.subject_name AS subject_name,
        vsumfee.subject_sub_id AS subject_sub_id,
        vsumfee.subject_sub_name AS subject_sub_name,
        vsumfee.pay_style AS pay_style,
        vsumfee.lesson_type AS lesson_type,
        vsumfee.lsn_count AS lsn_count,
        vsumfee.lsn_fee AS lsn_fee,
        vsumfee.lsn_pay AS lsn_pay,
        bnk.bank_id AS bank_id,
        bnk.bank_name AS bank_name,
        vsumfee.lsn_month AS pay_month,
        vsumfee.pay_date AS pay_date
    FROM
        v_info_lesson_sum_fee_pay_over vsumfee 
        LEFT JOIN t_mst_bank bnk ON (vsumfee.bank_id = bnk.bank_id)
;


-- 学费月度报告的分组查询 
-- ①未支付学费统计（分组查询学生，月份）
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_sum_unpaid_lsnfee_by_stu_and_month`;
-- 后台维护用
-- 本视图被下列视图单独调用
   -- v_total_lsnfee_with_paid_unpaid_every_month
   -- v_total_lsnfee_with_paid_unpaid_every_month_every_student
-- ①每个学生每个月未支付状况的分组合计 v_sum_unpaid_lsnfee_by_stu_and_month
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_sum_unpaid_lsnfee_by_stu_and_month AS
    SELECT 
        stu_id AS stu_id,
        stu_name AS stu_name,
        nik_name AS nik_name,
        SUM(lsn_fee) AS lsn_fee,
        lsn_month AS lsn_month
    FROM
        v_info_lesson_sum_fee_unpaid_yet
    GROUP BY 
        stu_id, 
        stu_name, 
        nik_name, 
        lsn_month
;

-- ②未支付学费统计（分组查询月份Only）
-- ③已支付学费统计（分组查询学生，月份）
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_sum_haspaid_lsnfee_by_stu_and_month`;

-- 后台维护用
-- 本视图被下列视图单独调用
   -- v_total_lsnfee_with_paid_unpaid_every_month
   -- v_total_lsnfee_with_paid_unpaid_every_month_every_student
-- ③所有在课学生的每个月已支付状况的分组合计 v_sum_haspaid_lsnfee_by_stu_and_month
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_sum_haspaid_lsnfee_by_stu_and_month AS
    SELECT
        stu_id AS stu_id,
        stu_name AS stu_name,
        nik_name AS nik_name,
        SUM(lsn_fee) AS lsn_fee,
        SUM(lsn_pay) AS lsn_pay,
        lsn_month AS lsn_month
    FROM
        v_info_lesson_sum_fee_pay_over
    GROUP BY stu_id,
             stu_name,
             nik_name,
             lsn_month
;

-- ④对课费管理视图的学费（已支付未支付都包括在内）的总计算按学生按月的分组查询
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_sum_lsn_fee_for_fee_connect_lsn_by_stu_month`;

-- 后台维护用
-- 本视图被下列视图单独调用
	-- v_total_lsnfee_with_paid_unpaid_every_month 
	-- v_total_lsnfee_with_paid_unpaid_every_month_every_student
-- ④对课费管理视图的学费（已支付未支付都包括在内）的总计算按学生按月的分组查询 v_sum_lsn_fee_for_fee_connect_lsn
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_sum_lsn_fee_for_fee_connect_lsn_by_stu_month AS
    SELECT 
        aa.lsn_fee_id AS lsn_fee_id,
        aa.stu_id AS stu_id,
        aa.stu_name AS stu_name,
        aa.nik_name AS nik_name,
        aa.subject_id AS subject_id,
        aa.subject_name AS subject_name,
        aa.subject_sub_id AS subject_sub_id,
        aa.subject_sub_name AS subject_sub_name,
        aa.subject_price AS subject_price,
        aa.pay_style AS pay_style,
        aa.lesson_type AS lesson_type,
        CASE  
            WHEN (aa.lesson_type = 1) THEN (aa.subject_price * 4)
            ELSE SUM(aa.lsn_fee)
        END as lsn_fee,
        aa.lsn_count AS lsn_count,
        aa.lsn_month AS lsn_month
    FROM
        (SELECT 
            T1.lsn_fee_id AS lsn_fee_id,
            T1.stu_id AS stu_id,
            T1.stu_name AS stu_name,
            T1.nik_name AS nik_name,
            T1.subject_id AS subject_id,
            T1.subject_name AS subject_name,
            T1.subject_sub_id AS subject_sub_id,
            T1.subject_sub_name AS subject_sub_name,
            T1.subject_price AS subject_price,
            T1.pay_style AS pay_style,
            T1.lesson_type AS lesson_type,
            SUM(T1.lsn_count) AS lsn_count,
            SUM(T1.lsn_fee) AS lsn_fee,
            T1.lsn_month AS lsn_month
        FROM
            v_info_lesson_fee_connect_lsn_and_extraToScheDataCorrect T1
        GROUP BY 
            T1.lsn_fee_id, T1.stu_id, T1.stu_name, T1.nik_name, T1.subject_id, 
            T1.subject_name, T1.subject_sub_id, T1.subject_sub_name, T1.lsn_month, 
            T1.subject_price, T1.pay_style, T1.lesson_type
        ) aa
    GROUP BY 
        aa.lsn_fee_id, aa.stu_id, aa.stu_name, aa.nik_name, aa.subject_id, 
        aa.subject_name, aa.subject_sub_id, aa.subject_sub_name, aa.lsn_month, 
        aa.subject_price, aa.pay_style, aa.lesson_type, aa.lsn_count
;

DROP VIEW IF EXISTS v_sum_lsn_fee_for_fee_connect_lsn;
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_sum_lsn_fee_for_fee_connect_lsn AS
/* 这是按照学生实际上的课产生的实际的学费
    SELECT 
        stu_id AS stu_id,
        stu_name AS stu_name,
        lsn_fee_id AS lsn_fee_id,
        subject_price AS subject_price,
        lesson_type AS lesson_type,
        SUM(lsn_fee) AS lsn_fee,
        lsn_month AS lsn_month
    FROM
        v_info_lesson_fee_connect_lsn_and_extraToScheDataCorrect
    GROUP BY stu_id ,
             stu_name , 
             lsn_month , 
             lsn_fee_id , 
             subject_price , 
             lesson_type;
*/ 
/* 这是按照学生应缴纳的学费 */
    SELECT 
        stu_id AS stu_id,
        stu_name AS stu_name,
        -- lsn_fee_id AS lsn_fee_id,
        subject_price AS subject_price,
        lesson_type AS lesson_type,
        case when (pay_style = 1 and lesson_type = 1) then subject_price * 4
			 else SUM(lsn_fee) 
		end AS lsn_fee,
        lsn_month AS lsn_month
    FROM
        v_info_lesson_fee_connect_lsn_and_extraToScheDataCorrect
    GROUP BY stu_id ,
             stu_name , 
             lsn_month , 
           --   lsn_fee_id , 
             subject_price , 
             lesson_type,
             pay_style
;

-- (学生总综合)所有学生当前年度每月总课费的总支付，未支付状况查询
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_total_lsnfee_with_paid_unpaid_every_month`;
-- 后台维护用
-- 所有在课学生的每个月总课费，已支付，未支付状况 v_total_lsnfee_with_paid_unpaid_every_month
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_total_lsnfee_with_paid_unpaid_every_month AS
    SELECT 
        SUM(lsn_fee_alias.should_pay_lsn_fee) AS should_pay_lsn_fee,
        SUM(lsn_fee_alias.has_paid_lsn_fee) AS has_paid_lsn_fee,
        SUM(lsn_fee_alias.unpaid_lsn_fee) AS unpaid_lsn_fee,
        lsn_fee_alias.lsn_month AS lsn_month
    FROM
        (SELECT 
            SUM(T1.lsn_fee) AS should_pay_lsn_fee,
            0.0 AS has_paid_lsn_fee,
            0.0 AS unpaid_lsn_fee,
            T1.lsn_month AS lsn_month
        FROM
            -- v_sum_lsn_fee_for_fee_connect_lsn_by_stu_month T1
            v_sum_lsn_fee_for_fee_connect_lsn T1
        GROUP BY T1.lsn_month 
        UNION ALL 
        SELECT 
            0.0 AS should_pay_lsn_fee,
            SUM(T2.lsn_pay) AS has_paid_lsn_fee,
            0.0 AS unpaid_lsn_fee,
            T2.lsn_month AS lsn_month
        FROM
            v_sum_haspaid_lsnfee_by_stu_and_month T2
        GROUP BY T2.lsn_month 
        UNION ALL 
        SELECT 
            0.0 AS should_pay_lsn_fee,
            0.0 AS has_paid_lsn_fee,
            SUM(T3.lsn_fee) AS unpaid_lsn_fee,
            T3.lsn_month AS lsn_month
        FROM
            v_sum_unpaid_lsnfee_by_stu_and_month T3
        GROUP BY T3.lsn_month
        ) lsn_fee_alias
    GROUP BY lsn_fee_alias.lsn_month
;

-- （学生明细综合）每个学生当前年度每月总课费的总支付，未支付状况查询
-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_total_lsnfee_with_paid_unpaid_every_month_every_student`;
-- 后台维护用
-- 每个学生当前年度每月总课费的总支付，未支付状况查询 v_total_lsnfee_with_paid_unpaid_every_month_every_student
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_total_lsnfee_with_paid_unpaid_every_month_every_student AS
    SELECT 
        feeStatus.stu_id AS stu_id,
        feeStatus.stu_name AS stu_name,
        feeStatus.nik_name AS nik_name,
        feeStatus.lsn_month AS lsn_month,
        SUM(feeStatus.should_pay_lsn_fee) AS should_pay_lsn_fee,
        SUM(feeStatus.has_paid_lsn_fee) AS has_paid_lsn_fee,
        SUM(feeStatus.unpaid_lsn_fee) AS unpaid_lsn_fee
    FROM
        (SELECT 
            T1.stu_id AS stu_id,
            T1.stu_name AS stu_name,
            T1.nik_name AS nik_name,
            SUM(T1.lsn_fee) AS should_pay_lsn_fee,
            0.0 AS has_paid_lsn_fee,
            0.0 AS unpaid_lsn_fee,
            T1.lsn_month AS lsn_month
        FROM
            v_sum_lsn_fee_for_fee_connect_lsn_by_stu_month T1
        GROUP BY T1.stu_id , T1.stu_name , T1.nik_name,T1.lsn_month 
        UNION ALL 
        SELECT 
            T2.stu_id AS stu_id,
            T2.stu_name AS stu_name,
            T2.nik_name AS nik_name,
            0.0 AS should_pay_lsn_fee,
            SUM(T2.lsn_fee) AS has_paid_lsn_fee,
            0.0 AS unpaid_lsn_fee,
            T2.lsn_month AS lsn_month
        FROM
            v_sum_haspaid_lsnfee_by_stu_and_month T2
        GROUP BY T2.stu_id , T2.stu_name ,T2.nik_name, T2.lsn_month 
        UNION ALL 
        SELECT 
            T3.stu_id AS stu_id,
            T3.stu_name AS stu_name,
            T3.nik_name AS nik_name,
            0.0 AS should_pay_lsn_fee,
            0.0 AS has_paid_lsn_fee,
            SUM(T3.lsn_fee) AS unpaid_lsn_fee,
            T3.lsn_month AS lsn_month
        FROM
            v_sum_unpaid_lsnfee_by_stu_and_month T3
        GROUP BY T3.stu_id, T3.stu_name, T3.nik_name, T3.lsn_month) feeStatus
    GROUP BY feeStatus.stu_id, feeStatus.stu_name, feeStatus.nik_name, feeStatus.lsn_month
;

-- USE prod_KNStudent;
DROP VIEW IF EXISTS v_info_all_extra_lsns;
-- 前提条件，加课都已经签到完了，找出那些已经结算和还未结算的加课信息
-- 零碎加课拼凑成整课，并且已经把整课换成正课的零碎课除外（即，零碎课的del_flg=1的除外了 2025-06-07追加）
-- 已经结算的加课费
CREATE VIEW v_info_all_extra_lsns AS 
SELECT 
    lsn.lesson_id,
    lsn.stu_id,
    lsn.subject_id,
    lsn.subject_sub_id,
    lsn.class_duration,
    lsn.lesson_type,
    lsn.schedual_type,
    lsn.schedual_date,
    lsn.lsn_adjusted_date,
    lsn.extra_to_dur_date,
    lsn.scanqr_date,
    1 as pay_flg 
FROM 
	t_info_lesson lsn
	inner join 
	t_info_lesson_fee fee
	on lsn.lesson_id = fee.lesson_id and fee.del_flg = 0 and lsn.del_flg = 0
	inner join
	t_info_lesson_pay pay
	on fee.lsn_fee_id = pay.lsn_fee_id
	where lsn.scanqr_date is not null 
	and lsn.lesson_type = 2 -- 2是加课课程的标识数字
union all
-- 还未结算的加课费
SELECT 
    main.lesson_id,
    main.stu_id,
    main.subject_id,
    main.subject_sub_id,
    main.class_duration,
    main.lesson_type,
    main.schedual_type,
    main.schedual_date,
    main.lsn_adjusted_date,
    main.extra_to_dur_date,
    main.scanqr_date,
    0 as pay_flg 
FROM t_info_lesson main
WHERE main.scanqr_date IS NOT NULL 
  AND main.lesson_type = 2
  AND main.del_flg = 0
  AND NOT EXISTS (
    SELECT 1 
    FROM t_info_lesson lsn
    INNER JOIN t_info_lesson_fee fee ON lsn.lesson_id = fee.lesson_id AND fee.del_flg = 0
    INNER JOIN t_info_lesson_pay pay ON fee.lsn_fee_id = pay.lsn_fee_id
    WHERE lsn.lesson_id = main.lesson_id
  )
;

-- USE prod_KNStudent;
DROP VIEW IF EXISTS `v_info_tmp_lesson_after_43_month_fee_unpaid_yet`;
-- 手机前端页面使用
/*
这个视图的前提业务是：按月交费的学生在某月比如10月份完成了规定年度的43节课，那么，43节课是一年12个月的课程，10份就上满了43节课，
这是提前完成了规定课程数，但是11月和12月的课费还没有交，通过执行存储过程(sp_insert_tmp_lesson_info)来给徐你课程表(t_info_lesson_tmp)插入11月和12月的课程信息，
同时也给课费表t_info_lesson_fee插入11月和12月的课费信息，但是这两个月的课费是未支付状态（own_flg=0），
存储过程的执行准备放在Batch系统里执行。每年的12月1号执行这个Batch任务。
这个视图就是用来统计虚拟课程的课费（即，空月按月支付的课费）这些未支付的按月支付课费信息。
*/
CREATE
    ALGORITHM = UNDEFINED
    DEFINER = `root`@`%`
    SQL SECURITY DEFINER
VIEW v_info_tmp_lesson_after_43_month_fee_unpaid_yet AS
/*
把按月交费的科目做一个统计，月交费场合下的lsn_fee_id lsn_tmp_id是1:n的关系，
此视图是将n个lesson的课时和课费做一个求和统计，
使得lsn_pay_id,lsn_fee_id能清楚地表达出这两个字段的1:1关系
*/
SELECT
    '' as lsn_pay_id,
    fee.lsn_fee_id,
    tmp.stu_id,
    tmp.stu_name,
    tmp.nik_name,
    tmp.subject_id,
    tmp.subject_name,
    tmp.subject_sub_id,
    tmp.subject_sub_name,
    fee.lsn_fee as subject_price,
    1 as pay_style,
    0 AS lsn_count,
    fee.lsn_fee * 4 as lsn_fee,
    NULL as pay_date,
    1 as lesson_type,
    left(tmp.schedual_date,7) as lsn_month,
    fee.own_flg as own_flg
FROM
    v_info_lesson_tmp tmp
INNER JOIN
	t_info_lesson_fee fee
ON tmp.lsn_tmp_id = fee.lesson_id
;

-- ============================================================
-- 坏账通缉犯名单视图
-- 用途：执行加课换正课时，查询该课程是否处于坏账状态
--       若命中此视图，则禁止执行加课换正课
-- ============================================================
DROP VIEW IF EXISTS v_info_bad_debt_lesson;
CREATE VIEW v_info_bad_debt_lesson AS
SELECT
    fee.lsn_fee_id,
    fee.lesson_id,
    lsn.lesson_type,
    fee.bad_debt_flg
FROM t_info_lesson_fee fee
JOIN t_info_lesson     lsn ON fee.lesson_id = lsn.lesson_id
WHERE fee.bad_debt_flg = 1
  AND fee.del_flg      = 0
;
