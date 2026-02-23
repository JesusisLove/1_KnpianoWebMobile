package com.liu.springboot04web.bean;

import com.liu.springboot04web.service.conflict.ConflictableLesson;

/**
 * 固定授業計画管理（Fixed Lesson Plan Management）的数据模型，实现 BzlFudousanBean 接口。
 * [课程排他公共模块] 2026-02-13 实现ConflictableLesson接口以支持统一的冲突检测
 */
public class Kn05S001LsnFixBean implements KnPianoBean, ConflictableLesson {
    private String stuId;          // 学生ID
    private String subjectId;      // 科目ID
    private String fixedWeek;      // 固定的星期
    private String originalFixedWeek;  // 原始的星期（用于更新时删除旧记录）
    private Integer fixedHour;     // 固定的小时
    private Integer fixedMinute;   // 固定的分钟

    private String stuName;
    private String subjectName;
    private Integer classDuration;  // [新潮界面] 2026-02-12 课程时长（分钟），从学生档案视图获取
    private Boolean forceOverlap;   // [固定排课排他功能] 2026-02-13 强制保存标记（忽略冲突警告）

 // Getter 和 Setter 方法
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

    public String getFixedWeek() {
        return fixedWeek;
    }

    public void setFixedWeek(String fixedWeek) {
        this.fixedWeek = fixedWeek;
    }

    public String getOriginalFixedWeek() {
        return originalFixedWeek;
    }

    public void setOriginalFixedWeek(String originalFixedWeek) {
        this.originalFixedWeek = originalFixedWeek;
    }

    public Integer getFixedHour() {
        return fixedHour;
    }

    public void setFixedHour(Integer fixedHour) {
        this.fixedHour = fixedHour;
    }

    public Integer getFixedMinute() {
        return fixedMinute;
    }

    public void setFixedMinute(Integer fixedMinute) {
        this.fixedMinute = fixedMinute;
    }

    public String getStuName() {
        return stuName;
    }

    public void setStuName(String stuName) {
        this.stuName = stuName;
    }

    public String getSubjectName() {
        return subjectName;
    }

    public void setSubjectName(String subjectName) {
        this.subjectName = subjectName;
    }

    // [新潮界面] 2026-02-12 课程时长getter/setter
    public Integer getClassDuration() {
        return classDuration;
    }

    public void setClassDuration(Integer classDuration) {
        this.classDuration = classDuration;
    }

    // [固定排课排他功能] 2026-02-13 强制保存标记getter/setter
    public Boolean getForceOverlap() {
        return forceOverlap;
    }

    public void setForceOverlap(Boolean forceOverlap) {
        this.forceOverlap = forceOverlap;
    }

    // [课程排他公共模块] 2026-02-13 实现ConflictableLesson接口方法
    @Override
    public String getStartTimeFormatted() {
        return String.format("%02d:%02d",
                fixedHour != null ? fixedHour : 0,
                fixedMinute != null ? fixedMinute : 0);
    }

    @Override
    public String getEndTimeFormatted() {
        int duration = classDuration != null && classDuration > 0 ? classDuration : 45;
        int startMinutes = (fixedHour != null ? fixedHour : 0) * 60 + (fixedMinute != null ? fixedMinute : 0);
        int endMinutes = startMinutes + duration;
        return String.format("%02d:%02d", endMinutes / 60, endMinutes % 60);
    }
}
