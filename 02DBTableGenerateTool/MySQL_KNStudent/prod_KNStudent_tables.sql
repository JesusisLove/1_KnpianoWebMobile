-- /////TABFLE///////////////////////////////////////////////////////////////////////////////
-- 注意：视图定义的执行顺序请严格按照下面顺序执行（视图间有先后的依赖关系）
-- USE prod_KNStudent;
-- -- Tables
-- DROP TABLE IF EXISTS `sequence`;
-- DROP TABLE IF EXISTS `t_sp_execution_log`;
-- DROP TABLE IF EXISTS `t_info_lsn_fee_advc_pay`;
-- DROP TABLE IF EXISTS `t_info_lesson_pay`;
-- DROP TABLE IF EXISTS `t_info_lesson_fee`;
-- DROP TABLE IF EXISTS `t_info_lesson`;
-- DROP TABLE IF EXISTS `t_info_student_document`;
-- DROP TABLE IF EXISTS `t_info_fixedlesson`;
-- DROP TABLE IF EXISTS `t_info_student_bank`;
-- DROP TABLE IF EXISTS `t_fixedlesson_status`;
-- DROP TABLE IF EXISTS `t_info_subject_edaban`;
-- DROP TABLE IF EXISTS `t_mst_bank`;
-- DROP TABLE IF EXISTS `t_mst_subject`;
-- DROP TABLE IF EXISTS `t_mst_student`;
-- DROP TABLE IF EXISTS `t_info_lesson_extra_to_sche`;
-- DROP TABLE IF EXISTS `t_info_lesson_pieces_extra_to_sche`;

-- -- Views
-- DROP VIEW IF EXISTS `v_info_subject_edaban`;
-- DROP VIEW IF EXISTS `v_info_student_bank`;
-- DROP VIEW IF EXISTS `v_info_fixedlesson`;
-- DROP VIEW IF EXISTS `v_info_student_document`;
-- DROP VIEW IF EXISTS `v_latest_subject_info_from_student_document`;
-- DROP VIEW IF EXISTS `v_earliest_fixed_week_info`;
-- DROP VIEW IF EXISTS `v_info_lesson`;
-- DROP VIEW IF EXISTS `v_info_lesson_include_extra2sche`;
-- DROP VIEW IF EXISTS `v_info_lsn_statistics_by_stuid`;
-- -- DROP VIEW IF EXISTS `v_info_lesson_fee_connect_lsn`;
-- DROP VIEW IF EXISTS `v_info_lesson_sum_fee_unpaid_yet`;
-- DROP VIEW IF EXISTS `v_info_lesson_sum_fee_pay_over`;
-- DROP VIEW IF EXISTS `v_info_lesson_pay_over`;
-- DROP VIEW IF EXISTS `v_sum_unpaid_lsnfee_by_stu_and_month`;
-- DROP VIEW IF EXISTS `v_sum_haspaid_lsnfee_by_stu_and_month`;
-- DROP VIEW IF EXISTS `v_sum_lsn_fee_for_fee_connect_lsn_by_stu_month`;
-- DROP VIEW IF EXISTS `v_total_lsnfee_with_paid_unpaid_every_month`;
-- DROP VIEW IF EXISTS `v_total_lsnfee_with_paid_unpaid_every_month_every_student`;
-- DROP VIEW IF EXISTS `v_info_lesson_fee_include_extra2sche`;
-- DROP VIEW IF EXISTS `v_info_all_extra_lsns`;
-- DROP VIEW IF EXISTS `v_info_lesson_tmp`;
-- DROP VIEW IF EXISTS `v_info_tmp_lesson_after_43_month_fee_unpaid_yet`;

-- -- Functions
-- DROP FUNCTION IF EXISTS `currval`;
-- DROP FUNCTION IF EXISTS `nextval`;
-- DROP FUNCTION IF EXISTS `setval`;
-- DROP FUNCTION IF EXISTS `generate_weekly_date_series`;

