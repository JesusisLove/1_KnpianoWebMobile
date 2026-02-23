-- ============================================================
-- KNDB2020 配置脚本 - 使用实际邮箱配置
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
    'KNDB2020',
    'kndb2020Job',
    '年度月收入报告数据监视',
    '0 30 0 * * ?',
    '每天凌晨0:30执行',
    '验证年度月收入报告数据准确性，确保应收=已支付+未支付，检测费用表和支付表的数据一致性',
    1
);

-- 2. 插入批处理邮件配置（使用环境变量中的邮箱）
INSERT INTO t_batch_mail_config (
    job_id,
    email_from,
    mail_to_devloper,
    email_to_user,
    mail_content_for_user
) VALUES (
    'KNDB2020',
    'liuym7599@gmail.com',
    'liu_ym@hotmail.com,jesuskazuyoshi@gmail.com,lym20230403@gmail.com',
    '',
    ''
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
WHERE job_id = 'KNDB2020';

SELECT '=== 邮件配置 ===' as check_type;
SELECT
    job_id,
    email_from,
    mail_to_devloper,
    email_to_user
FROM t_batch_mail_config
WHERE job_id = 'KNDB2020';

SELECT '=== 所有作业列表 ===' as check_type;
SELECT job_id, description, batch_enabled FROM t_batch_job_config ORDER BY job_id;
