import 'package:url_launcher/url_launcher.dart';

import 'care_book_downloader.dart';

abstract final class CareBookService {
  static const handbookAsset = 'assets/care_book/caregivers-book.pdf';
  static final officialSource = Uri.parse(
    'https://order.nia.nih.gov/publication/caregivers-handbook',
  );
  static final gettingStartedGuide = Uri.parse(
    'https://www.nia.nih.gov/health/caregiving/getting-started-caregiving',
  );

  static Future<String?> saveHandbookCopy() async {
    return downloadNiaHandbook();
  }

  static Future<bool> openReference(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}
