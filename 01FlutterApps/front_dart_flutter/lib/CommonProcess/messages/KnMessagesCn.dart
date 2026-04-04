import 'KnMessagesBase.dart';

/// KnMessagesCn.dart
/// 消息文字中文实现
/// 新增提示文字时，必须同时在 KnMessagesBase.dart 中追加抽象定义
class KnMessagesCn extends KnMessagesBase {

  // ══════════════════════════════════════════════════════════════
  // 对话框标题（title）
  // ══════════════════════════════════════════════════════════════
  @override String get titleSubmitSuccess        => '提交成功';
  @override String get titleSubmitFailed         => '提交失败';
  @override String get titleUpdateSuccess        => '更新成功';
  @override String get titleError                => '错误';
  @override String get titleInputError           => '输入错误';
  @override String get titleOperationError       => '操作异常';
  @override String get titleSignInConfirm        => '执行签到确认';
  @override String get titleUndoConfirm          => '撤销确认';
  @override String get titleDeleteConfirm        => '删除确认';
  @override String get titleCancelReschedule     => '取消调课确认';
  @override String get titleConfirm              => '确认';
  @override String get titleSchedulingBanned     => '排课禁止';
  @override String get titleUnableToConvert      => '无法换正课';
  @override String get titleBadDebtUndoConfirm   => '撤销坏账确认';
  @override String get titleForceWithdrawConfirm => '强行退学确认';
  @override String get titleUnsettledBills       => '未结算账单';
  @override String get titleScheduleConfirm      => '确认排课';

  // ══════════════════════════════════════════════════════════════
  // 成功提示消息（success）
  // ══════════════════════════════════════════════════════════════
  @override String get successStuInfoSave        => '学生信息已保存';
  @override String get successStuInfoUpdate      => '学生信息已更新';
  @override String get successStuArchiveSave     => '学生档案已成功保存。';
  @override String get successSubjectSave        => '科目信息已保存';
  @override String get successBankInfoSave       => '银行信息已保存';
  @override String get successFixedLessonAdd     => '固定排课时间已提交';
  @override String get successFixedLessonUpdate  => '固定排课时间已更新';

  // ══════════════════════════════════════════════════════════════
  // 确认对话框消息（confirm）
  // ══════════════════════════════════════════════════════════════
  @override String get confirmLessonSignIn           => '签到【%s】这节课，\n当日之内可以撤销，过了今日撤销不可！\n您确定要签到吗？';
  @override String get confirmLessonUndoSignIn       => '确实要撤销【%s】这节课吗？';
  @override String get confirmLessonDelete           => '确实要删除【%s】这节课吗？删除后将无法恢复';
  @override String get confirmLessonCancelReschedule => '确实要取消这次调课吗？';
  @override String get confirmBankDelete             => '确定要删除【%s】吗？';
  @override String get confirmFixedLessonDelete      => '确实要删除该固定课程吗？';
  @override String get confirmPaymentUndo            => '您确定要撤销这笔支付吗？';
  @override String get confirmBadDebtUndo            => '确定撤销「%s」的\n「%s」（%s）坏账标记吗？\n撤销后该课费将重新出现在未付款列表中。';

  // ══════════════════════════════════════════════════════════════
  // 进度提示消息（loading）
  // ══════════════════════════════════════════════════════════════
  @override String get loadingStuInfoSave        => '正在登记学生信息...';
  @override String get loadingStuInfoUpdate      => '正在更新学生信息...';
  @override String get loadingStuArchiveSave     => '正在登记学生档案信息...';
  @override String get loadingSubjectSave        => '正在%s科目信息...';
  @override String get loadingBankInfoSave       => '正在%s银行信息...';
  @override String get loadingBankStuSave        => '正在登录学生银行信息...';
  @override String get loadingLsnFeePay          => '正在处理学费入账......';
  @override String get loadingAdvancedFeePay     => '正在处理学费预支付......';
  @override String get loadingPerLessonFeePay    => '正在处理按课时预支付......';
  @override String get loadingCourseAdd          => '正在添加课程...';
  @override String get loadingFixedLessonAdd     => '正在添加固定排课处理...';
  @override String get loadingFixedLessonUpdate  => '正在更新固定排课处理...';
  @override String get loadingScheduleExecute    => '正在执行排课，请稍候...';

  // ══════════════════════════════════════════════════════════════
  // SnackBar 提示消息（snack）
  // ══════════════════════════════════════════════════════════════
  @override String get snackBadDebtUndo          => '已撤销坏账标记';
  @override String get snackBadDebtMark          => '已标记为坏账';
  @override String get snackStudentWithdrawn     => '退学处理成功（%s 名）';
  @override String get snackStudentReenrolled    => '学生已成功复学';
  @override String get snackLessonConvertSuccess => '加课换正课执行成功！';
  @override String get snackUndoSuccess          => '撤销成功';
  @override String get snackPinChanged           => 'PIN码修改完成';
  @override String get snackThemeChanged         => '已切换到「%s」主题';
  @override String get snackLockNever            => '已设置为从不自动锁定';
  @override String get snackLockTimerSet         => '自动锁定时间已设置为%s';
  @override String get snackFeatureInDevelopment => '语言切换功能开发中';
  @override String get snackMemoUpdated          => '备注更新成功';
}
