package com.liu.springboot04web.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.liu.springboot04web.bean.Kn01L002ExtraToScheBean;
import com.liu.springboot04web.bean.Kn01L002LsnBean;
import com.liu.springboot04web.bean.Kn03D002SubBean;
import com.liu.springboot04web.dao.Kn01L002ExtraToScheDao;
import com.liu.springboot04web.dao.Kn04I002SubjectOfStudentsDao;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpSession;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.stream.Collectors;

@Controller
public class Kn01L004BatchExtraToScheController {

    private static final String SESSION_SUBJECT_ID   = "batchExtra_subjectId";
    private static final String SESSION_SUBJECT_NAME = "batchExtra_subjectName";
    private static final String SESSION_LEFT_STUS    = "batchExtra_leftStudents";
    private static final String SESSION_RIGHT_STUS   = "batchExtra_rightStudents";
    private static final String SESSION_STEP2_JSON   = "batchExtra_step2Json";
    private static final String SESSION_RESULT       = "batchExtra_result";

    @Autowired
    private Kn01L002ExtraToScheDao extraToScheDao;

    @Autowired
    private Kn04I002SubjectOfStudentsDao subjectDao;

    private final ObjectMapper objectMapper = new ObjectMapper();

    // ─────────────────────────────────────────────
    // 第一步：初始化页面
    // ─────────────────────────────────────────────
    @GetMapping("/kn_batch_extra_to_sche/step1")
    public String step1(HttpSession session, Model model) {
        List<Kn03D002SubBean> subjectList = (List<Kn03D002SubBean>) subjectDao.getInfoList();
        model.addAttribute("subjectList", subjectList);

        // Back 时恢复状态
        model.addAttribute("selectedSubjectId", session.getAttribute(SESSION_SUBJECT_ID));
        model.addAttribute("selectedSubjectName", session.getAttribute(SESSION_SUBJECT_NAME));
        model.addAttribute("leftStudents",  session.getAttribute(SESSION_LEFT_STUS));
        model.addAttribute("rightStudents", session.getAttribute(SESSION_RIGHT_STUS));

        return "kn_batch_extra_to_sche/step1_stu_select";
    }

    // ─────────────────────────────────────────────
    // 第一步：查询在课学生（AJAX）
    // ─────────────────────────────────────────────
    @PostMapping("/kn_batch_extra_to_sche/step1/query")
    @ResponseBody
    public List<Map<String, String>> step1Query(@RequestParam("subjectId") String subjectId,
                                                HttpSession session) {
        List<Kn01L002ExtraToScheBean> stuList = extraToScheDao.getActiveStudentsBySubject(subjectId);

        // 同时把科目信息存入 session，供后续步骤使用
        session.setAttribute(SESSION_SUBJECT_ID, subjectId);

        return stuList.stream().map(s -> {
            Map<String, String> m = new LinkedHashMap<>();
            m.put("stuId",   s.getStuId());
            m.put("stuName", s.getStuName());
            m.put("nikName", s.getNikName() != null ? s.getNikName() : "");
            return m;
        }).collect(Collectors.toList());
    }

