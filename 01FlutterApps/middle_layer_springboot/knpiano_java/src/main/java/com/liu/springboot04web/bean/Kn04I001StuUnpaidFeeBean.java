package com.liu.springboot04web.bean;

public class Kn04I001StuUnpaidFeeBean {

    private String subjectName;
    private String subjectSubName;
    private String lsnMonth;
    private double lsnFee;

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

    public String getLsnMonth() {
        return lsnMonth;
    }

    public void setLsnMonth(String lsnMonth) {
        this.lsnMonth = lsnMonth;
    }

    public double getLsnFee() {
        return lsnFee;
    }

    public void setLsnFee(double lsnFee) {
        this.lsnFee = lsnFee;
    }
}
