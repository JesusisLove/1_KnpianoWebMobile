package com.liu.springboot04web.mapper;

import org.apache.ibatis.annotations.Param;

import com.liu.springboot04web.bean.Kn02F004AdvcLsnFeePayPerLsnBean;

import java.util.List;
import java.util.Map;

public interface Kn02F004AdvcLsnFeePayPerLsnMapper {

    public List<Kn02F004AdvcLsnFeePayPerLsnBean> getAdvcFeePayPerLsnStuInfo();

    public List<Kn02F004AdvcLsnFeePayPerLsnBean> getAdvcFeePayPerLsnSubjectsByStuId(@Param("stuId") String stuId);

    public List<Kn02F004AdvcLsnFeePayPerLsnBean> getAdvcFeePayPerLsnInfo(@Param("stuId") String stuId,
                                                                          @Param("yearMonth") String yearMonth,
                                                                          @Param("lessonCount") Integer lessonCount,
                                                                          @Param("subjectId") String subjectId,
                                                                          @Param("subjectSubId") String subjectSubId);

    public List<Kn02F004AdvcLsnFeePayPerLsnBean> getAdvcFeePaidPerLsnInfoByCondition(@Param("stuId") String stuId,
                                                                                      @Param("year") String year,
                                                                                      @Param("yearMonth") String yearMonth);

    public Kn02F004AdvcLsnFeePayPerLsnBean getAdvcFeePaidPerLsnInfoByIds(@Param("lessonId") String lessonId,
                                                                          @Param("lsnFeeId") String lsnFeeId,
                                                                          @Param("lsnPayId") String lsnPayId);

    public void updateInfo(Kn02F004AdvcLsnFeePayPerLsnBean bean);

    void executeAdvcLsnFeePayPerLesson(
        @Param("stuId") String stuId,
        @Param("subjectId") String subjectId,
        @Param("subjectSubId") String subjectSubId,
        @Param("lessonType") Integer lessonType,
        @Param("minutesPerLsn") Integer minutesPerLsn,
        @Param("subjectPrice") float subjectPrice,
        @Param("bankId") String bankId,
        @Param("lsnSeqCode") String lsnSeqCode,
        @Param("feeSeqCode") String feeSeqCode,
        @Param("paySeqCode") String paySeqCode,
        @Param("previewJson") String previewJson,
        @Param("paramMap") Map<String, Object> paramMap
    );
}
