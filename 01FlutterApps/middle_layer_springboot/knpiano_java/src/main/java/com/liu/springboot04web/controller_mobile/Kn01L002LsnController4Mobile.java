package com.liu.springboot04web.controller_mobile;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.liu.springboot04web.bean.Kn01L002LsnBean;
import com.liu.springboot04web.bean.Kn03D004StuDocBean;
import com.liu.springboot04web.dao.Kn01L002LsnDao;
import com.liu.springboot04web.dao.Kn03D004StuDocDao;
import com.liu.springboot04web.othercommon.DateUtils;
import com.liu.springboot04web.service.ComboListInfoService;
import com.liu.springboot04web.service.conflict.ConflictCheckService;

@RestController
@Service
public class Kn01L002LsnController4Mobile {
    private ComboListInfoService combListInfo;

    @Autowired
    private Kn01L002LsnDao kn01L002LsnDao;

    @Autowired
    private Kn03D004StuDocDao kn03D004StuDocDao;

    // [课程排他公共模块] 2026-02-13 注入公共冲突检测服务
    @Autowired
    private ConflictCheckService conflictCheckService;

    // 通过构造器注入方式接收ComboListInfoService的一个实例，获得application.properties里配置的上课时长数组
    public Kn01L002LsnController4Mobile(ComboListInfoService combListInfo) {
        this.combListInfo = combListInfo;
    }

    // 获取所有学生排课信息
    @GetMapping("/mb_kn_lsn_all/{year}")
    public ResponseEntity<List<Kn01L002LsnBean>> getInfoStuLsnList(@PathVariable Integer year) {
        // 获取当前正在上课的所有学生的排课信息
        List<Kn01L002LsnBean> collection = kn01L002LsnDao.getStuNameList(Integer.toString(year));
        return ResponseEntity.ok(collection);
    }

    // 手机端网页:点击手机日历上的日期，提取指定年月日这一天的课程
    @GetMapping("/mb_kn_lsn_info_by_day/{schedualDate}")
    public ResponseEntity<List<Kn01L002LsnBean>> getInfoListByDay(@PathVariable("schedualDate") String schedualDate) {
        // 获取当前正在上课的所有学生信息
        List<Kn01L002LsnBean> collection = kn01L002LsnDao.getInfoListByDay(schedualDate);
        return ResponseEntity.ok(collection);
    }

    // 课程表一览】画面にて、签到ボタンを押下
    @GetMapping("/mb_kn_lsn_001_lsn_sign/{id}")
    public void lessonSign(@PathVariable("id") String id) {
        // 拿到该课程信息
        Kn01L002LsnBean knLsn001Bean = kn01L002LsnDao.getInfoById(id);
        kn01L002LsnDao.excuteSign(knLsn001Bean);
        // return ResponseEntity.ok("Ok");
    }

    // 课程表一览】画面にて、撤销ボタンを押下
    @GetMapping("/mb_kn_lsn_001_lsn_undo/{id}")
    public void lessonUndo(@PathVariable("id") String id) {

        // 拿到该课程信息
        Kn01L002LsnBean knLsn001Bean = kn01L002LsnDao.getInfoById(id);
        // 撤销签到登记
        kn01L002LsnDao.excuteUndo(knLsn001Bean);
        // return ResponseEntity.ok("Ok");
    }

    // 【课程表一览】画面にて、【编辑】ボタンを押下
    @GetMapping("/mb_kn_lsn_001/{lessonId}")
    public ResponseEntity<Kn01L002LsnBean> getStudentByName(@PathVariable("lessonId") String lessonId) {
        Kn01L002LsnBean kn01L002LsnBean = kn01L002LsnDao.getInfoById(lessonId);
        return ResponseEntity.ok(kn01L002LsnBean);
    }