    // ─────────────────────────────────────────────
    // 第一步 → 第二步
    // ─────────────────────────────────────────────
    @PostMapping("/kn_batch_extra_to_sche/step2")
    public String step2(@RequestParam(value = "subjectId")               String subjectId,
                        @RequestParam(value = "subjectName", defaultValue = "") String subjectName,
                        @RequestParam(value = "leftStuIds",   required = false) List<String> leftStuIds,
                        @RequestParam(value = "leftStuNames", required = false) List<String> leftStuNames,
                        @RequestParam(value = "rightStuIds",  required = false) List<String> rightStuIds,
                        @RequestParam(value = "rightStuNames",required = false) List<String> rightStuNames,
                        HttpSession session, Model model) throws Exception {

        if (rightStuIds == null || rightStuIds.isEmpty()) {
            model.addAttribute("errorMsg", "请至少选择一名学生");
            return step1(session, model);
        }

        // 保存 Step1 状态到 Session
        session.setAttribute(SESSION_SUBJECT_ID,   subjectId);
        session.setAttribute(SESSION_SUBJECT_NAME, subjectName);
        session.setAttribute(SESSION_LEFT_STUS,  buildStuMapList(leftStuIds,  leftStuNames));
        session.setAttribute(SESSION_RIGHT_STUS, buildStuMapList(rightStuIds, rightStuNames));

        // 查询右侧学生的未消化加课
        List<Kn01L002ExtraToScheBean> extraList = extraToScheDao.getBatchUndigestedExtras(rightStuIds, subjectId);

        // 按学生分组成 Tag 数据
        Map<String, List<Kn01L002ExtraToScheBean>> tagMap = new LinkedHashMap<>();
        for (Kn01L002ExtraToScheBean bean : extraList) {
            tagMap.computeIfAbsent(bean.getStuId(), k -> new ArrayList<>()).add(bean);
        }
        // 保证右侧 List 顺序（即使某学生无未消化加课，也建一个空 tag）
        Map<String, List<Kn01L002ExtraToScheBean>> orderedTagMap = new LinkedHashMap<>();
        for (int i = 0; i < rightStuIds.size(); i++) {
            String sid = rightStuIds.get(i);
            orderedTagMap.put(sid, tagMap.getOrDefault(sid, new ArrayList<>()));
        }

        // 右侧学生姓名 Map（stuId → stuName）
        Map<String, String> stuNameMap = new LinkedHashMap<>();
        for (int i = 0; i < rightStuIds.size(); i++) {
            stuNameMap.put(rightStuIds.get(i), rightStuNames != null && i < rightStuNames.size() ? rightStuNames.get(i) : "");
        }

        // 查询每个学生该科目当年的未签到课程日期（用于Step2下拉快速选择）
        Map<String, List<Kn01L002LsnBean>> unsignedDatesMap = new LinkedHashMap<>();
        for (String sid : rightStuIds) {
            unsignedDatesMap.put(sid, extraToScheDao.getUnsignedLessonDates(sid, subjectId));
        }

        model.addAttribute("subjectId",        subjectId);
        model.addAttribute("subjectName",      subjectName);
        model.addAttribute("tagMap",           orderedTagMap);
        model.addAttribute("stuNameMap",       stuNameMap);
        model.addAttribute("unsignedDatesMap", unsignedDatesMap);
        // 恢复 Step2 已选状态（Back 时）
        model.addAttribute("step2Json", session.getAttribute(SESSION_STEP2_JSON));

        return "kn_batch_extra_to_sche/step2_extra_select";
    }

    // ─────────────────────────────────────────────
    // 从第二步返回第一步（GET：直接跳转；POST：携带step2Json保存状态）
    // ─────────────────────────────────────────────
    @GetMapping("/kn_batch_extra_to_sche/step1/back")
    public String backToStep1Get(HttpSession session, Model model) {
        return step1(session, model);
    }

    @PostMapping("/kn_batch_extra_to_sche/step1/back")
    public String backToStep1Post(@RequestParam(value = "step2Json", required = false) String step2Json,
                                  HttpSession session, Model model) {
        if (step2Json != null && !step2Json.isEmpty()) {
            session.setAttribute(SESSION_STEP2_JSON, step2Json);
        }
        return step1(session, model);
    }

