/// KnMessagesBase.dart
/// 提示框消息文字抽象基类
/// 所有消息 key 在此定义，各语言实现类继承此类并实现所有 getter
///
/// 使用规范：
/// - 含 %s 占位符的消息，调用时用 .replaceFirst('%s', value) 替换
/// - 含多个 %s 的消息，依次调用 .replaceFirst() 替换
/// - 动态错误内容（$responseBody / $e 等）不在此定义，由调用方直接传入
abstract class KnMessagesBase {

  // ══════════════════════════════════════════════════════════════
  // 对话框标题（title）
  // ══════════════════════════════════════════════════════════════
  String get titleSubmitSuccess;        // 提交成功
  String get titleSubmitFailed;         // 提交失败
  String get titleUpdateSuccess;        // 更新成功
  String get titleError;                // 错误
  String get titleInputError;           // 输入错误
  String get titleOperationError;       // 操作异常
  String get titleSignInConfirm;        // 执行签到确认
  String get titleUndoConfirm;          // 撤销确认
  String get titleDeleteConfirm;        // 删除确认
  String get titleCancelReschedule;     // 取消调课确认
  String get titleConfirm;              // 确认
  String get titleSchedulingBanned;     // 排课禁止
  String get titleUnableToConvert;      // 无法换正课
  String get titleBadDebtUndoConfirm;   // 撤销坏账确认
  String get titleForceWithdrawConfirm; // 强行退学确认
  String get titleUnsettledBills;       // 未结算账单
  String get titleScheduleConfirm;      // 确认排课

  // ══════════════════════════════════════════════════════════════
  // 成功提示消息（success）
  // ══════════════════════════════════════════════════════════════
  String get successStuInfoSave;        // 学生信息已保存
  String get successStuInfoUpdate;      // 学生信息已更新
  String get successStuArchiveSave;     // 学生档案已成功保存。
  String get successSubjectSave;        // 科目信息已保存
  String get successBankInfoSave;       // 银行信息已保存
  String get successFixedLessonAdd;     // 固定排课时间已提交
  String get successFixedLessonUpdate;  // 固定排课时间已更新

  // ══════════════════════════════════════════════════════════════
  // 确认对话框消息（confirm）
  // ※ 含 %s 占位符，调用时用 .replaceFirst('%s', value) 替换
  // ══════════════════════════════════════════════════════════════
  String get confirmLessonSignIn;           // 签到【%s】这节课，\n当日之内可以撤销，过了今日撤销不可！\n您确定要签到吗？
  String get confirmLessonUndoSignIn;       // 确实要撤销【%s】这节课吗？
  String get confirmLessonDelete;           // 确实要删除【%s】这节课吗？删除后将无法恢复
  String get confirmLessonCancelReschedule; // 确实要取消这次调课吗？
  String get confirmBankDelete;             // 确定要删除【%s】吗？
  String get confirmFixedLessonDelete;      // 确实要删除该固定课程吗？
  String get confirmPaymentUndo;            // 您确定要撤销这笔支付吗？
  String get confirmBadDebtUndo;            // 确定撤销「%s」的\n「%s」（%s）坏账标记吗？\n撤销后该课费将重新出现在未付款列表中。

  // ══════════════════════════════════════════════════════════════
  // 进度提示消息（loading）
  // ※ 含 %s 的，调用时替换为「添加」「编辑」等操作名
  // ══════════════════════════════════════════════════════════════
  String get loadingStuInfoSave;        // 正在登记学生信息...
  String get loadingStuInfoUpdate;      // 正在更新学生信息...
  String get loadingStuArchiveSave;     // 正在登记学生档案信息...
  String get loadingSubjectSave;        // 正在%s科目信息...
  String get loadingBankInfoSave;       // 正在%s银行信息...
  String get loadingBankStuSave;        // 正在登录学生银行信息...
  String get loadingLsnFeePay;          // 正在处理学费入账......
  String get loadingAdvancedFeePay;     // 正在处理学费预支付......
  String get loadingPerLessonFeePay;    // 正在处理按课时预支付......
  String get loadingCourseAdd;          // 正在添加课程...
  String get loadingFixedLessonAdd;     // 正在添加固定排课处理...
  String get loadingFixedLessonUpdate;  // 正在更新固定排课处理...
  String get loadingScheduleExecute;    // 正在执行排课，请稍候...

  // ══════════════════════════════════════════════════════════════
  // SnackBar 提示消息（snack）
  // ══════════════════════════════════════════════════════════════
  String get snackBadDebtUndo;          // 已撤销坏账标记
  String get snackBadDebtMark;          // 已标记为坏账
  String get snackStudentWithdrawn;     // 退学处理成功（%s 名）
  String get snackStudentReenrolled;    // 学生已成功复学
  String get snackLessonConvertSuccess; // 加课换正课执行成功！
  String get snackUndoSuccess;          // 撤销成功
  String get snackPinChanged;           // PIN码修改完成
  String get snackThemeChanged;         // 已切换到「%s」主题
  String get snackLockNever;            // 已设置为从不自动锁定
  String get snackLockTimerSet;         // 自动锁定时间已设置为%s
  String get snackFeatureInDevelopment; // 语言切换功能开发中
  String get snackMemoUpdated;          // 备注更新成功
}
