import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/toast_helper.dart';
import '../../items/models/item_models.dart';
import '../../items/repository/items_repository.dart';
import '../pdf_export_helper.dart';
import '../pdf_image_loader.dart';

class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({super.key});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final _repository = ItemsRepository();
  bool _working = false;
  String? _lastSavedPath;
  String? _lastImageStatus;
  Uint8List? _previewJpeg;
  Uint8List? _lastPdfBytes;
  String? _lastPdfFilename;
  final Map<String, Uint8List> _jpegByUrl = {};

  String _dateRange(Map<String, dynamic>? extra) =>
      (extra?['dateRange'] as String?) ?? 'Today';

  /// `in` | `out` | `inventory`
  String _reportType(Map<String, dynamic>? extra) =>
      (extra?['reportType'] as String?) ?? 'in';

  bool _isInventory(String reportType) => reportType == 'inventory';

  String _titleFor(String reportType) {
    switch (reportType) {
      case 'out':
        return 'Stock out report';
      case 'inventory':
        return 'Current inventory';
      default:
        return 'Stock in report';
    }
  }

  DateTime _cutoffForRange(String range) {
    final now = DateTime.now();
    if (range == 'Today') return DateTime(now.year, now.month, now.day);
    if (range == 'This week') return now.subtract(const Duration(days: 7));
    return now.subtract(const Duration(days: 30));
  }

  Future<List<StockEntryV2>> _loadEntryRows({
    required String reportType,
    required String dateRange,
  }) async {
    if (!FirebaseConfig.isConfigured) return [];
    final rows = await _repository.getStockEntries(
      limit: 500,
      entryType: reportType,
      since: _cutoffForRange(dateRange),
    );
    return _repository.enrichEntryImages(rows);
  }

  Future<List<StockSheetItem>> _loadInventoryRows() async {
    if (!FirebaseConfig.isConfigured) return [];
    final items = await _repository.getStockSheetItems();
    items.sort((a, b) {
      final byType = a.typeName.toLowerCase().compareTo(b.typeName.toLowerCase());
      if (byType != 0) return byType;
      final byCode = a.code.toLowerCase().compareTo(b.code.toLowerCase());
      if (byCode != 0) return byCode;
      return a.finish.toLowerCase().compareTo(b.finish.toLowerCase());
    });
    return items;
  }

  Future<Map<String, pw.ImageProvider>> _buildImageProviders(
    pw.Document doc,
    Iterable<String?> urls,
  ) async {
    final unique = <String>{};
    for (final url in urls) {
      final trimmed = url?.trim();
      if (trimmed != null && trimmed.isNotEmpty) unique.add(trimmed);
    }

    _jpegByUrl.clear();
    final cache = <String, pw.ImageProvider>{};
    _previewJpeg = null;

    final downloaded = <String, Uint8List>{};
    await Future.wait(
      unique.map((url) async {
        final jpeg = await PdfImageLoader.loadJpeg(url);
        if (jpeg != null && jpeg.isNotEmpty) {
          downloaded[url] = jpeg;
        }
      }),
    );

    for (final entry in downloaded.entries) {
      try {
        cache[entry.key] = pw.ImageProxy(
          PdfImage.jpeg(doc.document, image: entry.value),
        );
        _jpegByUrl[entry.key] = entry.value;
      } catch (_) {}
    }

    if (_jpegByUrl.isNotEmpty) {
      _previewJpeg = _jpegByUrl.values.first;
    }

    return cache;
  }

  pw.Widget _imgCell(pw.ImageProvider? cached) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: cached == null
          ? pw.Container(
              width: 36,
              height: 36,
              alignment: pw.Alignment.center,
              color: PdfColors.grey200,
              child: pw.Text('—', style: const pw.TextStyle(fontSize: 9)),
            )
          : pw.Image(
              cached,
              width: 36,
              height: 36,
              fit: pw.BoxFit.cover,
            ),
    );
  }

  pw.Widget _headerCell(String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        label,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  pw.Widget _cell(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        value,
        maxLines: 2,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  Future<List<int>> _buildEntriesPdf({
    required String title,
    required String dateRange,
    required List<StockEntryV2> rows,
  }) async {
    final doc = pw.Document();
    final imageCache = await _buildImageProviders(
      doc,
      rows.map((r) => r.typeImageUrl),
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Date range: $dateRange', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(48),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2.2),
              3: pw.FlexColumnWidth(1.1),
              4: pw.FlexColumnWidth(1.1),
              5: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _headerCell('Img'),
                  _headerCell('Item'),
                  _headerCell('When'),
                  _headerCell('10ft'),
                  _headerCell('12ft'),
                  _headerCell('By'),
                ],
              ),
              ...rows.map((r) {
                final imgUrl = r.typeImageUrl?.trim();
                final cached = (imgUrl != null && imgUrl.isNotEmpty)
                    ? imageCache[imgUrl]
                    : null;
                final by = r.enteredByName?.trim() ?? '';
                return pw.TableRow(
                  children: [
                    _imgCell(cached),
                    _cell(r.itemLabel.isEmpty ? '—' : r.itemLabel),
                    _cell(r.createdAt.toLocal().toString()),
                    _cell(r.delta10ft.toString()),
                    _cell(r.delta12ft.toString()),
                    _cell(by.isEmpty ? '—' : by),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<List<int>> _buildInventoryPdf({
    required List<StockSheetItem> items,
  }) async {
    final doc = pw.Document();
    final imageCache = await _buildImageProviders(
      doc,
      items.map((i) => i.typeImageUrl),
    );
    final generatedAt = DateTime.now().toLocal().toString();

    var total10 = 0;
    var total12 = 0;
    for (final item in items) {
      total10 += item.qty10ft;
      total12 += item.qty12ft;
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Current inventory',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'All items · generated $generatedAt',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Items: ${items.length}  ·  Total 10ft: $total10  ·  Total 12ft: $total12',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(48),
              1: pw.FlexColumnWidth(2.2),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
              4: pw.FlexColumnWidth(1.2),
              5: pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _headerCell('Img'),
                  _headerCell('Type'),
                  _headerCell('Code'),
                  _headerCell('Finish'),
                  _headerCell('10ft'),
                  _headerCell('12ft'),
                ],
              ),
              ...items.map((item) {
                final imgUrl = item.typeImageUrl?.trim();
                final cached = (imgUrl != null && imgUrl.isNotEmpty)
                    ? imageCache[imgUrl]
                    : null;
                return pw.TableRow(
                  children: [
                    _imgCell(cached),
                    _cell(item.typeName.isEmpty ? '—' : item.typeName),
                    _cell(item.code.isEmpty ? '—' : item.code),
                    _cell(item.finish.isEmpty ? '—' : item.finish),
                    _cell(item.qty10ft.toString()),
                    _cell(item.qty12ft.toString()),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<({Uint8List bytes, String filename})> _buildExport() async {
    final extra = GoRouterState.of(context).extra;
    final extraMap = extra is Map<String, dynamic> ? extra : null;
    final dateRange = _dateRange(extraMap);
    final reportType = _reportType(extraMap);
    final title = _titleFor(reportType);
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');

    late final List<int> rawBytes;
    late final int withUrl;
    late final String filePrefix;

    if (_isInventory(reportType)) {
      final items = await _loadInventoryRows();
      withUrl = items
          .where((i) => (i.typeImageUrl?.trim().isNotEmpty ?? false))
          .length;
      rawBytes = await _buildInventoryPdf(items: items);
      filePrefix = 'kooba_inventory';
    } else {
      final rows = await _loadEntryRows(
        reportType: reportType,
        dateRange: dateRange,
      );
      withUrl = rows
          .where((r) => (r.typeImageUrl?.trim().isNotEmpty ?? false))
          .length;
      rawBytes = await _buildEntriesPdf(
        title: title,
        dateRange: dateRange,
        rows: rows,
      );
      filePrefix = 'kooba_$reportType';
    }

    final bytes = Uint8List.fromList(rawBytes);
    final filename = '${filePrefix}_$ts.pdf';
    final embedded = _jpegByUrl.length;

    if (mounted) {
      setState(() {
        _lastPdfBytes = bytes;
        _lastPdfFilename = filename;
        _lastImageStatus = withUrl == 0
            ? 'No image URLs on these rows'
            : embedded == 0
                ? 'Found $withUrl URL(s) but download failed'
                : 'Images embedded: $embedded / $withUrl';
      });
    }

    return (bytes: bytes, filename: filename);
  }

  Future<void> _download() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final built = await _buildExport();
      final path = await PdfExportHelper.savePdf(
        bytes: built.bytes,
        filename: built.filename,
      );
      if (!mounted) return;
      setState(() => _lastSavedPath = path);
      final status = _lastImageStatus;
      ToastHelper.success(
        context,
        status == null ? 'Saved: $path' : 'Saved. $status',
      );
    } catch (e) {
      if (!mounted) return;
      ToastHelper.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _share() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final built = (_lastPdfBytes != null && _lastPdfFilename != null)
          ? (bytes: _lastPdfBytes!, filename: _lastPdfFilename!)
          : await _buildExport();

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 1, 1);

      final result = await PdfExportHelper.sharePdf(
        bytes: built.bytes,
        filename: built.filename,
        sharePositionOrigin: origin,
      );

      if (!mounted) return;

      switch (result.status) {
        case ShareResultStatus.success:
          ToastHelper.success(context, 'Share opened');
          break;
        case ShareResultStatus.dismissed:
          ToastHelper.info(context, 'Share cancelled');
          break;
        case ShareResultStatus.unavailable:
          ToastHelper.error(
            context,
            kIsWeb
                ? 'Share unavailable in this browser. Use Download instead.'
                : 'No app available to share. Install Drive/WhatsApp/Gmail.',
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.error(context, 'Share failed: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final extraMap = extra is Map<String, dynamic> ? extra : null;
    final dateRange = _dateRange(extraMap);
    final reportType = _reportType(extraMap);
    final title = _titleFor(reportType);
    final subtitle = _isInventory(reportType)
        ? 'All current items and stock levels'
        : 'Date range: $dateRange';

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 22,
          ),
        ),
        title: const Text(
          'Export',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 56,
                    color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$subtitle\nSaved to app documents.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_previewJpeg != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _previewJpeg!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Last embedded image preview',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label: 'Download PDF',
              icon: Icons.file_download_rounded,
              isLoading: _working,
              onPressed: _working ? null : _download,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _working ? null : _share,
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            if (_lastImageStatus != null) ...[
              const SizedBox(height: 12),
              Text(
                _lastImageStatus!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            if (_lastSavedPath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Saved:\n$_lastSavedPath',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
