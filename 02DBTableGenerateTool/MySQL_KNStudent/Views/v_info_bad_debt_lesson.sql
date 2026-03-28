-- ============================================================
-- 坏账通缉犯名单视图
-- 用途：执行加课换正课时，查询该课程是否处于坏账状态
--       若命中此视图，则禁止执行加课换正课（HTTP 409）
-- ============================================================
-- DROP VIEW IF EXISTS v_info_bad_debt_lesson;
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
