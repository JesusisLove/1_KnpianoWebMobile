package com.liu.springboot04web.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import com.liu.springboot04web.bean.Kn01L002ExtraToScheBean;
import com.liu.springboot04web.dao.Kn01L002ExtraToScheDao;
import com.liu.springboot04web.othercommon.DateUtils;
import com.liu.springboot04web.service.ComboListInfoService;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Controller
@Service
public class Kn01L002ExtraToScheController {
    final List<String> knYear; 
    final List<String> knMonth;

    // 把要付费的学生信息拿到前台画面，给学生下拉列表框做初期化
    Collection<Kn01L002ExtraToScheBean> extra2ScheStuList;
    @Autowired
    private Kn01L002ExtraToScheDao kn01L002ExtraToScheDao;

    public Kn01L002ExtraToScheController(ComboListInfoService combListInfo) {
        // 初期化年度下拉列表框
        this.knYear = DateUtils.getYearList();

        // 初期化月份下拉列表框
        this.knMonth = combListInfo.getMonths();
        this.extra2ScheStuList = null;
    }

    // 根据Web页面上年度和月份的下拉列表框的变化，实现学生姓名下拉列表框的联动初期化
    @GetMapping("/kn_extra_stu_all/{year}/{month}")
    public String list(@PathVariable("year") String year,@PathVariable("month") String month, Model model) {

        String yearMonth = ("ALL".equals(month)) ? year : year + "-" + month;
        List<Kn01L002ExtraToScheBean> list = kn01L002ExtraToScheDao.getSearchInfo4Stu(yearMonth);
        model.addAttribute("extra2ScheStuList", list);

        // 创建 Map 并添加到 Model
        Map<String, String> extra2ScheMap = new HashMap<>();
        extra2ScheMap.put("selectedyear", year);
        extra2ScheMap.put("selectedmonth", month);
        model.addAttribute("extra2ScheMap", extra2ScheMap);

        model.addAttribute("knyearlist", knYear);
        model.addAttribute("knmonthlist", knMonth);

        return "kn_extra_to_sche_001/kn_extra_list";
    }

    // 【KNPiano后台维护】点击“加课消化管理”画面初期化、初期化条件是系统当前年度（数据库取得最新课程档案信息是以当前年月日为查询基准日）
    @GetMapping("/kn_extratosche_all")
    public String list(Model model) {
        // 画面检索条件保持变量初始化前端检索部
        LocalDate currentDate = LocalDate.now();// 获取当前日期

        // 格式化为 yyyy
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy");
        String year = currentDate.format(formatter);

        // 用保持变量里的检索条件从DB里抽取数据
        Collection<Kn01L002ExtraToScheBean> collection = kn01L002ExtraToScheDao.getInfoList(year);
        extra2ScheStuList = collection;
        model.addAttribute("infoList", collection);

        /* 初始化画面检索部 */
        // 把要消化加课的学生信息拿到前台画面，给学生下拉列表框做初期化
        model.addAttribute("extra2ScheStuList", extra2ScheStuList);

        // 利用resultsTabStus的学生名，在前端页面做Tab
        Map<String, String> resultsTabStus = getResultsTabStus(collection);
        model.addAttribute("resultsTabStus", resultsTabStus);

        // 年度下拉列表框初期化前台页面
        // int currentYear = Year.now().getValue();
        // model.addAttribute("currentyear", currentYear);
        model.addAttribute("knyearlist", knYear);
        
        // 月份下拉列表框初期化前台页面
        String currentMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("MM"));
        model.addAttribute("currentmonth", currentMonth);
        model.addAttribute("knmonthlist", knMonth);

