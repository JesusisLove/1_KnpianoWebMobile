// ignore: file_names
import 'package:intl/intl.dart';

import '../../CommonProcess/CommonMethod.dart';

class Kn01L003LsnExtraBean {
  final String lessonId;
  final String subjectId;
  final String subjectSubId;
  final String subjectName;
  final String subjectSubName;
  final String stuId;
  final String stuName;
  final int classDuration;
  final int lessonType;
  final int schedualType;
  final int payFlg;
  final String lsnFeeId;
  final double lsnFee;
  final int isGoodChange;
  final String schedualDate;
  final String scanQrDate;
  final String lsnAdjustedDate;
  late String extraToDurDate;
  final String originalSchedualDate;
  final bool badDebtFlg;

  Kn01L003LsnExtraBean({
    required this.lessonId,
    required this.subjectId,
    required this.subjectSubId,
    required this.subjectName,
    required this.subjectSubName,
    required this.stuId,
    required this.stuName,
    required this.classDuration,
    required this.lessonType,
    required this.schedualType,
    required this.payFlg,
    required this.lsnFeeId,
    required this.lsnFee,
    required this.isGoodChange,
    required this.schedualDate,
    required this.scanQrDate,
    required this.lsnAdjustedDate,
    required this.extraToDurDate,
    required this.originalSchedualDate,
    this.badDebtFlg = false,
  });

  factory Kn01L003LsnExtraBean.fromJson(Map<String, dynamic> json) {
    String formattedSchedualDate = '';
    String formattedScanQrDate = '';
    String formattedLsnAdjustedDate = '';
    String formattedExtraToDurDate = '';
    String formattedOriginalSchedualDate = '';

    try {
      if (json['schedualDate'] != null &&
          json['schedualDate'].toString().isNotEmpty) {
        // DateTime parsedDate = DateTime.parse(json['schedualDate']);
        // formattedSchedualDate = DateFormat('yyyy-MM-dd HH:mm').format(parsedDate.toLocal());
        DateTime parsedDate =
            CommonMethod.parseServerDate(json['schedualDate']);
        formattedSchedualDate =
            DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
      }

      if (json['scanQrDate'] != null &&
          json['scanQrDate'].toString().isNotEmpty) {
        // DateTime parsedDate = DateTime.parse(json['scanQrDate']);
        // formattedScanQrDate = DateFormat('yyyy-MM-dd').format(parsedDate.toLocal());
        DateTime parsedDate = CommonMethod.parseServerDate(json['scanQrDate']);
        formattedScanQrDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      }

      if (json['lsnAdjustedDate'] != null &&
          json['lsnAdjustedDate'].toString().isNotEmpty) {
        // DateTime parsedDate = DateTime.parse(json['lsnAdjustedDate']);
        // formattedLsnAdjustedDate = DateFormat('yyyy-MM-dd HH:mm').format(parsedDate.toLocal());
        DateTime parsedDate =
            CommonMethod.parseServerDate(json['lsnAdjustedDate']);
        formattedLsnAdjustedDate =
            DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
      }

      if (json['extraToDurDate'] != null &&
          json['extraToDurDate'].toString().isNotEmpty) {
        // DateTime parsedDate = DateTime.parse(json['extraToDurDate']);
        // formattedExtraToDurDate =
        //     DateFormat('yyyy-MM-dd').format(parsedDate.toLocal());
        DateTime parsedDate =
            CommonMethod.parseServerDate(json['extraToDurDate']);
        formattedExtraToDurDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      }

      if (json['originalSchedualDate'] != null &&
          json['originalSchedualDate'].toString().isNotEmpty) {
        // DateTime parsedDate = DateTime.parse(json['originalSchedualDate']);
        // formattedOriginalSchedualDate =
        //     DateFormat('yyyy-MM-dd HH:mm').format(parsedDate.toLocal());
        DateTime parsedDate =
            CommonMethod.parseServerDate(json['originalSchedualDate']);
        formattedOriginalSchedualDate =
            DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    return Kn01L003LsnExtraBean(
      lessonId: json['lessonId'] ?? '',
      subjectId: json['subjectId'] ?? '',
      subjectSubId: json['subjectSubId'] ?? '',
      subjectName: json['subjectName'] ?? '',
      subjectSubName: json['subjectSubName'] ?? '',
      stuId: json['stuId'] ?? '',
      stuName: json['stuName'] ?? '',
      classDuration: json['classDuration'] ?? 0,
      lessonType: json['lessonType'] ?? 0,
      schedualType: json['schedualType'] ?? 0,
      payFlg: json['payFlg'] ?? 0,
      lsnFeeId: json['lsnFeeId'] ?? '',
      lsnFee: (json['lsnFee'] ?? 0.0).toDouble(),
      isGoodChange: json['isGoodChange'] ?? 0,
      schedualDate: formattedSchedualDate,
      scanQrDate: formattedScanQrDate,
      lsnAdjustedDate: formattedLsnAdjustedDate,
      extraToDurDate: formattedExtraToDurDate,
      originalSchedualDate: formattedOriginalSchedualDate,
      badDebtFlg: (json['badDebtFlg'] ?? 0) == 1,
    );
  }

// 创建一个符合后端格式的对象
  Map<String, dynamic> toRequestMap(String selectedDate) {
    return {
      'lessonId': lessonId,
      'subjectId': subjectId,
      'subjectSubId': subjectSubId,
      'subjectName': subjectName,
      'subjectSubName': subjectSubName,
      'stuId': stuId,
      'stuName': stuName,
      'classDuration': classDuration,
      'lessonType': lessonType,
      'schedualType': schedualType,
      'payFlg': payFlg,
      'lsnFeeId': lsnFeeId,
      'lsnFee': lsnFee,
      'isGoodChange': isGoodChange,
      // 统一日期格式为 "yyyy-MM-dd HH:mm"
      'schedualDate': schedualDate,
      'scanQrDate': null, // 如果不需要修改这个字段，设为null
      'lsnAdjustedDate': lsnAdjustedDate,
      'extraToDurDate': "$selectedDate 00:00", // 新选择的日期
      'originalSchedualDate': originalSchedualDate,
    };
  }
}
