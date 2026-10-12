/// Plain data exactly as the native listener sends it over the platform
/// channel. Contains no PendingIntent: only the *presence* of a content action.
final class RawNotificationPayload {
  const RawNotificationPayload({
    required this.key,
    required this.packageName,
    required this.postTimeMillis,
    this.appLabel,
    this.title,
    this.text,
    this.groupKey,
    this.isGroupSummary = false,
    this.isOngoing = false,
    this.hasContentAction = false,
    this.actionTitles = const <String>[],
    this.redactedHint = false,
  });

  /// Throws [FormatException] when mandatory fields are missing or mistyped.
  factory RawNotificationPayload.fromMap(Map<Object?, Object?> map) {
    final key = map['key'];
    final packageName = map['packageName'];
    final postTime = map['postTimeMillis'];
    if (key is! String || key.isEmpty) {
      throw const FormatException('Missing notification key');
    }
    if (packageName is! String || packageName.isEmpty) {
      throw const FormatException('Missing package name');
    }
    if (postTime is! int) {
      throw const FormatException('Missing post time');
    }
    final rawActions = map['actionTitles'];
    final actions = rawActions is List<Object?>
        ? rawActions.whereType<String>().toList(growable: false)
        : const <String>[];
    return RawNotificationPayload(
      key: key,
      packageName: packageName,
      postTimeMillis: postTime,
      appLabel: _str(map['appLabel']),
      title: _str(map['title']),
      text: _str(map['text']),
      groupKey: _str(map['groupKey']),
      isGroupSummary: map['isGroupSummary'] == true,
      isOngoing: map['isOngoing'] == true,
      hasContentAction: map['hasContentAction'] == true,
      actionTitles: actions,
      redactedHint: map['redactedHint'] == true,
    );
  }

  final String key;
  final String packageName;
  final int postTimeMillis;
  final String? appLabel;
  final String? title;
  final String? text;
  final String? groupKey;
  final bool isGroupSummary;
  final bool isOngoing;
  final bool hasContentAction;
  final List<String> actionTitles;

  /// Native side may flag content it knows is hidden (e.g. private lock-screen
  /// visibility). Empty title+text is also treated as redacted by the mapper.
  final bool redactedHint;

  static String? _str(Object? value) => value is String ? value : null;
}
