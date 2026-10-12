import 'package:drift/drift.dart';

import '../../domain/captured_notification.dart' show NotificationStatus;

part 'app_database.g.dart';

@DataClassName('NotificationRow')
@TableIndex(
  name: 'idx_notifications_source_content',
  columns: {#packageName, #contentHash},
)
class Notifications extends Table {
  TextColumn get notificationKey => text()();
  TextColumn get packageName => text()();
  TextColumn get appLabel => text().nullable()();
  TextColumn get title => text().nullable()();

  /// Notification text. Named `body` because `text` clashes with `text()`.
  TextColumn get body => text().nullable()();

  /// All timestamps are epoch milliseconds in UTC.
  IntColumn get postedAtMs => integer()();
  TextColumn get groupKey => text().nullable()();
  BoolColumn get isGroupSummary =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isOngoing => boolean().withDefault(const Constant(false))();
  BoolColumn get isRedacted => boolean().withDefault(const Constant(false))();
  TextColumn get contentHash => text()();
  BoolColumn get sourceHasContentAction =>
      boolean().withDefault(const Constant(false))();

  /// JSON array of action titles (no PendingIntents are ever stored).
  TextColumn get sourceActionTitles =>
      text().withDefault(const Constant('[]'))();
  IntColumn get status => intEnum<NotificationStatus>()();
  IntColumn get firstSeenAtMs => integer()();
  IntColumn get lastUpdatedAtMs => integer()();
  IntColumn get updateCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {notificationKey};
}

@DataClassName('SettingRow')
class AppSettings extends Table {
  TextColumn get settingName => text()();
  TextColumn get settingValue => text()();

  @override
  Set<Column<Object>> get primaryKey => {settingName};
}

@DataClassName('SourceRuleRow')
class SourceRules extends Table {
  TextColumn get packageName => text()();
  TextColumn get appLabel => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {packageName};
}

@DriftDatabase(tables: [Notifications, AppSettings, SourceRules])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
