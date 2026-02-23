// FixLesson.dart
// [固定排课新潮界面] 2026-02-12 添加 classDuration、endTime、cellSpan、timeSlotIndex

class KnFixLsn001Bean {
  final String studentId;
  final String subjectId;
  final String studentName;
  final String subjectName;
  final String fixedWeek;
  final int fixedHour;
  final int fixedMinute;
  final String classTime;
  final int classDuration; // 课程时长（分钟），默认45

  KnFixLsn001Bean({
    required this.studentId,
    required this.subjectId,
    required this.studentName,
    required this.subjectName,
    required this.fixedWeek,
    required this.fixedHour,
    required this.fixedMinute,
    required this.classTime,
    this.classDuration = 45,
  });

  factory KnFixLsn001Bean.fromJson(Map<String, dynamic> json) {
    return KnFixLsn001Bean(
      studentId: json['stuId'] ?? '',
      subjectId: json['subjectId'] ?? '',
      studentName: json['stuName'] ?? '',
      subjectName: json['subjectName'] ?? '',
      fixedWeek: json['fixedWeek'] ?? '',
      fixedHour: json['fixedHour'] ?? 0,
      fixedMinute: json['fixedMinute'] ?? 0,
      classTime:
          '${(json['fixedHour'] ?? 0).toString().padLeft(2, '0')}:${(json['fixedMinute'] ?? 0).toString().padLeft(2, '0')}',
      classDuration: json['classDuration'] ?? 45,
    );
  }

  /// 计算结束时间
  String get endTime {
    final totalMinutes = fixedHour * 60 + fixedMinute + classDuration;
    final endHour = (totalMinutes ~/ 60) % 24;
    final endMinute = totalMinutes % 60;
    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  /// 计算占用格子数（15分钟为一格）
  int get cellSpan => (classDuration / 15).ceil();

  /// 获取时间槽索引（从08:00开始，每15分钟一个槽）
  int get timeSlotIndex => (fixedHour - 8) * 4 + (fixedMinute ~/ 15);
}
