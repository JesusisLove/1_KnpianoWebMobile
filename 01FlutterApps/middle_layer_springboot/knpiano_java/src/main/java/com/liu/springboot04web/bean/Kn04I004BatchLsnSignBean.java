package com.liu.springboot04web.bean;

public class Kn04I004BatchLsnSignBean {

    protected int weekNumber;
    protected String startWeekDate;
    protected String endWeekDate;

    protected String lessonId;
    protected String stuId;
    protected String stuName;
    protected String subjectId;
    protected String subjectName;
    protected String subjectSubId;
    protected String subjectSubName;
    protected int lessonType;
    protected int classDuration;
    protected String lessonTime;
    protected String memo;
    protected String schedualDate;
    protected String scheWeek;

    public int getWeekNumber() {
        return weekNumber;
    }

    public void setWeekNumber(int weekNumber) {
        this.weekNumber = weekNumber;
    }

    public String getStartWeekDate() {
        return startWeekDate;
    }

    public void setStartWeekDate(String startWeekDate) {
        this.startWeekDate = startWeekDate;
    }

    public String getEndWeekDate() {
        return endWeekDate;
    }

    public void setEndWeekDate(String endWeekDate) {
        this.endWeekDate = endWeekDate;
    }

    public String getLessonId() {
        return lessonId;
    }

    public void setLessonId(String lessonId) {
        this.lessonId = lessonId;
    }

    public String getStuId() {
        return stuId;
    }

    public void setStuId(String stuId) {
        this.stuId = stuId;
    }

    public int getLessonType() {
        return lessonType;
    }

    public void setLessonType(int lessonType) {
        this.lessonType = lessonType;
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

    public String getSchedualDate() {
        return schedualDate;
    }

    public void setSchedualDate(String schedualDate) {
        this.schedualDate = schedualDate;
    }

    public String getScheWeek() {
        return scheWeek;
    }

    public void setScheWeek(String scheWeek) {
        this.scheWeek = scheWeek;
    }

    public String getStuName() {
        return stuName;
    }

    public void setStuName(String stuName) {
        this.stuName = stuName;
    }

    public int getClassDuration() {
        return classDuration;
    }

    public void setClassDuration(int classDuration) {
        this.classDuration = classDuration;
    }

    public String getLessonTime() {
        return lessonTime;
    }

    public void setLessonTime(String lessonTime) {
        this.lessonTime = lessonTime;
    }

    public String getMemo() {
        return memo;
    }

    public void setMemo(String memo) {
        this.memo = memo;
    }
}
