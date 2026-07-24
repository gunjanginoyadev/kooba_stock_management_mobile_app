import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:share_plus/share_plus.dart';

Future<String> savePdf({
  required Uint8List bytes,
  required String filename,
}) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return 'Downloaded: $filename';
}

Future<ShareResult> sharePdf({
  required Uint8List bytes,
  required String filename,
  Object? sharePositionOrigin,
}) {
  return SharePlus.instance.share(
    ShareParams(
      text: 'Kooba report',
      title: 'Kooba report',
      files: [
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: filename,
        ),
      ],
    ),
  );
}
