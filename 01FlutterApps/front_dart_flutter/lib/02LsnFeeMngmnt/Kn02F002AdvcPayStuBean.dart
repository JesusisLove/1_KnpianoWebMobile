class Kn02F002AdvcPayStuBean {
  final String stuId;
  final String stuName;
  final String? nikName;
  final bool hasMonthly;
  final bool hasPerLsn;
  final String? monthlySubjectNames;  // 按月科目名称（「、」拼接）
  final String? perLsnSubjectNames;   // 按课时科目名称（「、」拼接）

  Kn02F002AdvcPayStuBean({
    required this.stuId,
    required this.stuName,
    this.nikName,
    required this.hasMonthly,
    required this.hasPerLsn,
    this.monthlySubjectNames,
    this.perLsnSubjectNames,
  });

  String get displayName =>
      (nikName != null && nikName!.isNotEmpty) ? nikName! : stuName;

  factory Kn02F002AdvcPayStuBean.fromJson(Map<String, dynamic> json) {
    return Kn02F002AdvcPayStuBean(
      stuId: json['stuId'] ?? '',
      stuName: json['stuName'] ?? '',
      nikName: json['nikName'] as String?,
      hasMonthly: (json['hasMonthly'] == 1),
      hasPerLsn: (json['hasPerLsn'] == 1),
      monthlySubjectNames: json['monthlySubjectNames'] as String?,
      perLsnSubjectNames: json['perLsnSubjectNames'] as String?,
    );
  }
}
