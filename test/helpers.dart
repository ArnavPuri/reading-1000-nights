import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:thousand_nights/data/content_pack.dart';
import 'package:thousand_nights/data/database.dart';

/// The real bundled test pack, read from disk.
ContentPack loadPack1() => ContentPack.decode(File('assets/packs/pack-001.json').readAsStringSync());

AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

Future<AppDatabase> seededDb() async {
  final db = memoryDb();
  await PackImporter(db).import(loadPack1());
  return db;
}
