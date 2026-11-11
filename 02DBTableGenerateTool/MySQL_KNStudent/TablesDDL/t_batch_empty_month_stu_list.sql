-- DROP TABLE IF EXISTS `t_batch_empty_month_stu_list`;
-- 空月课费已处理学生清单（KNDB2060 空月课费自动生成批处理使用）
-- 一个学生的一个科目一年一行；在此表中的学生，批处理不再收集，保证每年只处理一次
CREATE TABLE `t_batch_empty_month_stu_list` (
  `stu_id` VARCHAR(32) NOT NULL COMMENT '学生ID',
  `subject_id` VARCHAR(32) NOT NULL COMMENT '科目ID',
  `lsn_year` VARCHAR(4) NOT NULL COMMENT '年度（yyyy）',
  `months_completed` INT NOT NULL COMMENT '达成月份（累计达到43节的月份）',
  `empty_months` VARCHAR(32) NOT NULL COMMENT '空月（逗号分隔，例：10,11,12；含Web画面已手动生成的月份）',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '登记日期',
  PRIMARY KEY (`stu_id`, `subject_id`, `lsn_year`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='空月课费已处理学生清单';
