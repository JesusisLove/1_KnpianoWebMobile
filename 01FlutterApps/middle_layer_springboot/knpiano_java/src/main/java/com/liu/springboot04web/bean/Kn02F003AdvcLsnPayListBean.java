package com.liu.springboot04web.bean;

import java.util.Date;

import org.springframework.format.annotation.DateTimeFormat;

import com.fasterxml.jackson.annotation.JsonFormat;

public class Kn02F003AdvcLsnPayListBean {
protected String    lessonId;
    protected String    lsnFeeId;
    protected String    lsnPayId;
    protected String    subjectId;
    protected String    subjectSubId;
    protected String    subjectName;
    protected String    subjectSubName;
    protected String    stuId;
    protected String    stuName;
    protected String    nikName;
    protected Integer   classDuration;
    protected Integer   lessonType;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm")// 后台维护页面的请求响应处理
    protected Date      schedualDate;
    protected Integer   payStyle;

    // 为了按月交费的计划课的精算业务，需要《学生档案》表里对象科目的最新价格
    protected float     subjectPrice;
    protected Integer   minutesPerLsn;
    protected float     lsnPay;
    protected String    bankId;
    protected String    bankName;
    protected Integer   advcFlg;

    /* 监视数据正常异常状态 ：data_status
        在课程费用支付信息查询结果中，增加数据状态判断字段（data_status），用于标识每条记录的数据状态（数据状态正常/数据状态异常）。
        判断规则

        当 advc_flg = 1 时：直接标记为"数据状态正常"
        当 advc_flg = 0 时：需要进一步验证
        检查是否存在相同学生ID（stu_id）、相同科目ID（subject_id）、相同月份（schedual_date前7位）且扫码日期（scanqr_date）不为空的记录
        如果存在：表示预支付时的lesson_id没有签到，相应的该月份其他的lesson_id反而签到了，表明用预支付做的这节排课，
        学生那天没有来上课，在业务规则上，该课是被统计为已经上课完了的课了，但实际上该课并没有上。这是在“撒谎”，所以要标记为"数据状态异常"
        如果不存在：表示这月分学生是真的没有来上课（整月都没来上课），因为所有排好的课程都是处于未签到的状态，是数据状态正常，所以，标记为"数据状态正常"

        数据状态的解释：
            0:表示该数据的逻辑状态是数据状态正常的状态 
            1:表示该数据的逻辑状态是异常数据的状态，需要确认，要做预支付再调整。
                再调整手段：把该月份已经签到的任何lesson_id去替换掉《课费预支付表（t_info_lsn_fee_advc_pay）》里的lesson_id即可。 
            -1:还未定的状态（应该不会出现）
    */
    protected Integer   dataStatus;

    public String getSubjectId() {
        return subjectId;
    }
    public void setSubjectId(String subjectId) {
        this.subjectId = subjectId;
    }
    public String getSubjectSubId() {
        return subjectSubId;
    }
    public void setSubjectSubId(String subjectSubId) {
        this.subjectSubId = subjectSubId;
    }
    public String getSubjectName() {
        return subjectName;
    }
    public void setSubjectName(String subjectName) {
        this.subjectName = subjectName;
    }
    public String getSubjectSubName() {
        return subjectSubName;
    }
    public void setSubjectSubName(String subjectSubName) {
        this.subjectSubName = subjectSubName;
    }
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
    public String getNikName() {
        return nikName;
    }
    public void setNikName(String nikName) {
        this.nikName = nikName;
    }
    public Integer getClassDuration() {
        return classDuration;
    }
    public void setClassDuration(Integer classDuration) {
        this.classDuration = classDuration;
    }
    public Integer getLessonType() {
        return lessonType;
    }
    public void setLessonType(Integer lessonType) {
        this.lessonType = lessonType;
    }
    public Date getSchedualDate() {
        return schedualDate;
    }
    public void setSchedualDate(Date schedualDate) {
        this.schedualDate = schedualDate;
    }

    public Integer getPayStyle() {
        return payStyle;
    }
    public void setPayStyle(Integer payStyle) {
        this.payStyle = payStyle;
    }
    public float getSubjectPrice() {
        return subjectPrice;
    }
    public void setSubjectPrice(float subjectPrice) {
        this.subjectPrice = subjectPrice;
    }
    public Integer getMinutesPerLsn() {
        return minutesPerLsn;
    }
    public void setMinutesPerLsn(Integer minutesPerLsn) {
        this.minutesPerLsn = minutesPerLsn;
    }
    public String getBankId() {
        return bankId;
    }
    public void setBankId(String bankId) {
        this.bankId = bankId;
    }
    public String getLessonId() {
        return lessonId;
    }
    public void setLessonId(String lessonId) {
        this.lessonId = lessonId;
    }
    public String getLsnFeeId() {
        return lsnFeeId;
    }
    public void setLsnFeeId(String lsnFeeId) {
        this.lsnFeeId = lsnFeeId;
    }
    public String getLsnPayId() {
        return lsnPayId;
    }
    public void setLsnPayId(String lsnPayId) {
        this.lsnPayId = lsnPayId;
    }
    public String getBankName() {
        return bankName;
    }
    public void setBankName(String bankName) {
        this.bankName = bankName;
    }
    public float getLsnPay() {
        return lsnPay;
    }
    public void setLsnPay(float lsnPay) {
        this.lsnPay = lsnPay;
    }
    public Integer getAdvcFlg() {
        return advcFlg;
    }
    public void setAdvcFlg(Integer advcFlg) {
        this.advcFlg = advcFlg;
    }
    public Integer getDataStatus() {
        return dataStatus;
    }
    public void setDataStatus(Integer dataStatus) {
        this.dataStatus = dataStatus;
    }
}
