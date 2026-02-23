package com.liu.springboot04web.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import com.liu.springboot04web.bean.Kn02F004UnpaidBean;
import com.liu.springboot04web.bean.Kn03D003BnkBean;
// import com.liu.springboot04web.bean.Kn03D003StubnkBean;
import com.liu.springboot04web.dao.Kn02F004UnpaidDao;
import com.liu.springboot04web.dao.Kn03D003StubnkDao;
import com.liu.springboot04web.mapper.Kn03D003BnkMapper;
import com.liu.springboot04web.othercommon.DateUtils;
import com.liu.springboot04web.service.ComboListInfoService;

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

@Controller
public class Kn02F004UnpaidController {
    final List<String> knYear;
    final List<String> knMonth;
    // 把要付费的学生信息拿到前台画面，给学生下拉列表框做初期化
    Collection<Kn02F004UnpaidBean> unPaidStuList;

    @Autowired
    Kn03D003BnkMapper kn03D003BnkMapper;
    @Autowired
    Kn03D003StubnkDao kn05S002StubnkDao;
    @Autowired
    Kn02F004UnpaidDao knLsnUnPaid001Dao;

    // 通过构造器注入方式接收ComboListInfoService的一个实例，获得application.properties里配置的上课时长数组
    public Kn02F004UnpaidController(ComboListInfoService combListInfo) {
        // 初期化年度下拉列表框
        this.knYear = DateUtils.getYearList();

        // 初期化月份下拉列表框
        this.knMonth = combListInfo.getMonths();
        this.unPaidStuList = null;
    }

    // 【課費未支払管理】ボタンをクリックして，全ての情報を表示すること
    @GetMapping("/kn_lsn_unpaid_001_all")
    public String list(Model model) {
        // 获取当前日期
        LocalDate currentDate = LocalDate.now();

        // 格式化为 yyyy
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy");
        String year = currentDate.format(formatter);

        // 未结算一览
        Collection<Kn02F004UnpaidBean> unPaiedCollection = knLsnUnPaid001Dao.getInfoList(year);
        this.unPaidStuList = unPaiedCollection;

        for (Kn02F004UnpaidBean kn02f004UnpaidBean : unPaiedCollection) {
            if (kn02f004UnpaidBean.getOwnFlg() == 1) {
                kn02f004UnpaidBean.setLsnFee(0);
            }
        }

        model.addAttribute("infoList", unPaiedCollection);

        // 把要付费的学生信息拿到前台画面，给学生下拉列表框做初期化
        model.addAttribute("unPaidStuList", unPaidStuList);

        // 年度下拉列表框初期化前台页面
        int currentYear = Year.now().getValue();
        model.addAttribute("currentyear", currentYear);
        model.addAttribute("knyearlist", knYear);

        // 月份下拉列表框初期化前台页面
        String currentMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("MM"));
        model.addAttribute("currentmonth", currentMonth);
        model.addAttribute("knmonthlist", knMonth);

        // 利用resultsTabStus的学生名，在前端页面做Tab
        Map<String, String> resultsTabStus = getResultsTabStus(unPaiedCollection);
        model.addAttribute("resultsTabStus", resultsTabStus);

