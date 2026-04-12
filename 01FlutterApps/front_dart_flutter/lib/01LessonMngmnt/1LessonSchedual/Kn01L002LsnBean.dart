// ignore: file_names
import 'package:intl/intl.dart';

import '../../CommonProcess/CommonMethod.dart';

class Kn01L002LsnBean {
  final String lessonId;
  final String stuId;
  final String subjectId;
  final String subjectSubId;
  final String stuName;
  String? nikName; //因为从后台返回的nikName有可能是NULL
  final String subjectName;
  final String subjectSubName;
  late final int classDuration;
  final int lessonType;
  final String schedualDate; // 将其标记为 final，因为它在构造函数中被赋值。
  final String time;
  final String scanQrDate;
  final String lsnAdjustedDate;
  final String extraToDurDate;
  final String originalSchedualDate;
  String? memo; //为了可以NULL，不用final关键字
  final int isFromPiceseLsn; // 添加这个字段
  final bool badDebtFlg; // 坏账标记

  // 更新构造函数以正确赋值
  Kn01L002LsnBean({
    required this.lessonId,
    required this.stuId,
    required this.subjectId,
    required this.subjectSubId,
    required this.stuName,
    this.nikName,
    required this.subjectName,
    required this.subjectSubName,
    required this.classDuration,
    required this.lessonType,
    required this.schedualDate,
    required this.time,
    required this.scanQrDate,
    required this.lsnAdjustedDate,
    required this.extraToDurDate,
    required this.originalSchedualDate,
    this.memo, //为了可以NULL，不用required关键字
    required this.isFromPiceseLsn, // 添加这个参数
    this.badDebtFlg = false, // 坏账标记，默认正常
  });

  // 更新工厂方法以正确解析和格式化日期
  factory Kn01L002LsnBean.fromJson(Map<String, dynamic> json) {
    String formattedSchedualDate = '';
    String formattedTime = '';
    String formattedScanQrDate = "";
    String formattedLsnAdjustedDate = "";
    String formattedExtraToDurDate = "";
    String formattedOriginalSchedualDate = "";

    try {
      if (json['schedualDate'] != null && json['schedualDate'] != '') {
        DateTime parsedDate =
            CommonMethod.parseServerDate(json['schedualDate']);

        // 已经不再需要DateFormat('yyyy-MM-dd HH:mm').format(parsedDate.toLocal());的处理了
        // 因为时区已经在parseServerDate中处理
        formattedSchedualDate =
            DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
        formattedTime = DateFormat('HH:mm').format(parsedDate);
      }

      if (json['scanQrDate'] != null && json['scanQrDate'] != '') {
        DateTime parsedDate = CommonMethod.parseServerDate(json['scanQrDate']);
        formattedScanQrDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      }

      if (json['lsnAdjustedDate'] != null && json['lsnAdjustedDate'] != '') {
        DateTime parsedDate =
            CommonMethod.parseServerDate(json['lsnAdjustedDate']);
        formattedLsnAdjustedDate =
            DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
        formattedTime = DateFormat('HH:mm').format(parsedDate);
      }

      if (json['extraToDurDate'] != null && json['extraToDurDate'] != '') {
        DateTime parsedDate =
            CommonMethod.parseServerDate(json['extraToDurDate']);
        formattedExtraToDurDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      }

      if (json['originalSchedualDate'] != null &&
          json['originalSchedualDate'] != '') {
        DateTime parsedDate =
            CommonMethod.parseServerDate(json['originalSchedualDate']);
        formattedOriginalSchedualDate =
            DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
        formattedTime = DateFormat('HH:mm').format(parsedDate);
      }
    } catch (e) {
      print('Error parsing or formatting schedualDate: $e');
    }

    return Kn01L002LsnBean(
      lessonId: json['lessonId'] as String,
      stuId: json['stuId'] as String,
      subjectId: json['subjectId'] as String,
      subjectSubId: json['subjectSubId'] as String,
      stuName: json['stuName'] as String,
      nikName: json['nikName'] as String?,
      subjectName: json['subjectName'] as String,
      subjectSubName: json['subjectSubName'] as String,
      classDuration: json['classDuration'] as int,
      lessonType: json['lessonType'] as int,
      schedualDate: formattedSchedualDate,
      time: formattedTime,
      scanQrDate: formattedScanQrDate,
      lsnAdjustedDate: formattedLsnAdjustedDate,
      extraToDurDate: formattedExtraToDurDate,
      originalSchedualDate: formattedOriginalSchedualDate,
      memo: json['memo'] as String?,
      // 关键：确保字段名与后端返回的JSON字段名完全一致
      isFromPiceseLsn: json['isFromPiceseLsn'] as int? ?? 0, // 添加默认值保护
      badDebtFlg: (json['badDebtFlg'] ?? 0) == 1,
    );
  }
}
