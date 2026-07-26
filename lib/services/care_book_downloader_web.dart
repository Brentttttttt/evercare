import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';

const _handbookAsset = 'assets/care_book/caregivers-book.pdf';

Future<String> downloadNiaHandbook() async {
  final data = await rootBundle.load(_handbookAsset);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  return FileSaver.instance.saveFile(
    name: 'nia-caregivers-handbook',
    bytes: bytes,
    fileExtension: 'pdf',
    mimeType: MimeType.pdf,
  );
}
