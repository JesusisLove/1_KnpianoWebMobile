package com.liu.springboot04web.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import com.liu.springboot04web.bean.Kn03D004StuDocBean;
import com.liu.springboot04web.bean.Kn05S001LsnFixBean;
import com.liu.springboot04web.dao.Kn03D004StuDocDao;
import com.liu.springboot04web.dao.Kn05S001LsnFixDao;
import com.liu.springboot04web.othercommon.CommonProcess;
import com.liu.springboot04web.service.ComboListInfoService;
import com.liu.springboot04web.service.conflict.ConflictCheckService;

import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;

@Controller
@Service
public class Kn05S001LsnFixController {
    private ComboListInfoService combListInfo;
    private String activeDay;

    @Autowired
    private Kn05S001LsnFixDao knFixLsn001Dao;
    @Autowired
    private Kn03D004StuDocDao kn03D002StuDocDao;
    // [固定排课新潮版 Web端] 2026-03-20 冲突检测公共服务
    @Autowired
    private ConflictCheckService conflictCheckService;
    
    public Kn05S001LsnFixController(ComboListInfoService combListInfo) {
        this.combListInfo = combListInfo;
    }

    // [固定排课新潮版 Web端] 2026-03-21 网格局部刷新专用JSON接口（保存后AJAX刷新网格，避免整页reload）
    @GetMapping("/kn_fixlsn_001_json")
    @ResponseBody
    public Collection<Kn05S001LsnFixBean> listJson() {
        return knFixLsn001Dao.getInfoList();
    }

    // 【KNPiano后台维护 固定课时信息】ボタンをクリック
    @GetMapping("/kn_fixlsn_001_all")
    public String list(Model model) {
        // 学生固定排课一览取得
        Collection<Kn05S001LsnFixBean> searchResults = knFixLsn001Dao.getInfoList();
        model.addAttribute("fixedLessonList", searchResults);

        List<String> resultsTabDays = CommonProcess.sortWeekdays(getResultsTabDays(searchResults));
        model.addAttribute("resultsTabDays", resultsTabDays);
        model.addAttribute("activeDay", (this.activeDay!=null)? this.activeDay : "Mon");

        return "kn_fixlsn_001/knfixlsn001_list";
    }

    // 【明细検索一覧】検索ボタンを押下
    @GetMapping("/kn_fixlsn_001/search")
    public String search(@RequestParam Map<String, Object> queryParams, Model model) {
        // 回传参数设置（画面检索部的查询参数）
        Map<String, Object> backForwordMap = new HashMap<>();
        backForwordMap.putAll(queryParams);
        model.addAttribute("fixedLessonMap", backForwordMap);

        /* 对Map里的key值做转换更改：将Bean的项目值改成表字段的项目值。例如: stuId改成stu_id
           目的是，这个Map要传递到KnFixLsn001Mapper.xml哪里做SQL的Where的查询条件 */
        Map<String, Object> conditions = CommonProcess.convertToSnakeCase(queryParams);

        // 将queryParams传递给Service层或Mapper接口
        Collection<Kn05S001LsnFixBean> searchResults = knFixLsn001Dao.searchFixedLessons(conditions);
        model.addAttribute("fixedLessonList", searchResults);

        List<String> resultsTabDays = CommonProcess.sortWeekdays(getResultsTabDays(searchResults));
        model.addAttribute("resultsTabDays", resultsTabDays);
        // 学生一周有复数天的排课，则默认显示第一个卡片（从Mon到Sun）
        model.addAttribute("activeDay", resultsTabDays.size()>0?resultsTabDays.get(0):"");

        return "kn_fixlsn_001/knfixlsn001_list"; // 返回只包含搜索结果表格部分的Thymeleaf模板
    }

