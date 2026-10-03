import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// The content pack format (version 1). See docs/content-pack-format.md.
class ContentPack {
  ContentPack({
    required this.format,
    required this.packId,
    required this.version,
    required this.firstDay,
    required this.lastDay,
    required this.days,
    required this.works,
  });

  factory ContentPack.fromJson(Map<String, dynamic> j) {
    final format = j['format'] as int;
    if (format != supportedFormat) {
      throw FormatException('Unsupported content pack format $format');
    }
    return ContentPack(
      format: format,
      packId: j['pack_id'] as int,
      version: j['version'] as int,
      firstDay: j['first_day'] as int,
      lastDay: j['last_day'] as int,
      days: [for (final d in j['days'] as List) PackDay.fromJson(d as Map<String, dynamic>)],
      works: [for (final w in j['works'] as List) PackWork.fromJson(w as Map<String, dynamic>)],
    );
  }

  factory ContentPack.decode(String source) => ContentPack.fromJson(jsonDecode(source) as Map<String, dynamic>);

  static const supportedFormat = 1;

  final int format;
  final int packId;
  final int version;
  final int firstDay;
  final int lastDay;
  final List<PackDay> days;
  final List<PackWork> works;

  /// Checks internal consistency before anything touches the database.
  void validate() {
    final ids = {for (final w in works) w.id};
    if (ids.length != works.length) throw const FormatException('Duplicate work ids');
    const types = {'story', 'poem', 'essay'};
    for (final w in works) {
      if (!types.contains(w.type)) throw FormatException('Bad type ${w.type} for ${w.id}');
    }
    for (final d in days) {
      if (d.dayNumber < firstDay || d.dayNumber > lastDay) {
        throw FormatException('Night ${d.dayNumber} outside pack range');
      }
      for (final id in [d.storyId, d.poemId, d.essayId]) {
        if (!ids.contains(id)) throw FormatException('Night ${d.dayNumber} references missing $id');
      }
    }
  }
}

class PackDay {
  PackDay({required this.dayNumber, required this.storyId, required this.poemId, required this.essayId});

  factory PackDay.fromJson(Map<String, dynamic> j) => PackDay(
    dayNumber: j['day_number'] as int,
    storyId: j['story_id'] as String,
    poemId: j['poem_id'] as String,
    essayId: j['essay_id'] as String,
  );

  final int dayNumber;
  final String storyId;
  final String poemId;
  final String essayId;
}

class PackWork {
  PackWork({
    required this.id,
    required this.type,
    required this.title,
    required this.author,
    required this.year,
    required this.wordCount,
    required this.estMinutes,
    required this.partLabel,
    required this.textMd,
    required this.imagePath,
    required this.sourceRef,
    required this.rightsNote,
    required this.pullQuote,
  });

  factory PackWork.fromJson(Map<String, dynamic> j) => PackWork(
    id: j['id'] as String,
    type: j['type'] as String,
    title: j['title'] as String,
    author: j['author'] as String,
    year: j['year'] as int,
    wordCount: j['word_count'] as int,
    estMinutes: j['est_minutes'] as int,
    partLabel: j['part_label'] as String?,
    textMd: j['text_md'] as String,
    imagePath: j['image_path'] as String?,
    sourceRef: j['source_ref'] as String,
    rightsNote: j['rights_note'] as String,
    pullQuote: j['pull_quote'] as String?,
  );

  final String id;
  final String type;
  final String title;
  final String author;
  final int year;
  final int wordCount;
  final int estMinutes;
  final String? partLabel;
  final String textMd;
  final String? imagePath;
  final String sourceRef;
  final String rightsNote;
  final String? pullQuote;
}

/// Writes content packs into the database. Importing the same pack version
/// twice is a no-op; a newer version replaces the pack's works and days but
/// never touches user progress.
class PackImporter {
  PackImporter(this.db);

  final AppDatabase db;

  /// Returns true if the pack was written.
  Future<bool> import(ContentPack pack) async {
    pack.validate();
    final existing = await (db.select(db.importedPacks)..where((p) => p.packId.equals(pack.packId))).getSingleOrNull();
    if (existing != null && existing.version >= pack.version) return false;

    await db.transaction(() async {
      await db.batch((b) {
        b.insertAllOnConflictUpdate(db.works, [
          for (final w in pack.works)
            WorksCompanion.insert(
              id: w.id,
              type: w.type,
              title: w.title,
              author: w.author,
              year: w.year,
              wordCount: w.wordCount,
              estMinutes: w.estMinutes,
              partLabel: Value(w.partLabel),
              textMd: w.textMd,
              imagePath: Value(w.imagePath),
              sourceRef: w.sourceRef,
              rightsNote: w.rightsNote,
              pullQuote: Value(w.pullQuote),
            ),
        ]);
        b.insertAllOnConflictUpdate(db.days, [
          for (final d in pack.days)
            DaysCompanion.insert(
              dayNumber: Value(d.dayNumber),
              storyId: d.storyId,
              poemId: d.poemId,
              essayId: d.essayId,
              packId: pack.packId,
            ),
        ]);
        b.insert(
          db.importedPacks,
          ImportedPacksCompanion.insert(packId: Value(pack.packId), version: pack.version, importedAt: DateTime.now()),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
    return true;
  }
}
