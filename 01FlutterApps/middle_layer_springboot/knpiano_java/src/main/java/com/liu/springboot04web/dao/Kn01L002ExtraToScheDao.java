package com.liu.springboot04web.dao;

import com.liu.springboot04web.bean.Kn01L002ExtraToScheBean;
import com.liu.springboot04web.bean.Kn01L002LsnBean;
import com.liu.springboot04web.bean.Kn02F002FeeBean;
import com.liu.springboot04web.bean.Kn03D004StuDocBean;
import com.liu.springboot04web.constant.KNConstant;
import com.liu.springboot04web.mapper.Kn01L002ExtraToScheMapper;
import com.liu.springboot04web.mapper.Kn01L002LsnMapper;
import com.liu.springboot04web.mapper.Kn02F002FeeMapper;
import com.liu.springboot04web.othercommon.DateUtils;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public class Kn01L002ExtraToScheDao {

    @Autowired
    private Kn01L002ExtraToScheMapper kn01l002ExtraToScheMapper;

    @Autowired
    private Kn01L002LsnMapper kn01L002LsnMapper;

    @Autowired(required = false)
    private Kn01L002LsnBean knLsn001Bean;

    @Autowired
    private Kn02F002FeeMapper knLsnFee001Mapper;

    private TInfoLessonExtraToScheBean tblBean = new TInfoLessonExtraToScheBean();


    // 手机前端，取得在课学生一览用的加课学生名单
    public List<Kn01L002ExtraToScheBean> getLsnExtraInfoList(String year) {
        List<Kn01L002ExtraToScheBean> list = kn01l002ExtraToScheMapper.getLsnExtraInfoList(year);
        return list;
    }

    // 根据Web页面上的检索部传过来的年月，取得有加课的学生编号，学生姓名。初期化页面的学生姓名下拉列表框
    public List<Kn01L002ExtraToScheBean> getSearchInfo4Stu(String yearMonth) {
        List<Kn01L002ExtraToScheBean> list = kn01l002ExtraToScheMapper.getSearchInfo4Stu(yearMonth);
        return list;
    }

    // Web页面后段维护
    public List<Kn01L002ExtraToScheBean> getInfoList(String year) {
        List<Kn01L002ExtraToScheBean> list = kn01l002ExtraToScheMapper.getInfoListExtraCanBeSche(null, year,null);
        return list;
    }

    // 手机前端页面:year 抽取当前年度的加课记录，adjustedBaseDate 学生档案科目调整基准日
    // adjustedBaseDate 收纳的是学生在界面选择的日期值
    public List<Kn01L002ExtraToScheBean> getInfoList(String stuId, String year, String adjustedBaseDate) {
        List<Kn01L002ExtraToScheBean> list = kn01l002ExtraToScheMapper.getInfoListExtraCanBeSche(stuId, year, adjustedBaseDate);
        return list;
    }

    // 获取所有符合查询条件的课程信息
    public List<Kn01L002ExtraToScheBean> searchLessons(Map<String, Object> params) {
        return kn01l002ExtraToScheMapper.searchUnpaidExtraLessons(params);
    }

    // 根据lessonId提取要换正课的加课明细
    public Kn01L002ExtraToScheBean getExtraLsnDetail(String lessonId) {
        return kn01l002ExtraToScheMapper.getInfoListExtraCanBeScheDetail(lessonId);
    }

    // 执行加课换正课处理
    /* 采用事务处理机制 */
    @Transactional
    public void executeExtraToSche(Kn01L002ExtraToScheBean kn01L002ExtraToScheBean) {
        // 从画面传过来的lessonId退避到变量中
        String lessonId = kn01L002ExtraToScheBean.getLessonId();

        // ①取得旧lsn_fee_id（该加课换正课前的课费ID）和加课的课费，取得条件：lessonId
        Kn02F002FeeBean feeBean = kn01l002ExtraToScheMapper.getOldLessonIdInfo(lessonId);
        String oldLsnFeeId = feeBean.getLsnFeeId();
        float lsnFee = feeBean.getLsnFee();

        // ②更新课程表的加课换正课日期(extra_to_dur_date)，更新条件：lesson_id
        knLsn001Bean = new Kn01L002LsnBean();
        knLsn001Bean.setLessonId(lessonId);
        knLsn001Bean.setExtraToDurDate(kn01L002ExtraToScheBean.getExtraToDurDate());
        kn01L002LsnMapper.updateInfo(knLsn001Bean);

        // ③取得新lsn_fee_id（换成正课后的课费ID），取得条件：换正课的月份
        // getExtraToDurDate：是从前端页面传过来的换正课日期yyyy-MM-dd
        String targetLsnDate = new java.text.SimpleDateFormat("yyyy-MM-dd")
                .format(kn01L002ExtraToScheBean.getExtraToDurDate());
        String targetLsnMonth = targetLsnDate.substring(0, 7);
        String studentId = kn01L002ExtraToScheBean.getStuId();
        String subjectId = kn01L002ExtraToScheBean.getSubjectId();
        List<Kn02F002FeeBean> toScheLsnFeeIdLst = kn01l002ExtraToScheMapper.getNewLessonIdInfo(studentId, subjectId,
                targetLsnMonth, 1);

        // ④加课换正课情報作成
        // ④-1:oldLsnFeeId的设置
        tblBean.setLessonId(lessonId);
        tblBean.setSubjectId(subjectId);
        tblBean.setOldLsnFeeId(oldLsnFeeId);
        tblBean.setToScheScanQrDate(kn01L002ExtraToScheBean.getExtraToDurDate());
        tblBean.setOldLsnFee(lsnFee); // 记录换正课之前的加课课费
        tblBean.setOldSubjectSubId(kn01L002ExtraToScheBean.getSubjectSubId());

        // ④-2:toScheLsnFeeId的设置
        // 换正课的lsn_fee_id採番（如果换正课所在月没有既存记录，就执行课费ID採番）
        if (toScheLsnFeeIdLst == null || toScheLsnFeeIdLst.size() == 0) {
            Map<String, Object> map = new HashMap<>();
            map.put("parm_in", KNConstant.CONSTANT_KN_LSN_FEE_SEQ);
            // 课程费用的自動採番:採番编号 = new_lsn_fee_id = origin_lsn_fee_id
            knLsnFee001Mapper.getNextSequence(map);
            String toScheLsnFeeId = KNConstant.CONSTANT_KN_LSN_FEE_SEQ + (Integer) map.get("parm_out");
            tblBean.setToScheLsnFeeId(toScheLsnFeeId);
            // 加课换正课中间表字段设置
            tblBean.setIsGoodChange(1);// 设置【有意义的换课】标识
            tblBean.setToScheOwnFlg(0);
        }
        // 换正课所在月的既存lsn_fee_id（换正课所在月有既存的lsn_fee_id记录）
        else {
            String toScheLsnFeeId = toScheLsnFeeIdLst.get(0).getLsnFeeId();
            /*
             * newLsnFeeIdLst里的数组元素个数就是换正课的月份已经上完了的月计划的课数，
             * 如果数组元素小于4，就表示该加课往这个月份上去换的正课是有效率的正课，它参与课费结算
             * 如果数组元素大等于4，就表示这个正课白换了，因为超过4节之后的课费都不参与课费结算
             */

            // 如果数组元素个数大于等于4，更新课费表（t_info_lesson_fee）表
            // 更新字段：lsn_fee, del_flg
            // 更新值：lsn_fee = 0.0, del_flg = 1
            // 更新条件：lesson_id
            // ------- 修改开始： 2025/11/08 幻数4天只是权宜之计，只用4天不对，月份一般都有第四周，但是也有第五周的可能 ------
            int weekDaysInMonth = DateUtils.countWeekdaysInMonth(targetLsnDate);
            // if (toScheLsnFeeIdLst.size() >= 4) {
            if (toScheLsnFeeIdLst.size() >= weekDaysInMonth) {
            // ------- 修改结束 ：2025/11/08 ---------------------------------------------------------------------
                // 课费表字段值设置
                lsnFee = 0;

                // 加课换正课中间表字段设置
                tblBean.setIsGoodChange(0);// 设置【无意义的换课】标识
                tblBean.setMemoReason("该月的计划课任务已完成，<br>再转正课就会白白浪费这节课时数。");
                // 无意义理由：该月的计划课X节任务已完成，再转正课就会白白浪费这节课时数。
            }

            // 如果数组元素个数小于4，更新课费表（t_info_lesson_fee）表
            // 更新字段：del_flg
            // 更新值：del_flg = 1
            // 更新条件：lesson_id
            else {

                // 课费的设置处理なし

                // 加课换正课中间表字段设置
                tblBean.setIsGoodChange(1);// 设置【有意义的换课】标识

                // 虽然上面的条件满足了（即，这次的加课换正课在当前月看来是 有意义的），还要再看，目前上完了的计划课总课时有没有超过计划课年度计划总课时（比如：43节）
                correctLessonTypeIfOverLimit_43(tblBean, studentId, subjectId);
            }
            // 设置换正课后的lsn_fee_id
            tblBean.setToScheLsnFeeId(toScheLsnFeeId);
            tblBean.setToScheOwnFlg(toScheLsnFeeIdLst.get(0).getOwnFlg());
        }

        /*
         * 2025-02-24 追加了下面的业务逻辑处理 开始
         * 加课换正课的时机如果赶上学生的子科目变动了，比如去年12月还在学钢琴5级，用的是5级的学费，到今年1月学生进入6级的学习，子科目和学费价格都发生了变化。
         * 加课换正课表也追加了这4个字段，记录加课换正课后的课程属性发生的变化。加课换成正课，原来的加课课程属性跟着正课的属性走（即，原来虽然是5级，变成正课后，
         * 该课就被视为6级的钢琴课，价格也是按照6级的价格走）
         */
        // 从③那里取得的targetLsnMonth，去学生档案表里查找，该月份学生正在学习科目中的哪个一阶段的子科目以及该子科目的价格
        Kn03D004StuDocBean toScheDocInfo = kn01l002ExtraToScheMapper.getToScheDocumentInfo(studentId, subjectId,
                targetLsnMonth);
        // ④-3:toScheSubjectPrice的设置(调课价格优先)
        tblBean.setToScheLsnFee(toScheDocInfo.getLessonFeeAdjusted() > 0 ? toScheDocInfo.getLessonFeeAdjusted() : toScheDocInfo.getLessonFee());

        // ④-4:toScheSubjectSubId的设置
        tblBean.setToScheSubjectSubId(toScheDocInfo.getSubjectSubId());
        /* 2025-02-24 追加了下面的业务逻辑处理 结束 */

        // ⑤将旧lsn_fee_id（原加课的课费记录）“废除”:更新t_info_lesson_fee表里的del_flg=1,更新条件：课程Id（lessonId)
        kn01l002ExtraToScheMapper.updateLsnFeeFlg(lessonId, lsnFee, 1);

        // ⑥执行保存加课换正课的处理（其实处理的是课费的结算，即原来准备按加课费收费，由于换成其他月份的正课，就不在当前月收取加课费了）
        kn01l002ExtraToScheMapper.insertExtraToScheInfo(tblBean.getLessonId(),
                                                        tblBean.getSubjectId(),
                                                        tblBean.getOldLsnFeeId(),
                                                        tblBean.getToScheLsnFeeId(),
                                                        tblBean.getOldSubjectSubId(),
                                                        tblBean.getToScheSubjectSubId(),
                                                        tblBean.getOldLsnFee(),
                                                        tblBean.getToScheLsnFee(),
                                                        tblBean.getToScheScanQrDate(),
                                                        tblBean.getIsGoodChange(),
                                                        tblBean.getMemoReason(),
                                                        tblBean.getToScheOwnFlg());
    }

    // ===== 以下为批量加课换正课（Web版）新增方法 =====

    // Step1: 按科目查询在课学生
    public List<Kn01L002ExtraToScheBean> getActiveStudentsBySubject(String subjectId) {
        return kn01l002ExtraToScheMapper.getActiveStudentsBySubject(subjectId);
    }

    // Step2: 批量查询多个学生的未消化加课
    public List<Kn01L002ExtraToScheBean> getBatchUndigestedExtras(List<String> stuIds, String subjectId) {
        return kn01l002ExtraToScheMapper.getBatchUndigestedExtras(stuIds, subjectId);
    }

    // Step2: 查询指定学生该科目当年的未签到课程日期（用于下拉快速选择）
    public List<Kn01L002LsnBean> getUnsignedLessonDates(String stuId, String subjectId) {
        return kn01l002ExtraToScheMapper.getUnsignedLessonDates(stuId, subjectId);
    }

    // 批量执行换正课（一次失败全部回滚）
    @Transactional
    public void batchExecuteExtraToSche(List<Kn01L002ExtraToScheBean> beanList) {
        for (Kn01L002ExtraToScheBean bean : beanList) {
            tblBean = new TInfoLessonExtraToScheBean(); // 每次执行前重置，防止上一次数据残留
            executeExtraToSche(bean);
        }
    }

    // 撤销加课换正课处理
    /* 采用事务处理机制 */
    @Transactional
    public void undoExtraToSche(String lessonId) {

        // ①将《课程表》的加课换正课日期赋值为null，更新条件：lessonId
        kn01l002ExtraToScheMapper.updateExtraDateIsNull(lessonId);

        // ②从《加课换正课中间表》中取得原来的课费（lsn_fee）
        Kn01L002ExtraToScheBean bean = kn01l002ExtraToScheMapper.getRollbackExtraToScheInfo(lessonId);
        // 将《课费表》的del_flg值还原为0.更新条件：lessonId
        kn01l002ExtraToScheMapper.updateLsnFeeFlg(lessonId, bean.getLsnFee(), 0);

        // ③删除《加课换正课中间表》的记录，删除条件：lessonId
        kn01l002ExtraToScheMapper.deleteOldNewLsnFeeId(lessonId);
    }

    // 坏账检查：该 lessonId 是否在坏账通缉犯名单中
    public boolean isBadDebtLesson(String lessonId) {
        Integer count = kn01l002ExtraToScheMapper.checkBadDebt(lessonId);
        return count != null && count > 0;
    }

    /* 再进一步判断该加课是否是有意义的换正课
    * 该学生目前已经上完的计划课和该生预定的年度计划总课时进行比较
    * 如果上完的计划总课时小于预定的年度计划总课时：有意义的换正课，否则是无意义的换正课【无意义理由：年度计划课X节任务已完成，再转正课就会白白浪费这节课时数。】
    * 
    */
    private void correctLessonTypeIfOverLimit_43(TInfoLessonExtraToScheBean tblBean, String stuId, String subjectId) {
        // 取得该生到目前为止，本年度计划课总课时
        // ✅ 使用Optional处理当返回的对象为null时返回值为0L
        float lsnCnt =  Optional.ofNullable(kn01L002LsnMapper.stuLsnCountByNow(stuId, subjectId)).orElse(0L);
        
        // 获取该生该科目年度总课时
        float yearLsnCnt = kn01L002LsnMapper.getYearLsnCnt(stuId, subjectId);

        // 到目前为止的总课时还没有达到43节课的，返回
        if (lsnCnt < yearLsnCnt) return;  // if (lsnCnt < 43) return;

        // 总课时超过43节课的，该课由计划课强行转换为加课
        tblBean.setIsGoodChange(0);// 设置【无意义的换课】标识
        tblBean.setMemoReason("年度计划课["+yearLsnCnt+"节]任务已完成，<br>再转正课就会白白浪费这节课时数。");
    }
}

