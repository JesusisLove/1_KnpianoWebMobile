package com.liu.springboot04web.bean;

import java.util.Date;

public class Kn02F002FeeBean implements KnPianoBean{
    protected String    lsnFeeId;
    protected String    lessonId;
    protected float     lsnFee;
    protected String    lsnMonth;
    protected Integer   ownFlg;
    protected Integer   badDebtFlg;
    protected Integer   delFlg;
    protected Date      createDate;
    protected Date      updateDate;
    // 表关联项目
    protected Integer   lessonType;
    protected String    stuId;
    protected String    subjectId;
    protected String    stuName;
    protected String    nikName;
    protected String    subjectName;
    protected Integer   payStyle;
    protected float     lsnCount;
    // 手机端 课程进度统计，在前端页面的chart图上初期化各科目1年中每月的课程数量图
    protected float     totalLsnCount0;
    protected float     totalLsnCount1;;
    protected float     totalLsnCount2;;
    protected Integer   extra2scheFlg; // 0:正常课程标识    1:加课换正课标识
    protected Integer isFromPiceseLsn; // 是不是用零碎加课拼凑的课[0:不是拼凑的课。 1:是拼凑的课]

    public String getLsnFeeId() {
        return lsnFeeId;
    }
    public void setLsnFeeId(String lsnFeeId) {
        this.lsnFeeId = lsnFeeId;
    }
    public String getLessonId() {
        return lessonId;
    }
    public void setLessonId(String lessonId) {
        this.lessonId = lessonId;
    }
    public float getLsnFee() {
        return lsnFee;
    }
    public void setLsnFee(float lsnFee) {
        this.lsnFee = lsnFee;
    }
    public String getLsnMonth() {
        return lsnMonth;
    }
    public void setLsnMonth(String lsnMonth) {
        this.lsnMonth = lsnMonth;
    }
    public Integer getOwnFlg() {
        return ownFlg;
    }
    public void setOwnFlg(Integer ownFlg) {
        this.ownFlg = ownFlg;
    }
    public Integer getBadDebtFlg() {
        return badDebtFlg;
    }
    public void setBadDebtFlg(Integer badDebtFlg) {
        this.badDebtFlg = badDebtFlg;
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
    public Integer getLessonType() {
        return lessonType;
    }
    public void setLessonType(Integer lessonType) {
        this.lessonType = lessonType;
    }
    public String getStuId() {
        return stuId;
    }
    public void setStuId(String stuId) {
        this.stuId = stuId;
    }
    public String getSubjectId() {
        return subjectId;
    }
    public void setSubjectId(String subjectId) {
        this.subjectId = subjectId;
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
    public String getSubjectName() {
        return subjectName;
    }
    public void setSubjectName(String subjectName) {
        this.subjectName = subjectName;
    }
    public Integer getPayStyle() {
        return payStyle;
    }
    public void setPayStyle(Integer payStyle) {
        this.payStyle = payStyle;
    }
    public float getLsnCount() {
        return lsnCount;
    }
    public void setLsnCount(float lsnCount) {
        this.lsnCount = lsnCount;
    }
    public float getTotalLsnCount0() {
        return totalLsnCount0;
    }
    public void setTotalLsnCount0(float totalLsnCount0) {
        this.totalLsnCount0 = totalLsnCount0;
    }
    public float getTotalLsnCount1() {
        return totalLsnCount1;
    }
    public void setTotalLsnCount1(float totalLsnCount1) {
        this.totalLsnCount1 = totalLsnCount1;
    }
    public float getTotalLsnCount2() {
        return totalLsnCount2;
    }
    public void setTotalLsnCount2(float totalLsnCount2) {
        this.totalLsnCount2 = totalLsnCount2;
    }
    public Integer getExtra2scheFlg() {
        return extra2scheFlg;
    }
    public void setExtra2scheFlg(Integer extra2scheFlg) {
        this.extra2scheFlg = extra2scheFlg;
    }
    public Integer getIsFromPiceseLsn() {
        return isFromPiceseLsn;
    }
    public void setIsFromPiceseLsn(Integer isFromPiceseLsn) {
        this.isFromPiceseLsn = isFromPiceseLsn;
    }
}
