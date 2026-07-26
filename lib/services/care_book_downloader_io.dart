import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _handbookAsset = 'assets/care_book/caregivers-book.pdf';
const _baseFileName = 'nia-caregivers-handbook';

Future<String> downloadNiaHandbook() async {
  final directory =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  if (!await directory.exists()) await directory.create(recursive: true);

  final destination = await _availableDestination(directory);
  final data = await rootBundle.load(_handbookAsset);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await destination.writeAsBytes(bytes, flush: true);
  return destination.path;
}

Future<File> _availableDestination(Directory directory) async {
  var candidate = File(
    '${directory.path}${Platform.pathSeparator}$_baseFileName.pdf',
  );
  var suffix = 1;
  while (await candidate.exists()) {
    candidate = File(
      '${directory.path}${Platform.pathSeparator}$_baseFileName ($suffix).pdf',
    );
    suffix++;
  }
  return candidate;
}
