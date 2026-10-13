/// An app that posted notifications, or that the user added to the filter list.
final class SourceApp {
  const SourceApp({required this.packageName, this.label});

  final String packageName;
  final String? label;

  String get displayName {
    final value = label;
    return (value == null || value.isEmpty) ? packageName : value;
  }
}
