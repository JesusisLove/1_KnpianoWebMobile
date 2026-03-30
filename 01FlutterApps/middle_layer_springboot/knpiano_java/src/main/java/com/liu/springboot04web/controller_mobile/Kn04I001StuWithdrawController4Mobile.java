package com.liu.springboot04web.controller_mobile;

import java.util.Collection;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.liu.springboot04web.bean.Kn03D001StuBean;
import com.liu.springboot04web.bean.Kn04I001StuUnpaidFeeBean;
import com.liu.springboot04web.bean.Kn04I001StuWithdrawBean;
import com.liu.springboot04web.dao.Kn04I001StuWithdrawDao;
import com.liu.springboot04web.dao.Kn05S001LsnFixDao;

@RestController
@Service
public class Kn04I001StuWithdrawController4Mobile {

    @Autowired
    Kn04I001StuWithdrawDao knStu001Dao;
    @Autowired
    Kn05S001LsnFixDao knFixLsn001Dao;

    // 手机前端退学休学的学生信息取得
    @GetMapping("/mb_kn_stu_leave_all")
    public ResponseEntity<Collection<Kn04I001StuWithdrawBean>> getStuLeaveList() {
        // 获取休学学生信息
        Collection<Kn04I001StuWithdrawBean> collection = knStu001Dao.getInfoList(null, 1);
        return ResponseEntity.ok(collection);
    }

    // 手机前端退学休学的学生信息取得
    @GetMapping("/mb_kn_stu_onLsn_all")
    public ResponseEntity<Collection<Kn04I001StuWithdrawBean>> getStuOnLesonList() {
        // 获取休学学生信息
        Collection<Kn04I001StuWithdrawBean> collection = knStu001Dao.getInfoList(null, 0);
        return ResponseEntity.ok(collection);
    }

    // 手机前端执行学生退学/休学处理，可选复述个学生一并执行
    @PostMapping("/mb_kn_stu_leave")
    @Transactional
    public ResponseEntity<String> stuWithdraw(@RequestBody List<Kn03D001StuBean> beans) {
        // 更严密的业务逻辑应该是：在学生退学的时候，要对该生进行学费查账
        // 如果学费已交齐，则可以执行删除操作
        // 否则要先清理完欠的学费，或者给出可以欠学费的情况下可以退学的理由。否则不予以退学处理（2025/10/26 记录）。
        // TODO

        // 处理多个对象的逻辑
        knStu001Dao.stuWithdraw(beans);
        // 删除该生在固定排课表里的记录
        for (Kn03D001StuBean bean : beans) {
            knFixLsn001Dao.deleteByKeys(bean.getStuId(), null, null);
        }
        return ResponseEntity.ok("退学处理成功");
    }

    // 手机前端执行学生复学处理，只能是单个执行
    @PostMapping("/mb_kn_stu_return/{stuId}")
    public ResponseEntity<String> excuteReturn( @PathVariable("stuId") String stuId) {
        // 处理多个对象的逻辑
        knStu001Dao.stuReinstatement(stuId);
        return ResponseEntity.ok("复学处理成功");
    }

    // 退学前学费查账：取得该学生的未付款课费列表（空列表=学费已交齐）
    @GetMapping("/mb_kn_stu_fee_check/{stuId}")
    public ResponseEntity<List<Kn04I001StuUnpaidFeeBean>> checkStuFee(@PathVariable("stuId") String stuId) {
        List<Kn04I001StuUnpaidFeeBean> unpaidList = knStu001Dao.getUnpaidFeesByStuId(stuId);
        return ResponseEntity.ok(unpaidList);
    }

    // 强行退学：批量标记坏账 + 执行退学（事务保证原子性）
    @PostMapping("/mb_kn_stu_force_leave/{stuId}")
    @Transactional
    public ResponseEntity<String> forceLeave(@PathVariable("stuId") String stuId,
                                             @RequestParam String memo) {
        // 1. 批量标记该学生所有未付款课费为坏账（含理由）
        knStu001Dao.batchMarkBadDebtByStuId(stuId, memo);
        // 2. 执行退学
        knStu001Dao.stuWithdraw(stuId);
        // 3. 删除该生在固定排课表里的记录
        knFixLsn001Dao.deleteByKeys(stuId, null, null);
        return ResponseEntity.ok("强行退学处理成功");
    }

}
