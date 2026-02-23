package com.liu.springboot04web.bean;

import org.springframework.format.annotation.DateTimeFormat;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.util.Date;

public class Kn02F003AdvcLsnFeePayBean {
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
    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm",
    // // timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm")// 后台维护页面的请求响应处理
    protected Date      schedualDate;
    /* GMT 
     * 详细解释：
     *      GMT（格林威治标准时间）:
     *      GMT 是全球时间的标准，基于位于英国格林威治的一个天文台的时间。
     *      它作为世界各地时间的参考点，0° 经度的地方的时间被称为 GMT。
     * 时区偏移:
     *      GMT+7 表示该时区的时间比 GMT 时间快 7 小时。
     *      GMT+8 表示该时区的时间比 GMT 时间快 8 小时。
     *      同样，GMT-5 表示该时区的时间比 GMT 时间慢 5 小时。
     * 示例:
     *      如果在 GMT 时间是正午 12:00（12:00 PM），那么在 GMT+7 时区的时间是 7:00 PM（19:00），因为比 GMT 时间快了 7 小时
     *      同样，GMT+8 时区的时间将是晚上 8:00（20:00），因为比 GMT 时间快了 8 小时。
     * 
     *      GMT+7：代表如印度尼西亚、西部泰国、越南等地的时区。
     *      GMT+8：代表如中国大陆、马来西亚、新加坡、菲律宾等地的时区
     * 
     * 本案对应：
     * 东京时间（Japan Standard Time, JST）是 GMT+9，即比 GMT 时间快 9 小时。
     * 
    */
    protected Integer   payStyle;
    // 为了按月交费的计划课的精算业务，需要《学生档案》表里对象科目的最新价格
    protected float     subjectPrice;
    protected Integer   minutesPerLsn;
    protected float     lsnPay;
    protected String    bankId;
    protected String    bankName;
    protected Integer   advcFlg;
    

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

}