        return "kn_extra_to_sche_001/kn_extra_list";
    }

    /* 【一覧画面検索部】検索ボタンを押下，
     *  取得要换正课的加课明细。取得条件是:年度和月份是下拉列表框选择的年度和月份
     *  对于学生历史档案的最新科目取得的业务逻辑说明如下：
     *     如果下拉列表框取得的年份是系统当前年度，那么，最新课程档案信息视图里的最新截止日期是以当前年月日为查询基准日，基准日传递null即可。
     *     如果下拉列表框取得的年份非系统当前年度，那么，最新课程档案信息视图里的最新截止日期是yyyy-12-31
    */
    @GetMapping("/kn_extratosche_all/search")
    public String search(@RequestParam Map<String, Object> queryParams, Model model) {
        // 把画面传来的年和月拼接成yyyy-mm的        
        Map<String, Object> params = new HashMap<>();
        String lsnMonth = (String) queryParams.get("selectedmonth");
        String lsnYear = (String) queryParams.get("selectedyear");
        if ( !("ALL".equals(lsnMonth))) {
            int month = Integer.parseInt(lsnMonth); // 将月份转换为整数类型
            lsnMonth = String.format("%02d", month); // 格式化为两位数并添加前导零
            params.put("lsn_month", queryParams.get("selectedyear") + "-" + lsnMonth);
        } else {
            params.put("lsn_month", queryParams.get("selectedyear"));
        }

        // 已结算的加课：1   未消化的加课：0   所有加课（不包括已转正的加课）：空值
        params.put("extra_lsn_pay_status", queryParams.get("lsnExtraFlg") == "" ? "-1" : queryParams.get("lsnExtraFlg"));

        String yearMonth = ("ALL".equals(lsnMonth)) ? lsnYear : lsnYear + "-" + lsnMonth;
        List<Kn01L002ExtraToScheBean> list = kn01L002ExtraToScheDao.getSearchInfo4Stu(yearMonth);
        model.addAttribute("extra2ScheStuList", list);

        // 检索条件
        params.put("stu_id", queryParams.get("stuId"));

        // 学生最新档案基准日调整的设置（如果下拉列表框是系统当前年度，基准日调整设置为null，如果是非系统当前年度，基准日调整设置为yyyy-12-31）
        String systemYear = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy"));
        String adjustedBaseDate = lsnYear.equals(systemYear) ? null : lsnYear + "-12-31";
        params.put("adjustedBaseDate", adjustedBaseDate);

        // 回传参数设置（画面检索部的查询参数）
        Map<String, Object> backForwordMap = new HashMap<>();
        backForwordMap.putAll(queryParams);
        model.addAttribute("extra2ScheMap", backForwordMap);
        // model.addAttribute("currentyear", lsnYear);
        model.addAttribute("knyearlist", knYear);
        model.addAttribute("currentmonth", lsnMonth);
        model.addAttribute("knmonthlist", knMonth);

        // 将queryParams传递给Service层或Mapper接口
        Collection<Kn01L002ExtraToScheBean> searchResults = kn01L002ExtraToScheDao.searchLessons(params);
        model.addAttribute("infoList", searchResults);

        // 利用resultsTabStus的学生名，在前端页面做Tab
        Map<String, String> resultsTabStus = getResultsTabStus(searchResults);
        model.addAttribute("resultsTabStus", resultsTabStus);
        return "kn_extra_to_sche_001/kn_extra_list"; // 返回只包含搜索结果表格部分的Thymeleaf模板
    }

    // 【一覧画面明细部】加课换正课ボタンを押下从检索画面迁移到加课换正课的详细信息画面
    @GetMapping("/kn_extra_lsn_detail/{lessonid}")
    public String toProcessExtraLsn(@PathVariable("lessonid") String lessonid, Model model) {
        // [坏账拦截] 坏账课程不允许执行加课换正课，直接跳回列表页
        if (kn01L002ExtraToScheDao.isBadDebtLesson(lessonid)) {
            return "redirect:/kn_extratosche_all";
        }
        Kn01L002ExtraToScheBean bean = kn01L002ExtraToScheDao.getExtraLsnDetail(lessonid);
        model.addAttribute("selectedinfo", bean);
        return "kn_extra_to_sche_001/knl_extra_change_to_sche";
    }

    // 执行加课换正课的业务处理（未结算的加课可以换成任何时候的正课，过去的正课，现在的正课，将来的正课）
    @GetMapping("/kn_extra_tobe_sche")
    public String doProcessExtraLsn(Kn01L002ExtraToScheBean kn01L002ExtraToScheBean, Model model) {
        // [坏账拦截] 坏账课程不允许执行加课换正课，直接跳回列表页
        if (kn01L002ExtraToScheDao.isBadDebtLesson(kn01L002ExtraToScheBean.getLessonId())) {
            return "redirect:/kn_extratosche_all";
        }
        // 画面数据有效性校验
        if (validateHasError(model, kn01L002ExtraToScheBean)) {
            return "kn_extra_to_sche_001/knl_extra_change_to_sche";
        }
        // 执行加课换正课处理
        kn01L002ExtraToScheDao.executeExtraToSche(kn01L002ExtraToScheBean);

        return "redirect:/kn_extratosche_all";
    }

    private boolean validateHasError(Model model, Kn01L002ExtraToScheBean knLsn001Bean) {
        boolean hasError = false;
        List<String> msgList = new ArrayList<String>();
        hasError = inputDataHasError(knLsn001Bean, msgList);
        if (hasError == true) {

            // 将错误消息显示在画面上
            model.addAttribute("errorMessageList", msgList);
            model.addAttribute("selectedinfo", knLsn001Bean);
        }
        return hasError;
    }

    private boolean inputDataHasError(Kn01L002ExtraToScheBean knLsn001Bean, List<String> msgList) {
        if (knLsn001Bean.getExtraToDurDate() == null ) {
            msgList.add("请选定加课换正课的日期");
        }

        return (msgList.size() != 0);
    }

    //【一覧画面明细部】加课换正课撤销ボタンを押下
    @GetMapping("/kn_extra_lsn_undo/{lessonid}")
    public String lessonUndo(@PathVariable("lessonid") String lessonId, Model model) {
        // 撤销加课换正课处理
        kn01L002ExtraToScheDao.undoExtraToSche(lessonId);
        return "redirect:/kn_extratosche_all";
    }

    // 从结果集中去除掉重复的星期，前端页面脚本以此定义tab名
        private Map<String, String> getResultsTabStus(Collection<Kn01L002ExtraToScheBean> collection) {
        // 首先创建一个用于去重的Map
        Map<String, String> tempMap = new HashMap<>();
        
        // 填充临时Map
        for (Kn01L002ExtraToScheBean bean : collection) {
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

}