    // [固定排课新潮版 Web端] 2026-03-20 新潮版网格专用JSON保存端点（带冲突检测）
    // 用于 knfixlsn001_list.html 新潮版的 Quick Add / Add Modal / Edit Modal / 拖拽 操作
    @PostMapping("/kn_fixlsn_001_grid")
    @ResponseBody
    public ResponseEntity<Map<String, Object>> executeFixedLessonGridSave(
            @RequestBody Kn05S001LsnFixBean knFixLsn001Bean) {

        String originalFixedWeek = knFixLsn001Bean.getOriginalFixedWeek();
        boolean addNewMode = (originalFixedWeek == null || originalFixedWeek.isEmpty());

        Boolean forceOverlap = knFixLsn001Bean.getForceOverlap();
        if (forceOverlap == null) forceOverlap = false;

        // 冲突检测
        if (!forceOverlap) {
            Integer classDuration = knFixLsn001Bean.getClassDuration();

            String excludeStuId    = addNewMode ? null : knFixLsn001Bean.getStuId();
            String excludeSubjectId = addNewMode ? null : knFixLsn001Bean.getSubjectId();

            List<Kn05S001LsnFixBean> conflictLessons = knFixLsn001Dao.findConflictLessons(
                    knFixLsn001Bean.getFixedWeek(),
                    knFixLsn001Bean.getFixedHour(),
                    knFixLsn001Bean.getFixedMinute(),
                    classDuration,
                    excludeStuId,
                    excludeSubjectId);

            if (conflictLessons != null && !conflictLessons.isEmpty()) {
                Map<String, Object> conflictResponse = conflictCheckService.buildConflictResponse(
                        conflictLessons, knFixLsn001Bean.getStuId());
                return conflictCheckService.toResponseEntity(conflictResponse);
            }
        }

        // 无冲突或强制保存，执行保存
        if (addNewMode) {
            // [BUG Fix 2026-03-21] 预检查：同一学生+同科目+同星期已存在时，返回可读错误提示
            // （原来依赖DataIntegrityViolationException静默捕获，用户感知为"无反应"）
            Kn05S001LsnFixBean existingLesson = knFixLsn001Dao.getInfoByKey(
                    knFixLsn001Bean.getStuId(),
                    knFixLsn001Bean.getSubjectId(),
                    knFixLsn001Bean.getFixedWeek());
            if (existingLesson != null) {
                Map<String, Object> errResponse = new HashMap<>();
                errResponse.put("success", false);
                errResponse.put("hasConflict", false);
                errResponse.put("message", "该学生的同一科目在 " + knFixLsn001Bean.getFixedWeek() + " 已有固定排课，不能重复添加。");
                return ResponseEntity.ok(errResponse);
            }
            try {
                knFixLsn001Dao.save(knFixLsn001Bean, true);
            } catch (DataIntegrityViolationException e) {
                // 竞争条件安全网：并发INSERT同一主键时静默忽略
            }
        } else if (originalFixedWeek != null && !originalFixedWeek.isEmpty()) {
            // 拖拽/编辑星期变更时，检查目标槽位是否已被自身占用
            if (!knFixLsn001Bean.getFixedWeek().equals(originalFixedWeek)) {
                Kn05S001LsnFixBean existingAtTarget = knFixLsn001Dao.getInfoByKey(
                        knFixLsn001Bean.getStuId(),
                        knFixLsn001Bean.getSubjectId(),
                        knFixLsn001Bean.getFixedWeek());
                if (existingAtTarget != null) {
                    Map<String, Object> conflictResponse = conflictCheckService.buildConflictResponse(
                            Collections.singletonList(existingAtTarget), knFixLsn001Bean.getStuId());
                    return conflictCheckService.toResponseEntity(conflictResponse);
                }
            }
            knFixLsn001Dao.save(knFixLsn001Bean, false, originalFixedWeek);
        } else {
            knFixLsn001Dao.save(knFixLsn001Bean, false);
        }

        // [固定排课新潮版 Web端] 2026-03-21 保存成功时在响应中附带最新课程列表，供前端直接刷新网格
        Map<String, Object> successResponse = conflictCheckService.buildSuccessResponse();
        successResponse.put("lessonList", knFixLsn001Dao.getInfoList());
        return conflictCheckService.toResponseEntity(successResponse);
    }

