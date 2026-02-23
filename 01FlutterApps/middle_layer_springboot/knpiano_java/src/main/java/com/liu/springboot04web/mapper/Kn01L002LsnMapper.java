package com.liu.springboot04web.mapper;

import com.liu.springboot04web.bean.Kn01L002LsnBean;

import java.util.List;
import java.util.Map;

import org.apache.ibatis.annotations.Param;

public interface Kn01L002LsnMapper  {
    // 手机前端：课程信息的在课学生一览
    public List<Kn01L002LsnBean> getStuNameList (@Param("year") String year);
    
    public List<Kn01L002LsnBean> getInfoList(@Param("year") String year);

    // 手机前端页面课程表页面，获取指定元月日这一天的学生的排课课程
    public List<Kn01L002LsnBean> getInfoListByDay(@Param("schedualDate") String schedualDate);

    // 获取所有学生最新正在上课的科目信息
    public List<Kn01L002LsnBean>  getLatestSubjectList();

    /**
     * 获取学生到目前为止的课程数量（年初至今）
     * @param stuId 学生ID
     * @param subjectId 科目ID
     * @return 课程数量
     */
    Long stuLsnCountByNow(@Param("stuId") String stuId, 
                          @Param("subjectId") String subjectId);

    /**
     * 获取学生最新在课科目的年度总课时
     * @param stuId 学生ID
     * @param subjectId 科目ID
     * @return 课程数量
     */
    Long getYearLsnCnt(@Param("stuId") String stuId, 
                       @Param("subjectId") String subjectId);

    /**
     * 获取该生该科目的1节课的课时
     * @param stuId 学生ID
     * @param subjectId 科目ID
     * @return 课程数量
     */
    Integer getMinutesPerLsn(@Param("stuId") String stuId, 
                          @Param("subjectId") String subjectId);

    public Kn01L002LsnBean getInfoById(String id);

    List<Kn01L002LsnBean> searchLessons(@Param("params") Map<String, Object> queryparams);

    // 撤销签到
    public void restoreSignedLsn(@Param("lessonId") String lessonId);

    // 取消调课
    public void reScheduleLsnCancel(@Param("lessonId") String lessonId);

    // 更新排课
    public void updateInfo(Kn01L002LsnBean bean);

    // 新规排课
    public void insertInfo(Kn01L002LsnBean bean);

    // 删除排课
    public void deleteInfo(String id);

    // 更新备注
    public int updateMemo(String lessonId, String memo);

    // 执行数据库存储过程
    public void callProcedure(Map<String, Integer> map);

    // 获取下一个序列值
    public void getNextSequence(Map<String, Object> map);

    // 手机前端：课程进度统计--【还未上课统计】Tab，提取未上课（未签到）的 处理
    public List<Kn01L002LsnBean> getUnScanSQDateLsnInfoByYear(@Param("stuId") String stuId,
            @Param("year") String year);

    // 手机前端：XXXX的课程进度统计 查询谋学生该年度所有月份已经上完课的详细信息
    public List<Kn01L002LsnBean> getScanSQLsnInfoByYear(@Param("stuId") String stuId,
            @Param("year") String year);

    public int updateLessonTime(Kn01L002LsnBean knLsn001Bean);

    // [课程排他状态功能] 查询指定时间段内的冲突课程
    List<Kn01L002LsnBean> findConflictLessons(@Param("schedualDate") java.util.Date schedualDate, @Param("classDuration") Integer classDuration, @Param("excludeLessonId") String excludeLessonId);
}