    // 【学生排课新規、调课】画面にて、【保存】ボタンを押下
    // [课程排他公共模块] 2026-02-13 使用公共冲突检测服务重构
    @PostMapping("/mb_kn_lsn_001_save")
    public ResponseEntity<Map<String, Object>> excuteInfoAdd(@RequestBody Map<String, Object> requestBody) {
        // 从请求体中提取课程信息
        Kn01L002LsnBean knStuLsn001Bean = extractLessonBean(requestBody);
        // 提取是否强制保存标志（前端使用forceOverlap）
        Boolean forceOverlap = (Boolean) requestBody.get("forceOverlap");
        if (forceOverlap == null) {
            forceOverlap = false;
        }

        // 如果是新规排课，要执行有效排课校验
        if (knStuLsn001Bean.getLessonId() == null) {
            String errMsg = validateHasError(knStuLsn001Bean);
            if (!"".equals(errMsg)) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body(conflictCheckService.buildErrorResponse(errMsg));
            }
        }

        // 冲突检测（使用公共服务）
        if (!forceOverlap) {
            // 获取排课时间（调课情况下使用调课时间，否则使用原排课时间）
            Date effectiveDate = knStuLsn001Bean.getLsnAdjustedDate() != null
                    ? knStuLsn001Bean.getLsnAdjustedDate()
                    : knStuLsn001Bean.getSchedualDate();

            // 查询冲突课程
            List<Kn01L002LsnBean> conflictLessons = kn01L002LsnDao.findConflictLessons(
                    effectiveDate,
                    knStuLsn001Bean.getClassDuration(),
                    knStuLsn001Bean.getLessonId());

            // 使用公共服务构建冲突响应
            if (conflictLessons != null && !conflictLessons.isEmpty()) {
                Map<String, Object> conflictResponse = conflictCheckService.buildConflictResponse(
                        conflictLessons, knStuLsn001Bean.getStuId());
                return conflictCheckService.toResponseEntity(conflictResponse);
            }
        }

