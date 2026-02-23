package com.liu.springboot04web.othercommon;

import java.text.SimpleDateFormat;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;

public class DateUtils {

    /**
     * 获取系统日期并转换为 "yyyy/MM" 形式的字符串
     *
     * @return 格式化后的日期字符串
     */
    public static String getCurrentDateYearMonth() {
        // 获取当前系统日期
        LocalDate currentDate = LocalDate.now();
        
        // 定义目标日期格式
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM");
        
        // 格式化日期
        return currentDate.format(formatter);
    }

     /**
     * 将 Date 对象转换为 "yyyy/MM" 形式的字符串
     *
     * @param date 要转换的 Date 对象
     * @return 格式化后的日期字符串
     */
    public static String getCurrentDateYearMonth(Date date) {
  
        // 定义目标日期格式
        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM");
        
        // 格式化日期
        return formatter.format(date);
    }

    /**
     * 获取年度列表（下拉框使用）
     * 返回从系统起始年度(SystemConstants.SYSTEM_STARTED_YEAR)到当前年份的降序列表
     *
     * @return 年度字符串列表，例如: ["2026", "2025", "2024"]
     */
    public static List<String> getYearList() {
        // 获取当前年份
        int currentYear = Calendar.getInstance().get(Calendar.YEAR);
        // 创建年份列表，从SystemConstants.SYSTEM_STARTED_YEAR开始到当前年份
        List<String> yearList = new ArrayList<>();
        for (int year = currentYear; year >= SystemConstants.SYSTEM_STARTED_YEAR; year--) {
            yearList.add(String.valueOf(year));
        }
        return yearList;
    }

    /**
     * 方法1: 灵活解析日期格式并比较（推荐）
     * 自动识别日期格式并比较两个日期，只比较到年月日
     * @param firstDate 可能的格式: yyyy-MM-dd 或 yyyy-MM-dd HH:mm
     * @param secondDate 可能的格式: yyyy-MM-dd 或 yyyy-MM-dd HH:mm
     * @return 如果firstDate <= secondDate返回true，否则返回false
     */
    public static boolean compareDatesMethod1(String firstDate, String secondDate) {
        // 解析第一个日期，自动识别格式
        LocalDate date1 = parseToLocalDate(firstDate);
        
        // 解析第二个日期，自动识别格式
        LocalDate date2 = parseToLocalDate(secondDate);
        
        // 比较：date1 <= date2
        return !date1.isAfter(date2);
    }
    
    /**
     * 辅助方法：自动识别日期格式并转换为LocalDate
     * @param dateString 日期字符串，格式可能是 yyyy-MM-dd 或 yyyy-MM-dd HH:mm
     * @return LocalDate对象
     */
    private static LocalDate parseToLocalDate(String dateString) {
        if (dateString == null || dateString.trim().isEmpty()) {
            throw new IllegalArgumentException("日期字符串不能为空");
        }
        
        dateString = dateString.trim();
        
        try {
            // 尝试解析为 yyyy-MM-dd HH:mm 格式
            if (dateString.contains(" ") && dateString.length() > 10) {
                LocalDateTime dateTime = LocalDateTime.parse(dateString, 
                    DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
                return dateTime.toLocalDate();
            } else {
                // 解析为 yyyy-MM-dd 格式
                return LocalDate.parse(dateString, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            }
        } catch (Exception e) {
            throw new IllegalArgumentException("无法解析日期格式: " + dateString + 
                ". 支持的格式: yyyy-MM-dd 或 yyyy-MM-dd HH:mm", e);
        }
    }
    
    /**
     * 方法2: 如果bean返回的是Date对象
     * @param firstDate Date对象
     * @param secondDate Date对象
     * @return 如果adjustedDate <= schedualDate返回true，否则返回false
     */
    public static boolean compareDatesMethod2(Date firstDate, Date secondDate) {
        // 将Date转换为LocalDate进行比较
        LocalDate date1 = firstDate.toInstant()
                .atZone(java.time.ZoneId.systemDefault())
                .toLocalDate();
        
        LocalDate date2 = secondDate.toInstant()
                .atZone(java.time.ZoneId.systemDefault())
                .toLocalDate();
        
        return date1.isBefore(date2) || date1.isEqual(date2);
    }

    /** 2025-11-08 新增
     * 计算指定日期所在月份中，有多少个与该日期相同星期几的天数。
     * 例如，如果输入的日期是星期二，则计算该月有多少个星期二。
     *
     * @param dateStr 日期字符串，格式为"yyyy-MM-dd"，例如"2025-09-30"
     * @return 该月中相同星期几的天数
     * @throws DateTimeParseException 如果输入的日期字符串格式不正确
     */
    public static int countWeekdaysInMonth(String dateStr) {
        // 解析输入的日期字符串
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        LocalDate date = LocalDate.parse(dateStr, formatter);
        
        // 获取输入日期是星期几
        DayOfWeek targetDayOfWeek = date.getDayOfWeek();
        
        // 获取该月的第一天
        LocalDate firstDayOfMonth = date.withDayOfMonth(1);
        
        // 获取该月第一个目标星期几的日期
        LocalDate firstTargetDay = firstDayOfMonth;
        while (firstTargetDay.getDayOfWeek() != targetDayOfWeek) {
            firstTargetDay = firstTargetDay.plusDays(1);
        }
        
        // 计数该月中有多少个相同的星期几
        int count = 0;
        LocalDate currentDate = firstTargetDay;
        
        while (currentDate.getMonthValue() == date.getMonthValue()) {
            count++;
            currentDate = currentDate.plusDays(7);
        }
        
        return count;
    }
}