        return "kn_lsn_unpaid_001/knlsnunpaid001_list";
    }

    // 【课费未支付明细検索一覧】検索ボタンを押下
    @GetMapping("/kn_lsn_unpaid_001/search")
    public String search(@RequestParam Map<String, Object> queryParams, Model model) {
        // 获取用户选择的年度和月份
        String lsnMonth = (String) queryParams.get("selectedmonth");
        String lsnYear = (String) queryParams.get("selectedyear");

        // 🔧 2026-01-08 修复：根据用户选择的年度重新查询学生列表，确保年度联动正确
        unPaidStuList = knLsnUnPaid001Dao.getInfoList(lsnYear);

        // 把画面传来的年和月拼接成yyyy-mm的
        Map<String, Object> params = new HashMap<>();
        if (!("ALL".equals(lsnMonth))) {
            int month = Integer.parseInt(lsnMonth); // 将月份转换为整数类型
            lsnMonth = String.format("%02d", month); // 格式化为两位数并添加前导零
            params.put("lsn_month", queryParams.get("selectedyear") + "-" + lsnMonth);
        } else {
            params.put("lsn_month", queryParams.get("selectedyear"));
        }

        // 检索条件
        params.put("stu_id", queryParams.get("stuId"));

        // 回传参数设置（画面检索部的查询参数）
        Map<String, Object> backForwordMap = new HashMap<>();
        backForwordMap.putAll(queryParams);
        model.addAttribute("unPayMap", backForwordMap);
        model.addAttribute("currentyear", lsnYear);
        model.addAttribute("knyearlist", knYear);
        model.addAttribute("currentmonth", lsnMonth);
        model.addAttribute("knmonthlist", knMonth);
        // 把要付费的学生信息拿到前台画面，给学生下拉列表框做初期化
        model.addAttribute("unPaidStuList", unPaidStuList);

        // 未结算一览
        Collection<Kn02F004UnpaidBean> unPaiedCollection = knLsnUnPaid001Dao.searchLsnUnpay(params);
        model.addAttribute("infoList", unPaiedCollection);

        // 利用resultsTabStus的学生名，在前端页面做Tab
        Map<String, String> resultsTabStus = getResultsTabStus(unPaiedCollection);
        model.addAttribute("resultsTabStus", resultsTabStus);

        return "kn_lsn_unpaid_001/knlsnunpaid001_list";
    }

    // 【課費未支払管理】学费精算ボタンを押下して、【課費未支払管理】学费支付画面へ遷移すること
    @GetMapping("/kn_lsn_unpaid_001/{lsnFeeId}")
    public String toLsnPay(@PathVariable("lsnFeeId") String lsnFeeId,
            Model model) {
        // 根据课费编号，取得未支付的课费信息
        Kn02F004UnpaidBean knLsnUnPaid001Bean = knLsnUnPaid001Dao.getLsnUnpayByID(lsnFeeId);

        /* ↓↓↓↓↓↓↓↓ 这块的业务逻辑目前是不需要的，这里取的不是学生的银行，而是老师的银行信息 ↓↓↓↓↓↓↓ */
        // // 取得该生的银行信息
        // String stuId = knLsnUnPaid001Bean.getStuId();
        // // 根据stuId从银行管理表，取得该学生使用的银行名称（复数个银行可能）
        // Map<String, String> stuBankMap = getStuBnkCodeValueMap(stuId);
        /* ↑↑↑↑↑↑↑↑ 这块的业务逻辑目前是不需要的，这里取的不是学生的银行，而是老师的银行信息 ↑↑↑↑↑↑↑↑ */

        Map<String, String> bankMap = getTeacherBnkCodeValueMap();
        model.addAttribute("bankMap", bankMap);

        // 将学生交费信息响应送给前端
        model.addAttribute("selectedinfo", knLsnUnPaid001Bean);
        return "kn_lsn_unpaid_001/knlsnunpaid001_add_update";
    }

    // 【課費未支払管理】精算画面にて、【保存】ボタンを押下して、課費精算を行うこと
    @PostMapping("/kn_lsn_unpaid_001")
    public String excuteLsnPay(Model model, Kn02F004UnpaidBean knLsnUnPaid001Bean) {
        // 画面数据有效性校验
        if (validateHasError(model, knLsnUnPaid001Bean)) {
            return "kn_lsn_unpaid_001/knlsnunpaid001_add_update";
        }
        // 課費精算を行う
        knLsnUnPaid001Dao.excuteLsnPay(knLsnUnPaid001Bean);
        return "redirect:/kn_lsn_unpaid_001_all";
    }

    @PutMapping("/kn_lsn_unpaid_001")
    public String excuteLsnPayEdit(Model model, Kn02F004UnpaidBean knLsnUnPaid001Bean) {
        // 画面数据有效性校验
        if (validateHasError(model, knLsnUnPaid001Bean)) {
            return "kn_lsn_unpaid_001/knlsnunpaid001_add_update";
        }
        // 課費精算を行う
        knLsnUnPaid001Dao.excuteLsnPay(knLsnUnPaid001Bean);
        return "redirect:/kn_lsn_unpaid_001_all";
    }

    // 老师银行下拉列表框初期化
    private Map<String, String> getTeacherBnkCodeValueMap() {
        Collection<Kn03D003BnkBean> collection = kn03D003BnkMapper.getInfoList();

        Map<String, String> map = new HashMap<>();
        for (Kn03D003BnkBean bean : collection) {
            map.put(bean.getBankId(), bean.getBankName());
        }
        return map;
    }

    // // 学生银行下拉列表框初期化 暂时不要删除
    // private Map<String, String> getStuBnkCodeValueMap(String stuId) {
    // Collection<Kn03D003StubnkBean> collection =
    // kn05S002StubnkDao.getInfoById(stuId);
    // Map<String, String> map = new HashMap<>();
    // for (Kn03D003StubnkBean bean : collection) {
    // map.put(bean.getBankId(), bean.getBankName());
    // }
    // return map;
    // }

    // // 从结果集中去除掉重复的星期，前端页面脚本以此定义tab名
    private Map<String, String> getResultsTabStus(Collection<Kn02F004UnpaidBean> collection) {
        // 首先创建一个用于去重的Map
        Map<String, String> tempMap = new HashMap<>();

        // 填充临时Map
        for (Kn02F004UnpaidBean bean : collection) {
            tempMap.putIfAbsent(bean.getStuId(), bean.getStuName());
        }

        // 按值（学生姓名）排序并收集到新的LinkedHashMap中
        return tempMap.entrySet()
                .stream()
                .sorted(Map.Entry.comparingByValue())
                .collect(Collectors.toMap(
                        Map.Entry::getKey,
                        Map.Entry::getValue,
                        (oldValue, newValue) -> oldValue, // 处理重复键的情况
                        LinkedHashMap::new // 使用LinkedHashMap保持排序
                ));
    }

    private boolean validateHasError(Model model, Kn02F004UnpaidBean knLsnUnPaid001Bean) {
        boolean hasError = false;
        List<String> msgList = new ArrayList<String>();
        hasError = inputDataHasError(knLsnUnPaid001Bean, msgList);
        if (hasError == true) {
            // 将学生交费信息响应送给前端
            model.addAttribute("selectedinfo", knLsnUnPaid001Bean);

            /* ↓↓↓↓↓↓↓↓ 这块的业务逻辑目前是不需要的，这里取的不是学生的银行，而是老师的银行信息 ↓↓↓↓↓↓↓ */
            // // 取得该生的银行信息
            // String stuId = knLsnUnPaid001Bean.getStuId();
            // // 根据stuId从银行管理表，取得该学生使用的银行名称（复数个银行可能）
            // Map<String, String> stuBankMap = getStuBnkCodeValueMap(stuId);
            // model.addAttribute("bankMap", stuBankMap);
            /* ↑↑↑↑↑↑↑↑ 这块的业务逻辑目前是不需要的，这里取的不是学生的银行，而是老师的银行信息 ↑↑↑↑↑↑↑↑ */

            Map<String, String> bankMap = getTeacherBnkCodeValueMap();
            model.addAttribute("bankMap", bankMap);

            // 将错误消息显示在画面上
            model.addAttribute("errorMessageList", msgList);
            model.addAttribute("selectedinfo", knLsnUnPaid001Bean);
        }

        return hasError;
    }

    private boolean inputDataHasError(Kn02F004UnpaidBean knLsnUnPaid001Bean, List<String> msgList) {
        if (knLsnUnPaid001Bean.getLsnPay() <= 0) {
            msgList.add("请输入実績支払金額。");
        }

        if (knLsnUnPaid001Bean.getLessonType() == 1 && knLsnUnPaid001Bean.getPayStyle() == 1) {
            if (knLsnUnPaid001Bean.getSubjectPrice() * 4 != knLsnUnPaid001Bean.getLsnPay()) {
                msgList.add("精算金額和実際精算金額不一致，请重新输入");
            }
        } else {
            if (knLsnUnPaid001Bean.getLsnFee() != knLsnUnPaid001Bean.getLsnPay()) {
                msgList.add("精算金額和実際精算金額不一致，请重新输入");
            }
        }

        if (knLsnUnPaid001Bean.getBankId() == null || knLsnUnPaid001Bean.getBankId().isEmpty()) {
            msgList.add("请选择银行名称");
        }

        if (knLsnUnPaid001Bean.getPayMonth() == null || knLsnUnPaid001Bean.getPayMonth().isEmpty()) {
            msgList.add("请选择要结算月份");
        }

        return (msgList.size() != 0);
    }
}
