package com.liu.springboot04web.mapper;

import org.apache.ibatis.annotations.Param;

import com.liu.springboot04web.bean.Kn02F003AdvcLsnFeePayBean;

import java.util.Date;
import java.util.List;
import java.util.Map;

public interface Kn02F003AdvcLsnFeePayMapper {


    public List<Kn02F003AdvcLsnFeePayBean> getAdvcFeePayStuInfo();

    public List<Kn02F003AdvcLsnFeePayBean> getAdvcFeePayLsnInfo(@Param("stuId") String stuId,
                                                                @Param("yearMonth") String yearMonth);

    public List<Kn02F003AdvcLsnFeePayBean> getAdvcFeePaidInfoByCondition(@Param("stuId") String stuId,
                                                                         @Param("year") String year,
                                                                         @Param("yearMonth") String yearMonth);
                                                                         
    public Kn02F003AdvcLsnFeePayBean getAdvcFeePaidyInfoByIds(@Param("lessonId") String lessonId,
                                                                    @Param("lsnFeeId") String lsnFeeId,
                                                                    @Param("lsnPayId") String lsnPayId);

    public void updateInfo(Kn02F003AdvcLsnFeePayBean bean);

    void executeAdvcLsnFeePay(
        @Param("stuId") String stuId,
        @Param("subjectId") String subjectId,
        @Param("subjectSubId") String subjectSubId,
        @Param("lessonType") Integer lessonType,
        @Param("minutesPerLsn") Integer minutesPerLsn,
        @Param("subjectPrice") float subjectPrice,
        @Param("schedualDate") Date schedualDate,
        @Param("bankId") String bankId,
        @Param("lsnSeqCode") String lsnSeqCode,
        @Param("feeSeqCode") String feeSeqCode,
        @Param("paySeqCode") String paySeqCode,
        @Param("paramMap") Map<String, Object> paramMap
    );
}