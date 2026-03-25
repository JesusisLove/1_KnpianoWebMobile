/**
* 前提条件，加课换正课执行完了，换正课的lesson_id会将t_info_lesson_fee表中的该记录的del_flg更新为1(表示换正课之前计算的这个课费记录不要了)
*同时，会在t_info_lesson_extra_to_sche中,记录原来的lsn_fee_id和换正课后所在月份的新的lsn_fee_id
*如果加课换正课赶上了课程升级（比如，去年12月份学的5级的加课换成今年1月份正课，如果1月份开始已经进入6级的课程，
*那么，换到1月正课的那个加课将被视为6级课程，课程价格也将按照6级的价格记录在会在t_info_lesson_extra_to_sche中。
* 该视图就是将原来的课费信息和换正课后的课费信息进行了重新整合。
*/
-- DROP VIEW IF EXISTS v_info_lesson_fee_and_extraToScheDataCorrect;
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW v_info_lesson_fee_and_extraToScheDataCorrect AS 
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
        bad_debt_flg,        -- 坏账标记
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
        fee.bad_debt_flg,    -- 坏账标记
        fee.create_date,
        fee.update_date
    FROM
        t_info_lesson_fee fee
    INNER JOIN
        t_info_lesson_extra_to_sche ext
    ON
        fee.lesson_id = ext.lesson_id
        AND fee.del_flg = 1;