/**
 * 加课换正课情報作成
 * 数据库t_info_lesson_extra_to_sche表的Bean类
 */
class TInfoLessonExtraToScheBean {

    // 课程ID
    String lessonId;

    // 换正课之后的课费ID
    String toScheLsnFeeId;

    // 换正课之前的课费ID
    String oldLsnFeeId;

    // 科目ID
    String subjectId;

    // 换正课之后的子科目ID
    String toScheSubjectSubId;

    // 换正课之前的子科目ID
    String oldSubjectSubId;

    // 加课时的课费
    float oldLsnFee;

    // 正课时的课费
    float toScheLsnFee;

    // @JsonFormat(pattern = "yyyy-MM-dd", timezone = "GMT+9") //
    // 采用东京标准时区，接受手机前端的请求时接纳前端String类型的日期值
    // @DateTimeFormat(pattern = "yyyy-MM-dd")
    protected Date toScheScanQrDate;

    Integer toScheOwnFlg;

    /**
     * 1:有效率的加课换正课，换正课月份的计划课时不足4节课，加课能有效顶替正课，视为很有效率的加课换正课。
     * 0:没有效率的加课换正课，换正课月份的计划课时已经够4节课了，在换正课就相当于白白浪费了一节加课课时，视为无效率的加课换正课。
     */
    int isGoodChange;

