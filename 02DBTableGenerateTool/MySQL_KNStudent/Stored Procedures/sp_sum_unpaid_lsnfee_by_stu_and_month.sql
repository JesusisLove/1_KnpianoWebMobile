DELIMITER //

DROP PROCEDURE IF EXISTS sp_sum_unpaid_lsnfee_by_stu_and_month //

CREATE DEFINER=`root`@`%` PROCEDURE `sp_sum_unpaid_lsnfee_by_stu_and_month`(IN currentYear VARCHAR(4))
BEGIN
    SET @sql = CONCAT('
        SELECT
            stu_id,
            stu_name,
            SUM(CASE
                    WHEN lesson_type = 1 THEN subject_price * 4
                    ELSE lsn_fee
                END) AS lsn_fee,
            lsn_month
        FROM v_info_lesson_sum_fee_unpaid_yet
        WHERE SUBSTRING(lsn_month, 1, 4) = ', currentYear, '
        GROUP BY stu_id, stu_name, lsn_month
        ORDER BY lsn_month, CAST(SUBSTRING_INDEX(stu_id, ''-'', -1) AS UNSIGNED);
    ');

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //

DELIMITER ;
