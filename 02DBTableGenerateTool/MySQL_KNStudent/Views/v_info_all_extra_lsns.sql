-- USE prod_KNStudent;
-- DROP VIEW IF EXISTS v_info_all_extra_lsns;
-- 前提条件，加课都已经签到完了，找出那些已经结算和还未结算的加课信息
-- 零碎加课拼凑成整课，并且已经把整课换成正课的零碎课除外（即，零碎课的del_flg=1的除外了 2025-06-07追加）
-- 已经结算的加课费
CREATE
    ALGORITHM = UNDEFINED
    DEFINER = `root`@`%`
    SQL SECURITY DEFINER
VIEW v_info_all_extra_lsns AS
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
    1 as pay_flg,
    COALESCE(fee.bad_debt_flg, 0) AS bad_debt_flg
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
-- 还未结算的加课费（包含坏账课程）
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
    0 as pay_flg,
    COALESCE(fee2.bad_debt_flg, 0) AS bad_debt_flg
FROM t_info_lesson main
LEFT JOIN t_info_lesson_fee fee2 ON main.lesson_id = fee2.lesson_id AND fee2.del_flg = 0
WHERE main.scanqr_date IS NOT NULL
  AND main.lesson_type = 2
  AND main.del_flg = 0
  AND NOT EXISTS (
    SELECT 1
    FROM t_info_lesson lsn
    INNER JOIN t_info_lesson_fee fee ON lsn.lesson_id = fee.lesson_id AND fee.del_flg = 0
    INNER JOIN t_info_lesson_pay pay ON fee.lsn_fee_id = pay.lsn_fee_id
    WHERE lsn.lesson_id = main.lesson_id
  );
