package com.liu.springboot04web.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import com.liu.springboot04web.bean.Kn02F002FeeBean;
import com.liu.springboot04web.dao.Kn02F002FeeDao;
import com.liu.springboot04web.othercommon.DateUtils;
import com.liu.springboot04web.service.ComboListInfoService;

import java.time.LocalDate;
import java.time.Year;
import java.time.format.DateTimeFormatter;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
@Controller
public class Kn02F002FeeController{
    final List<String> knYear; 
    final List<String> knMonth;
    // 把要付费的学生信息拿到前台画面，给学生下拉列表框做初期化
    Collection<Kn02F002FeeBean> lsnFeeStuList;

    @Autowired
    Kn02F002FeeDao knLsnFee001Dao;

    // 通过构造器注入方式接收ComboListInfoService的一个实例，获得application.properties里配置的上课时长数组
    public Kn02F002FeeController(ComboListInfoService combListInfo) {
        // 初期化年度下拉列表框
        this.knYear = DateUtils.getYearList();

        // 初期化月份下拉列表框
        this.knMonth = combListInfo.getMonths();
        this.lsnFeeStuList = null;
    }

    // 【课程费用管理】ボタンをクリックして，全ての情報を表示すること
    @GetMapping("/kn_lsn_fee_001_all")
    public String list(Model model) {
        /* 获取课费明细一览 */
        LocalDate currentDate = LocalDate.now();// 获取当前日期

        // 格式化为 yyyy
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy");
        String year = currentDate.format(formatter);
        
        // 课费一览取得
        Collection<Kn02F002FeeBean> collection = knLsnFee001Dao.getInfoList(year);
        this.lsnFeeStuList = collection;
        model.addAttribute("infoList",collection);

        // 用学生名，在前端页面分Tab页
        Map<String, String> resultsTabStus = getResultsTabStus(collection);
        model.addAttribute("resultsTabStus", resultsTabStus);

        /* 初始化画面检索部 */
        // 把要付费的学生信息拿到前台画面，给学生下拉列表框做初期化
        model.addAttribute("lsnfeestuList", lsnFeeStuList);

        // 年度下拉列表框初期化前台页面
        int currentYear = Year.now().getValue();
        model.addAttribute("currentyear", currentYear);
        model.addAttribute("knyearlist", knYear);

        // 月份下拉列表框初期化前台页面
        String currentMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("MM"));
        model.addAttribute("currentmonth", currentMonth);
        model.addAttribute("knmonthlist", knMonth);

