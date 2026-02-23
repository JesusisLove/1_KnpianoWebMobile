package com.liu.springboot04web.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.liu.springboot04web.bean.Kn02F006EmptyLessonFeeBean;
import com.liu.springboot04web.dao.Kn02F006EmptyLessonFeeDao;

import java.time.Year;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class Kn02F006EmptyLessonFeeController {

    private List<String> knYear = null;
    private Map<String, Object> backForwordMap;

    @Autowired
    Kn02F006EmptyLessonFeeDao kn02F006EmptyLessonFeeDao;

    public Kn02F006EmptyLessonFeeController() {
        // 回传参数设置（画面检索部的查询参数）画面检索条件保持变量
        backForwordMap = new HashMap<>();

        // ⚠️ 特别说明：此页面不使用系统统一的年度管理常量 SystemConstants.SYSTEM_STARTED_YEAR
        // 原因：空课学费功能从2025年启用，且需要向未来扩展（当前年+5年）
        // 其他页面使用 DateUtils.getYearList()（从2024年到当前年）
        // 此页面使用 getYearListFrom2025()（从2025年到未来5年）
        this.knYear = getYearListFrom2025();
    }

    /**
     * 页面初期化
     */
    @GetMapping("/kn_02_f_006_empty_lesson_fee_monthly_pay")
    public String list(Model model, @ModelAttribute("successMessage") String successMessage) {

        // 获取当前年度
        int currentYear = Year.now().getValue();
        String currentYearStr = String.valueOf(currentYear);

        // 自动查询当前年度的数据
        List<Kn02F006EmptyLessonFeeBean> list = kn02F006EmptyLessonFeeDao
                .getStudentsReached43Lessons(currentYearStr);
        model.addAttribute("infoList", list);

        // 设置searchParams，让下拉框默认选中当前年度
        backForwordMap.put("selectedyear", currentYearStr);
        model.addAttribute("searchParams", backForwordMap);

        // 画面初期化基本设定
        setModel(model);

        if (!successMessage.isEmpty()) {
            model.addAttribute("successMessage", successMessage);
        }

        return "kn_02f006_empty_lesson_fee/kn_02_f_006_empty_lesson_fee_monthly_pay";
    }

    /**
     * 点击Web页面上的【查询】按钮
     */
    @GetMapping("/kn_02_f_006_empty_lesson_fee_monthly_pay/search")
    public String search(@RequestParam Map<String, Object> queryParams, Model model) {

        String selectedYear = (String) queryParams.get("selectedyear");

        if (!validateHasError(model, queryParams)) {
            // 查询达到43节课的学生列表
            List<Kn02F006EmptyLessonFeeBean> list = kn02F006EmptyLessonFeeDao
                    .getStudentsReached43Lessons(selectedYear);
            model.addAttribute("infoList", list);
        }

        // 回传参数设置（画面检索部的查询参数）
        backForwordMap.putAll(queryParams);
        model.addAttribute("searchParams", backForwordMap);

        // 画面初期化基本设定
        setModel(model);

        return "kn_02f006_empty_lesson_fee/kn_02_f_006_empty_lesson_fee_monthly_pay";
    }

    /**
     * 画面基本数据初始化
     */
    private void setModel(Model model) {
        // 年度下拉列表框初期化前台页面（从2025年开始，向未来扩展5年）
        // 注：此页面不使用 DateUtils.getYearList()，有独立的年度范围要求
        int currentYear = Year.now().getValue();
        model.addAttribute("currentyear", currentYear);
        model.addAttribute("knyearlist", knYear);
    }

    /**
     * 输入验证
     */
    private boolean validateHasError(Model model, Map<String, Object> queryParams) {
        boolean hasError = false;
        List<String> msgList = new ArrayList<String>();

        String selectedYear = (String) queryParams.get("selectedyear");
        if (selectedYear == null || selectedYear.isEmpty()) {
            msgList.add("请选择年度。");
            hasError = true;
        }

        if (hasError) {
            model.addAttribute("errorMessageList", msgList);
        }

        return hasError;
    }

    /**
     * 生成年度列表（从2025年开始到当前年度+5年）
     *
     * ⚠️ 特别说明：
     * 1. 此方法独立实现，不使用 DateUtils.getYearList()
     * 2. 其他页面使用统一的 SystemConstants.SYSTEM_STARTED_YEAR = 2024
     * 3. 此页面有特殊业务需求：
     *    - 空课学费功能从2025年启用（不需要2024年及以前的数据）
     *    - 需要向未来扩展5年（用于生成未来的课费计划）
     *    - 年度范围：[2025...当前年+5]，例如：2026年时显示 [2025-2031]
     *
     * 与其他页面的对比：
     * - 其他页面：使用 DateUtils.getYearList() → [2024...当前年]（历史到现在）
     * - 此页面：使用本方法 → [2025...当前年+5]（现在到未来）
     *
     * @return 年度字符串列表，升序排列
     */
    private List<String> getYearListFrom2025() {
        List<String> yearList = new ArrayList<>();
        int currentYear = Year.now().getValue();
        int startYear = 2025;  // 空课学费功能启用年份（硬编码，不使用SystemConstants）
        int endYear = currentYear + 5;  // 向未来扩展5年

        for (int year = startYear; year <= endYear; year++) {
            yearList.add(String.valueOf(year));
        }

        return yearList;
    }

    /**
     * 处理GET请求到生成端点（防止405错误）
     */
    @GetMapping("/kn_02_f_006_empty_lesson_fee_monthly_pay/generate")
    public String generateEmptyLessonFeeGet(RedirectAttributes redirectAttributes) {
        redirectAttributes.addFlashAttribute("errorMessageList",
            java.util.Arrays.asList("请使用页面上的按钮进行操作，不要直接访问此链接。"));
        return "redirect:/kn_02_f_006_empty_lesson_fee_monthly_pay";
    }

    /**
     * 点击Web页面上的【生成临时课程】按钮
     */
    @PostMapping("/kn_02_f_006_empty_lesson_fee_monthly_pay/generate")
    public String generateEmptyLessonFee(@RequestBody Kn02F006EmptyLessonFeeBean bean,
                                          RedirectAttributes redirectAttributes) {
            String stuId = bean.getStuId();
            String subjectId = bean.getSubjectId();
            String stuName = bean.getStuName();
            String subjectName = bean.getSubjectName();
            Integer monthsCompleted = bean.getMonthsCompleted();
            String year = bean.getYear();

            // 计算剩余月份：从 monthsCompleted + 1 到 12
            int startMonth = monthsCompleted + 1;
            int endMonth = 12;

            // 为剩余每个月生成临时课程
            for (int month = startMonth; month <= endMonth; month++) {
                // 构造目标日期：YYYY-MM-01
                String targetDate = String.format("%s-%02d-01", year, month);

                // 调用存储过程生成临时课程和课费
                kn02F006EmptyLessonFeeDao.callInsertTmpLessonInfo(stuId, subjectId, targetDate);
            }

            // 计算生成的月份数
            int generatedMonths = endMonth - startMonth + 1;

            // 返回成功消息
            String successMessage = String.format("%s 的 %s 成功生成了 %d 个月的临时课程（%d月-%d月）。",
                    stuName, subjectName, generatedMonths, startMonth, endMonth);

            redirectAttributes.addFlashAttribute("successMessage", successMessage);
            return "redirect:/kn_02_f_006_empty_lesson_fee_monthly_pay";
    }

    /**
     * 查询某个学生某个科目的空月课费月度明细（AJAX请求）
     */
    @GetMapping("/kn_02_f_006_empty_lesson_fee_monthly_pay/getMonthlyDetails")
    @ResponseBody
    public Map<String, Object> getMonthlyDetails(@RequestParam String stuId,
                                                   @RequestParam String subjectId,
                                                   @RequestParam String year) {
        Map<String, Object> result = new HashMap<>();

        try {
            List<Kn02F006EmptyLessonFeeBean> detailList = kn02F006EmptyLessonFeeDao
                    .getMonthlyDetailsForCancel(stuId, subjectId, year);

            result.put("success", true);
            result.put("data", detailList);
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "查询失败：" + e.getMessage());
        }

        return result;
    }

    /**
     * 撤销空月课费（AJAX请求）
     */
    @PostMapping("/kn_02_f_006_empty_lesson_fee_monthly_pay/cancel")
    @ResponseBody
    public Map<String, Object> cancelEmptyLessonFee(@RequestBody Map<String, String> params) {
        Map<String, Object> result = new HashMap<>();

        try {
            String lsnTmpId = params.get("lsnTmpId");
            String lsnFeeId = params.get("lsnFeeId");

            // 调用存储过程撤销空月课费
            kn02F006EmptyLessonFeeDao.callCancelTmpLessonInfo(lsnTmpId, lsnFeeId);

            result.put("success", true);
            result.put("message", "撤销成功！");
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "撤销失败：" + e.getMessage());
        }

        return result;
    }
}
