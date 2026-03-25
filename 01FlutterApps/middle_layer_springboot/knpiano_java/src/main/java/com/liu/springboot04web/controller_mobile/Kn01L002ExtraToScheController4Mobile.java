package com.liu.springboot04web.controller_mobile;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.liu.springboot04web.bean.Kn01L002ExtraToScheBean;
import com.liu.springboot04web.dao.Kn01L002ExtraToScheDao;

@RestController
public class Kn01L002ExtraToScheController4Mobile {
    @Autowired
    private Kn01L002ExtraToScheDao kn01L002ExtraToScheDao;

    // 手机前端：加课消化管理的在课学生一览
    @GetMapping("/mb_kn_lsn_all_extra/{year}")
    public ResponseEntity<List<Kn01L002ExtraToScheBean>> getInfoStuLsnExtraList(@PathVariable Integer year) {
        // 获取当前正在上课的所有学生的排课信息
        List<Kn01L002ExtraToScheBean> collection = kn01L002ExtraToScheDao.getLsnExtraInfoList(Integer.toString(year));
        return ResponseEntity.ok(collection);
    }

    // 因为有了配置类CorsConfig，这里的CrossOrigin的配置不需要了
    @GetMapping("/mb_kn_extratosche_all/{stuId}/{year}")
    public ResponseEntity<List<Kn01L002ExtraToScheBean>> getExtraLsnList(@PathVariable String stuId,
                                                                         @PathVariable String year) {

        // 学生最新档案基准日调整的设置（如果手机前端选择的是系统当前年度，基准日调整设置为null，如果是非系统当前年度，基准日调整设置为yyyy-12-31）
        String systemYear = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy"));
        String adjustedBaseDate = year.equals(systemYear) ? null : year + "-12-31";

        // 获取当前正在上课的所有学生的加课信息
        List<Kn01L002ExtraToScheBean> collection = kn01L002ExtraToScheDao.getInfoList(stuId, year, adjustedBaseDate);
        return ResponseEntity.ok(collection);
    }

    // 执行加课换正课
    @PostMapping("/mb_kn_extra_tobe_sche")
    public ResponseEntity<String> executeExtra(@RequestBody Kn01L002ExtraToScheBean extraToScheBean) {
        try {
            // 参数验证
            if (extraToScheBean.getExtraToDurDate() == null) {
                return ResponseEntity.badRequest().body("换课日期不能为空");
            }

            // 坏账检查：若该加课课程已被标记为坏账，拒绝换正课
            if (kn01L002ExtraToScheDao.isBadDebtLesson(extraToScheBean.getLessonId())) {
                return ResponseEntity.status(HttpStatus.CONFLICT).body("坏账课程无法换正课");
            }

            // 执行加课换正课处理
            kn01L002ExtraToScheDao.executeExtraToSche(extraToScheBean);

            return ResponseEntity.ok("success");
        } catch (Exception e) {
            // 记录日志
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("处理失败：" + e.getMessage());
        }
    }

    // 撤销加课换正课
    @GetMapping("/mb_kn_extra_lsn_undo/{lessonId}")
    public ResponseEntity<Map<String, String>> undoExtra(@PathVariable String lessonId) {
        try {
            kn01L002ExtraToScheDao.undoExtraToSche(lessonId);
            Map<String, String> response = new HashMap<>();
            response.put("status", "success");
            response.put("message", "撤销成功");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("status", "error");
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

}