        return "kn_lsn_fee_001/knlsnfee001_list";
    }

    // 【检索部】検索ボタンを押下
    @GetMapping("/kn_lsn_fee_001/search")
    public String search(@RequestParam Map<String, Object> queryParams, Model model) {
        // 获取用户选择的年度和月份
        String lsnMonth = (String) queryParams.get("selectedmonth");
        String lsnYear = (String) queryParams.get("selectedyear");

        // 🔧 2026-01-08 修复：根据用户选择的年度重新查询学生列表，确保年度联动正确
        lsnFeeStuList = knLsnFee001Dao.getInfoList(lsnYear);

        // 把画面传来的年和月拼接成yyyy-mm的
        Map<String, Object> params = new HashMap<>();
        if ( !("ALL".equals(lsnMonth))) {
            int month = Integer.parseInt(lsnMonth); // 将月份转换为整数类型
            lsnMonth = String.format("%02d", month); // 格式化为两位数并添加前导零
            params.put("lsn_month", queryParams.get("selectedyear") + "-" + lsnMonth);
        } else {
            params.put("lsn_month", queryParams.get("selectedyear"));
        }
        
        // 检索条件
        params.put("stu_id", queryParams.get("stuId"));
        params.put("lsn_fee_id", queryParams.get("lsnFeeId"));
        params.put("lesson_id", queryParams.get("lessonId"));
        params.put("lesson_type", queryParams.get("lessonType"));
        params.put("own_flg", queryParams.get("ownFlg"));

        // 回传参数设置（画面检索部的查询参数）
        Map<String, Object> backForwordMap = new HashMap<>();
        backForwordMap.putAll(queryParams);
        model.addAttribute("stuLsnFeeMap", backForwordMap);
        model.addAttribute("currentyear", lsnYear);
        model.addAttribute("knyearlist", knYear);
        model.addAttribute("currentmonth", lsnMonth);
        model.addAttribute("knmonthlist", knMonth);
        model.addAttribute("lsnfeestuList", lsnFeeStuList);

        Collection<Kn02F002FeeBean> searchResults = knLsnFee001Dao.searchLsnFee(params);
        model.addAttribute("infoList", searchResults);

        // 利用resultsTabStus的学生名，在前端页面做Tab
        Map<String, String> resultsTabStus = getResultsTabStus(searchResults);
        model.addAttribute("resultsTabStus", resultsTabStus);
        
        return "kn_lsn_fee_001/knlsnfee001_list"; // 返回只包含搜索结果表格部分的Thymeleaf模板
    }

    // 【課費情報管理】新規ボタンを押下して、【課費情報管理】新規画面へ遷移すること
    @GetMapping("/kn_lsn_fee_001")
    public String toInfoAdd(Model model) {
        return "kn_lsn_fee_001/knlsnfee001_add_update";
    }

    // 【課費情報管理】新規画面にて、【保存】ボタンを押下して、新規情報を保存すること
    @PostMapping("/kn_lsn_fee_001")
    public String excuteInfoAdd(Kn02F002FeeBean knLsnFee001Bean) {
        knLsnFee001Dao.save(knLsnFee001Bean);
        return "redirect:/kn_lsn_fee_001_all";
    }

    // 【課費情報管理】編集ボタンを押下して、【課費情報管理】編集画面へ遷移すること
    @GetMapping("/kn_lsn_fee_001/{lsnFeeId}/{lessonId}")
    public String toInfoEdit(@PathVariable("lsnFeeId") String lsnFeeId, 
                             @PathVariable("lessonId") String lessonId,
                             Model model) {
        Kn02F002FeeBean knLsnFee001Bean = knLsnFee001Dao.getInfoById(lsnFeeId, lessonId);
        model.addAttribute("selectedinfo", knLsnFee001Bean);
        return "kn_lsn_fee_001/knlsnfee001_add_update";
    }

    // 【課費情報管理】編集画面にて、【保存】ボタンを押下して、変更した情報を保存すること
    @PutMapping("/kn_lsn_fee_001")
    public String excuteInfoEdit(@ModelAttribute Kn02F002FeeBean knLsnFee001Bean) {
        knLsnFee001Dao.save(knLsnFee001Bean);
        return "redirect:/kn_lsn_fee_001_all";
    }

    // 【課費情報管理】削除ボタンを押下して、当該情報を削除すること
    @DeleteMapping("/kn_lsn_fee_001/{lsnFeeId}/{lessonId}")
    public String excuteInfoDelete(@PathVariable("lsnFeeId") String lsnFeeId, 
                                   @PathVariable("lessonId") String lessonId) {
        knLsnFee001Dao.delete(lsnFeeId, lessonId);
        return "redirect:/kn_lsn_fee_001_all";
    }

    // 从结果集中去除掉重复的星期，前端页面脚本以此定义tab名
    private Map<String, String> getResultsTabStus(Collection<Kn02F002FeeBean> collection) {
        // 首先创建一个用于去重的Map
        Map<String, String> tempMap = new HashMap<>();

        // 填充临时Map
        for (Kn02F002FeeBean bean : collection) {
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

    // 获取学生上一个月支付时使用的银行ID（用于设置默认银行）
    @GetMapping("/kn_default_bank/{stuId}/{currentMonth}")
    @ResponseBody
    public String getDefaultBankId(@PathVariable("stuId") String stuId,
                                   @PathVariable("currentMonth") String currentMonth) {
        String bankId = knLsnFee001Dao.getLastPaymentBankId(stuId, currentMonth);
        return bankId != null ? bankId : "";
    }
}