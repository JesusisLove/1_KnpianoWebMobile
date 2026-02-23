package com.liu.springboot04web.service.conflict;

/**
 * [课程排他公共模块] 2026-02-13
 * 可冲突检测的课程接口
 *
 * 所有需要进行时间冲突检测的课程类型都应实现此接口：
 * - 课程表（Kn01L002LsnBean）
 * - 固定排课（Kn05S001LsnFixBean）
 * - 将来可能新增的其他课程类型
 */
public interface ConflictableLesson {

    /**
     * 获取学生ID
     */
    String getStuId();

    /**
     * 获取学生姓名
     */
    String getStuName();

    /**
     * 获取课程开始时间（HH:mm格式）
     */
    String getStartTimeFormatted();

    /**
     * 获取课程结束时间（HH:mm格式）
     */
    String getEndTimeFormatted();

    /**
     * 获取课程时长（分钟）
     */
    Integer getClassDuration();
}
