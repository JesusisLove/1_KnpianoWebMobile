package com.liu.springboot04web.mapper;

import org.apache.ibatis.annotations.Param;
import java.util.List;
import java.util.Map;
import com.liu.springboot04web.bean.Kn05S001LsnFixBean;

public interface Kn05S001LsnFixMapper {

    // 获取所有固定授業計画的列表
    public List<Kn05S001LsnFixBean> getInfoList();

    // 根据特定条件搜索固定授業計画
    public List<Kn05S001LsnFixBean> searchFixedLessons(@Param("params") Map<String, Object> queryparams);

    // 根据学生ID获取固定授業計画详细信息
    public Kn05S001LsnFixBean getInfoById(@Param("stuId") String stuId, 
                                        @Param("subjectId") String subjectId, 
                                        @Param("fixedWeek") String fixedWeek);

    // 新增固定授業計画信息
    public void insertInfo(Kn05S001LsnFixBean bean);

    // 更新固定授業計画信息
    public void updateInfo(Kn05S001LsnFixBean bean);

    // 删除固定授業計画信息
    public void deleteInfoByKeys(@Param("stuId") String stuId, 
                                  @Param("subjectId") String subjectId, 
                                  @Param("fixedWeek") String fixedWeek);

    // 调用数据库序列生成新的ID
    public void getNextSequence(Map<String, Object> map);

    // [固定排课排他功能] 2026-02-13 查询冲突的固定排课
    public List<Kn05S001LsnFixBean> findConflictLessons(
            @Param("fixedWeek") String fixedWeek,
            @Param("fixedHour") Integer fixedHour,
            @Param("fixedMinute") Integer fixedMinute,
            @Param("classDuration") Integer classDuration,
            @Param("excludeStuId") String excludeStuId,
            @Param("excludeSubjectId") String excludeSubjectId);
}
