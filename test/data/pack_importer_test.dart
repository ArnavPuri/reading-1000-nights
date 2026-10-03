import 'package:flutter_test/flutter_test.dart';
import 'package:thousand_nights/data/content_pack.dart';

import '../helpers.dart';

void main() {
  test('pack 1 is valid: 7 nights, 21 works, story/poem/essay each night', () {
    final pack = loadPack1();
    pack.validate();
    expect(pack.days, hasLength(7));
    expect(pack.works, hasLength(21));
    for (final w in pack.works) {
      expect(w.textMd.toLowerCase(), isNot(contains('gutenberg')), reason: w.id);
      expect(w.year, lessThanOrEqualTo(1930), reason: '${w.id}: 1930 rule');
      expect(w.rightsNote, isNotEmpty);
    }
  });

  test('phase 0 gate: imports the pack and night 1 titles come from the database', () async {
    final db = memoryDb();
    expect(await PackImporter(db).import(loadPack1()), isTrue);

    final day1 = await (db.select(db.days)..where((d) => d.dayNumber.equals(1))).getSingle();
    final titles = [
      for (final id in [day1.storyId, day1.poemId, day1.essayId])
        (await (db.select(db.works)..where((w) => w.id.equals(id))).getSingle()).title,
    ];
    expect(titles, ['The Nightingale and the Rose', 'A Dream Within a Dream', 'El Dorado']);
    await db.close();
  });

  test('importing the same version twice is a no-op', () async {
    final db = memoryDb();
    final importer = PackImporter(db);
    expect(await importer.import(loadPack1()), isTrue);
    expect(await importer.import(loadPack1()), isFalse);
    expect(await db.select(db.works).get(), hasLength(21));
    await db.close();
  });

  test('rejects a pack whose night references a missing work', () {
    final json = {
      'format': 1,
      'pack_id': 9,
      'version': 1,
      'first_day': 1,
      'last_day': 1,
      'days': [
        {'day_number': 1, 'story_id': 'a', 'poem_id': 'b', 'essay_id': 'missing'},
      ],
      'works': <Object>[],
    };
    expect(() => ContentPack.fromJson(json).validate(), throwsFormatException);
  });

  test('rejects an unknown pack format', () {
    expect(() => ContentPack.fromJson({'format': 2}), throwsFormatException);
  });
}
