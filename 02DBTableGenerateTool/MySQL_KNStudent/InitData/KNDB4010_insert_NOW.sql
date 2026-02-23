-- ============================================================
-- KNDB4010 配置脚本 - 次周自动排课
-- 该模块开发完后，需要做该模块数据的初期化，请立即执行此文件！
-- ============================================================
-- 数据库: KNStudent (192.168.50.101:*****)
-- ============================================================

-- 1. 插入批处理作业配置
INSERT INTO t_batch_job_config (
    job_id,
    bean_name,
    description,
    cron_expression,
    cron_description,
    target_description,
    batch_enabled
) VALUES (
    'KNDB4010',
    'kndb4010Job',
    '次周自动排课',
    '0 0 20 ? * SUN',
    '每周日20:00执行',
    '根据固定排课模板自动为学生生成下一周的课程记录，替代老师手动排课操作',
    1
);

-- 2. 插入批处理邮件配置
INSERT INTO t_batch_mail_config (
    job_id,
    email_from,
    mail_to_devloper,
    email_to_user,
    mail_content_for_user
) VALUES (
    'KNDB4010',
    'liuym7599@gmail.com',
    'liu_ym@hotmail.com,jesuskazuyoshi@gmail.com,lym20230403@gmail.com',
    '',
    'FROMDATE～TODATEの週間レッスンスケジュールが自動生成されました。内容をご確認ください。'
);

-- 3. 验证插入结果
SELECT '=== 作业配置 ===' as check_type;
SELECT
    job_id,
    bean_name,
    description,
    cron_expression,
    batch_enabled
FROM t_batch_job_config
WHERE job_id = 'KNDB4010';

SELECT '=== 邮件配置 ===' as check_type;
SELECT
    job_id,
    email_from,
    mail_to_devloper,
    email_to_user
FROM t_batch_mail_config
WHERE job_id = 'KNDB4010';

SELECT '=== 所有作业列表 ===' as check_type;
SELECT job_id, description, batch_enabled FROM t_batch_job_config ORDER BY job_id;