    // ─────────────────────────────────────────────
    // 第二步 → 第三步
    // ─────────────────────────────────────────────
    @PostMapping("/kn_batch_extra_to_sche/step3")
    public String step3(@RequestParam("subjectId")   String subjectId,
                        @RequestParam("subjectName") String subjectName,
                        @RequestParam("step2Json")   String step2Json,
                        HttpSession session, Model model) throws Exception {

        // 保存 Step2 状态到 Session（供 Back 时恢复）
        session.setAttribute(SESSION_STEP2_JSON, step2Json);

        // 解析 JSON：List<{ stuId, stuName, lessons: [{lessonId, schedualDate, classDuration, subjectSubName, targetDate}] }>
        List<Map<String, Object>> step2Data = objectMapper.readValue(step2Json, new TypeReference<List<Map<String, Object>>>() {});

        // 过滤掉 lessons 为空的学生（空卡片不显示）
        List<Map<String, Object>> confirmList = step2Data.stream()
                .filter(d -> {
                    List<?> lessons = (List<?>) d.get("lessons");
                    return lessons != null && !lessons.isEmpty();
                })
                .collect(Collectors.toList());

        int totalLsnCount = confirmList.stream()
                .mapToInt(d -> ((List<?>) d.get("lessons")).size())
                .sum();

        model.addAttribute("subjectId",      subjectId);
        model.addAttribute("subjectName",    subjectName);
        model.addAttribute("confirmList",    confirmList);
        model.addAttribute("totalStuCount",  confirmList.size());
        model.addAttribute("totalLsnCount",  totalLsnCount);
        model.addAttribute("step2Json",      step2Json);

        return "kn_batch_extra_to_sche/step3_confirm";
    }

    // ─────────────────────────────────────────────
    // 从第三步返回第二步
    // ─────────────────────────────────────────────
    @PostMapping("/kn_batch_extra_to_sche/step2/back")
    public String backToStep2(@RequestParam("subjectId")   String subjectId,
                               @RequestParam("subjectName") String subjectName,
                               @RequestParam("step2Json")   String step2Json,
                               HttpSession session, Model model) throws Exception {
        // 将最新的 step2Json 存回 session（恢复 checkbox 状态）
        session.setAttribute(SESSION_STEP2_JSON, step2Json);

        List<String> rightStuIds   = getSessionRightStuIds(session);
        List<String> rightStuNames = getSessionRightStuNames(session);

        return step2(subjectId, subjectName,
                     getSessionLeftStuIds(session),   getSessionLeftStuNames(session),
                     rightStuIds, rightStuNames,
                     session, model);
    }

    // ─────────────────────────────────────────────
    // 批量执行
    // ─────────────────────────────────────────────
    @PostMapping("/kn_batch_extra_to_sche/execute")
    public String execute(@RequestParam("step2Json") String step2Json,
                          HttpSession session) {
        try {
            List<Map<String, Object>> step2Data = objectMapper.readValue(
                    step2Json, new TypeReference<List<Map<String, Object>>>() {});

            // 展开成 Bean 列表
            List<Kn01L002ExtraToScheBean> beanList = new ArrayList<>();
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm");

            for (Map<String, Object> stuData : step2Data) {
                String stuId     = (String) stuData.get("stuId");
                String subjectId = (String) stuData.get("subjectId");
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> lessons = (List<Map<String, Object>>) stuData.get("lessons");
                if (lessons == null) continue;

                for (Map<String, Object> lsn : lessons) {
                    Kn01L002ExtraToScheBean bean = new Kn01L002ExtraToScheBean();
                    bean.setLessonId(  (String) lsn.get("lessonId"));
                    bean.setStuId(     stuId);
                    bean.setSubjectId( subjectId != null ? subjectId : (String) lsn.get("subjectId"));
                    bean.setSubjectSubId((String) lsn.get("subjectSubId"));
                    String targetDateStr = (String) lsn.get("targetDate");
                    bean.setExtraToDurDate(sdf.parse(targetDateStr));
                    beanList.add(bean);
                }
            }

            extraToScheDao.batchExecuteExtraToSche(beanList);

            // 成功
            Map<String, Object> result = new HashMap<>();
            result.put("success",           true);
            result.put("processedStuCount", step2Data.stream().filter(d -> {
                List<?> l = (List<?>) d.get("lessons");
                return l != null && !l.isEmpty();
            }).count());
            result.put("processedLsnCount", beanList.size());
            session.setAttribute(SESSION_RESULT, result);

        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("success",      false);
            result.put("errorMessage", e.getMessage() != null ? e.getMessage() : "系统错误，请联系管理员");
            session.setAttribute(SESSION_RESULT, result);
        }

        return "redirect:/kn_batch_extra_to_sche/result";
    }

