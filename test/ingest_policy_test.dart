import 'package:flutter_test/flutter_test.dart';
import 'package:unified_inbox/domain/captured_notification.dart';
import 'package:unified_inbox/domain/ingest_policy.dart';

import 'support/fixtures.dart';

void main() {
  const open = CapturePolicy();

  group('decideIngest', () {
    test('inserts a brand new notification', () {
      expect(
        decideIngest(incoming: captured(), policy: open),
        IngestDecision.insert,
      );
    });

    test('ignores same key with same content', () {
      expect(
        decideIngest(
          incoming: captured(time: 2),
          existingByKey: captured(),
          policy: open,
        ),
        IngestDecision.ignoreDuplicate,
      );
    });

    test('updates same key when text changed', () {
      expect(
        decideIngest(
          incoming: captured(text: 'Edited'),
          existingByKey: captured(),
          policy: open,
        ),
        IngestDecision.update,
      );
    });

    test('reactivates a removed notification re-posted with the same key', () {
      final removed = captured().markRemoved(fixedNow);
      expect(
        decideIngest(
          incoming: captured(),
          existingByKey: removed,
          policy: open,
        ),
        IngestDecision.update,
      );
    });

    test('does not overwrite readable content with a redacted version', () {
      expect(
        decideIngest(
          incoming: captured(title: null, text: null),
          existingByKey: captured(),
          policy: open,
        ),
        IngestDecision.ignoreDuplicate,
      );
    });

    test('upgrades a redacted entry when content becomes readable', () {
      expect(
        decideIngest(
          incoming: captured(),
          existingByKey: captured(title: null, text: null),
          policy: open,
        ),
        IngestDecision.update,
      );
    });

    test('ignores identical content re-posted under a new key quickly', () {
      expect(
        decideIngest(
          incoming: captured(key: 'A', time: 1760000001000),
          recentSameContent: captured(key: 'B', time: 1760000000000),
          policy: open,
        ),
        IngestDecision.ignoreDuplicate,
      );
    });

    test('inserts identical content outside the re-post window', () {
      expect(
        decideIngest(
          incoming: captured(key: 'A', time: 1760000005000),
          recentSameContent: captured(key: 'B', time: 1760000000000),
          policy: open,
        ),
        IngestDecision.insert,
      );
    });
  });

  group('CapturePolicy', () {
    test('blocklist filters listed packages', () {
      const policy = CapturePolicy(
        mode: FilterMode.blocklist,
        packages: <String>{'com.chat'},
      );
      expect(
        decideIngest(incoming: captured(), policy: policy),
        IngestDecision.ignoreFiltered,
      );
      expect(
        decideIngest(incoming: captured(pkg: 'com.other'), policy: policy),
        IngestDecision.insert,
      );
    });

    test('allowlist only lets listed packages through', () {
      const policy = CapturePolicy(
        mode: FilterMode.allowlist,
        packages: <String>{'com.chat'},
      );
      expect(
        decideIngest(incoming: captured(), policy: policy),
        IngestDecision.insert,
      );
      expect(
        decideIngest(incoming: captured(pkg: 'com.other'), policy: policy),
        IngestDecision.ignoreFiltered,
      );
    });

    test('never captures its own notifications', () {
      const policy = CapturePolicy(ownPackageName: 'com.chat');
      expect(
        decideIngest(incoming: captured(), policy: policy),
        IngestDecision.ignoreFiltered,
      );
    });

    test('skips ongoing and group-summary entries by default', () {
      expect(
        decideIngest(incoming: captured(ongoing: true), policy: open),
        IngestDecision.ignoreFiltered,
      );
      expect(
        decideIngest(incoming: captured(summary: true), policy: open),
        IngestDecision.ignoreFiltered,
      );
    });
  });

  group('CapturedNotification', () {
    test('applyUpdateFrom keeps firstSeenAt and increments updateCount', () {
      final later = DateTime.utc(2026, 10, 13);
      final updated = captured().applyUpdateFrom(
        captured(text: 'Edited'),
        later,
      );
      expect(updated.text, 'Edited');
      expect(updated.firstSeenAt, fixedNow);
      expect(updated.lastUpdatedAt, later);
      expect(updated.updateCount, 1);
      expect(updated.status, NotificationStatus.active);
    });

    test('markRemoved keeps content', () {
      final removed = captured().markRemoved(fixedNow);
      expect(removed.status, NotificationStatus.removed);
      expect(removed.text, 'Hello');
    });
  });
}
