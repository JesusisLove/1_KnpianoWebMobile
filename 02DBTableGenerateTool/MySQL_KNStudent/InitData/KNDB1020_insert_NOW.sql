-- ============================================================
-- KNDB1020 配置脚本 - 学生信息同步
-- 该模块开发完后，需要做该模块数据的初期化，请立即执行此文件！
-- ============================================================
-- 数据库: KNStudent (192.168.50.101:*****)
-- 注意: KNDB1020为手动执行Job，无定时调度，batch_enabled设为0
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
    'KNDB1020',
    'kndb1020Job',
    '学生信息同步',
    '',
    '手动执行（按需触发）',
    '同步需要更新的学生基本信息，确保数据一致性',
    0
);

-- 2. 插入批处理邮件配置
INSERT INTO t_batch_mail_config (
    job_id,
    email_from,
    mail_to_devloper,
    email_to_user,
    mail_content_for_user
) VALUES (
    'KNDB1020',
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
WHERE job_id = 'KNDB1020';

SELECT '=== 邮件配置 ===' as check_type;
SELECT
    job_id,
    email_from,
    mail_to_devloper,
    email_to_user
FROM t_batch_mail_config
WHERE job_id = 'KNDB1020';

SELECT '=== 所有作业列表 ===' as check_type;
SELECT job_id, description, batch_enabled FROM t_batch_job_config ORDER BY job_id;
