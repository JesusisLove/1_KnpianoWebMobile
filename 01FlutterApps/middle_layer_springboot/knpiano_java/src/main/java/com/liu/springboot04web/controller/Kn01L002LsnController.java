package com.liu.springboot04web.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.liu.springboot04web.bean.Kn01L002LsnBean;
import com.liu.springboot04web.bean.Kn03D004StuDocBean;
import com.liu.springboot04web.constant.KNConstant;
import com.liu.springboot04web.dao.Kn01L002LsnDao;
import com.liu.springboot04web.dao.Kn03D004StuDocDao;
import com.liu.springboot04web.othercommon.DateUtils;
import com.liu.springboot04web.service.ComboListInfoService;

import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.Year;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import javax.servlet.http.HttpSession;

@Controller
@Service
public class Kn01L002LsnController{
    private final ComboListInfoService combListInfo;
    final List<String> knYear; 
    final List<String> knMonth;
    // 把要付费的学生信息拿到前台画面，给学生下拉列表框做初期化
    Collection<Kn01L002LsnBean> lsnStuList;

    @Autowired
    private Kn01L002LsnDao knLsn001Dao;
    @Autowired
    private Kn03D004StuDocDao kn03D002StuDocDao;

    public Kn01L002LsnController(ComboListInfoService combListInfo) {
        // 通过构造器注入方式接收ComboListInfoService的一个实例，获得application.properties里配置的上课时长数组
        this.combListInfo = combListInfo;
        // 初期化年度下拉列表框
        this.knYear = DateUtils.getYearList();

        // 初期化月份下拉列表框
        this.knMonth = combListInfo.getMonths();
        this.lsnStuList = null;
    }

    // 【KNPiano后台维护 课程信息管理】ボタンをクリック
    @GetMapping("/kn_lsn_001_all")
    public String list(Model model, HttpSession session) {
        /* 获取课费明细一览 */
        LocalDate currentDate = LocalDate.now();// 获取当前日期
        // 格式化为 yyyy
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy");
        String year = currentDate.format(formatter);

        // 画面检索条件保持变量初始化前端检索部
        // model.addAttribute("lsnMap", backForwordMap);

        // 用保持变量里的检索条件从DB里抽取数据
        Collection<Kn01L002LsnBean> collection = knLsn001Dao.getInfoList(year);
        this.lsnStuList = collection;

        // 2025-11-03 将学生下拉列表框信息保存到Session会话中，以便其他操作可以使用（签到，删除，撤销操作之后的页面重定向）
        session.setAttribute("lsnStuList", collection);

        for (Kn01L002LsnBean bean:collection) {
            setButtonUsable(bean);
        }
        model.addAttribute("infoList",collection);

        // 利用resultsTabStus的学生名，在前端页面做Tab
        Map<String, String> resultsTabStus = getResultsTabStus(collection);
        model.addAttribute("resultsTabStus", resultsTabStus);

        /* 初始化画面检索部 */
        // 把要付费的学生信息拿到前台画面，给学生下拉列表框做初期化
        model.addAttribute("lsnStuList", lsnStuList);

        // 年度下拉列表框初期化前台页面
        int currentYear = Year.now().getValue();
        model.addAttribute("currentyear", currentYear);
        model.addAttribute("knyearlist", knYear);
        // 月份下拉列表框初期化前台页面
        String currentMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("MM"));
        model.addAttribute("currentmonth", currentMonth);
        model.addAttribute("knmonthlist", knMonth);

