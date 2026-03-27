package com.liu.springboot04web.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import com.liu.springboot04web.bean.Kn02F004FeePaid4MobileBean;
import com.liu.springboot04web.bean.Kn02f005FeeMonthlyReportBean;
import com.liu.springboot04web.dao.Kn02F002FeeDao;
import com.liu.springboot04web.dao.Kn02f005FeeMonthlyReportDao;
import com.liu.springboot04web.othercommon.DateUtils;
import com.liu.springboot04web.service.ComboListInfoService;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class Kn02f005FeeMonthlyReportController {
    final List<String> knYear; 
    @Autowired
    Kn02f005FeeMonthlyReportDao kn02f005Dao;
    @Autowired
    Kn02F002FeeDao kn02F002FeeDao;
        // 回传参数设置（画面检索部的查询参数）画面检索条件保持变量
    Map<String, Object> backForwordMap;
    public Kn02f005FeeMonthlyReportController(ComboListInfoService combListInfo) {
        // 通过构造器注入方式接收ComboListInfoService的一个实例，获得application.properties里配置的上课时长数组
        // 回传参数设置（画面检索部的查询参数）画面检索条件保持变量
        backForwordMap = new HashMap<>();

        // 初期化年度下拉列表框
        this.knYear = DateUtils.getYearList();
    }

    // 【学费月度 报告】ボタンをクリックして，全ての情報を表示すること
    @GetMapping("/kn02f005_all/{year}")
    public String list(@PathVariable Integer year, Model model) {
        // 年度下拉列表框初期化前台页面

        model.addAttribute("currentyear", year);
        model.addAttribute("knyearlist", knYear);
        List<Kn02f005FeeMonthlyReportBean> collection = kn02f005Dao.getInfoList(Integer.toString(year));
        model.addAttribute("infoList", collection);

        // 坏账一览（Tab②用）
        List<Kn02F004FeePaid4MobileBean> badDebtList = kn02F002FeeDao.getBadDebtList(Integer.toString(year));
        model.addAttribute("badDebtList", badDebtList);

        return "kn_02f005_fee_report/kn02f005_fee_report_list";
    }

    // 【学费月度 报告】新規ボタンを押下して、【学费月度 报告】新規画面へ遷移すること
    @GetMapping("/kn02f005_unpaid_details/{yearMonth}")
    public String unPaidDetailslist(@PathVariable String yearMonth, Model model) {

        List<Kn02f005FeeMonthlyReportBean> collection = kn02f005Dao.getUnpaidInfo(yearMonth);
        model.addAttribute("infoList",collection);
        String currentMonth = yearMonth.substring(5);
        model.addAttribute("currentMonth", currentMonth);
        String currentYear = yearMonth.substring(0,4);
        model.addAttribute("currentYear", currentYear);
        List<Kn02f005FeeMonthlyReportBean> allList = kn02f005Dao.getInfoList(currentYear);
        List<String> knmonthlist = unpaidMonth(allList);
        model.addAttribute("knmonthlist", knmonthlist);

        return "kn_02f005_fee_report/kn02f005_unpaid_list";
    }

    private List<String> unpaidMonth(List<Kn02f005FeeMonthlyReportBean> collection) {
        List<String> months = new ArrayList<>();

        for (Kn02f005FeeMonthlyReportBean bean : collection) {
            String lsnMonth = bean.getLsnMonth();
            // Extract month part (MM) from lsnMonth (format yyyy-MM)
            String month = lsnMonth.substring(5); // Extracts characters starting from index 5 to end
            months.add(month);
        }
        // 将 Set 转换为 List 并返回
        return new ArrayList<>(months);
    }

    // 撤销坏账（月度报表Tab②用）
    @PostMapping("/kn02f005_bad_debt_undo/{lsnFeeId}")
    public String undoBadDebt(@PathVariable("lsnFeeId") String lsnFeeId,
                              @RequestParam("year") String year) {
        kn02F002FeeDao.undoBadDebt(lsnFeeId);
        return "redirect:/kn02f005_all/" + year;
    }
}
