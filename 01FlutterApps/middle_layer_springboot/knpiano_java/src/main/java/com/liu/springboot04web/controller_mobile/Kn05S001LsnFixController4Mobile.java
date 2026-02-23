package com.liu.springboot04web.controller_mobile;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.liu.springboot04web.bean.Kn03D004StuDocBean;
import com.liu.springboot04web.bean.Kn05S001LsnFixBean;
import com.liu.springboot04web.dao.Kn03D004StuDocDao;
import com.liu.springboot04web.dao.Kn05S001LsnFixDao;
import com.liu.springboot04web.service.conflict.ConflictCheckService;
import java.util.Collection;
import java.util.List;
import java.util.Map;

@RestController
public class Kn05S001LsnFixController4Mobile {

    @Autowired
    Kn05S001LsnFixDao knFixLsn001Dao;
    @Autowired
    private Kn03D004StuDocDao kn03D002StuDocDao;
    // [课程排他公共模块] 2026-02-13 注入公共冲突检测服务
    @Autowired
    private ConflictCheckService conflictCheckService;

    @GetMapping("/mb_kn_fixlsn_001_all")
    public ResponseEntity<Collection<Kn05S001LsnFixBean>> getStudentList() {
        // 获取当前正在上课的所有学生信息
        Collection<Kn05S001LsnFixBean> collection = knFixLsn001Dao.getInfoList();
        return ResponseEntity.ok(collection);
    }

    // 从学生档案信息表里，把已经开课了的学生姓名以及Ta正在上的科目名取出来
    @GetMapping("/mb_kn_fixlsn_stusub_get")
    private ResponseEntity<Collection<Kn03D004StuDocBean>> getStuSubList() {
        List<Kn03D004StuDocBean> list = kn03D002StuDocDao.getLatestSubjectList();
        return ResponseEntity.ok(list);
    }

    // 【新規登録/変更編集】画面にて、【保存】ボタンを押下
    // [课程排他公共模块] 2026-02-13 使用公共冲突检测服务重构
    @PostMapping("/mb_kn_fixlsn_001")
    public ResponseEntity<Map<String, Object>> excuteInfoAdd(@RequestBody Kn05S001LsnFixBean knFixLsn001Bean) {
        // 从请求体中获取原始星期几
        String originalFixedWeek = knFixLsn001Bean.getOriginalFixedWeek();

        // 判断是新增还是更新
        boolean addNewMode = (originalFixedWeek == null || originalFixedWeek.isEmpty());

        // 获取强制保存标志
        Boolean forceOverlap = knFixLsn001Bean.getForceOverlap();
        if (forceOverlap == null) {
            forceOverlap = false;
        }

        // 冲突检测（使用公共服务）
        if (!forceOverlap) {
            // 获取课程时长（默认45分钟）
            Integer classDuration = knFixLsn001Bean.getClassDuration();
            if (classDuration == null || classDuration <= 0) {
                classDuration = 45;
            }

            // 编辑模式下需要排除当前记录
            String excludeStuId = addNewMode ? null : knFixLsn001Bean.getStuId();
            String excludeSubjectId = addNewMode ? null : knFixLsn001Bean.getSubjectId();

            // 查询冲突的固定排课
            List<Kn05S001LsnFixBean> conflictLessons = knFixLsn001Dao.findConflictLessons(
                    knFixLsn001Bean.getFixedWeek(),
                    knFixLsn001Bean.getFixedHour(),
                    knFixLsn001Bean.getFixedMinute(),
                    classDuration,
                    excludeStuId,
                    excludeSubjectId);

            // 使用公共服务构建冲突响应
            if (conflictLessons != null && !conflictLessons.isEmpty()) {
                Map<String, Object> conflictResponse = conflictCheckService.buildConflictResponse(
                        conflictLessons, knFixLsn001Bean.getStuId());
                return conflictCheckService.toResponseEntity(conflictResponse);
            }
        }

        // 无冲突或强制保存，执行保存操作
        knFixLsn001Dao.save(knFixLsn001Bean, addNewMode, originalFixedWeek);

        return conflictCheckService.toResponseEntity(conflictCheckService.buildSuccessResponse());
    }

    // 【排课一覧】削除ボタンを押下
    @DeleteMapping("/mb_kn_fixlsn_001/{stuId}/{subjectId}/{fixedWeek}")
    public ResponseEntity<String> executeFixedLessonDelete(@PathVariable("stuId") String stuId, 
                                                           @PathVariable("subjectId") String subjectId, 
                                                           @PathVariable("fixedWeek") String fixedWeek, 
                                                           Model model) {
        knFixLsn001Dao.deleteByKeys(stuId, subjectId, fixedWeek);
        return ResponseEntity.ok("Success");
    }
}