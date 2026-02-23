package com.liu.springboot04web.othercommon;

/**
 * 系统全局常量定义类
 * 用于统一管理系统级别的配置常量
 *
 * @author Liu
 * @date 2026-01-07
 */
public class SystemConstants {

    /**
     * 系统年度管理：年度选择器的起始年度
     * 说明：所有年度下拉框、年度列表生成都应使用此常量
     *
     * ⚠️ 重要：修改此值时，务必同步更新前端 Constants.systemStartedYear
     * 前端路径：01FlutterApps/front_dart_flutter/lib/Constants.dart
     *
     * 当前值：2024
     * 修改历史：
     *   - 2026-01-07: 从2017/2018统一修改为2024
     */
    public static final int SYSTEM_STARTED_YEAR = 2024;

    /**
     * 私有构造函数，防止实例化
     * 此类仅包含静态常量和静态方法，不应被实例化
     */
    private SystemConstants() {
        throw new AssertionError("Cannot instantiate constants class");
    }
}
