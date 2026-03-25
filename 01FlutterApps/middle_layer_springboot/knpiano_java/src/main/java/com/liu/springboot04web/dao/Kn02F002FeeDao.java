package com.liu.springboot04web.dao;

import com.liu.springboot04web.constant.KNConstant;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.liu.springboot04web.bean.Kn02F002FeeBean;
import com.liu.springboot04web.bean.Kn02F004FeePaid4MobileBean;
import com.liu.springboot04web.mapper.Kn02F002FeeMapper;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Repository
public class Kn02F002FeeDao {

    @Autowired
    private Kn02F002FeeMapper knLsnFee001Mapper;

    // 画面初期化显示所科目信息
    // public List<Kn02F002FeeBean> getInfoList() {
    // List<Kn02F002FeeBean> list =knLsnFee001Mapper.getInfoList();
    // return list;
    // }

    public List<Kn02F002FeeBean> getInfoList(String year) {
        List<Kn02F002FeeBean> list = knLsnFee001Mapper.getInfoList(year);
        return list;
    }

    // 手机前端：学费支付管理的在课学生一览
    public List<Kn02F002FeeBean> getStuNameList(String year) {
        List<Kn02F002FeeBean> list = knLsnFee001Mapper.getStuNameList(year);
        return list;
    }

    // 获取所有符合查询条件的课费信息
    public List<Kn02F002FeeBean> searchLsnFee(Map<String, Object> params) {
        return knLsnFee001Mapper.searchLsnFee(params);
    }

    // 根据ID获取课费信息
    public Kn02F002FeeBean getInfoById(String lsnFeeId, String lessonId) {
        Kn02F002FeeBean knLsnFee001Bean = knLsnFee001Mapper.getInfoById(lsnFeeId, lessonId);
        return knLsnFee001Bean;
    }

    // 保存
    public void save(Kn02F002FeeBean knLsnFee001Bean) {
        if (knLsnFee001Bean.getLsnFeeId() == null || knLsnFee001Bean.getLsnFeeId().isEmpty()) {
            // 该签到课程的课费计算业务逻辑处理
            knLsnFee001Bean = processFeeLsn(knLsnFee001Bean);
            // 签到课程的课费新规保存
            insert(knLsnFee001Bean);
        } else {
            update(knLsnFee001Bean);
        }
    }

    // 新規
    private void insert(Kn02F002FeeBean knLsnFee001Bean) {
        knLsnFee001Mapper.insertInfo(knLsnFee001Bean);
    }

    // 変更
    private void update(Kn02F002FeeBean knLsnFee001Bean) {
        knLsnFee001Mapper.updateInfo(knLsnFee001Bean);
    }

    // 課費未精算模块里，点击【学費精算】ボタン、精算画面にての【保存】ボタン押下、 own_flgの値を０から１に変更する処理
    public void updateOwnFlg(Kn02F002FeeBean knLsnFee001Bean) {
        knLsnFee001Mapper.updateOwnFlg(knLsnFee001Bean);
    }

    // 削除
    public void delete(String lsnFeeId, String lessonId) {
        knLsnFee001Mapper.deleteInfo(lsnFeeId, lessonId);
    }

    /*
     * 根据该当科目是按月交费（月课费），还是按课时交费（时课费）
     * 只限按月交费的课程（加课除外）：一个月内的所有按计划的上课编号（课程id）对应一个课费id，是一对多的关系(即lesson_id:
     * lsn_fee_id是一对多的关系)
     * 注意，如果月计划课已经上完了4节课的话，第五周的第5节课不能收钱（即，课费应设置为0.0元）。
     * 另外，课结算和月加课的课程id和课费id（lsn_fee_id和lesson_id）是一对一的关系
     */
    private Kn02F002FeeBean processFeeLsn(Kn02F002FeeBean knLsnFee001Bean) {
        // 按月结算课程且是计划课的场合，lsn_fee_id和lesson_id是一对多的处理
        if (knLsnFee001Bean.getLessonType() == KNConstant.CONSTANT_LESSON_TYPE_MONTHLY_SCHEDUAL) {
            List<Kn02F002FeeBean> feeList = knLsnFee001Mapper.checkScheLsnCurrentMonth(knLsnFee001Bean.getStuId(),
                    knLsnFee001Bean.getSubjectId(),
                    knLsnFee001Bean.getLessonType(),
                    knLsnFee001Bean.getLsnMonth());
            // 按月交费的课费结算，同一个月的计划课使用同一个lsn_fee_id
            if (feeList != null && feeList.size() > 0) {
                knLsnFee001Bean.setLsnFeeId(feeList.get(0).getLsnFeeId());
            } else {
                Map<String, Object> map = new HashMap<>();
                map.put("parm_in", KNConstant.CONSTANT_KN_LSN_FEE_SEQ);
                // 课程费用的自動採番
                knLsnFee001Mapper.getNextSequence(map);
                knLsnFee001Bean.setLsnFeeId(KNConstant.CONSTANT_KN_LSN_FEE_SEQ + (Integer) map.get("parm_out"));
            }

            // 因为是按月收费，一个月4节课，如果该月有第五周，第5节课不收钱
            if (feeList.size() >= 4) {
                knLsnFee001Bean.setLsnFee(0);
            }

        }
        // 课程属性是“课结算” 或者 “月加课”
        else {
            Map<String, Object> map = new HashMap<>();
            map.put("parm_in", KNConstant.CONSTANT_KN_LSN_FEE_SEQ);
            // 课程费用的自動採番
            knLsnFee001Mapper.getNextSequence(map);
            knLsnFee001Bean.setLsnFeeId(KNConstant.CONSTANT_KN_LSN_FEE_SEQ + (Integer) map.get("parm_out"));
        }

        return knLsnFee001Bean;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // 画面初期化显示所科目信息
    public List<Kn02F004FeePaid4MobileBean> getStuFeeDetaillist(String stuId, String yearMonth) {
        List<Kn02F004FeePaid4MobileBean> list = knLsnFee001Mapper.getStuFeeListByYearmonth(stuId, yearMonth);
        return list;
    }

    // 手机前端课程进度统计页面的上课完了Tab页（统计指定年度中的每一个已经签到完了的课程（已支付/未支付的课程都算）
    public List<Kn02F002FeeBean> getInfoLsnStatisticList(String stuId, String year) {

        return knLsnFee001Mapper.getInfoLsnStatisticsByStuId(stuId, year);
    }

    // 获取学生上一个月支付时使用的银行ID（用于设置默认银行）
    public String getLastPaymentBankId(String stuId, String currentMonth) {
        return knLsnFee001Mapper.getLastPaymentBankId(stuId, currentMonth);
    }

    // 坏账处理：标记坏账
    public void markBadDebt(String lsnFeeId) {
        knLsnFee001Mapper.markBadDebt(lsnFeeId);
    }

    // 坏账处理：撤销坏账
    public void undoBadDebt(String lsnFeeId) {
        knLsnFee001Mapper.undoBadDebt(lsnFeeId);
    }

    // 坏账一览取得
    public List<Kn02F004FeePaid4MobileBean> getBadDebtList(String year) {
        return knLsnFee001Mapper.getBadDebtList(year);
    }
}
