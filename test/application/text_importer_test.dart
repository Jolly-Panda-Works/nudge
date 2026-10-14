import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/application/text_importer.dart';
import 'package:nudge/domain/shared_source.dart';

import '../support/fixtures.dart';
import '../support/in_memory_repositories.dart';

void main() {
  late InMemoryNotificationRepository repo;
  late TextImporter importer;

  setUp(() {
    repo = InMemoryNotificationRepository();
    importer = TextImporter(notifications: repo, clock: () => fixedNow);
  });

  test('blank text is rejected and nothing is stored', () async {
    expect(await importer.importText(text: '   '), isFalse);
    expect(await repo.count(), 0);
  });

  test('stores trimmed text under the shared source', () async {
    expect(
      await importer.importText(text: '  Remember the milk  ', title: 'Todo'),
      isTrue,
    );

    final stored = (await repo.listAll()).single;
    expect(stored.packageName, sharedPackageName);
    expect(stored.appLabel, sharedAppLabel);
    expect(stored.title, 'Todo');
    expect(stored.text, 'Remember the milk');
    expect(stored.postedAt, fixedNow);
    expect(stored.isRedacted, isFalse);
  });

  test('two imports get different keys', () async {
    await importer.importText(text: 'one');
    await importer.importText(text: 'two');

    final keys = (await repo.listAll()).map((n) => n.key).toSet();
    expect(keys, hasLength(2));
  });

  test('uses the given post time', () async {
    final posted = DateTime.utc(2026, 1, 2, 3, 4, 5);
    await importer.importText(text: 'hello', postedAt: posted);
    expect((await repo.listAll()).single.postedAt, posted);
  });
}