    // ─────────────────────────────────────────────
    // 执行结果页面
    // ─────────────────────────────────────────────
    @GetMapping("/kn_batch_extra_to_sche/result")
    public String result(HttpSession session, Model model) {
        @SuppressWarnings("unchecked")
        Map<String, Object> resultMap = (Map<String, Object>) session.getAttribute(SESSION_RESULT);
        if (resultMap == null) {
            return "redirect:/kn_batch_extra_to_sche/step1";
        }
        model.addAttribute("isSuccess",          resultMap.get("success"));
        model.addAttribute("processedStuCount",  resultMap.get("processedStuCount"));
        model.addAttribute("processedLsnCount",  resultMap.get("processedLsnCount"));
        model.addAttribute("errorMessage",       resultMap.get("errorMessage"));
        return "kn_batch_extra_to_sche/result";
    }

    // ─────────────────────────────────────────────
    // 从结果页返回第一步（清空所有 Session）
    // ─────────────────────────────────────────────
    @GetMapping("/kn_batch_extra_to_sche/complete")
    public String complete(HttpSession session) {
        session.removeAttribute(SESSION_SUBJECT_ID);
        session.removeAttribute(SESSION_SUBJECT_NAME);
        session.removeAttribute(SESSION_LEFT_STUS);
        session.removeAttribute(SESSION_RIGHT_STUS);
        session.removeAttribute(SESSION_STEP2_JSON);
        session.removeAttribute(SESSION_RESULT);
        return "redirect:/kn_batch_extra_to_sche/step1";
    }

    // ─────────────────────────────────────────────
    // 工具方法
    // ─────────────────────────────────────────────
    private List<Map<String, String>> buildStuMapList(List<String> ids, List<String> names) {
        List<Map<String, String>> list = new ArrayList<>();
        if (ids == null) return list;
        for (int i = 0; i < ids.size(); i++) {
            Map<String, String> m = new LinkedHashMap<>();
            m.put("stuId",   ids.get(i));
            m.put("stuName", names != null && i < names.size() ? names.get(i) : "");
            list.add(m);
        }
        return list;
    }

    @SuppressWarnings("unchecked")
    private List<String> getSessionRightStuIds(HttpSession session) {
        List<Map<String, String>> rightStus = (List<Map<String, String>>) session.getAttribute(SESSION_RIGHT_STUS);
        if (rightStus == null) return new ArrayList<>();
        return rightStus.stream().map(m -> m.get("stuId")).collect(Collectors.toList());
    }

    @SuppressWarnings("unchecked")
    private List<String> getSessionRightStuNames(HttpSession session) {
        List<Map<String, String>> rightStus = (List<Map<String, String>>) session.getAttribute(SESSION_RIGHT_STUS);
        if (rightStus == null) return new ArrayList<>();
        return rightStus.stream().map(m -> m.get("stuName")).collect(Collectors.toList());
    }

    @SuppressWarnings("unchecked")
    private List<String> getSessionLeftStuIds(HttpSession session) {
        List<Map<String, String>> leftStus = (List<Map<String, String>>) session.getAttribute(SESSION_LEFT_STUS);
        if (leftStus == null) return new ArrayList<>();
        return leftStus.stream().map(m -> m.get("stuId")).collect(Collectors.toList());
    }

    @SuppressWarnings("unchecked")
    private List<String> getSessionLeftStuNames(HttpSession session) {
        List<Map<String, String>> leftStus = (List<Map<String, String>>) session.getAttribute(SESSION_LEFT_STUS);
        if (leftStus == null) return new ArrayList<>();
        return leftStus.stream().map(m -> m.get("stuName")).collect(Collectors.toList());
    }
}
