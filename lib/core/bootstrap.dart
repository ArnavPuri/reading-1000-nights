import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart';

import '../data/content_pack.dart';
import '../data/database.dart';

/// Packs bundled in the app binary, so night 1 works offline (PRD).
/// The test pack covers nights 1-7; the launch pack 1 covers nights 1-30.
const bundledPacks = ['assets/packs/pack-001.json'];

AppDatabase openAppDatabase() => AppDatabase(driftDatabase(name: 'thousand_nights'));

Future<void> importBundledPacks(AppDatabase db, AssetBundle bundle) async {
  final importer = PackImporter(db);
  for (final path in bundledPacks) {
    await importer.import(ContentPack.decode(await bundle.loadString(path)));
  }
}