        return "kn_lsn_001/knlsn001_list";
    }

    // 【検索部】検索ボタンを押下
    /**
     * 
     * @param queryParams
     * @param session 使用session的目的是因为，撤销操作，删除操作，签到操作完之后都重定向到该请求
     * @param model
     * @return
     */
    @GetMapping("/kn_lsn_001/search")
    public String search(@RequestParam Map<String, Object> queryParams, HttpSession session, Model model) {

        // 2025-11-03 将搜索条件保存到会话中，以便其他操作可以使用（签到，删除，撤销操作之后的页面重定向）
        session.setAttribute("lastSearchParams", new HashMap<>(queryParams));

        // 把画面传来的年和月拼接成yyyy-mm的
        Map<String, Object> params = new HashMap<>();
        String lsnMonth = (String) queryParams.get("selectedmonth");
        String lsnYear = (String) queryParams.get("selectedyear");

        // 🔧 2026-01-08 修复：根据用户选择的年度重新查询学生列表，确保年度联动正确
        // 从Session里获取缓存的学生列表和年度
        @SuppressWarnings("unchecked")
        Collection<Kn01L002LsnBean> lsnStuList = (Collection<Kn01L002LsnBean>)
            session.getAttribute("lsnStuList");
        String cachedYear = (String) session.getAttribute("lsnStuListYear");

        // 如果缓存为空，或者年度发生变化，则重新查询
        if (lsnStuList == null || !lsnYear.equals(cachedYear)) {
            lsnStuList = knLsn001Dao.getInfoList(lsnYear);
            session.setAttribute("lsnStuList", lsnStuList);
            session.setAttribute("lsnStuListYear", lsnYear);
        }
        if ( !("ALL".equals(lsnMonth))) {
            int month = Integer.parseInt(lsnMonth); // 将月份转换为整数类型
            lsnMonth = String.format("%02d", month); // 格式化为两位数并添加前导零
            params.put("lsn_month", queryParams.get("selectedyear") + "-" + lsnMonth);
        } else {
            params.put("lsn_month", queryParams.get("selectedyear"));
        }
        // 已签到：1   未签到：0   所有课：空值
        params.put("lsn_status",queryParams.get("lsnSignFlg")==""?"-1":queryParams.get("lsnSignFlg"));

        // 检索条件
         params.put("stu_id", queryParams.get("stuId"));
 
         // 回传参数设置（画面检索部的查询参数）
         Map<String, Object> backForwordMap = new HashMap<>();
         backForwordMap.putAll(queryParams);
         model.addAttribute("lsnMap", backForwordMap);
         model.addAttribute("currentyear", lsnYear);
         model.addAttribute("knyearlist", knYear);
         model.addAttribute("currentmonth", lsnMonth);
         model.addAttribute("knmonthlist", knMonth);
         model.addAttribute("lsnStuList", lsnStuList);

        // 将queryParams传递给Service层或Mapper接口
        Collection<Kn01L002LsnBean> searchResults = knLsn001Dao.searchLessons(params);

        for (Kn01L002LsnBean bean:searchResults) {
            setButtonUsable(bean);
        }
        model.addAttribute("infoList", searchResults);

        // 利用resultsTabStus的学生名，在前端页面做Tab
        Map<String, String> resultsTabStus = getResultsTabStus(searchResults);
        model.addAttribute("resultsTabStus", resultsTabStus);

        return "kn_lsn_001/knlsn001_list"; // 返回只包含搜索结果表格部分的Thymeleaf模板
    }

    // 【一覧画面】新規登録ボタンを押下
    @GetMapping("/kn_lsn_001")
    public String toInfoAdd(Model model) {

        // 从学生档案信息表里，把已经开课了的学生姓名以及Ta正在上的科目名取出来，初期化新规/变更画面的科目下拉列表框
        model.addAttribute("stuSubList", getStuSubList());

        final List<String> durations = combListInfo.getDurations();
        model.addAttribute("duration",durations );
        return "kn_lsn_001/knlsn001_add_update";
    }

    // 【一覧画面明细部】編集ボタンを押下
    @GetMapping("/kn_lsn_001/{id}")
    public String toInfoEdit(@PathVariable("id") String id, Model model) {
  
        Kn01L002LsnBean knLsn001Bean = knLsn001Dao.getInfoById(id);
        model.addAttribute("selectedinfo", knLsn001Bean);
        
        final List<String> durations = combListInfo.getDurations();
        model.addAttribute("duration", durations);
        return "kn_lsn_001/knlsn001_add_update";
    }

    // 【一覧画面明细部】削除ボタンを押下
    @DeleteMapping("/kn_lsn_001/{id}")
    public String excuteInfoDelete(@PathVariable("id") String id,
                                    RedirectAttributes redirectAttributes,
                                    HttpSession session) {
        knLsn001Dao.delete(id);
        /* 2025-11-03 重定向到search方法 修正开始 */
        // return "redirect:/kn_lsn_001_all";
        // 从会话中恢复上次的搜索参数
        return redirectToSrarch(session, redirectAttributes);
        /* 2025-11-03 重定向到search方法 修正结束 */
    }

    // 【一覧画面明细部】签到ボタンを押下
    @GetMapping("/kn_lsn_001_lsn_sign/{lessonid}")
    public String lessonSign(@PathVariable("lessonid") String id, 
                             RedirectAttributes redirectAttributes,
                             HttpSession session) {
        // 拿到该课程信息
        Kn01L002LsnBean knLsn001Bean = knLsn001Dao.getInfoById(id);
        
        // 执行签到
        knLsn001Dao.excuteSign(knLsn001Bean);

        /* 2025-11-03 重定向到search方法 修正开始 */
        // return "redirect:/kn_lsn_001_all";
        // 从会话中恢复上次的搜索参数
        return redirectToSrarch(session, redirectAttributes);
        /* 2025-11-03 重定向到search方法 修正结束 */
    }

    // 【一覧画面明细部】撤销ボタンを押下
    @GetMapping("/kn_lsn_001_lsn_undo/{lessonid}")
    public String lessonUndo(@PathVariable("lessonid") String id,
                             RedirectAttributes redirectAttributes,
                             HttpSession session) {
    
        // 拿到该课程信息
        Kn01L002LsnBean knLsn001Bean = knLsn001Dao.getInfoById(id);
        // 撤销签到登记
        knLsn001Dao.excuteUndo(knLsn001Bean);

        /* 2025-11-03 重定向到search方法 修正开始 */
        // return "redirect:/kn_lsn_001_all";
        // 从会话中恢复上次的搜索参数
        return redirectToSrarch(session, redirectAttributes);
        /* 2025-11-03 重定向到search方法 修正结束 */
    }

    // 【一覧画面明细部】备注ボタンを押下
    @GetMapping("/kn_lsn_001_lsn_memo/{lessonid}")
    public String lessonMemo(@PathVariable("lessonid") String id, Model model) {

        // 拿到该课程信息
        // Kn01L002LsnBean knLsn001Bean = knLsn001Dao.getInfoById(id);
        // 备注更新
        
        return "redirect:/kn_lsn_001_all";
    }

    // 【新規登録】画面にて、【保存】ボタンを押下
    @PostMapping("/kn_lsn_001")
    public String excuteInfoAdd(Model model, Kn01L002LsnBean knLsn001Bean) {
        // 画面数据有效性校验
        if (validateHasError(model, knLsn001Bean)) {
            return "kn_lsn_001/knlsn001_add_update";
        }
        knLsn001Dao.save(knLsn001Bean);
        return "redirect:/kn_lsn_001_all";
    }

    // 【変更編集】画面にて、【保存】ボタンを押下
    @PutMapping("/kn_lsn_001")
    public String excuteInfoEdit(Model model, @ModelAttribute Kn01L002LsnBean knLsn001Bean) {
        // 画面数据有效性校验
        if (validateHasError(model, knLsn001Bean)) {
            return "kn_lsn_001/knlsn001_add_update";
        }
        knLsn001Dao.save(knLsn001Bean);
        return "redirect:/kn_lsn_001_all";
    }

    // 从学生档案信息表里，把已经开课了的学生姓名以及Ta正在上的科目名取出来
    private List<Kn03D004StuDocBean> getStuSubList() {
        List<Kn03D004StuDocBean> list = kn03D002StuDocDao.getLatestSubjectList();
        return list;
    }

    // 从结果集中去除掉重复的星期，前端页面脚本以此定义tab名
    private Map<String, String> getResultsTabStus(Collection<Kn01L002LsnBean> collection) {
        // 首先创建一个用于去重的Map
        Map<String, String> tempMap = new HashMap<>();
        
        // 填充临时Map
        for (Kn01L002LsnBean bean : collection) {
            tempMap.putIfAbsent(bean.getStuId(), bean.getStuName());
        }
        
        // 按值（学生姓名）排序并收集到新的LinkedHashMap中
        return tempMap.entrySet()
                .stream()
                .sorted(Map.Entry.comparingByValue())
                .collect(Collectors.toMap(
                    Map.Entry::getKey,
                    Map.Entry::getValue,
                    (oldValue, newValue) -> oldValue,  // 处理重复键的情况
                    LinkedHashMap::new  // 使用LinkedHashMap保持排序
                ));
    }

    // 给后台页面上课一览明细部的按钮设置活性非活性状态
     public Kn01L002LsnBean setButtonUsable(Kn01L002LsnBean bean) {
        int lessonType = bean.getLessonType();
        boolean hasPlannedDate = bean.getSchedualDate() != null;
        boolean hasActualDate = bean.getScanQrDate() != null;
        boolean hasAdditionalToPlannedDate = bean.getExtraToDurDate() != null;

        // 初始化按钮状态
        bean.setUsableEdit(false);
        bean.setUsableDelete(false);
        bean.setUsableSign(false);
        bean.setUsableCancel(false);

        if (lessonType == KNConstant.CONSTANT_LESSON_TYPE_MONTHLY_SCHEDUAL 
            || lessonType == KNConstant.CONSTANT_LESSON_TYPE_TIAMLY) { // 计划课
            if (!hasActualDate) {
                // #1 未开始上课
                bean.setUsableEdit(true);
                bean.setUsableDelete(true);
                bean.setUsableSign(true);
                bean.setUsableCancel(false);
            } else if (hasPlannedDate && hasActualDate) {
                // 按照调课后的日期上课完了
                bean.setUsableEdit(false);
                bean.setUsableDelete(false);
                bean.setUsableSign(false);
                if (bean.isToday(bean.getScanQrDate())){
                    // 当日撤销可
                    bean.setUsableCancel(true);
                } else {
                    // 次日以后撤销不可
                    bean.setUsableCancel(false);
                }
            } 
        } else if (lessonType == KNConstant.CONSTANT_LESSON_TYPE_MONTHLY_ADDITIONAL) { // 追加课
            if (!hasActualDate && !hasAdditionalToPlannedDate) {
                bean.setUsableEdit(true);
                bean.setUsableDelete(true);
                bean.setUsableSign(true);
                bean.setUsableCancel(false);
            } else if (hasPlannedDate && hasActualDate && !hasAdditionalToPlannedDate) {
                bean.setUsableEdit(true);
                bean.setUsableDelete(false);
                bean.setUsableSign(false);
                if (bean.isToday(bean.getScanQrDate())){
                    // 当日撤销可
                    bean.setUsableCancel(true);
                } else {
                    // 次日以后撤销不可
                    bean.setUsableCancel(false);
                }
            } else if (hasPlannedDate  && hasActualDate && hasAdditionalToPlannedDate) {
                bean.setUsableEdit(true);
                bean.setUsableDelete(false);
                bean.setUsableSign(false);
                bean.setUsableCancel(false);
            } 
        }
        return bean;
    }

    private boolean validateHasError(Model model, Kn01L002LsnBean knLsn001Bean) {
        boolean hasError = false;
        List<String> msgList = new ArrayList<String>();
        hasError = inputDataHasError(knLsn001Bean, msgList);
        if (hasError == true) {
            // 新规画面下拉列表框项目内容初始化
            model.addAttribute("stuSubList", getStuSubList());

            final List<String> durations = combListInfo.getDurations();
            model.addAttribute("duration",durations );

            // 将错误消息显示在画面上
            model.addAttribute("errorMessageList", msgList);
            model.addAttribute("selectedinfo", knLsn001Bean);
        }
        return hasError;
    }

    private boolean inputDataHasError(Kn01L002LsnBean knLsn001Bean, List<String> msgList) {
        if (knLsn001Bean.getStuId()==null || knLsn001Bean.getStuId().isEmpty() ) {
            msgList.add("请选择学生姓名");
        }

        if (knLsn001Bean.getSubjectId() == null || knLsn001Bean.getSubjectId().isEmpty()) {
            msgList.add("请选择科目名称");
        }

        if (knLsn001Bean.getSchedualDate() == null) {
            msgList.add("请选择计划上课日期");
        }

        if (knLsn001Bean.getClassDuration() == null || knLsn001Bean.getClassDuration() == 0) {
            msgList.add("请选择上课时长");
        }

        // 确认是不是有效的排课日期
        Kn03D004StuDocBean docBeanForDate = kn03D002StuDocDao.getLatestMinAdjustDateByStuId(knLsn001Bean.getStuId(), knLsn001Bean.getSubjectId());
        // 如果不符合排课日期大于学生档案里第一次的调整日期（第一次入档可以上课的日期），则禁止排课操作
        if (DateUtils.compareDatesMethod2(docBeanForDate.getAdjustedDate(), knLsn001Bean.getSchedualDate()) == false) {
            // 定义目标日期格式
            SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd");
            msgList.add("排课操作被禁止：该生的排课请在【" + formatter.format(docBeanForDate.getAdjustedDate()) + "】以后执行排课！");

        }

        // 获取该生一整节课的分钟数
        Integer lsnMinutes = knLsn001Dao.getMinutesPerLsn(knLsn001Bean.getStuId(), knLsn001Bean.getSubjectId());
        // 月计划，课结算的制约：必须按1整节课排课
        if ((knLsn001Bean.getLessonType() == 0 || knLsn001Bean.getLessonType() == 1) 
                                            && !(knLsn001Bean.getClassDuration() == lsnMinutes)) {
            String lsnType = knLsn001Bean.getLessonType() == 1 ? "月计划" : "课结算";

            msgList.add("排课操作被禁止：【" + lsnType +"】必须按1整节课【" + lsnMinutes + "】分钟排课。\n 要想排小于1节课的零碎课，请选择「月加课」的排课方式。");
        }

        // 月加课的制约：不得超过1节整课
        if ((knLsn001Bean.getLessonType() == 2) 
                            && (knLsn001Bean.getClassDuration() > lsnMinutes)) {
            String lsnType = "月加课";
            msgList.add("排课操作被禁止：【" + lsnType +"】必须按小于等于1整节课【" + lsnMinutes + "】分钟来排课");

        }

        return (msgList.size() != 0);
    }

    // 2025-11-03 签到，删除，撤销操作之后的页面重定向
    private String redirectToSrarch (HttpSession session, RedirectAttributes redirectAttributes) {

        /*
         * 解释用@SuppressWarnings("unchecked")的理由：
         * 因为session.getAttribute()返回的是Object类型，需要转换为Map<String, Object>，
         * 但编译器无法在编译时验证这个转换是否安全，所以使用@SuppressWarnings("unchecked")来抑制这个警告。
         * 通过使用这个注解，可以避免在编译时看到黄色警告线，使代码更清晰。
         * 应当谨慎使用此注解，只有当你确定类型转换是安全的情况下才使用它。
        */
        @SuppressWarnings("unchecked")
        Map<String, Object> lastSearchParams = (Map<String, Object>) session.getAttribute("lastSearchParams");
        
        if (lastSearchParams != null) {
            // 将参数添加到重定向URL
            for (Map.Entry<String, Object> entry : lastSearchParams.entrySet()) {
                redirectAttributes.addAttribute(entry.getKey(), entry.getValue());
            }
        } else {
            // 如果没有保存的搜索参数，添加默认值
            LocalDate currentDate = LocalDate.now();
            String currentYear = String.valueOf(currentDate.getYear());
            String currentMonth = currentDate.format(DateTimeFormatter.ofPattern("MM"));
            
            redirectAttributes.addAttribute("selectedyear", currentYear);
            redirectAttributes.addAttribute("selectedmonth", currentMonth);
        }
        
        return "redirect:/kn_lsn_001/search";
    }
}
