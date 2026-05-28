import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/toast_helper.dart';
import '../../../core/config/supabase_config.dart';

class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({super.key});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _working = false;
  File? _lastSavedFile;

  String _dateRange(Map<String, dynamic>? extra) =>
      (extra?['dateRange'] as String?) ?? 'Today';

  String _reportType(Map<String, dynamic>? extra) =>
      (extra?['reportType'] as String?) ?? 'in';

  DateTime _cutoffForRange(String range) {
    final now = DateTime.now();
    if (range == 'Today') return DateTime(now.year, now.month, now.day);
    if (range == 'This week') return now.subtract(const Duration(days: 7));
    return now.subtract(const Duration(days: 30));
  }

  Future<List<Map<String, dynamic>>> _loadRows({
    required String reportType,
    required String dateRange,
  }) async {
    if (!SupabaseConfig.isConfigured) return [];
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return [];

    final cutoff = _cutoffForRange(dateRange);
    final res = await client
        .from('stock_entries_v2')
        .select(
          'created_at, entry_type, delta_10ft, delta_12ft, entered_by_name, items_v2(code, finish, item_types(name, image_url))',
        )
        .eq('entry_type', reportType)
        .gte('created_at', cutoff.toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(500);

    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<Uint8List?> _downloadImageBytes(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) return null;

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'kooba-app');
      final resp = await req.close().timeout(const Duration(seconds: 12));
      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;
      final bytes = await consolidateHttpClientResponseBytes(resp);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, Uint8List>> _prefetchImages(List<Map<String, dynamic>> rows) async {
    final urls = <String>{};
    for (final r in rows) {
      final item = r['items_v2'] as Map<String, dynamic>?;
      final type = item?['item_types'] as Map<String, dynamic>?;
      final url = (type?['image_url'] as String?)?.trim();
      if (url != null && url.isNotEmpty) urls.add(url);
    }

    final cache = <String, Uint8List>{};
    for (final url in urls) {
      final bytes = await _downloadImageBytes(url);
      if (bytes != null) cache[url] = bytes;
    }
    return cache;
  }

  Future<List<int>> _buildPdfBytes({
    required String title,
    required String dateRange,
    required List<Map<String, dynamic>> rows,
    required Map<String, Uint8List> imageCache,
  }) async {
    final doc = pw.Document();

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
          pw.Text('Date range: $dateRange'),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(42), // image
              1: pw.FlexColumnWidth(3), // item label
              2: pw.FlexColumnWidth(2), // when
              3: pw.FlexColumnWidth(1.3), // 10ft
              4: pw.FlexColumnWidth(1.3), // 12ft
              5: pw.FlexColumnWidth(2), // by
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Img', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('When', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('10ft', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('12ft', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('By', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...rows.map((r) {
                final item = r['items_v2'] as Map<String, dynamic>?;
                final type = item?['item_types'] as Map<String, dynamic>?;
                final typeName = (type?['name'] as String?) ?? '';
                final imgUrl = (type?['image_url'] as String?)?.trim();
                final code = (item?['code'] as String?) ?? '';
                final finish = (item?['finish'] as String?) ?? '';
                final itemLabel =
                    [typeName, code, finish].where((e) => e.trim().isNotEmpty).join(' · ');

                final when = (r['created_at']?.toString() ?? '');
                final d10 = (r['delta_10ft'] as num?)?.toInt() ?? 0;
                final d12 = (r['delta_12ft'] as num?)?.toInt() ?? 0;
                final by = (r['entered_by_name'] as String?) ?? '';

                pw.Widget cell(String v) => pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(v, maxLines: 2, overflow: pw.TextOverflow.clip),
                    );

                final bytes = (imgUrl != null && imgUrl.isNotEmpty) ? imageCache[imgUrl] : null;
                final imgWidget = bytes == null
                    ? pw.Container(
                        alignment: pw.Alignment.center,
                        width: 32,
                        height: 32,
                        child: pw.Text('—'),
                      )
                    : pw.Image(
                        pw.MemoryImage(bytes),
                        width: 32,
                        height: 32,
                        fit: pw.BoxFit.cover,
                      );

                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.ClipRRect(
                        horizontalRadius: 4,
                        verticalRadius: 4,
                        child: imgWidget,
                      ),
                    ),
                    cell(itemLabel.isEmpty ? '—' : itemLabel),
                    cell(when),
                    cell(d10.toString()),
                    cell(d12.toString()),
                    cell(by.isEmpty ? '—' : by),
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

  Future<File> _savePdfToAppFolder(List<int> bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> _ensurePdfFile() async {
    if (_lastSavedFile != null && await _lastSavedFile!.exists()) {
      return _lastSavedFile!;
    }

    final extra = GoRouterState.of(context).extra;
    final extraMap = extra is Map<String, dynamic> ? extra : null;
    final dateRange = _dateRange(extraMap);
    final reportType = _reportType(extraMap);
    final title = reportType == 'in' ? 'Stock in report' : 'Stock out report';

    final rows = await _loadRows(reportType: reportType, dateRange: dateRange);
    final imageCache = await _prefetchImages(rows);
    final bytes = await _buildPdfBytes(
      title: title,
      dateRange: dateRange,
      rows: rows,
      imageCache: imageCache,
    );
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = await _savePdfToAppFolder(bytes, 'kooba_${reportType}_$ts.pdf');
    if (mounted) setState(() => _lastSavedFile = file);
    return file;
  }

  Future<void> _download() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final file = await _ensurePdfFile();
      if (!mounted) return;
      ToastHelper.success(context, 'Saved: ${file.path}');
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
      final file = await _ensurePdfFile();
      if (!await file.exists()) {
        if (!mounted) return;
        ToastHelper.error(context, 'PDF not ready. Try again.');
        return;
      }

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 1, 1);

      final result = await SharePlus.instance.share(
        ShareParams(
          text: 'Kooba report',
          title: 'Kooba report',
          files: [XFile(file.path, mimeType: 'application/pdf')],
          sharePositionOrigin: origin,
        ),
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
            'No app available to share. Install Drive/WhatsApp/Gmail.',
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
    final dateRange = _dateRange(extra is Map<String, dynamic> ? extra : null);
    final reportType = _reportType(extra is Map<String, dynamic> ? extra : null);
    final title = reportType == 'in' ? 'Stock in report' : 'Stock out report';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 64,
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date range: $dateRange\nSaved to app documents (we will show the path).',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
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
          if (_lastSavedFile != null) ...[
            const SizedBox(height: 12),
            Text(
              'Saved file:\n${_lastSavedFile!.path}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
