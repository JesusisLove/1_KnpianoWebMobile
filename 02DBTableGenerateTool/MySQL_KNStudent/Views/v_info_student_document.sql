-- 学生歴史ドキュメント情報
-- USE prod_KNStudent;
 DROP VIEW IF EXISTS `v_info_student_document`;
-- 视图 不要做驼峰命名变更，为了java程序处理的统一性。
CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW `v_info_student_document` AS
    SELECT 
        `doc`.`stu_id` AS `stu_id`,
        `stu`.`stu_name` AS `stu_name`,
        `stu`.`nik_name` AS `nik_name`,
        `doc`.`subject_id` AS `subject_id`,
        `jct`.`subject_name` AS `subject_name`,
        `doc`.`subject_sub_id` AS `subject_sub_id`,
        `sub`.`subject_sub_name` AS `subject_sub_name`,
        `doc`.`adjusted_date` AS `adjusted_date`,
        `doc`.`pay_style` AS `pay_style`,
        `doc`.`minutes_per_lsn` AS `minutes_per_lsn`,
        `doc`.`lesson_fee` AS `lesson_fee`,
        `doc`.`lesson_fee_adjusted` AS `lesson_fee_adjusted`,
        `doc`.`year_lsn_cnt` AS `year_lsn_cnt`,
        `doc`.`del_flg` AS `del_flg`,
        `doc`.`create_date` AS `create_date`,
        `doc`.`update_date` AS `update_date`
    FROM
        (((`t_info_student_document` `doc`
        LEFT JOIN `t_mst_student` `stu` ON ((`doc`.`stu_id` = `stu`.`stu_id`)))
        LEFT JOIN `t_mst_subject` `jct` ON ((`doc`.`subject_id` = `jct`.`subject_id`)))
        LEFT JOIN `v_info_subject_edaban` `sub` ON (((`doc`.`subject_sub_id` = `sub`.`subject_sub_id`)
            AND (`doc`.`subject_id` = `sub`.`subject_id`))))
    ;