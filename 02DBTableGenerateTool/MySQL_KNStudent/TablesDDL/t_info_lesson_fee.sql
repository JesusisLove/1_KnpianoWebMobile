-- DROP TABLE IF EXISTS `t_info_lesson_fee`;
CREATE TABLE `t_info_lesson_fee` (
  `lsn_fee_id` varchar(255) NOT NULL,
  `lesson_id` varchar(255) NOT NULL COMMENT '课程ID（可引用t_info_lesson或t_info_lesson_tmp）',
  `pay_style` int DEFAULT NULL,
  `lsn_fee` float DEFAULT NULL,
  `lsn_month` varchar(7) DEFAULT NULL,
  `own_flg` int DEFAULT '0',
  `bad_debt_flg` int DEFAULT '0' COMMENT '坏账标记: 0=正常, 1=坏账',
  `memo` varchar(500) DEFAULT NULL COMMENT '坏账处理理由',
  `del_flg` int DEFAULT '0',
  `create_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `update_date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`lsn_fee_id`,`lesson_id`),
  KEY `fk_lesson_id` (`lesson_id`)
  -- 外键约束已删除，因为lesson_id需要同时支持正式课程表(t_info_lesson)和临时课程表(t_info_lesson_tmp)
  -- CONSTRAINT `fk_lesson_id` FOREIGN KEY (`lesson_id`) REFERENCES `t_info_lesson` (`lesson_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='课程费用表（支持正式课程和临时课程）';