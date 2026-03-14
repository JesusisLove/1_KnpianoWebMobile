package com.liu.springboot04web.dao;

import com.liu.springboot04web.bean.Kn03D002SubEdaBanBean;
import com.liu.springboot04web.constant.KNConstant;
import com.liu.springboot04web.mapper.Kn03D002SubEdaBanMapper;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Repository
public class Kn03D002SubEdaBanDao implements InterfaceKnPianoDao {

    @Autowired
    private Kn03D002SubEdaBanMapper kn05S003SubjectEdabnMapper;

    public List<Kn03D002SubEdaBanBean> getInfoList() {
        List<Kn03D002SubEdaBanBean> list = kn05S003SubjectEdabnMapper.getInfoList();
        return list;
    }

    // 手机端查询用
    public List<Kn03D002SubEdaBanBean> getSubEdaList(String subId) {
        List<Kn03D002SubEdaBanBean> list = kn05S003SubjectEdabnMapper.getSubEdaList(subId);
        return list;
    }

    // 获取所有符合查询条件的学生档案信息
    public List<Kn03D002SubEdaBanBean> searchEdaSubject(Map<String, Object> params) {
        return kn05S003SubjectEdabnMapper.searchEdaSubject(params);
    }

    public Kn03D002SubEdaBanBean getInfoById(String id) {
        return null;
    }

    public Kn03D002SubEdaBanBean getInfoById(String subId, String edabanId) {
        Kn03D002SubEdaBanBean kn05S003SubjectEdabnBean = kn05S003SubjectEdabnMapper.getInfoById(subId, edabanId);
        return kn05S003SubjectEdabnBean;
    }

    public void save(Kn03D002SubEdaBanBean kn05S003SubjectEdabnBean) {
        if (kn05S003SubjectEdabnBean.getSubjectSubId() == null
                || kn05S003SubjectEdabnBean.getSubjectSubId().isEmpty()) {

            Map<String, Object> map = new HashMap<String, Object>();
            map.put("parm_in", KNConstant.CONSTANT_KN_SUB_EDA_SEQ);
            // 授業自動採番
            kn05S003SubjectEdabnMapper.getNextSequence(map);
            kn05S003SubjectEdabnBean
                    .setSubjectSubId(KNConstant.CONSTANT_KN_SUB_EDA_SEQ + (Integer) map.get("parm_out"));

            insert(kn05S003SubjectEdabnBean);
        } else {
            update(kn05S003SubjectEdabnBean);
        }
    }

    // 新規
    private void insert(Kn03D002SubEdaBanBean kn05S003SubjectEdabnBean) {
        kn05S003SubjectEdabnMapper.insertInfo(kn05S003SubjectEdabnBean);

    }

    // 変更
    private void update(Kn03D002SubEdaBanBean kn05S003SubjectEdabnBean) {
        kn05S003SubjectEdabnMapper.updateInfo(kn05S003SubjectEdabnBean);
    }

    // 削除
    public void delete(String subId, String edabanId) {
        kn05S003SubjectEdabnMapper.deleteInfo(subId, edabanId);
    }
}