-- ============================================================
-- KNDB4030 配置脚本 - 零碎课补整节课邮件提醒
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
    'KNDB4030',
    'kndb4030Job',
    '零碎课补整节课邮件提醒',
    '0 0 8 * * ?',
    '每天8:00执行',
    '检测碎片加课（lesson_type=2）是否可凑成整课并邮件提醒钢琴老师',
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
    'KNDB4030',
    'liuym7599@gmail.com',
    'liu_ym@hotmail.com,jesuskazuyoshi@gmail.com,lym20230403@gmail.com',
    '',
    '【零碎課合併提醒】BASEDATE\n\n以下の生徒の零碎課が整課に合併可能です。詳細をご確認ください。'
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
WHERE job_id = 'KNDB4030';

SELECT '=== 邮件配置 ===' as check_type;
SELECT
    job_id,
    email_from,
    mail_to_devloper,
    email_to_user
FROM t_batch_mail_config
WHERE job_id = 'KNDB4030';

SELECT '=== 所有作业列表 ===' as check_type;
SELECT job_id, description, batch_enabled FROM t_batch_job_config ORDER BY job_id;
