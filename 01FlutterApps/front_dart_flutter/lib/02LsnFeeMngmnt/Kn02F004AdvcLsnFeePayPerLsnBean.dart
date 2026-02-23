import 'package:intl/intl.dart';

class Kn02F004AdvcLsnFeePayPerLsnBean {
  final String lessonId;
  final String lsnFeeId;
  final String lsnPayId;
  final String subjectId;
  final String subjectSubId;
  final String subjectName;
  final String subjectSubName;
  final String stuId;
  final String stuName;
  String? nikName;
  final int classDuration;
  final int lessonType;
  late String schedualDate;
  final int payStyle;
  final double subjectPrice;
  final int minutesPerLsn;
  final double lsnPay;
  late String bankId;
  final String bankName;
  final int advcFlg;
  late bool isChecked;
  late int lessonCount; // 按课时预支付的课时数
  // Preview SP返回的处理模式（A=新建, B=复用lesson, C=复用lesson+fee）
  final String? processingMode;
  final String? existingLessonId;
  final String? existingFeeId;
  final int? sequenceNo;

  Kn02F004AdvcLsnFeePayPerLsnBean(
      {required this.lessonId,
      required this.lsnFeeId,
      required this.lsnPayId,
      required this.subjectId,
      required this.subjectSubId,
      required this.subjectName,
      required this.subjectSubName,
      required this.stuId,
      required this.stuName,
      this.nikName,
      required this.classDuration,
      required this.lessonType,
      required this.schedualDate,
      required this.payStyle,
      required this.subjectPrice,
      required this.minutesPerLsn,
      required this.lsnPay,
      required this.bankId,
      required this.bankName,
      required this.advcFlg,
      required this.isChecked,
      required this.lessonCount,
      this.processingMode,
      this.existingLessonId,
      this.existingFeeId,
      this.sequenceNo});

  factory Kn02F004AdvcLsnFeePayPerLsnBean.fromJson(Map<String, dynamic> json) {
    String formattedSchedualDate = '';
    try {
      if (json['schedualDate'] != null && json['schedualDate'] != '') {
        DateTime parsedDate = DateTime.parse(json['schedualDate']);
        formattedSchedualDate =
            DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
      }
    } catch (e) {
      print('Error parsing or formatting schedualDate: $e');
    }

    return Kn02F004AdvcLsnFeePayPerLsnBean(
      lessonId: json['lessonId'] ?? '',
      lsnFeeId: json['lsnFeeId'] ?? '',
      lsnPayId: json['lsnPayId'] ?? '',
      subjectId: json['subjectId'] ?? '',
      subjectSubId: json['subjectSubId'] ?? '',
      subjectName: json['subjectName'] ?? '',
      subjectSubName: json['subjectSubName'] ?? '',
      stuId: json['stuId'] ?? '',
      stuName: json['stuName'] ?? '',
      nikName: json['nikName'] as String?,
      classDuration: json['classDuration'] ?? 0,
      lessonType: json['lessonType'] ?? 0,
      schedualDate: formattedSchedualDate,
      payStyle: json['payStyle'] ?? 0,
      subjectPrice: json['subjectPrice']?.toDouble() ?? 0.0,
      minutesPerLsn: json['minutesPerLsn'] ?? 0,
      lsnPay: json['lsnPay']?.toDouble() ?? 0.0,
      bankId: json['bankId'] ?? '',
      bankName: json['bankName'] ?? '',
      advcFlg: json['advcFlg'] ?? 0,
      isChecked: false,
      lessonCount: json['lessonCount'] ?? 4, // 默认4节课
      processingMode: json['processingMode'] as String?,
      existingLessonId: json['existingLessonId'] as String?,
      existingFeeId: json['existingFeeId'] as String?,
      sequenceNo: json['sequenceNo'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'lsnFeeId': lsnFeeId,
        'lsnPayId': lsnPayId,
        'subjectId': subjectId,
        'subjectSubId': subjectSubId,
        'subjectName': subjectName,
        'subjectSubName': subjectSubName,
        'stuId': stuId,
        'stuName': stuName,
        'classDuration': classDuration,
        'lessonType': lessonType,
        'schedualDate': schedualDate,
        'payStyle': payStyle,
        'subjectPrice': subjectPrice,
        'minutesPerLsn': minutesPerLsn,
        'lsnPay': lsnPay,
        'bankId': bankId,
        'bankName': bankName,
        'advcFlg': advcFlg,
        'lessonCount': lessonCount,
        'processingMode': processingMode,
        'existingLessonId': existingLessonId,
        'existingFeeId': existingFeeId,
        'sequenceNo': sequenceNo,
      };
}
