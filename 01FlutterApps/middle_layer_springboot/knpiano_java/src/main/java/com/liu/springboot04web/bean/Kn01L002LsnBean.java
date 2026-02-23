package com.liu.springboot04web.bean;

import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Calendar;
import java.util.Date;

import org.springframework.format.annotation.DateTimeFormat;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.liu.springboot04web.service.conflict.ConflictableLesson;

/**
 * [课程排他公共模块] 2026-02-13 实现ConflictableLesson接口以支持统一的冲突检测
 */
public class Kn01L002LsnBean implements KnPianoBean, ConflictableLesson {

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
    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm", 
    // //  timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm")// 后台维护页面的请求响应处理
    protected Date schedualDate;

    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm", 
    // //  timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd")
    protected Date scanQrDate;

    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm", 
    // //  timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm")
    protected Date lsnAdjustedDate;

    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm", 
    // //  timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm")
    protected Date extraToDurDate;

    // @JsonFormat(pattern = "yyyy-MM-dd HH:mm", 
    // //  timezone = "GMT+9" // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // timezone = "GMT+8" // 采用新加坡标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // )
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm") // timezone = "GMT+8" 的设置被统一到了application.properties里
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm")
    protected Date originalSchedualDate; // 加课换正课后记录原来实际的计划上课日期
    protected String memo;
    protected Integer delFlg;
    protected Integer isFromPiceseLsn; // 是不是用零碎加课拼凑的课[0:不是拼凑的课。 1:是拼凑的课]
    protected Integer isExtraToScheLsn; // 是不是用加课换成的正课[0:不是。 1:是]
    protected Date createDate;
    protected Date updateDate;
// 变更，删除，签到，撤销，四个按钮在画面上活性/非活性的状态设置
    protected boolean usableEdit;
    protected boolean usableDelete;
    protected boolean usableSign;
    protected boolean usableCancel;
    protected boolean isToday;
// 其他
    protected Integer payStyle;
    protected String lsnMonth;    //监视排课异常数据模块用
    protected float subjectPrice; //监视排课异常数据模块用

    public float getSubjectPrice() {
        return subjectPrice;
    }
    public void setSubjectPrice(float subjectPrice) {
        this.subjectPrice = subjectPrice;
    }
    public String getLsnMonth() {
        return lsnMonth;
    }
    public void setLsnMonth(String lsnMonth) {
        this.lsnMonth = lsnMonth;
    }
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
    public Integer getDelFlg() {
        return delFlg;
    }
    public void setDelFlg(Integer delFlg) {
        this.delFlg = delFlg;
    }
    public Date getCreateDate() {
        return createDate;
    }
    public void setCreateDate(Date createDate) {
        this.createDate = createDate;
    }
    public Date getUpdateDate() {
        return updateDate;
    }
    public void setUpdateDate(Date updateDate) {
        this.updateDate = updateDate;
    }
// 变更，删除，签到，撤销，四个按钮在画面上活性/非活性的状态设置
    public void setUsableEdit(boolean usableEdit) {
        this.usableEdit = usableEdit;
    }
    public void setUsableDelete(boolean usableDelete) {
        this.usableDelete = usableDelete;
    }
    public void setUsableSign(boolean usableSign) {
        this.usableSign = usableSign;
    }
    public void setUsableCancel(boolean usableCancel) {
        this.usableCancel = usableCancel;
    }
    public boolean isUsableEdit() {
        return usableEdit;
    }
    public boolean isUsableDelete() {
        return usableDelete;
    }
    public boolean isUsableSign() {
        return usableSign;
    }
    public boolean isUsableCancel() {
        return usableCancel;
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
    public boolean isToday() {
        return isToday;
    }
    public void setToday(boolean isToday) {
        this.isToday = isToday;
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
    public Date getOriginalSchedualDate() {
        return originalSchedualDate;
    }
    public void setOriginalSchedualDate(Date originalSchedualDate) {
        this.originalSchedualDate = originalSchedualDate;
    }
    public String getMemo() {
        return memo;
    }
    public void setMemo(String memo) {
        this.memo = memo;
    }
    public Integer getIsFromPiceseLsn() {
        return isFromPiceseLsn;
    }
    public void setIsFromPiceseLsn(Integer isFromPiceseLsn) {
        this.isFromPiceseLsn = isFromPiceseLsn;
    }
    public Integer getIsExtraToScheLsn() {
        return isExtraToScheLsn;
    }
    public void setIsExtraToScheLsn(Integer isExtraToScheLsn) {
        this.isExtraToScheLsn = isExtraToScheLsn;
    }

    // [课程排他公共模块] 2026-02-13 实现ConflictableLesson接口方法
    @Override
    public String getStartTimeFormatted() {
        // 优先使用调课时间，否则使用原排课时间
        Date effectiveDate = lsnAdjustedDate != null ? lsnAdjustedDate : schedualDate;
        if (effectiveDate == null) {
            return "00:00";
        }
        SimpleDateFormat sdf = new SimpleDateFormat("HH:mm");
        return sdf.format(effectiveDate);
    }

    @Override
    public String getEndTimeFormatted() {
        // 优先使用调课时间，否则使用原排课时间
        Date effectiveDate = lsnAdjustedDate != null ? lsnAdjustedDate : schedualDate;
        if (effectiveDate == null) {
            return "00:00";
        }
        int duration = classDuration != null && classDuration > 0 ? classDuration : 45;
        Calendar cal = Calendar.getInstance();
        cal.setTime(effectiveDate);
        cal.add(Calendar.MINUTE, duration);
        SimpleDateFormat sdf = new SimpleDateFormat("HH:mm");
        return sdf.format(cal.getTime());
    }
}
