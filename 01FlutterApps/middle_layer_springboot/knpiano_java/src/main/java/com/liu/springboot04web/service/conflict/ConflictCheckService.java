package com.liu.springboot04web.service.conflict;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * [课程排他公共模块] 2026-02-13
 * 课程冲突检测公共服务
 *
 * 提供统一的冲突检测响应构建逻辑，适用于：
 * - 课程表（传统版、新潮版）
 * - 固定排课（传统版、新潮版）
 * - 将来可能新增的其他排课模块
 */
@Service
public class ConflictCheckService {

    /**
     * 构建冲突检测响应
     *
     * @param conflictLessons 检测到的冲突课程列表
     * @param currentStuId    当前正在保存的学生ID（用于判断是否同一学生冲突）
     * @return 冲突响应Map，包含以下字段：
     *         - success: false
     *         - hasConflict: true
     *         - isSameStudentConflict: 是否为同一学生冲突（禁止保存）
     *         - conflicts: 冲突课程信息列表
     *         - message: 提示消息
     */
    public Map<String, Object> buildConflictResponse(
            List<? extends ConflictableLesson> conflictLessons,
            String currentStuId) {

        Map<String, Object> response = new HashMap<>();

        if (conflictLessons == null || conflictLessons.isEmpty()) {
            // 无冲突
            response.put("success", true);
            response.put("hasConflict", false);
            response.put("message", "无冲突");
            return response;
        }

        // 检查是否有同一学生的冲突（禁止保存）
        boolean hasSameStudentConflict = false;
        List<Map<String, Object>> conflictInfoList = new ArrayList<>();

        for (ConflictableLesson conflict : conflictLessons) {
            // 判断是否是同一学生
            if (conflict.getStuId() != null && conflict.getStuId().equals(currentStuId)) {
                hasSameStudentConflict = true;
            }

            // 构建冲突信息（匹配前端ConflictInfo类的字段）
            Map<String, Object> conflictInfo = new HashMap<>();
            conflictInfo.put("stuId", conflict.getStuId());
            conflictInfo.put("stuName", conflict.getStuName());
            conflictInfo.put("startTime", conflict.getStartTimeFormatted());
            conflictInfo.put("endTime", conflict.getEndTimeFormatted());

            conflictInfoList.add(conflictInfo);
        }

        // 构建冲突响应
        response.put("success", false);
        response.put("hasConflict", true);
        response.put("isSameStudentConflict", hasSameStudentConflict);
        response.put("conflicts", conflictInfoList);

        if (hasSameStudentConflict) {
            response.put("message", "同一学生在该时间段已有其他课程，无法保存");
        } else {
            response.put("message", "检测到时间冲突，请确认是否继续");
        }

        return response;
    }

    /**
     * 构建成功响应
     *
     * @return 成功响应Map
     */
    public Map<String, Object> buildSuccessResponse() {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("hasConflict", false);
        response.put("message", "保存成功");
        return response;
    }

    /**
     * 构建错误响应
     *
     * @param errorMessage 错误消息
     * @return 错误响应Map
     */
    public Map<String, Object> buildErrorResponse(String errorMessage) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("hasConflict", false);
        response.put("message", errorMessage);
        return response;
    }

    /**
     * 包装为ResponseEntity返回
     *
     * @param response 响应Map
     * @return ResponseEntity
     */
    public ResponseEntity<Map<String, Object>> toResponseEntity(Map<String, Object> response) {
        return ResponseEntity.ok(response);
    }
}
