import 'package:dio/dio.dart';

import 'api/api_service.dart';
import 'session/account.dart';
import 'utils/logger.dart';

/// 抢答（快速参与抢答）。
///
/// 该文件刻意放在 `lib/api/` 之外：抢答属于本 fork 的附加功能，
/// 不属于上游 `lib/api/` 的核心协议实现。
class QuickAnswer {
  /// 学生侧参与抢答的接口。
  static const String _stuAnswerUrl =
      'https://mobilelearn.chaoxing.com/pptAnswer/stuAnswer';

  /// 提交一次抢答参与请求。
  ///
  /// [activityId] 为活动 id（IM 推送里的 `aid`），
  /// [classId] / [courseId] 为课程班级信息，[stuName] 缺省取当前账号姓名。
  static Future<QuickAnswerResult> claim({
    required String activityId,
    required String classId,
    required String courseId,
    String? stuName,
  }) async {
    final name = stuName ?? AccountManager.currentUser?.name ?? '';
    final stopwatch = Stopwatch()..start();
    final response = await ApiService.sendRequest(
      _stuAnswerUrl,
      params: {
        'answerId': activityId,
        'classId': classId,
        'role': '',
        'courseId': courseId,
        'general': '',
        'appType': '15',
        'stuMiddlePage': '1',
        'stuName': name,
      },
      responseType: ResponseType.plain,
      receiveTimeoutSeconds: 5,
    );
    stopwatch.stop();

    final body = response?.data?.toString().trim() ?? '';
    final ok = body == 'success' ||
        body == 'true' ||
        body.contains('"status":true') ||
        body.contains('您已抢答');

    logger.i(
      '抢答 aid=$activityId classId=$classId courseId=$courseId '
      '耗时=${stopwatch.elapsedMilliseconds}ms ok=$ok body=$body',
    );

    return QuickAnswerResult(
      ok: ok,
      body: body,
      elapsedMs: stopwatch.elapsedMilliseconds,
    );
  }
}

class QuickAnswerResult {
  final bool ok;
  final String body;
  final int elapsedMs;

  const QuickAnswerResult({
    required this.ok,
    required this.body,
    required this.elapsedMs,
  });

  /// 给通知/弹窗用的一句话结果。
  String get description {
    if (ok) return '✅ 已抢答（${elapsedMs}ms），去学习通里作答';
    if (body.isEmpty) return '❌ 抢答失败：无响应';
    return '❌ 抢答失败：$body';
  }
}
