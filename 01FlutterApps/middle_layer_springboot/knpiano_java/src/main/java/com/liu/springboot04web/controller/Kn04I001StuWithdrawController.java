package com.liu.springboot04web.controller;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.liu.springboot04web.bean.Kn03D001StuBean;
import com.liu.springboot04web.bean.Kn04I001StuUnpaidFeeBean;
import com.liu.springboot04web.dao.Kn04I001StuWithdrawDao;
import com.liu.springboot04web.dao.Kn05S001LsnFixDao;

@Controller
public class Kn04I001StuWithdrawController {

    @Autowired
    private Kn04I001StuWithdrawDao knStudents001Dao;
    @Autowired
    private Kn05S001LsnFixDao knFixLsn001Dao;

    // 【KNPiano后台维护 退学复学管理】ボタンをクリック
    @GetMapping("/kn_student_mst_all")
    public String list(Model model) {
        List<Kn03D001StuBean> list = knStudents001Dao.getInfoList();

        List<Kn03D001StuBean> stuOnLsnList = new ArrayList<>();
        List<Kn03D001StuBean> stuLeaveList = new ArrayList<>();

        for (Kn03D001StuBean stuBean : list) {
            if (stuBean.getDelFlg() == 0) {
                stuOnLsnList.add(stuBean);
            } else if (stuBean.getDelFlg() == 1) {
                stuLeaveList.add(stuBean);
            }
        }
        model.addAttribute("stuOnLsn", stuOnLsnList);
        model.addAttribute("stuLeaveLsn", stuLeaveList);
        return "kn_04i001_stuwithdraw/kn04i001withdraw_list";
    }

    // 【明细検索一覧】休学/复学ボタンを押下
    @GetMapping("/kn_stu_leave/{stuId}")
    public String excuteWithdraw(@PathVariable("stuId") String stuId,
            @RequestParam(value = "deleteSchedule", required = false) Boolean deleteSchedule) {

        // 执行退学操作
        knStudents001Dao.stuWithdraw(stuId);
        // 如果画面CheckBox选中了，也顺便删除固定排课记录
        if (Boolean.TRUE.equals(deleteSchedule)) {
            knFixLsn001Dao.deleteByKeys(stuId, null, null);
        }

        return "redirect:/kn_student_mst_all";
    }

    // 【明细检索一览】复学按钮按下
    @GetMapping("/kn_stu_return/{stuId}")
    public String excuteReturn(@PathVariable("stuId") String stuId) {
        knStudents001Dao.stuReinstatement(stuId);
        return "redirect:/kn_student_mst_all";
    }

    // 退学前学费查账（AJAX用，返回JSON欠费列表；空列表=学费已交齐）
    @GetMapping("/kn_stu_fee_check/{stuId}")
    @ResponseBody
    public List<Kn04I001StuUnpaidFeeBean> checkStuFee(@PathVariable("stuId") String stuId) {
        return knStudents001Dao.getUnpaidFeesByStuId(stuId);
    }

    // 强行退学：批量标记坏账 + 退学 + 删除固定排课（事务保证原子性）
    @PostMapping("/kn_stu_force_leave/{stuId}")
    @Transactional
    public String forceLeave(@PathVariable("stuId") String stuId) {
        knStudents001Dao.batchMarkBadDebtByStuId(stuId);
        knStudents001Dao.stuWithdraw(stuId);
        knFixLsn001Dao.deleteByKeys(stuId, null, null);
        return "redirect:/kn_student_mst_all";
    }
}
