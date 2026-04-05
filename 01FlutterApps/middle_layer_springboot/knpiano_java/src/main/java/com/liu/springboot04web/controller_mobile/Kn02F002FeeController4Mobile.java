package com.liu.springboot04web.controller_mobile;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.liu.springboot04web.bean.Kn02F002FeeBean;
import com.liu.springboot04web.bean.Kn02F004FeePaid4MobileBean;
import com.liu.springboot04web.bean.Kn02F004UnpaidBean;
import com.liu.springboot04web.dao.Kn02F002FeeDao;
import com.liu.springboot04web.dao.Kn02F004PayDao;
import com.liu.springboot04web.dao.Kn02F004UnpaidDao;

@RestController
@Service
public class Kn02F002FeeController4Mobile {

    @Autowired
    Kn02F002FeeDao knLsnFee001Dao;

    @Autowired
    Kn02F004UnpaidDao knLsnUnPaid001Dao;

    @Autowired
    Kn02F004PayDao knLsnPay001Dao;

    // 取得当前年度要付课费的学生名称一览
    @GetMapping("/mb_kn_lsn_fee_001_all/{selectedYear}")
    public ResponseEntity<List<Kn02F002FeeBean>> list(@PathVariable("selectedYear") Integer year) {
        List<Kn02F002FeeBean> list = knLsnFee001Dao.getStuNameList(Integer.toString(year));
        return ResponseEntity.ok(list);
    }

    // 取得该生当前年度的课费详细信息
    @GetMapping("/mb_kn_lsn_fee_by_year/{stuId}/{selectedYear}")
    /*  因为手机前端的处理根后台维护处理方式不同，手机前端是把Kn01002LsnBean，Kn02F004UnpaidBean，Kn02F004PayBean的项目都放在一起处理了
     *  所以，Kn02F004FeePaid4MobileBean就是上面三个Bean项目的并集。
    */
    public ResponseEntity<List<Kn02F004FeePaid4MobileBean>> getStuFeeDetaillist(@PathVariable("stuId") String stuId,
                                                                     @PathVariable("selectedYear") Integer year) {
        List<Kn02F004FeePaid4MobileBean> list = knLsnFee001Dao.getStuFeeDetaillist(stuId, Integer.toString(year));
        return ResponseEntity.ok(list);
    }

    // 手机前端：学费管理-->学费月度报告-->未缴纳学费明细-->点击“学生姓名”
    // 当观妮在学费月度报告模块的未支付明细里执行课费支付操作时，需要提供学生学号和学生要支付学费的月份，把该学生的未支付课费信息调出来执行学费支付操作。
    @GetMapping("/mb_kn_lsn_fee_by_yearmonth/{stuId}/{targetYearMonth}")
    public ResponseEntity<List<Kn02F004FeePaid4MobileBean>> getStuFeeDetailMonthlist(@PathVariable("stuId") String stuId,
                                                                     @PathVariable("targetYearMonth") String yearMonth) {
        List<Kn02F004FeePaid4MobileBean> list = knLsnFee001Dao.getStuFeeDetaillist(stuId, yearMonth);
        return ResponseEntity.ok(list);
    }

    // 在学生的课费账单画面点击【学费入账】按钮处理
    @PostMapping("/mb_kn_lsn_pay_save")
    public ResponseEntity<String> excuteLsnPay(@RequestBody List<Kn02F004UnpaidBean> kn02F004UnpaidList) {
        for (Kn02F004UnpaidBean kn02f002FeeBean : kn02F004UnpaidList) {
            knLsnUnPaid001Dao.excuteLsnPay(kn02f002FeeBean);
        }
        return ResponseEntity.ok("Ok");
    }

    // 【課費精算管理】撤销ボタンを押下して、当該情報を引き戻すこと
    @DeleteMapping("/mb_kn_lsn_pay_undo/{lsnPayId}/{lsnFeeId}/{payMonth}")
    public ResponseEntity<String> undoLsnPay(@PathVariable("lsnPayId") String lsnPayId,
                                             @PathVariable("lsnFeeId") String lsnFeeId,
                                             @PathVariable("payMonth") String payMonth) {
        knLsnPay001Dao.excuteUndoLsnPay(lsnPayId, lsnFeeId, payMonth);
        return ResponseEntity.ok("Ok");
    }

    // 获取学生上一个月支付时使用的银行ID（用于设置默认银行）
    @GetMapping("/mb_kn_default_bank/{stuId}/{currentMonth}")
    public ResponseEntity<String> getDefaultBankId(@PathVariable("stuId") String stuId,
                                                    @PathVariable("currentMonth") String currentMonth) {
        String bankId = knLsnFee001Dao.getLastPaymentBankId(stuId, currentMonth);
        return ResponseEntity.ok(bankId != null ? bankId : "");
    }

    // 坏账处理：标记坏账
    // 兼容两种课费类型：普通课费（t_info_lesson_fee.del_flg=0）和加课换正课课费（通过t_info_lesson_extra_to_sche关联）
    @PutMapping("/mb_kn_lsn_fee_bad_debt/{lsnFeeId}")
    public ResponseEntity<?> markBadDebt(@PathVariable String lsnFeeId,
                                         @RequestParam String memo) {
        int updated = knLsnFee001Dao.markBadDebt(lsnFeeId, memo);
        if (updated == 0) {
            return ResponseEntity.status(404).body("target record not found: " + lsnFeeId);
        }
        return ResponseEntity.ok("success");
    }

    // 坏账处理：撤销坏账
    // 兼容两种课费类型：普通课费和加课换正课课费
    @PutMapping("/mb_kn_lsn_fee_bad_debt_undo/{lsnFeeId}")
    public ResponseEntity<?> undoBadDebt(@PathVariable String lsnFeeId) {
        int updated = knLsnFee001Dao.undoBadDebt(lsnFeeId);
        if (updated == 0) {
            return ResponseEntity.status(404).body("target record not found: " + lsnFeeId);
        }
        return ResponseEntity.ok("success");
    }

    // 坏账一览取得（年度指定）
    @GetMapping("/mb_kn_lsn_fee_bad_debt_list/{year}")
    public ResponseEntity<List<Kn02F004FeePaid4MobileBean>> getBadDebtList(@PathVariable String year) {
        List<Kn02F004FeePaid4MobileBean> list = knLsnFee001Dao.getBadDebtList(year);
        return ResponseEntity.ok(list);
    }

    // 坏账详情取得（按lsn_fee_id查询对应的所有课程记录，用于详情对话框）
    @GetMapping("/mb_kn_lsn_fee_bad_debt_detail/{lsnFeeId}")
    public ResponseEntity<List<Kn02F004FeePaid4MobileBean>> getBadDebtDetail(@PathVariable String lsnFeeId) {
        List<Kn02F004FeePaid4MobileBean> list = knLsnFee001Dao.getBadDebtDetailByFeeId(lsnFeeId);
        return ResponseEntity.ok(list);
    }
}
