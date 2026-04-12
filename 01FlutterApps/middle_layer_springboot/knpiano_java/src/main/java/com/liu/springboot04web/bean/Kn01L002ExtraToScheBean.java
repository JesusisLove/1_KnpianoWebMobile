package com.liu.springboot04web.bean;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;

import org.springframework.format.annotation.DateTimeFormat;

import com.fasterxml.jackson.annotation.JsonFormat;

public class Kn01L002ExtraToScheBean implements KnPianoBean {

    protected String lessonId;
    protected String subjectId;
    protected String subjectSubId;
    protected String subjectName;
    protected String subjectSubName;
    protected String stuId;
    protected String stuName;
    protected String nikName;
    protected Integer classDuration;
    protected Integer lessonType;
    protected Integer schedualType;
    protected Integer payFlg;
    protected String lsnFeeId;
    protected float lsnFee;
    protected Integer isGoodChange;
    protected String memoReason;

    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm", 
    // // timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm") // 后台维护页面的请求响应处理
    protected Date schedualDate;

    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm", 
    // // timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    protected Date scanQrDate;

    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm", 
    // // timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm")
    protected Date lsnAdjustedDate;

    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm", 
    // // timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    protected Date extraToDurDate;

    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm", 
    // // timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm")
    protected Date originalSchedualDate; // 加课换正课后记录原来实际的计划上课日期

    protected Integer badDebtFlg;

    // 其他
    protected Integer payStyle;

    public String getLessonId() {
        return lessonId;
    }

    public void setLessonId(String lessonId) {
        this.lessonId = lessonId;
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

    public Date getLsnAdjustedDate() {
        return lsnAdjustedDate;
    }

    public void setLsnAdjustedDate(Date lsnAdjustedDate) {
        this.lsnAdjustedDate = lsnAdjustedDate;
    }

    public Date getExtraToDurDate() {
        return extraToDurDate;
    }

    public void setExtraToDurDate(Date extraToDurDate) {
        this.extraToDurDate = extraToDurDate;
    }

    public boolean isToday(Date schedualDate) {
        // 获取当前日期
        LocalDate today = LocalDate.now();
        // 将传入的 Date 对象转换为 LocalDate 对象
        LocalDate schedualLocalDate = schedualDate.toInstant().atZone(ZoneId.systemDefault()).toLocalDate();

        // 比较两个 LocalDate 是否相等
        return schedualLocalDate.equals(today);
    }

    public Date getScanQrDate() {
        return scanQrDate;
    }

    public void setScanQrDate(Date scanQrDate) {
        this.scanQrDate = scanQrDate;
    }

    public Integer getPayStyle() {
        return payStyle;
    }

    public void setPayStyle(Integer payStyle) {
        this.payStyle = payStyle;
    }

    public String getSubjectSubId() {
        return subjectSubId;
    }

    public void setSubjectSubId(String subjectSubId) {
        this.subjectSubId = subjectSubId;
    }

    public String getSubjectSubName() {
        return subjectSubName;
    }

    public void setSubjectSubName(String subjectSubName) {
        this.subjectSubName = subjectSubName;
    }

    public Integer getSchedualType() {
        return schedualType;
    }

    public void setSchedualType(Integer schedualType) {
        this.schedualType = schedualType;
    }

    public Integer getPayFlg() {
        return payFlg;
    }

    public void setPayFlg(Integer payFlg) {
        this.payFlg = payFlg;
    }

    
    public String getLsnFeeId() {
        return lsnFeeId;
    }

    public void setLsnFeeId(String lsnFeeId) {
        this.lsnFeeId = lsnFeeId;
    }

    public Integer getIsGoodChange() {
        return isGoodChange;
    }

    public void setIsGoodChange(Integer isGoodChange) {
        this.isGoodChange = isGoodChange;
    }

    public float getLsnFee() {
        return lsnFee;
    }

    public void setLsnFee(float lsnFee) {
        this.lsnFee = lsnFee;
    }

    public Date getOriginalSchedualDate() {
        return originalSchedualDate;
    }

    public void setOriginalSchedualDate(Date originalSchedualDate) {
        this.originalSchedualDate = originalSchedualDate;
    }

    public String getMemoReason() {
        return memoReason;
    }

    public void setMemoReason(String memoReason) {
        this.memoReason = memoReason;
    }

    public Integer getBadDebtFlg() {
        return badDebtFlg;
    }

    public void setBadDebtFlg(Integer badDebtFlg) {
        this.badDebtFlg = badDebtFlg;
    }
}