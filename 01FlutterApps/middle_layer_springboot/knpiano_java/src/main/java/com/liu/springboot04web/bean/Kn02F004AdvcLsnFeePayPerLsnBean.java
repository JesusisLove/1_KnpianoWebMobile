package com.liu.springboot04web.bean;

public class Kn02F004AdvcLsnFeePayPerLsnBean extends Kn02F003AdvcLsnFeePayBean {
    // 按课时预支付时，用户指定的课时数（一次性预支付多少节课）
    private Integer lessonCount;

    // Preview SP返回的处理模式标识（A=新建, B=复用lesson, C=复用lesson+fee）
    private String processingMode;
    // Preview SP返回的既存lesson_id（模式B/C时有值，模式A时为null）
    private String existingLessonId;
    // Preview SP返回的既存fee_id（模式C时有值，模式A/B时为null）
    private String existingFeeId;
    // Preview SP返回的显示顺序（1~N）
    private Integer sequenceNo;

    public Integer getLessonCount() {
        return lessonCount;
    }
    public void setLessonCount(Integer lessonCount) {
        this.lessonCount = lessonCount;
    }
    public String getProcessingMode() {
        return processingMode;
    }
    public void setProcessingMode(String processingMode) {
        this.processingMode = processingMode;
    }
    public String getExistingLessonId() {
        return existingLessonId;
    }
    public void setExistingLessonId(String existingLessonId) {
        this.existingLessonId = existingLessonId;
    }
    public String getExistingFeeId() {
        return existingFeeId;
    }
    public void setExistingFeeId(String existingFeeId) {
        this.existingFeeId = existingFeeId;
    }
    public Integer getSequenceNo() {
        return sequenceNo;
    }
    public void setSequenceNo(Integer sequenceNo) {
        this.sequenceNo = sequenceNo;
    }
}
