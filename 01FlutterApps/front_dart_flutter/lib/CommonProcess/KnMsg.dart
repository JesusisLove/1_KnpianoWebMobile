import 'messages/KnMessagesBase.dart';
import 'messages/KnMessagesCn.dart';

/// KnMsg.dart
/// 消息文字全局访问入口
///
/// 使用方式：
///   KnMsg.i.titleSubmitSuccess          // → '提交成功'
///   KnMsg.i.confirmLessonDelete.replaceFirst('%s', subjectName)
///
/// 将来国际化扩展时，只需新增语言实现类并在 setLanguage 中注册，
/// 无需修改任何业务代码。
class KnMsg {
  static KnMessagesBase _current = KnMessagesCn();

  /// 切换语言（将来国际化扩展时使用）
  static void setLanguage(String lang) {
    switch (lang) {
      case 'zh':
        _current = KnMessagesCn();
        break;
      // case 'ja': _current = KnMessagesJp(); break;
      // case 'en': _current = KnMessagesEn(); break;
    }
  }

  /// 获取当前语言的消息实例
  static KnMessagesBase get i => _current;
}