    // 如果是无意义的排课，写下无意义排课的理由
    String memoReason;

    public String getLessonId() {
        return lessonId;
    }

    public void setLessonId(String lessonId) {
        this.lessonId = lessonId;
    }

    public String getToScheLsnFeeId() {
        return toScheLsnFeeId;
    }

    public void setToScheLsnFeeId(String newLsnFeeId) {
        this.toScheLsnFeeId = newLsnFeeId;
    }

    public String getOldLsnFeeId() {
        return oldLsnFeeId;
    }

    public void setOldLsnFeeId(String oldLsnFeeId) {
        this.oldLsnFeeId = oldLsnFeeId;
    }

    public Date getToScheScanQrDate() {
        return toScheScanQrDate;
    }

    public void setToScheScanQrDate(Date newScanQrDate) {
        this.toScheScanQrDate = newScanQrDate;
    }

    public int getIsGoodChange() {
        return isGoodChange;
    }

    public void setIsGoodChange(int isGoodChange) {
        this.isGoodChange = isGoodChange;
    }

    public int getToScheOwnFlg() {
        return toScheOwnFlg;
    }

    public void setToScheOwnFlg(int newOwnFlg) {
        this.toScheOwnFlg = newOwnFlg;
    }

    public String getToScheSubjectSubId() {
        return toScheSubjectSubId;
    }

    public void setToScheSubjectSubId(String newSubjectSubId) {
        this.toScheSubjectSubId = newSubjectSubId;
    }

    public String getOldSubjectSubId() {
        return oldSubjectSubId;
    }

    public void setOldSubjectSubId(String oldSubjectSubId) {
        this.oldSubjectSubId = oldSubjectSubId;
    }

    public float getOldLsnFee() {
        return oldLsnFee;
    }

    public void setOldLsnFee(float oldLsnFee) {
        this.oldLsnFee = oldLsnFee;
    }

    public float getToScheLsnFee() {
        return toScheLsnFee;
    }

    public void setToScheLsnFee(float newLsnFee) {
        this.toScheLsnFee = newLsnFee;
    }

    public String getMemoReason() {
        return memoReason;
    }

    public void setMemoReason(String memoReason) {
        this.memoReason = memoReason;
    }

    public String getSubjectId() {
        return subjectId;
    }

    public void setSubjectId(String subjectId) {
        this.subjectId = subjectId;
    }
}