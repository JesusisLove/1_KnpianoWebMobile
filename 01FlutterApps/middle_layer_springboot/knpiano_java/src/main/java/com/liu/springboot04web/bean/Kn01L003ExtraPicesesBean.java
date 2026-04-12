package com.liu.springboot04web.bean;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;

import org.springframework.format.annotation.DateTimeFormat;

import com.fasterxml.jackson.annotation.JsonFormat;

public class Kn01L003ExtraPicesesBean implements KnPianoBean {

    protected String lessonId;
    protected String oldLessonId;
    protected String subjectId;
    protected String subjectSubId;
    protected String subjectName;
    protected String subjectSubName;
    protected String stuId;
    protected String stuName;
    protected Integer classDuration;
    protected Integer minutesPerLsn;
    protected Integer badDebtFlg;

    public Integer getMinutesPerLsn() {
        return minutesPerLsn;
    }

    public void setMinutesPerLsn(Integer minutesPerLsn) {
        this.minutesPerLsn = minutesPerLsn;
    }

    public Integer getBadDebtFlg() {
        return badDebtFlg;
    }

    public void setBadDebtFlg(Integer badDebtFlg) {
        this.badDebtFlg = badDebtFlg;
    }

    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm", 
    // // timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    protected Date scanQrDate;

    // 其他
    protected Integer payStyle;

    public String getLessonId() {
        return lessonId;
    }

    public void setLessonId(String lessonId) {
        this.lessonId = lessonId;
    }

    public String getOldLessonId() {
        return oldLessonId;
    }

    public void setOldLessonId(String oldLessonId) {
        this.oldLessonId = oldLessonId;
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

    public Integer getClassDuration() {
        return classDuration;
    }

    public void setClassDuration(Integer classDuration) {
        this.classDuration = classDuration;
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
}