-- -- Triggers
-- DROP TRIGGER IF EXISTS `before_update_t_mst_student`;
-- DROP TRIGGER IF EXISTS `before_update_t_mst_subject`;
-- DROP TRIGGER IF EXISTS `before_update_t_info_subject_edaban`;
-- DROP TRIGGER IF EXISTS `before_update_t_mst_bank`;
-- DROP TRIGGER IF EXISTS `before_update_t_info_student_bank`;
-- DROP TRIGGER IF EXISTS `before_update_t_info_student_document`;
-- DROP TRIGGER IF EXISTS `before_update_t_info_lesson`;
-- DROP TRIGGER IF EXISTS `before_update_t_info_lesson_fee`;
-- DROP TRIGGER IF EXISTS `before_update_t_info_lesson_pay`;

-- -- Procedures
-- DROP PROCEDURE IF EXISTS `sp_weekly_batch_lsn_schedule_process`;
-- DROP PROCEDURE IF EXISTS `sp_sum_unpaid_lsnfee_by_stu_and_month`;
-- DROP PROCEDURE IF EXISTS `sp_get_advance_pay_subjects_and_lsnschedual_info`;
-- DROP PROCEDURE IF EXISTS `sp_execute_weekly_batch_lsn_schedule`;
-- DROP PROCEDURE IF EXISTS `sp_execute_advc_lsn_fee_pay`;
-- DROP PROCEDURE IF EXISTS `sp_insert_tmp_lesson_info`;
-- DROP PROCEDURE IF EXISTS `sp_cancel_tmp_lesson_info`;