    // 【明細検索一覧】新規登録ボタンを押下
    @GetMapping("/kn_fixlsn_001")
    public String toFixedLessonAdd(Model model) {
        // 告诉前端画面，这是新规登录模式
        model.addAttribute("isAddNewMode", true);

        // 从学生档案信息表里，把已经开课了的学生姓名以及Ta正在上的科目名取出来，初期化新规/变更画面的科目下拉列表框
        model.addAttribute("stuSubList", getStuSubList());

        // 初期化星期下拉列表框
        final List<String> regularWeek = combListInfo.getRegularWeek();
        model.addAttribute("regularweek",regularWeek );

        // 初期化固定上课时间几点的下拉列表框
        final List<String> regularHour = combListInfo.getRegularHour();
        model.addAttribute("regularhour",regularHour );
        
        // 初期化固定上课时间几分的下拉列表框
        final List<String> regularMinute = combListInfo.getRegularMinute();
        model.addAttribute("regularminute",regularMinute );

        return "kn_fixlsn_001/knfixlsn001_add_update";
    }

    // 【新規登録】画面にて、【保存】ボタンを押下
    @PostMapping("/kn_fixlsn_001")
    public String executeFixedLessonAdd(Kn05S001LsnFixBean knFixLsn001Bean, Model model) {
        // 因为是复合主键，只能通过从表里抽出记录来确定是新规操作还是更新操作
        boolean addNewMode = false;
        if (knFixLsn001Dao.getInfoByKey(knFixLsn001Bean.getStuId(), 
                                        knFixLsn001Bean.getSubjectId(), 
                                        knFixLsn001Bean.getFixedWeek()) == null) {
            // 前端画面在数据校验的时候，需要知道从后端传来的是新规登录模式还是变更编辑模式
            addNewMode = true;
        }

        // 画面数据有效性校验
        if (validateHasError(model, knFixLsn001Bean, addNewMode)) {
            return "kn_fixlsn_001/knfixlsn001_add_update";
        }

        // 执行新规登录操作
        knFixLsn001Dao.save(knFixLsn001Bean, addNewMode);
        this.activeDay = knFixLsn001Bean.getFixedWeek();
        return "redirect:/kn_fixlsn_001_all";
    }

    // 【明细検索一覧】編集ボタンを押下
    @GetMapping("/kn_fixlsn_001/{stuId}/{subjectId}/{fixedWeek}")
    public String toFixedLessonEdit(@PathVariable("stuId") String stuId, 
                                    @PathVariable("subjectId") String subjectId, 
                                    @PathVariable("fixedWeek") String fixedWeek, 
                                    Model model) {
        // 告诉前端画面，这是变更编辑模式
        model.addAttribute("isAddNewMode", false);

        Kn05S001LsnFixBean knFixLsn001Bean = knFixLsn001Dao.getInfoByKey(stuId, subjectId, fixedWeek);
        model.addAttribute("selectedFixedLesson", knFixLsn001Bean);

        // [固定排课排他功能] 2026-03-20 编辑模式也需要stuSubList用于冲突检测时长计算
        model.addAttribute("stuSubList", getStuSubList());

        final List<String> regularWeek = combListInfo.getRegularWeek();
        model.addAttribute("regularweek",regularWeek );

        final List<String> regularHour = combListInfo.getRegularHour();
        model.addAttribute("regularhour",regularHour );

        final List<String> regularMinute = combListInfo.getRegularMinute();
        model.addAttribute("regularminute",regularMinute );
        model.addAttribute("activeDay",knFixLsn001Bean.getFixedWeek() );

        return "kn_fixlsn_001/knfixlsn001_add_update";
    }

    // 【変更編集】画面にて、【保存】ボタンを押下
    @PutMapping("/kn_fixlsn_001")
    public String executeFixedLessonEdit(Kn05S001LsnFixBean knFixLsn001Bean, Model model) {
        // 从表单中获取原始星期几
        String originalFixedWeek = knFixLsn001Bean.getOriginalFixedWeek();

        // 判断是新增还是更新
        boolean addNewMode = false;
        if (originalFixedWeek != null && !originalFixedWeek.isEmpty()) {
            // 使用原始星期几判断记录是否存在
            if (knFixLsn001Dao.getInfoByKey(knFixLsn001Bean.getStuId(),
                                            knFixLsn001Bean.getSubjectId(),
                                            originalFixedWeek) == null) {
                addNewMode = true;
            }
        } else {
            // 如果没有原始星期几，按照旧逻辑判断
            if (knFixLsn001Dao.getInfoByKey(knFixLsn001Bean.getStuId(),
                                            knFixLsn001Bean.getSubjectId(),
                                            knFixLsn001Bean.getFixedWeek()) == null) {
                addNewMode = true;
            }
        }

        // 画面数据有效性校验
        if (validateHasError(model, knFixLsn001Bean, addNewMode)) {
            return "kn_fixlsn_001/knfixlsn001_add_update";
        }

        // 执行变更编辑操作
        knFixLsn001Dao.save(knFixLsn001Bean, addNewMode, originalFixedWeek);

        // 重要：使用原始星期几设置activeDay，让页面停留在原来的Tab页
        this.activeDay = (originalFixedWeek != null && !originalFixedWeek.isEmpty())
                         ? originalFixedWeek
                         : knFixLsn001Bean.getFixedWeek();
        return "redirect:/kn_fixlsn_001_all";
    }

