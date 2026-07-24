import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> savePdf({
  required Uint8List bytes,
  required String filename,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}${Platform.pathSeparator}$filename';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return path;
}

Future<ShareResult> sharePdf({
  required Uint8List bytes,
  required String filename,
  Object? sharePositionOrigin,
}) {
  final origin = sharePositionOrigin is Rect ? sharePositionOrigin : null;
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
      sharePositionOrigin: origin,
    ),
  );
}
