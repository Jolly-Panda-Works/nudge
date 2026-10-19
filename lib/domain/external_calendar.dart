/// A calendar the device exposes (through the Android Calendar Provider), for
/// example one from a Google or Samsung account.
final class ExternalCalendar {
  const ExternalCalendar({
    required this.id,
    required this.displayName,
    required this.accountName,
    required this.accountType,
    required this.canWrite,
    required this.isOwner,
    required this.visibleInProvider,
    this.color,
  });

  /// The provider's identifier, kept as text.
  final String id;
  final String displayName;
  final String accountName;

  /// For example `com.google` or `com.samsung.android.calendar`.
  final String accountType;

  /// Colour as ARGB, or null when the provider gave none.
  final int? color;

  /// True when events can be created in it (contributor access or better).
  final bool canWrite;

  /// True for the account's own calendar, false for subscribed or shared ones.
  final bool isOwner;

  /// Whether the device's own calendar app shows it.
  final bool visibleInProvider;

  /// A readable name: the display name, or the account when it is empty.
  String get label => displayName.isNotEmpty ? displayName : accountName;

  /// A short name for the kind of account.
  String get accountKind {
    if (accountType == 'com.google') return 'Google';
    if (accountType.contains('samsung')) return 'Samsung';
    if (accountType == 'LOCAL' || accountType.isEmpty) return 'Device';
    return accountType;
  }
}

/// Which calendar permissions the user has granted.
final class CalendarPermissions {
  const CalendarPermissions({required this.read, required this.write});

  static const CalendarPermissions none = CalendarPermissions(
    read: false,
    write: false,
  );

  final bool read;
  final bool write;
}
