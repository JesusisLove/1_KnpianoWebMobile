package com.liu.springboot04web.dao;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;

import com.liu.springboot04web.bean.Kn02F004AdvcLsnFeePayPerLsnBean;
import com.liu.springboot04web.constant.KNConstant;
import com.liu.springboot04web.mapper.Kn02F004AdvcLsnFeePayPerLsnMapper;

import java.util.List;
import java.util.HashMap;
import java.util.Map;

@Repository
public class Kn02F004AdvcLsnFeePayPerLsnDao {
    @Autowired
    private Kn02F004AdvcLsnFeePayPerLsnMapper kn02F004Mapper;

    @Autowired
    private SqlSessionFactory sqlSessionFactory;

    // 取得按课时交费的在课学生名单列表
    public List<Kn02F004AdvcLsnFeePayPerLsnBean> getAdvcFeePayPerLsnStuInfo() {
        return kn02F004Mapper.getAdvcFeePayPerLsnStuInfo();
    }

    // 取得指定学生的按课时交费科目列表（用于科目下拉选择器）
    public List<Kn02F004AdvcLsnFeePayPerLsnBean> getAdvcFeePayPerLsnSubjectsByStuId(String stuId) {
        return kn02F004Mapper.getAdvcFeePayPerLsnSubjectsByStuId(stuId);
    }

    public List<Kn02F004AdvcLsnFeePayPerLsnBean> getAdvcFeePayPerLsnInfo(String stuId, String yearMonth,
                                                                          Integer lessonCount, String subjectId,
                                                                          String subjectSubId) {
        return kn02F004Mapper.getAdvcFeePayPerLsnInfo(stuId, yearMonth, lessonCount, subjectId, subjectSubId);
    }

    public List<Kn02F004AdvcLsnFeePayPerLsnBean> getAdvcFeePaidPerLsnInfoByCondition(String stuId,
                                                                                      String year,
                                                                                      String yearMonth) {
        return kn02F004Mapper.getAdvcFeePaidPerLsnInfoByCondition(stuId, year, yearMonth);
    }

    // 确认课程Id，课费Id，支付Id在课费预支付表里是否存在
    public Kn02F004AdvcLsnFeePayPerLsnBean getAdvcFeePaidPerLsnInfoByIds(String lessonId,
                                                                          String lsnFeeId,
                                                                          String lsnPayId) {
        return kn02F004Mapper.getAdvcFeePaidPerLsnInfoByIds(lessonId, lsnFeeId, lsnPayId);
    }

    // 课程签到/撤销时，用到该处理
    public void update(Kn02F004AdvcLsnFeePayPerLsnBean bean) {
        kn02F004Mapper.updateInfo(bean);
    }

    /**
     * 执行按课时预支付处理
     * @param bean 包含学生、科目、银行等基本信息
     * @param previewJson Preview SP 返回的结果 JSON 字符串
     * @return 执行结果 (1=成功, 0=失败)
     */
    public Integer executeAdvcLsnFeePayPerLesson(Kn02F004AdvcLsnFeePayPerLsnBean bean, String previewJson) {
        SqlSession session = sqlSessionFactory.openSession();
        try {
            // 创建 Map 对象来接收输出参数
            Map<String, Object> paramMap = new HashMap<>();
            paramMap.put("result", null);  // 初始化输出参数为 null

            // 调用按课时预支付的存储过程（传入 Preview 结果 JSON）
            kn02F004Mapper.executeAdvcLsnFeePayPerLesson(
                bean.getStuId(),
                bean.getSubjectId(),
                bean.getSubjectSubId(),
                bean.getLessonType(),
                bean.getMinutesPerLsn(),
                bean.getSubjectPrice(),
                bean.getBankId(),
                KNConstant.CONSTANT_KN_LSN_SEQ,
                KNConstant.CONSTANT_KN_LSN_FEE_SEQ,
                KNConstant.CONSTANT_KN_LSN_PAY_SEQ,
                previewJson,
                paramMap
            );

            // 获取结果
            Integer result = (Integer) paramMap.get("result");
            return result != null ? result : -1;
        } finally {
            session.close();
        }
    }
}
