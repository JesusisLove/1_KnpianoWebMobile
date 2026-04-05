package com.liu.springboot04web.dao;

import com.liu.springboot04web.bean.Kn02F002FeeBean;
import com.liu.springboot04web.bean.Kn02F004FeePaid4MobileBean;
import com.liu.springboot04web.constant.KNConstant;
import com.liu.springboot04web.mapper.Kn02F002FeeMapper;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;



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

    /**
     * 坏账处理：标记坏账
     *
     * 【业务背景】
     *   计划课的课费是"一对多"结构：同一个月内，多节计划课共用同一个 lsn_fee_id。
     *   其中可能包含两类课程：
     *     ① 正常签到的计划课 → 课费记录存在于 t_info_lesson_fee（del_flg=0）
     *     ② 由加课换正课而来的课程 → 该课程原本是加课，执行换正课后并入当月计划课。
     *        换正课后的课费ID（new_lsn_fee_id）记录在 t_info_lesson_extra_to_sche 表中，
     *        原始课费记录在 t_info_lesson_fee 中保留但 del_flg=1（已被替代标记）。
     *        视图展示时，②的坏账标记读取的是这条 del_flg=1 的原始记录的 bad_debt_flg。
     *
     * 【注意】加课换正课是容易被遗漏的场景：
     *   当同一个 lsn_fee_id 既对应①又对应②时，两条课费记录都需要标记坏账。
     *   若只更新①而跳过②，视图中②的课费记录仍会出现在未缴纳明细里，
     *   造成"坏账一览有记录，未缴纳明细也有记录"的数据不一致现象。
     */
    public int markBadDebt(String lsnFeeId, String memo) {
        // ① 更新普通课费记录（t_info_lesson_fee.del_flg=0）的 bad_debt_flg=1
        int updated = knLsnFee001Mapper.markBadDebt(lsnFeeId, memo);

        // ② 无论①是否命中，同时更新加课换正课原始记录（del_flg=1）的 bad_debt_flg=1
        //    通过 t_info_lesson_extra_to_sche.new_lsn_fee_id 关联找到原始记录
        int updatedExtra = knLsnFee001Mapper.markBadDebtForExtra2Sche(lsnFeeId, memo);

        // 任意一个UPDATE成功即视为处理成功，两者均为0才返回0（表示找不到记录）
        return (updated + updatedExtra > 0) ? 1 : 0;
    }

    // 坏账处理：撤销坏账（与标记坏账同理，必须同时执行两个UPDATE）
    public int undoBadDebt(String lsnFeeId) {
        // ① 撤销普通课费记录（del_flg=0）的坏账标记：bad_debt_flg=0
        int updated = knLsnFee001Mapper.undoBadDebt(lsnFeeId);
        // ② 同时撤销加课换正课原始记录（del_flg=1）的坏账标记：bad_debt_flg=0
        int updatedExtra = knLsnFee001Mapper.undoBadDebtForExtra2Sche(lsnFeeId);
        // 任意一个成功即视为撤销成功
        return (updated + updatedExtra > 0) ? 1 : 0;
    }

    // 坏账一览取得
    public List<Kn02F004FeePaid4MobileBean> getBadDebtList(String year) {
        return knLsnFee001Mapper.getBadDebtList(year);
    }

    // 坏账详情取得（按lsn_fee_id查询对应的所有课程记录，用于详情对话框）
    public List<Kn02F004FeePaid4MobileBean> getBadDebtDetailByFeeId(String lsnFeeId) {
        return knLsnFee001Mapper.getBadDebtDetailByFeeId(lsnFeeId);
    }
}
