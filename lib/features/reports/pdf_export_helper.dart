import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'pdf_save_io.dart' if (dart.library.html) 'pdf_save_web.dart' as impl;

/// Saves / shares a generated PDF on mobile and web.
class PdfExportHelper {
  PdfExportHelper._();

  /// Returns a local path on IO platforms; on web triggers a browser download.
  static Future<String> savePdf({
    required Uint8List bytes,
    required String filename,
  }) =>
      impl.savePdf(bytes: bytes, filename: filename);

  static Future<ShareResult> sharePdf({
    required Uint8List bytes,
    required String filename,
    Object? sharePositionOrigin,
  }) =>
      impl.sharePdf(
        bytes: bytes,
        filename: filename,
        sharePositionOrigin: sharePositionOrigin,
      );
}
