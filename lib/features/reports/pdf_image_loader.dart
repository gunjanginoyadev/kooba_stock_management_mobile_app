import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Loads remote stock images as JPEG bytes for `PdfImage.jpeg` (best PDF support).
/// Works on mobile and web (no `dart:io`).
class PdfImageLoader {
  PdfImageLoader._();

  static Uint8List _asBytes(ByteData data) {
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Solid green JPEG used to verify PDF image embedding works in the viewer.
  static Uint8List testJpeg({int size = 48}) {
    final image = img.Image(width: size, height: size, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(34, 197, 94));
    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }

  static Future<Uint8List?> loadJpeg(String url, {int maxSide = 160}) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    final fromFlutter = await _bitmapFromNetworkImage(trimmed);
    if (fromFlutter != null) {
      return _encodeJpeg(fromFlutter, maxSide: maxSide);
    }

    final fromHttp = await _bitmapFromHttp(trimmed);
    if (fromHttp != null) {
      return _encodeJpeg(fromHttp, maxSide: maxSide);
    }
    return null;
  }

  static Uint8List _encodeJpeg(img.Image src, {required int maxSide}) {
    var image = src;
    if (image.width > maxSide || image.height > maxSide) {
      image = img.copyResize(
        image,
        width: image.width >= image.height ? maxSide : null,
        height: image.height > image.width ? maxSide : null,
        interpolation: img.Interpolation.average,
      );
    }
    if (image.numChannels != 3) {
      image = image.convert(format: img.Format.uint8, numChannels: 3);
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 85));
  }

  static Future<img.Image?> _bitmapFromNetworkImage(String url) async {
    ui.Image? image;
    try {
      image = await _resolveNetworkImage(url);
      if (image == null) return null;
      final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) return null;
      return img.decodePng(_asBytes(pngData));
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
    }
  }

  static Future<img.Image?> _bitmapFromHttp(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        return null;
      }

      final resp = await http
          .get(
            uri,
            headers: const {
              'Accept': 'image/*,*/*;q=0.8',
              'User-Agent':
                  'Mozilla/5.0 (compatible; KoobaStockApp/1.0; +https://localhost)',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;

      final raw = resp.bodyBytes;
      if (raw.isEmpty) return null;

      if (raw.length >= 15) {
        final head = String.fromCharCodes(raw.take(15)).toLowerCase();
        if (head.contains('<!doctype') || head.contains('<html')) {
          return null;
        }
      }

      return img.decodeImage(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image?> _resolveNetworkImage(String url) async {
    final completer = Completer<ui.Image?>();
    final provider = NetworkImage(url);
    final stream = provider.resolve(const ImageConfiguration());

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!completer.isCompleted) completer.complete(info.image.clone());
        stream.removeListener(listener);
      },
      onError: (Object _, StackTrace? stack) {
        if (!completer.isCompleted) completer.complete(null);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);

    try {
      return await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          stream.removeListener(listener);
          return null;
        },
      );
    } catch (_) {
      stream.removeListener(listener);
      return null;
    }
  }
}
