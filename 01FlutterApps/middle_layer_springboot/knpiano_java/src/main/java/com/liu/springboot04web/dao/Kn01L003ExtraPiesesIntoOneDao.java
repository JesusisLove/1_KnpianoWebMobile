package com.liu.springboot04web.dao;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.liu.springboot04web.bean.Kn01L002LsnBean;
import com.liu.springboot04web.bean.Kn01L003ExtraPicesesBean;
import com.liu.springboot04web.bean.Kn02F002FeeBean;
import com.liu.springboot04web.bean.Kn02F004PayBean;
import com.liu.springboot04web.bean.Kn03D004StuDocBean;
import com.liu.springboot04web.constant.KNConstant;
import com.liu.springboot04web.mapper.Kn01L002LsnMapper;
import com.liu.springboot04web.mapper.Kn01L003ExtraPiesesIntoOneMapper;
import com.liu.springboot04web.othercommon.DateUtils;

@Repository
public class Kn01L003ExtraPiesesIntoOneDao {

    @Autowired
    private Kn01L003ExtraPiesesIntoOneMapper kn01L003ExtraPiesesIntoOneMapper;

    // 对凑成整课的加课转正课后执行签到用
    @Autowired
    private Kn01L002LsnMapper knLsn001Mapper;
    @Autowired
    private Kn03D004StuDocDao knStuDoc001Dao;
    @Autowired
    private Kn02F002FeeDao kn02F002FeeDao;
    @Autowired
    private Kn02F004PayDao kn02f004PayDao;
    
    
    // 画面初期化，检索
    public List<Kn01L003ExtraPicesesBean> getExtraPiesesLsnList(String year, String stuId) {
        return kn01L003ExtraPiesesIntoOneMapper.getExtraPiesesLsnList(year, stuId);
    }

    // WEB页面：年度，学生姓名的联动变化
    public List<Kn01L003ExtraPicesesBean> getSearchInfo4Stu(String year) {
        return kn01L003ExtraPiesesIntoOneMapper.getSearchInfo4Stu(year);
    }

    // 手机设备：学生名单显示在学生在课一览画面上
    public List<Kn03D004StuDocBean> getStuName4Mobile(String year) {
        return kn01L003ExtraPiesesIntoOneMapper.getStuName4Mobile(year);
    }

    // 手机设备：获取有零碎加课的学生正在上课的各科价格
    public List<Kn03D004StuDocBean> getLatestPrice4Mobile(String year, String stuId) {
        return kn01L003ExtraPiesesIntoOneMapper.getLatestLsnPriceInfo4Mobile(year, stuId);
    }

    // 执行拼凑完成的加课换正课
    public void excutePicesesIntoOneAndChangeToSche(Kn01L002LsnBean knLsn001Bean) {
        // 课程编号采番
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("parm_in", KNConstant.CONSTANT_KN_LSN_SEQ);
        // 授業自動採番
        knLsn001Mapper.getNextSequence(map);
        knLsn001Bean.setLessonId(KNConstant.CONSTANT_KN_LSN_SEQ + (Integer) map.get("parm_out"));

        knLsn001Mapper.insertInfo(knLsn001Bean);
    }


    // 保存拼成整课的课程ID和零碎课的课程ID的关联映射
    public int save(String lessonId, String oldLessonId) {
        return kn01L003ExtraPiesesIntoOneMapper.savePiceseExtraIntoOne(lessonId, oldLessonId);
    }

    // 逻辑删除《课程表》里零碎课的课程信息（set del_flg = 1）
    public int logicalDelLesson(String lessonId) {

        return kn01L003ExtraPiesesIntoOneMapper.logicalDelLesson(lessonId);
    }

    // 逻辑删除《课费表》里零碎课的课程信息（set del_flg = 1）
    public int logicalDelLsfFee(String lessonId) {
        return kn01L003ExtraPiesesIntoOneMapper.logicalDelLsfFee(lessonId);
    }

    // 像计划课签到一样走签到的业务流程
    public void excuteSign(Kn01L002LsnBean knLsn001Bean) {

        addNewLsnFee(knLsn001Bean);

    }

    // 将该签到课程新规登录到《课费管理表》里
    private void addNewLsnFee(Kn01L002LsnBean knLsn001Bean) {
        // 该签到课程的课费信息作成处理
        Kn02F002FeeBean kn02F002FeeBean = setLsnFeeBean(knLsn001Bean);

        // 新规课程费信息，保存到《课费管理表》里
        kn02F002FeeDao.save(kn02F002FeeBean);
    }


    private Kn02F002FeeBean setLsnFeeBean(Kn01L002LsnBean knLsn001Bean) {
        // 取得该生最新的档案记录信息
        Kn03D004StuDocBean stuDocBean = knStuDoc001Dao.getLsnPrice(knLsn001Bean.getStuId(), knLsn001Bean.getSubjectId(),
                knLsn001Bean.getSubjectSubId());

        Kn02F002FeeBean bean = new Kn02F002FeeBean();
        bean.setStuId(knLsn001Bean.getStuId());
        bean.setLessonId(knLsn001Bean.getLessonId());
        // 有调整价格的使用调整价格
        bean.setLsnFee(
                stuDocBean.getLessonFeeAdjusted() > 0 ? stuDocBean.getLessonFeeAdjusted() : stuDocBean.getLessonFee());
        // 利用计划课取得产生课费的月份
        bean.setLsnMonth(DateUtils.getCurrentDateYearMonth(knLsn001Bean.getSchedualDate()));

        // 课程类型lessonType 0:按课时结算的课程（课结算） 1:按月结算的课程（月计划） 2:按月结算的课程（月加课）
        bean.setLessonType(knLsn001Bean.getLessonType());
        bean.setSubjectId(knLsn001Bean.getSubjectId());
        bean.setPayStyle(stuDocBean.getPayStyle());
        bean.setOwnFlg(0);

        // 按月精算的课程的own_flg设定处理
        // 计划课还分为月计划:(lessonType=1)，和月加课:(lessonType=2)，这里处理的对象是月计划。月加课的费用另结算
        if (bean.getPayStyle() == 1 && bean.getLessonType() == 1) {
            setOwnFlg(bean);
        }

        return bean;
    }

    /**
     * 检测对象：月计划课在该月是否未满4节课的情况下做了结算操作
     * 对象场景：该月的计划课时签到未满（一个月4节课或5节课）的情况下，就执行了月精算处理
     * （也就是说，该月计划课程还没上满4节课（该月有第五周就时5节课）就已经执行了精算处理）
     * 业务场景：签到了1节课，就执行了按月计算处理，这样课费表里只有这一节签到课的ownFlg变更为0了
     * 那么剩下的这3节课，因为是计划课，所以在签到的同时也应当把自身的ownFlg设置为0存到课费金额表里
     */
    private void setOwnFlg(Kn02F002FeeBean bean) {
        List<Kn02F004PayBean> list = kn02f004PayDao.isHasMonthlyPaid(bean.getStuId(), bean.getSubjectId(),
                bean.getLsnMonth());
        if (list.size() > 0) {
            bean.setOwnFlg(1);
        }
    }

}
