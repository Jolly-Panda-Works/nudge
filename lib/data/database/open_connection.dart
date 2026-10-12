import 'package:drift_flutter/drift_flutter.dart';

import 'app_database.dart';

/// Opens the on-device database (Android and Windows).
AppDatabase openAppDatabase() => AppDatabase(driftDatabase(name: 'nudge'));
