package com.liu.springboot04web.mapper;

import com.liu.springboot04web.bean.Kn03D001StuBean;
import com.liu.springboot04web.bean.Kn04I001StuUnpaidFeeBean;
import com.liu.springboot04web.bean.Kn04I001StuWithdrawBean;

import org.apache.ibatis.annotations.Param;
import java.util.List;

public interface Kn04I001StuWithdrawMapper {

    // 后端维护用：取得在课记录或休学的学生记录
    List<Kn03D001StuBean> getInfoList();

    // 手机前端用：取得在课记录或休学的学生记录
    List<Kn04I001StuWithdrawBean> getInfoListWitParm(@Param("stuId") String stuId, @Param("delFlg") Integer delFlg);

    // 后端维护的Web页面里的休学/退学处理-
    void stuWithdrawProcessSingle(@Param("stuId") String stuId);

    // 手机前端页面里的休学/退学处理（可选复述个学生）
    void stuWithdrawProcessList(@Param("beans") List<Kn03D001StuBean> beans);

    // 复学处理
    void stuReinstatement(@Param("stuId") String stuId);

    // 退学前学费查账：取得该学生的未付款课费列表
    List<Kn04I001StuUnpaidFeeBean> getUnpaidFeesByStuId(@Param("stuId") String stuId);

    // 强行退学：批量标记该学生的所有未付款课费为坏账
    void batchMarkBadDebtByStuId(@Param("stuId") String stuId, @Param("memo") String memo);

}
