import 'package:intl/intl.dart';

import '../CommonProcess/CommonMethod.dart';

class Kn02F002FeeBean {
  final String lsnPayId;
  final String lsnFeeId;
  final String lessonId;
  final double lsnFee;
  final double lsnPay;
  final String lsnMonth;
  late int ownFlg;
  final int lessonType;
  late String stuId;
  final String subjectId;
  late String stuName; // 因为后续需要赋值操作，所以由final改为late
  String? nikName; //因为从后台返回的nikName有可能是NULL
  final String subjectName;
  final int payStyle;
  final double lsnCount;
  // 画面用变量
  final int month;
  final String? payDate;
  final int? payStatus;
  // chart图上初期化各科目1年中每月的课程数量图
  final double totalLsnCount0;
  final double totalLsnCount1;
  final double totalLsnCount2;
  // 为了按月交费的计划课的精算业务，需要《学生档案》表里对象科目的最新价格
  final double? subjectPrice;
  // 新增：识别该精算课费是不是预支付的课费（只有advcFlg=0 是预支付课费）
  final int advcFlg;
  final String bankName;
  // 坏账标记：0=正常，1=坏账
  final int badDebtFlg;

  Kn02F002FeeBean({
    required this.lsnPayId,
    required this.lsnFeeId,
    required this.lessonId,
    required this.lsnFee,
    required this.lsnPay,
    required this.lsnMonth,
    required this.ownFlg,
    required this.lessonType,
    required this.stuId,
    required this.subjectId,
    required this.stuName,
    this.nikName,
    required this.subjectName,
    required this.payStyle,
    required this.lsnCount,
    // 画面用变量
    required this.month,
    required this.payDate,
    required this.payStatus,
    required this.totalLsnCount0,
    required this.totalLsnCount1,
    required this.totalLsnCount2,
    required this.subjectPrice,
    required this.advcFlg,
    required this.bankName,
    required this.badDebtFlg,
  });

  factory Kn02F002FeeBean.fromJson(Map<String, dynamic> json) {
    String formattedPayDate = '';

    try {
      if (json['payDate'] != null && json['payDate'] != '') {
        // DateTime parsedDate = DateTime.parse(json['payDate']);
        // formattedPayDate =
        //     DateFormat('yyyy-MM-dd').format(parsedDate);
        DateTime parsedDate = CommonMethod.parseServerDate(json['payDate']);
        formattedPayDate =
            DateFormat('yyyy-MM-dd').format(parsedDate);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing or formatting payDate: $e');
    }

    String lsnMonth = json['lsnMonth'] ?? '';
    int month = 0; // 从 "2024-06" 提取月份
    if (lsnMonth.isNotEmpty) {
      try {
        month = int.parse(lsnMonth.split('-')[1]);
      } catch (e) {
        // ignore: avoid_print
        print('Error parsing month: $e');
      }
    }

    return Kn02F002FeeBean(
      lsnPayId: json['lsnPayId'] ?? '',
      lsnFeeId: json['lsnFeeId'] ?? '',
      lessonId: json['lessonId'] ?? '',
      lsnFee: json['lsnFee']?.toDouble() ?? 0.0,
      lsnPay: json['lsnPay']?.toDouble() ?? 0.0,
      lsnMonth: json['lsnMonth'] ?? '',
      ownFlg: json['ownFlg'] ?? 0,
      lessonType: json['lessonType'] ?? 0,
      stuId: json['stuId'] ?? '',
      subjectId: json['subjectId'] ?? '',
      stuName: json['stuName'] ?? '',
      nikName: json['nikName'] as String?,
      subjectName: json['subjectName'] ?? '',
      payStyle: json['payStyle'] ?? 0,
      lsnCount: json['lsnCount']?.toDouble() ?? 0.0,
      month: month,
      payDate: formattedPayDate,
      payStatus: json['payStatus'] as int? ?? 0,
      totalLsnCount0: json['totalLsnCount0']?.toDouble() ?? 0.0,
      totalLsnCount1: json['totalLsnCount1']?.toDouble() ?? 0.0,
      totalLsnCount2: json['totalLsnCount2']?.toDouble() ?? 0.0,
      subjectPrice: json['subjectPrice']?.toDouble() ?? 0.0,
      advcFlg: json['advcFlg'] == 0 ? 0 : 1, // 只有advcFlg=0 才是预支付费用
      bankName: json['bankName'] ?? '',
      badDebtFlg: json['badDebtFlg'] ?? 0,
    );
  }
}