        // 执行排课
        kn01L002LsnDao.save(knStuLsn001Bean);
        return conflictCheckService.toResponseEntity(conflictCheckService.buildSuccessResponse());
    }

    // 从请求体Map中提取LessonBean
    private Kn01L002LsnBean extractLessonBean(Map<String, Object> requestBody) {
        Kn01L002LsnBean bean = new Kn01L002LsnBean();

        bean.setLessonId((String) requestBody.get("lessonId"));
        bean.setStuId((String) requestBody.get("stuId"));
        bean.setSubjectId((String) requestBody.get("subjectId"));
        bean.setSubjectSubId((String) requestBody.get("subjectSubId"));
        bean.setMemo((String) requestBody.get("memo"));

        // [Bug Fix 2026-02-11] 处理整数类型（兼容String和Number输入）
        if (requestBody.get("classDuration") != null) {
            bean.setClassDuration(parseInteger(requestBody.get("classDuration")));
        }
        if (requestBody.get("lessonType") != null) {
            bean.setLessonType(parseInteger(requestBody.get("lessonType")));
        }
        if (requestBody.get("schedualType") != null) {
            bean.setSchedualType(parseInteger(requestBody.get("schedualType")));
        }

        // 处理日期类型
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");
        try {
            if (requestBody.get("schedualDate") != null) {
                bean.setSchedualDate(sdf.parse((String) requestBody.get("schedualDate")));
            }
            if (requestBody.get("lsnAdjustedDate") != null) {
                bean.setLsnAdjustedDate(sdf.parse((String) requestBody.get("lsnAdjustedDate")));
            }
            if (requestBody.get("scanQrDate") != null) {
                bean.setScanQrDate(sdf.parse((String) requestBody.get("scanQrDate")));
            }
            if (requestBody.get("extraToDurDate") != null) {
                bean.setExtraToDurDate(sdf.parse((String) requestBody.get("extraToDurDate")));
            }
        } catch (Exception e) {
            // 日期解析失败时忽略
        }

        return bean;
    }

    // [课程排他公共模块] 2026-02-13 取消调课API - 使用公共冲突检测服务
    @PostMapping("/mb_kn_lsn_resche_cancel/{lessonId}")
    public ResponseEntity<Map<String, Object>> executeInfoRescheCancel(@PathVariable("lessonId") String lessonId) {
        try {
            // 1. 获取课程信息
            Kn01L002LsnBean lesson = kn01L002LsnDao.getInfoById(lessonId);
            if (lesson == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(conflictCheckService.buildErrorResponse("课程不存在"));
            }

            // 2. 检测原时间是否有冲突（排除自身）
            Date originalDate = lesson.getSchedualDate();
            List<Kn01L002LsnBean> conflictLessons = kn01L002LsnDao.findConflictLessons(
                    originalDate,
                    lesson.getClassDuration(),
                    lessonId);

            // 使用公共服务构建冲突响应
            if (conflictLessons != null && !conflictLessons.isEmpty()) {
                Map<String, Object> conflictResponse = conflictCheckService.buildConflictResponse(
                        conflictLessons, lesson.getStuId());
                conflictResponse.put("message", "原时间段已安排其他学生的课程，无法恢复");
                return ResponseEntity.status(HttpStatus.CONFLICT).body(conflictResponse);
            }

            // 3. 执行取消调课
            kn01L002LsnDao.reScheduleLsnCancel(lessonId);
            Map<String, Object> successResponse = conflictCheckService.buildSuccessResponse();
            successResponse.put("message", "取消调课成功");
            return ResponseEntity.ok(successResponse);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(conflictCheckService.buildErrorResponse("系统错误：" + e.getMessage()));
        }
    }

    // 【课程表一覧】削除ボタンを押下
    @DeleteMapping("/mb_kn_lsn_001_delete/{lessonId}")
    public ResponseEntity<String> executeInfoDelete(@PathVariable("lessonId") String lessonId) {
        try {
            // 拿到该课程信息
            Kn01L002LsnBean knLsn001Bean = kn01L002LsnDao.getInfoById(lessonId);
            // 取出该课程，判断是原课还是调课
            if (knLsn001Bean.getLsnAdjustedDate() != null) {
                // 是调课，退回到原课状态
                kn01L002LsnDao.reScheduleLsnCancel(lessonId);

            } else {
                // 是原课，执行物理删除
                kn01L002LsnDao.delete(lessonId);

            }
            return ResponseEntity.ok("success");
        } catch (DataIntegrityViolationException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT)  // 409 Conflict
                    .body("学科编号为【" + lessonId + "】的科目在使用。所以删除不了。");
        }
    }

    // 【课程表一覧】更新备注
    // @CrossOrigin(origins = "*")
    @PostMapping("/mb_kn_lsn_001_lsn_memo/{lessonId}")
    public ResponseEntity<Map<String, String>> updateInfoMemo(@PathVariable("lessonId") String lessonId,
            @RequestBody Map<String, String> memoMap) {
        try {
            String memo = memoMap.get("memo");

            // 调用服务层更新备注
            int updatedCnt = kn01L002LsnDao.updateMemo(lessonId, memo);

            if (updatedCnt == 1) {
                Map<String, String> response = new HashMap<>();
                response.put("status", "success");
                response.put("message", "备注更新成功");
                return ResponseEntity.ok(response);
            } else {
                Map<String, String> response = new HashMap<>();
                response.put("status", "error");
                response.put("message", "更新备注失败");
                return ResponseEntity.badRequest().body(response);
            }

        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "系统错误：" + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    // 取得学生的上课时长
    // @CrossOrigin(origins = "*")
    @GetMapping("/mb_kn_lsn_duration")
    public ResponseEntity<List<String>> getDurations() {
        // 获取系统定义的排课时长
        final List<String> duration = combListInfo.getDurations();
        return ResponseEntity.ok(duration);
    }

    // [课程排他公共模块] 2026-02-13 调课API - 使用公共冲突检测服务
    @PostMapping("/mb_kn_lsn_updatetime")
    public ResponseEntity<Map<String, Object>> updateLessonTime(@RequestBody Map<String, Object> requestBody) {
        try {
            // 1. 提取参数
            String lessonId = (String) requestBody.get("lessonId");
            String lsnAdjustedDateStr = (String) requestBody.get("lsnAdjustedDate");
            Boolean forceOverlap = (Boolean) requestBody.get("forceOverlap");
            if (forceOverlap == null) {
                forceOverlap = false;
            }

            // 2. 获取原课程信息
            Kn01L002LsnBean lesson = kn01L002LsnDao.getInfoById(lessonId);
            if (lesson == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(conflictCheckService.buildErrorResponse("课程不存在"));
            }

            // 3. 解析调课目标时间
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm");
            Date newDate = sdf.parse(lsnAdjustedDateStr);

            // 4. 冲突检测（使用公共服务）
            if (!forceOverlap) {
                List<Kn01L002LsnBean> conflictLessons = kn01L002LsnDao.findConflictLessons(
                        newDate,
                        lesson.getClassDuration(),
                        lessonId);

                if (conflictLessons != null && !conflictLessons.isEmpty()) {
                    Map<String, Object> conflictResponse = conflictCheckService.buildConflictResponse(
                            conflictLessons, lesson.getStuId());
                    return conflictCheckService.toResponseEntity(conflictResponse);
                }
            }

            // 5. 执行调课
            Kn01L002LsnBean updateBean = new Kn01L002LsnBean();
            updateBean.setLessonId(lessonId);
            updateBean.setLsnAdjustedDate(newDate);
            int isUpdated = kn01L002LsnDao.updateLessonTime(updateBean);

            if (isUpdated > 0) {
                Map<String, Object> successResponse = conflictCheckService.buildSuccessResponse();
                successResponse.put("message", "调课成功");
                return ResponseEntity.ok(successResponse);
            } else {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body(conflictCheckService.buildErrorResponse("调课失败"));
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(conflictCheckService.buildErrorResponse("系统错误：" + e.getMessage()));
        }
    }

    // 手机前端添加课程的排课画面：从学生档案表视图中取得该学生正在上的所有科目信息
    // @CrossOrigin(origins = "*") 
    @GetMapping("/mb_kn_latest_subjects/{stuId}")
    public ResponseEntity<List<Kn03D004StuDocBean>> getLatestSubjectListByStuId(@PathVariable("stuId") String stuId) {
        List<Kn03D004StuDocBean> subjectList = kn03D004StuDocDao.getLatestSubjectListByStuId(stuId);
        return ResponseEntity.ok(subjectList);
    }

    private String validateHasError(Kn01L002LsnBean knStuLsn001Bean) {
        String errMsg = "";

        // 确认是不是有效的排课日期
        Kn03D004StuDocBean docBeanForDate = kn03D004StuDocDao.getLatestMinAdjustDateByStuId(knStuLsn001Bean.getStuId(), knStuLsn001Bean.getSubjectId());
        // 如果不符合排课日期大于学生档案里第一次的调整日期（第一次入档可以上课的日期），则禁止排课操作
        if (DateUtils.compareDatesMethod2(docBeanForDate.getAdjustedDate(), knStuLsn001Bean.getSchedualDate()) == false) {
            // 定义目标日期格式
            SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd");
            errMsg = "排课操作被禁止：该生的排课请在【" + formatter.format(docBeanForDate.getAdjustedDate()) + "】以后执行排课！";
        }

        // 获取该生一整节课的分钟数
        Integer lsnMinutes = kn01L002LsnDao.getMinutesPerLsn(knStuLsn001Bean.getStuId(), knStuLsn001Bean.getSubjectId());
        // 月计划，课结算的制约：必须按1整节课排课
        if ((knStuLsn001Bean.getLessonType() == 0 || knStuLsn001Bean.getLessonType() == 1) 
                                            && !(knStuLsn001Bean.getClassDuration() == lsnMinutes)) {
            String lsnType = knStuLsn001Bean.getLessonType() == 1 ? "月计划" : "课结算";
            errMsg = "排课操作被禁止：【" + lsnType +"】必须按1整节课【" + lsnMinutes + "】分钟排课。\n 要想排小于1节课的零碎课，请选择「月加课」的排课方式。";
        }

        // 月加课的制约：不得超过1节整课
        if ((knStuLsn001Bean.getLessonType() == 2) 
                            && (knStuLsn001Bean.getClassDuration() > lsnMinutes)) {
            String lsnType = "月加课";
            errMsg = "排课操作被禁止：【" + lsnType +"】必须按小于等于1整节课【" + lsnMinutes + "】分钟来排课";
        }
        return errMsg;
    }

    /**
     * [Bug Fix 2026-02-11] 解析整数值（兼容String和Number输入）
     * 前端通过jQuery val()获取的值是String，但后端需要Integer
     * @param value 可能是String或Number
     * @return 解析后的整数值，如果解析失败返回null
     */
    private Integer parseInteger(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        if (value instanceof String) {
            try {
                return Integer.parseInt((String) value);
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

}