    // 【明细検索一覧】削除ボタンを押下
    @DeleteMapping("/kn_fixlsn_001/{stuId}/{subjectId}/{fixedWeek}")
    public String executeFixedLessonDelete (@PathVariable("stuId") String stuId, 
                                            @PathVariable("subjectId") String subjectId, 
                                            @PathVariable("fixedWeek") String fixedWeek, 
                                            Model model) {
        knFixLsn001Dao.deleteByKeys(stuId, subjectId, fixedWeek);
        this.activeDay = fixedWeek;
        return "redirect:/kn_fixlsn_001_all";
    }

    // 从学生档案信息表里，把已经开课了的学生姓名以及Ta正在上的科目名取出来
    private List<Kn03D004StuDocBean> getStuSubList() {
        List<Kn03D004StuDocBean> list = kn03D002StuDocDao.getLatestSubjectList();
        return list;
    }

    // 从结果集中去除掉重复的星期，前端页面脚本以此定义tab名
    private List<String> getResultsTabDays(Collection<Kn05S001LsnFixBean> collection) {

        List<String> activeDaysList = new ArrayList<>();
        for (Kn05S001LsnFixBean bean : collection) {
            activeDaysList.add(bean.getFixedWeek());
        }
        return CommonProcess.removeDuplicates(activeDaysList) ;
    }

    private boolean validateHasError(Model model, Kn05S001LsnFixBean knFixLsn001Bean, boolean addNewMode) {
        boolean hasError = false;
        List<String> msgList = new ArrayList<String>();
        hasError = inputDataHasError(knFixLsn001Bean, msgList);
        if (hasError == true) {
            // 从学生档案信息表里，把已经开课了的学生姓名以及Ta正在上的科目名取出来，初期化新规/变更画面的科目下拉列表框
            model.addAttribute("stuSubList", getStuSubList());

            // 初期化星期下拉列表框
            final List<String> regularWeek = combListInfo.getRegularWeek();
            model.addAttribute("regularweek",regularWeek );

            // 初期化固定上课时间几点的下拉列表框
            final List<String> regularHour = combListInfo.getRegularHour();
            model.addAttribute("regularhour",regularHour );
            
            // 初期化固定上课时间几分的下拉列表框
            final List<String> regularMinute = combListInfo.getRegularMinute();
            model.addAttribute("regularminute",regularMinute );

            model.addAttribute("selectedFixedLesson", knFixLsn001Bean);
            // 告诉前端画面当前的模式是新规登录还是变更编辑模式
            model.addAttribute("isAddNewMode", addNewMode);

            // 将错误消息显示在画面上
            model.addAttribute("errorMessageList", msgList);
            model.addAttribute("selectedinfo", knFixLsn001Bean);
        }
        return hasError;
    }

    private boolean inputDataHasError(Kn05S001LsnFixBean knFixLsn001Bean, List<String> msgList) {
        if (knFixLsn001Bean.getStuId()==null || knFixLsn001Bean.getStuId().isEmpty() ) {
            msgList.add("请选择学生姓名");
        }

        if (knFixLsn001Bean.getSubjectId() == null || knFixLsn001Bean.getSubjectId().isEmpty()) {
            msgList.add("请选择科目名称");
        }

        if (knFixLsn001Bean.getFixedWeek() == null || knFixLsn001Bean.getFixedWeek().isEmpty()) {
            msgList.add("请选择星期");
        }

        if (knFixLsn001Bean.getFixedHour() == null) {
            msgList.add("请选择时");
        }

        if (knFixLsn001Bean.getFixedMinute() == null) {
            msgList.add("请选择分");
        }

        return (msgList.size() != 0);
    }
}