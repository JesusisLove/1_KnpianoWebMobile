-- ============================================================
-- KNDB4000 配置脚本 - 年度周次表生成
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
    'KNDB4000',
    'kndb4000Job',
    '年度周次表生成',
    '0 0 0 1 1 ?',
    '每年1月1日00:00执行',
    '为当前年度生成完整的周次表（52-53周），用于KNDB4010自动排课功能的状态管理',
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
    'KNDB4000',
    'liuym7599@gmail.com',
    'liu_ym@hotmail.com,jesuskazuyoshi@gmail.com,lym20230403@gmail.com',
    '',
    'YYYY年度の週次スケジュールテーブルが正常に生成されました。'
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
WHERE job_id = 'KNDB4000';

SELECT '=== 邮件配置 ===' as check_type;
SELECT
    job_id,
    email_from,
    mail_to_devloper,
    email_to_user
FROM t_batch_mail_config
WHERE job_id = 'KNDB4000';

SELECT '=== 所有作业列表 ===' as check_type;
SELECT job_id, description, batch_enabled FROM t_batch_job_config ORDER BY job_id;
