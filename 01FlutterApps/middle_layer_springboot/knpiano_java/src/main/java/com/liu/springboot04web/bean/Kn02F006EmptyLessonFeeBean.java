package com.liu.springboot04web.bean;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.List;

/**
 * 空课学费按月支付Bean
 * 用于显示达到43节课的学生列表
 */
public class Kn02F006EmptyLessonFeeBean {
    protected String stuId;
    protected String stuName;
    protected String subjectId;
    protected String subjectName;
    protected Double cumulativeCount;    // 累计课程数
    protected Integer monthsCompleted;    // 完成月份数
    protected String year;                // 年度（用于生成临时课程）
    protected String generatedMonths;     // 已生成空月课费的月份（逗号分隔，例：11,12）
    protected Integer targetMonth;        // 本次要生成空月课费的月份

    // 月度明细相关字段
    protected String lsnTmpId;            // 临时课程ID
    protected String lsnFeeId;            // 课费ID
    @JsonFormat(pattern = "yyyy/MM/dd HH:mm:ss", timezone = "GMT+8")
    protected Date schedualDate;          // 排课日期
    protected Double lsnFee;              // 课费金额
    protected String ownFlg;              // 结算标志（1=已结算，0=未结算）

    public String getStuId() {
        return stuId;
    }

    public void setStuId(String stuId) {
        this.stuId = stuId;
    }

    public String getStuName() {
        return stuName;
    }

    public void setStuName(String stuName) {
        this.stuName = stuName;
    }

    public String getSubjectId() {
        return subjectId;
    }

    public void setSubjectId(String subjectId) {
        this.subjectId = subjectId;
    }

    public String getSubjectName() {
        return subjectName;
    }

    public void setSubjectName(String subjectName) {
        this.subjectName = subjectName;
    }

    public Double getCumulativeCount() {
        return cumulativeCount;
    }

    public void setCumulativeCount(Double cumulativeCount) {
        this.cumulativeCount = cumulativeCount;
    }

    public Integer getMonthsCompleted() {
        return monthsCompleted;
    }

    public void setMonthsCompleted(Integer monthsCompleted) {
        this.monthsCompleted = monthsCompleted;
    }

    public String getYear() {
        return year;
    }

    public void setYear(String year) {
        this.year = year;
    }

    public String getGeneratedMonths() {
        return generatedMonths;
    }

    public void setGeneratedMonths(String generatedMonths) {
        this.generatedMonths = generatedMonths;
    }

    public Integer getTargetMonth() {
        return targetMonth;
    }

    public void setTargetMonth(Integer targetMonth) {
        this.targetMonth = targetMonth;
    }

    // 操作列每个小行对应的月份。12月达成时没有空月，保留一行显示“对象外”
    // 不命名为 getXxx，避免月度明细转 JSON 时被调用（明细数据没有 monthsCompleted）
    public List<Integer> rowMonths() {
        List<Integer> months = new ArrayList<>();
        for (int month = monthsCompleted + 1; month <= 12; month++) {
            months.add(month);
        }
        return months.isEmpty() ? Collections.singletonList(12) : months;
    }

    public boolean isMonthGenerated(int month) {
        return generatedMonths != null
                && Arrays.asList(generatedMonths.split(",")).contains(String.valueOf(month));
    }

    public String getLsnTmpId() {
        return lsnTmpId;
    }

    public void setLsnTmpId(String lsnTmpId) {
        this.lsnTmpId = lsnTmpId;
    }

    public String getLsnFeeId() {
        return lsnFeeId;
    }

    public void setLsnFeeId(String lsnFeeId) {
        this.lsnFeeId = lsnFeeId;
    }

    public Date getSchedualDate() {
        return schedualDate;
    }

    public void setSchedualDate(Date schedualDate) {
        this.schedualDate = schedualDate;
    }

    public Double getLsnFee() {
        return lsnFee;
    }

    public void setLsnFee(Double lsnFee) {
        this.lsnFee = lsnFee;
    }

    public String getOwnFlg() {
        return ownFlg;
    }

    public void setOwnFlg(String ownFlg) {
        this.ownFlg = ownFlg;
    }
}