-- 00採番テーブル定義
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `sequence`;
CREATE TABLE `sequence` (
  `seqid` varchar(255) NOT NULL,
  `name` varchar(50) NOT NULL,
  `current_value` int DEFAULT NULL,
  `increment` int DEFAULT '1',
  PRIMARY KEY (`seqid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- USE prod_KNStudent;
INSERT INTO sequence VALUES ('kn-stu-','学生番号',   0, 1);
INSERT INTO sequence VALUES ('kn-sub-','学科番号',   0, 1);
INSERT INTO sequence VALUES ('kn-sub-eda-','学科枝番',   0, 1);
INSERT INTO sequence VALUES ('kn-bnk-','銀行番号',   0, 1);
INSERT INTO sequence VALUES ('kn-lsn-','授業番号',   0, 1);
INSERT INTO sequence VALUES ('kn-lsn-tmp-','虚课番号',   0, 1);
INSERT INTO sequence VALUES ('kn-fee-','課費番号',   0, 1);
INSERT INTO sequence VALUES ('kn-pay-','精算番号',   0, 1);

-- 01学生基本情報マスタ
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_mst_student`;
CREATE TABLE `t_mst_student` (
  `stu_id` varchar(255) NOT NULL,
  `stu_name` varchar(56) NOT NULL,
  `nik_name` varchar(31) NOT NULL,
  `gender` int DEFAULT NULL,
  `birthday` varchar(10) DEFAULT NULL,
  `address` varchar(64) DEFAULT NULL,
  `post_code` varchar(12) DEFAULT NULL,
  `tel1` varchar(20) DEFAULT NULL,
  `tel2` varchar(20) DEFAULT NULL,
  `tel3` varchar(20) DEFAULT NULL,
  `tel4` varchar(20) DEFAULT NULL,
  `introducer` varchar(20) DEFAULT NULL,
  `del_flg` int DEFAULT '0',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`stu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 02学科基本情報マスタ
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_mst_subject`;
CREATE TABLE `t_mst_subject` (
  `subject_id` varchar(255) NOT NULL,
  `subject_name` varchar(20) NOT NULL,
  `del_flg` int DEFAULT '0',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL,
  PRIMARY KEY (`subject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 科目子表
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_info_subject_edaban`;
CREATE TABLE `t_info_subject_edaban` (
  `subject_id` varchar(255) NOT NULL,
  `subject_sub_id` varchar(255) NOT NULL,
  `subject_sub_name` varchar(20) DEFAULT NULL,
  `subject_price` float DEFAULT NULL,
  `del_flg` int DEFAULT '0',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`subject_id`,`subject_sub_id`),
  CONSTRAINT subject_edaban FOREIGN KEY (subject_id) REFERENCES t_mst_subject(subject_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 03銀行基本情報マスタ
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_mst_bank`;
CREATE TABLE `t_mst_bank` (
  `bank_id` varchar(255) NOT NULL,
  `bank_name` varchar(20) NOT NULL,
  `del_flg` int DEFAULT '0',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`bank_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_info_student_bank`;
CREATE TABLE `t_info_student_bank` (
  `bank_id` varchar(255) NOT NULL,
  `stu_id` varchar(255) NOT NULL,
  `del_flg` int DEFAULT '0',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`bank_id`,`stu_id`),
  KEY `fk_bank_stu_id` (`stu_id`),
  CONSTRAINT fk_bank_stu_id FOREIGN KEY (stu_id) REFERENCES t_mst_student(stu_id),
  CONSTRAINT fk_bank_bank_id FOREIGN KEY (bank_id) REFERENCES t_mst_bank(bank_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 10学生固定授業計画管理
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_info_fixedlesson`;
CREATE TABLE `t_info_fixedlesson` (
  `stu_id` varchar(255) NOT NULL,
  `subject_id` varchar(255) NOT NULL,
  `fixed_week` varchar(255) NOT NULL,
  `fixed_hour` int DEFAULT NULL,
  `fixed_minute` int DEFAULT NULL,
  PRIMARY KEY (`stu_id`,`subject_id`,`fixed_week`),
  KEY `fk_fixedlesson_subject_id_new` (`subject_id`),
  CONSTRAINT `fk_fixedlesson_stu_id` FOREIGN KEY (`stu_id`) REFERENCES `t_mst_student` (`stu_id`),
  CONSTRAINT `fk_fixedlesson_subject_id_new` FOREIGN KEY (`subject_id`) REFERENCES `t_mst_subject` (`subject_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 11学生歴史ドキュメント情報
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_info_student_document`;
CREATE TABLE `t_info_student_document` (
  `stu_id` varchar(32) NOT NULL,
  `subject_id` varchar(32) NOT NULL,
  `subject_sub_id` varchar(32) NOT NULL,
  `adjusted_date` date NOT NULL,
  `pay_style` int DEFAULT NULL,
  `minutes_per_lsn` int DEFAULT NULL,
  `lesson_fee` float DEFAULT NULL,
  `lesson_fee_adjusted` float DEFAULT NULL,
  `year_lsn_cnt` int DEFAULT '0',
  `exam_date` date DEFAULT NULL,
  `exam_score` float DEFAULT NULL,
  `del_flg` int DEFAULT '0',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`stu_id`,`subject_id`,`subject_sub_id`,`adjusted_date`),
  KEY `fk_subject_id` (`subject_id`),
  CONSTRAINT `fk_student_id` FOREIGN KEY (`stu_id`) REFERENCES `t_mst_student` (`stu_id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_subject_id` FOREIGN KEY (`subject_id`) REFERENCES `t_mst_subject` (`subject_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 说明：加上foreign key制约，为了保证主从表数据的完整性，当删除主表的学生或科目的时候，
-- 用foreign key来保证因从表有记录而不能随便删除主表与从表有关联关系的数据

-- 12学生授業情報管理
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_info_lesson`;
CREATE TABLE `t_info_lesson` (
  `lesson_id` varchar(32) NOT NULL,
  `stu_id` varchar(32) DEFAULT NULL,
  `subject_id` varchar(32) DEFAULT NULL,
  `subject_sub_id` varchar(32) DEFAULT NULL,
  `class_duration` int DEFAULT NULL,
  `extra_to_dur_date` datetime(6) DEFAULT NULL,
  `lesson_type` int DEFAULT NULL,
  `schedual_type` int DEFAULT '0',
  `schedual_date` datetime(6) DEFAULT NULL,
  `lsn_adjusted_date` datetime(6) DEFAULT NULL,
  `scanqr_date` datetime(6) DEFAULT NULL,
  `memo` varchar(255) DEFAULT NULL,
  `del_flg` int DEFAULT '0',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`lesson_id`),
  KEY `fk_lesson_stu_id` (`stu_id`),
  KEY `fk_lesson_subject_id` (`subject_id`),
  CONSTRAINT `fk_lesson_stu_id` FOREIGN KEY (`stu_id`) REFERENCES `t_mst_student` (`stu_id`),
  CONSTRAINT `fk_lesson_subject_id` FOREIGN KEY (`subject_id`) REFERENCES `t_mst_subject` (`subject_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 21授業料金情報管理
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_info_lesson_fee`;
CREATE TABLE `t_info_lesson_fee` (
  `lsn_fee_id` varchar(255) NOT NULL,
  `lesson_id` varchar(255) NOT NULL COMMENT '课程ID（可引用t_info_lesson或t_info_lesson_tmp）',
  `pay_style` int DEFAULT NULL,
  `lsn_fee` float DEFAULT NULL,
  `lsn_month` varchar(7) DEFAULT NULL,
  `own_flg` int DEFAULT '0',
  `bad_debt_flg` int DEFAULT '0' COMMENT '坏账标记: 0=正常, 1=坏账',
  `del_flg` int DEFAULT '0',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`lsn_fee_id`,`lesson_id`),
  KEY `fk_lesson_id` (`lesson_id`)
  -- 外键约束已删除，因为lesson_id需要同时支持正式课程表(t_info_lesson)和临时课程表(t_info_lesson_tmp)
  -- CONSTRAINT `fk_lesson_id` FOREIGN KEY (`lesson_id`) REFERENCES `t_info_lesson` (`lesson_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='课程费用表（支持正式课程和临时课程）';

-- 22授業課費精算管理
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_info_lesson_pay`;
CREATE TABLE `t_info_lesson_pay` (
  `lsn_pay_id` varchar(255) NOT NULL,
  `lsn_fee_id` varchar(255) NOT NULL,
  `lsn_pay` float DEFAULT NULL,
  `bank_id` varchar(32) DEFAULT NULL,
  `pay_month` varchar(7) DEFAULT NULL,
  `pay_date` datetime DEFAULT NULL,
  `del_flg` int DEFAULT '0',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`lsn_pay_id`,`lsn_fee_id`),
  KEY `fk_lsn_fee_id` (`lsn_fee_id`),
  KEY `fk_bank_id` (`bank_id`),
  CONSTRAINT `fk_bank_id` FOREIGN KEY (`bank_id`) REFERENCES `t_mst_bank` (`bank_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 23年度星期生成表
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_fixedlesson_status`;
CREATE TABLE `t_fixedlesson_status` (
  `week_number` int NOT NULL,
  `start_week_date` varchar(10) NOT NULL,
  `end_week_date` varchar(10) NOT NULL,
  `fixed_status` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 24课费预支付管理表
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_info_lsn_fee_advc_pay`;
CREATE TABLE `t_info_lsn_fee_advc_pay` (
  `lesson_id` varchar(32) NOT NULL,
  `lsn_fee_id` varchar(32) NOT NULL,
  `lsn_pay_id` varchar(32) NOT NULL,
  `advance_pay_date` datetime DEFAULT NULL,
  `advc_flg` int DEFAULT '0',
  `del_flg` int DEFAULT '0',
  `create_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_date` datetime DEFAULT NULL,
  PRIMARY KEY (`lsn_pay_id`,`lsn_fee_id`,`lesson_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- 建立调用课费预支付存储过程日志表
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_sp_execution_log`;
CREATE TABLE t_sp_execution_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    procedure_name VARCHAR(100),
    procedure_alias_name VARCHAR(100),
    step_name VARCHAR(100),
    result VARCHAR(255),
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 建立加课换正课中间表
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_info_lesson_extra_to_sche`;
/* 添加索引的原由：
对加课换正课的新的课费id做已经支付的更新处理，
由于这个表没有主键，所以程序在执行的时候启动safe update模式（安全更新模式）
没有主键或没有索引，不让更新，索引添加了idx_fee_id_date
*/
CREATE TABLE `t_info_lesson_extra_to_sche` (
  `lesson_id` varchar(45) NOT NULL,
  `subject_id` varchar(45) NOT NULL,
  `old_lsn_fee_id` varchar(255) NOT NULL,
  `new_lsn_fee_id` varchar(255) NOT NULL,
  `old_subject_sub_id` varchar(255) NOT NULL,
  `new_subject_sub_id` varchar(255) NOT NULL,
  `old_lsn_fee` decimal(4,0) DEFAULT NULL,
  `new_lsn_fee` decimal(4,0) DEFAULT NULL,
  `new_scanqr_date` datetime DEFAULT NULL,
  `is_good_change` int DEFAULT NULL,
  `memo_reason` varchar(255) NOT NULL,
  `new_own_flg` int DEFAULT '0',
  INDEX idx_fee_id_date (new_lsn_fee_id, new_scanqr_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 建立零碎的加课换正课中间表
-- USE prod_KNStudent;
-- DROP TABLE IF EXISTS `t_info_lesson_pieces_extra_to_sche`;
/* 添加索引的原由：
对加课换正课的新的课费id做已经支付的更新处理，
由于这个表没有主键，所以程序在执行的时候启动safe update模式（安全更新模式）
没有主键或没有索引，不让更新，索引添加了idx_fee_id_date
*/
CREATE TABLE t_info_lesson_pieces_extra_to_sche (
  lesson_id varchar(32) NOT NULL,
  old_lesson_id varchar(32) NOT NULL,
  own_flg INT DEFAULT 0,
PRIMARY KEY (lesson_id,old_lesson_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- DROP TABLE IF EXISTS `t_info_lesson_tmp`;
CREATE TABLE `t_info_lesson_tmp` (
  `lsn_tmp_id` VARCHAR(32) NOT NULL,
  `stu_id` VARCHAR(32) NULL,
  `subject_id` VARCHAR(32) NULL,
  `subject_sub_id` VARCHAR(32) NULL,
  `lsn_fee` FLOAT DEFAULT NULL,
  `schedual_date` DATETIME NULL,
  `scanqr_date` DATETIME NULL,
  `del_flg` int DEFAULT '0',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`lsn_tmp_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- KNBatch系统用的表
-- USE prod_KNStudent;
-- Job启动配置表
CREATE TABLE t_batch_job_config (
    job_id VARCHAR(20) NOT NULL COMMENT '作业ID',
    bean_name VARCHAR(100) NOT NULL COMMENT 'Bean名称',
    description VARCHAR(255) NOT NULL COMMENT '作业描述', 
    cron_expression VARCHAR(100) NOT NULL COMMENT 'Cron表达式',
    cron_description VARCHAR(255) NOT NULL COMMENT 'Cron描述',
    target_description VARCHAR(255) NOT NULL COMMENT '目标描述',
    batch_enabled BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否启用批处理',
    PRIMARY KEY (job_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='批处理作业配置表';

-- 邮件配置表
CREATE TABLE t_batch_mail_config (
    job_id VARCHAR(20) NOT NULL COMMENT '作业ID',
    email_from VARCHAR(100) NOT NULL COMMENT '发送方邮箱',
    mail_to_devloper VARCHAR(500) COMMENT '开发者邮箱(多个邮箱用逗号分隔)',
    email_to_user VARCHAR(500) COMMENT '用户邮箱(多个邮箱用逗号分隔)',
    mail_content_for_user TEXT COMMENT '给用户的邮件内容',
    PRIMARY KEY (job_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='批处理邮件配置表';