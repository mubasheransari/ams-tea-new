import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Screens/home_screen.dart';
import 'package:new_amst_flutter/Screens/products.dart';
import 'dart:typed_data';
import 'package:get_storage/get_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:new_amst_flutter/Data/order_storage.dart';


// NOTE: Import your existing models/storage.
//// import 'orders_storage.dart'; // must provide OrderRecord & OrdersStorage

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});
  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

enum _Filter { all, today, last7, thisMonth }
enum _DlgAction { view, download }

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  _Filter _filter = _Filter.all;

  final GetStorage _box = GetStorage();
  List<OrderRecord> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Live reload as soon as cart screen updates 'local_orders'
    _box.listenKey('local_orders', (_) {
      if (!mounted) return;
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    final list = await OrdersStorage().listOrders();
    if (!mounted) return;
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  List<OrderRecord> get _filtered {
    final now = DateTime.now();
    switch (_filter) {
      case _Filter.all:
        return _orders;
      case _Filter.today:
        return _orders.where((e) =>
          e.createdAt.year == now.year &&
          e.createdAt.month == now.month &&
          e.createdAt.day == now.day).toList();
      case _Filter.last7:
        final from = now.subtract(const Duration(days: 7));
        return _orders.where((e) => e.createdAt.isAfter(from)).toList();
      case _Filter.thisMonth:
        return _orders.where((e) =>
          e.createdAt.year == now.year &&
          e.createdAt.month == now.month).toList();
    }
  }

  String _prettyDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hh = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mm = d.minute.toString().padLeft(2, '0');
    final am = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${m[d.month - 1]}, ${d.year}  —  $hh:$mm $am';
  }

  String _orderTitle(OrderRecord r) {
    if ((r.title ?? '').trim().isNotEmpty) return r.title!.trim();
    if (r.lines.isEmpty) return 'No items';
    final first = r.lines.first;
    final name = '${first['name'] ?? 'Item'}';
    final more = r.lines.length - 1;
    return more > 0 ? '$name +$more more' : name;
  }

  // ====== PDF actions (unlimited) ======

  Future<void> _viewPdf(OrderRecord r) async {
    final bytes = await _buildPdfBytes(r);
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }



Future<void> _downloadPdf(OrderRecord r) async {
  final Uint8List bytes = await _buildPdfBytes(r); // must return Uint8List
  final String baseName = 'order_${r.id}';

  String? savedPath;
  try {
    savedPath = await FileSaver.instance.saveFile(
      name: baseName,        // REQUIRED named param
      bytes: bytes,          // REQUIRED named param (Uint8List)
      ext: 'pdf',            // file extension without dot
      // mimeType: MimeType.pdf,  // optional (omit if enum mismatch)
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Save failed: $e')),
    );
    return;
  }

  // Optional: mark as downloaded for badge/label; does NOT restrict future downloads
  await OrdersStorage().setDownloaded(r.id, true);
  if (!mounted) return;
  final i = _orders.indexWhere((e) => e.id == r.id);
  if (i >= 0) setState(() => _orders[i] = _orders[i].copyWith(downloaded: true));

  // Notify + quick OPEN action
  final path = savedPath ?? '';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(path.isEmpty ? 'PDF saved' : 'Saved to: $path'),
      action: path.isEmpty
          ? null
          : SnackBarAction(
              label: 'OPEN',
              onPressed: () => OpenFilex.open(path),
            ),
    ),
  );
}


  // Future<void> _downloadPdf(OrderRecord r) async {
  //   final bytes = await _buildPdfBytes(r); // Uint8List
  //   final base = 'order_${r.id}';
  //   // Save directly to user-visible storage (Downloads on Android)
  //   final savedPath = await FileSaver.instance.saveFile(
  //     base,      // filename without extension
  //     bytes,     // Uint8List
  //     'pdf',     // extension without dot
  //     mimeType: MimeType.PDF,
  //   );

  //   // Optional: mark as downloaded for label/badge; no restriction enforced
  //   await OrdersStorage().setDownloaded(r.id, true);
  //   if (!mounted) return;
  //   final i = _orders.indexWhere((e) => e.id == r.id);
  //   if (i >= 0) setState(() => _orders[i] = _orders[i].copyWith(downloaded: true));

  //   // Offer to open the saved file right away
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //         (savedPath == null || savedPath.isEmpty)
  //             ? 'Saved PDF'
  //             : 'Saved to: $savedPath',
  //       ),
  //       action: (savedPath != null && savedPath.isNotEmpty)
  //           ? SnackBarAction(
  //               label: 'OPEN',
  //               onPressed: () => OpenFilex.open(savedPath),
  //             )
  //           : null,
  //     ),
  //   );
  // }

  Future<Uint8List> _buildPdfBytes(OrderRecord r) async {
    final pdf = pw.Document();
    final title = (r.title?.trim().isNotEmpty ?? false) ? r.title!.trim() : _orderTitle(r);

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFF2F8)),
        children: [
          _cell('No.', bold: true),
          _cell('Product', bold: true),
        //  _cell('Brand', bold: true),
          _cellRight('Qty', bold: true),
        ],
      ),
    ];

    int i = 1;
    int totalQty = 0;
    for (final line in r.lines) {
      final name = '${line['name'] ?? ''}';
      final brand = '${line['brand'] ?? ''}';
      final qty = (line['qty'] is int)
          ? line['qty'] as int
          : int.tryParse('${line['qty']}') ?? 0;
      totalQty += qty;
      rows.add(
        pw.TableRow(
          children: [
         //   _cell('$i'),
            _cell(name),
            _cell(brand),
            _cellRight('$qty'),
          ],
        ),
      );
      i++;
    }

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                     pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical:3),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFDCE7FF),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text('Order Summary', style: const pw.TextStyle(fontSize: 10)),
              ),
                  // pw.Text('Order Summary', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  if (r.shopName != null && r.shopName!.isNotEmpty)
                    pw.Text(r.shopName!, style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 4),
                  pw.Text(_prettyDate(r.createdAt), style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 8),
                  pw.Text(title, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              // pw.Container(
              //   padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              //   decoration: pw.BoxDecoration(
              //     color: PdfColor.fromInt(0xFFDCE7FF),
              //     borderRadius: pw.BorderRadius.circular(6),
              //   ),
              //   child: pw.Text('ID: ${r.id}', style: const pw.TextStyle(fontSize: 10)),
              // ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE5E7EB), width: .6),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: rows,
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFEFF1FF),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text('Total Qty: $totalQty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Text('Auto Generated Report', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );

    final raw = await pdf.save();           // List<int>
    return Uint8List.fromList(raw);         // return Uint8List for FileSaver
  }

  pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  pw.Widget _cellRight(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      );

      Future<_DlgAction?> _showActionDialog(BuildContext context) {
  final s = MediaQuery.sizeOf(context).width / 390.0;

  return showGeneralDialog<_DlgAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 330 * s,
            padding: EdgeInsets.fromLTRB(18 * s, 18 * s, 18 * s, 16 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20 * s),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 18 * s,
                  offset: Offset(0, 10 * s),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // gradient chip heading
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * s,
                    vertical: 6 * s,
                  ),
                  decoration: BoxDecoration(
                    gradient: kGradBluePurple,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6 * s),
                      const Text(
                        'Report Options',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 14 * s),

                // main title
                Text(
                  'What would you like to do?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontSize: 18 * s,
                    fontWeight: FontWeight.w800,
                    color: kTxtDark,
                  ),
                ),

                SizedBox(height: 10 * s),

                // subtitle
                Text(
                  'You can quickly preview this report on screen or download a PDF copy for your records.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontSize: 13.5 * s,
                    height: 1.35,
                    color: kTxtDim,
                  ),
                ),

                SizedBox(height: 18 * s),

                Row(
                  children: [

                                 Expanded(
  child: Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(12 * s),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7F53FD).withOpacity(0.22),
          blurRadius: 14 * s,
          offset: Offset(0, 6 * s),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      icon: const Icon(Icons.visibility_rounded, size: 18,  color: Colors.white),
      label: const Text(
        'View',
        style: TextStyle(
          fontFamily: 'ClashGrotesk',
          fontWeight: FontWeight.w800,
          color: Colors.white
        ),
      ),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: 8 * s,
          vertical: 10 * s,
        ),
        backgroundColor: Colors
            .transparent, // let gradient from parent show through
        shadowColor: Colors.transparent,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * s),
        ),
      ),
      onPressed: () =>
          Navigator.of(context).pop(_DlgAction.view),
    ),
  ),
),
                    // VIEW button - outlined, gradient border
                    // Expanded(
                    //   child: OutlinedButton.icon(
                    //     icon: const Icon(Icons.visibility_rounded, size: 18),
                    //     label: const Text(
                    //       'View',
                    //       style: TextStyle(
                    //         fontFamily: 'ClashGrotesk',
                    //         fontWeight: FontWeight.w700,
                    //       ),
                    //     ),
                    //     style: OutlinedButton.styleFrom(
                    //       padding: EdgeInsets.symmetric(
                    //           horizontal: 8 * s, vertical: 10 * s),
                    //       side: const BorderSide(
                    //         color: Color(0xFF7F53FD),
                    //         width: 1.2,
                    //       ),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(12 * s),
                    //       ),
                    //       foregroundColor: const Color(0xFF4B5563),
                    //     ),
                    //     onPressed: () =>
                    //         Navigator.of(context).pop(_DlgAction.view),
                    //   ),
                    // ),
                    SizedBox(width: 12 * s),

                    // DOWNLOAD button - solid gradient
             Expanded(
  child: Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(12 * s),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7F53FD).withOpacity(0.22),
          blurRadius: 14 * s,
          offset: Offset(0, 6 * s),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      icon: const Icon(Icons.download_rounded, size: 18,  color: Colors.white),
      label: const Text(
        'Download',
        style: TextStyle(
          fontFamily: 'ClashGrotesk',
          fontWeight: FontWeight.w800,
          color: Colors.white
        ),
      ),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: 8 * s,
          vertical: 10 * s,
        ),
        backgroundColor: Colors
            .transparent, // let gradient from parent show through
        shadowColor: Colors.transparent,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * s),
        ),
      ),
      onPressed: () =>
          Navigator.of(context).pop(_DlgAction.download),
    ),
  ),
)

                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}


  // Future<_DlgAction?> _showActionDialog(BuildContext context) {
  //   return showGeneralDialog<_DlgAction>(
  //     context: context,
  //     barrierDismissible: true,
  //     barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  //     barrierColor: Colors.black54,
  //     transitionDuration: const Duration(milliseconds: 250),
  //     pageBuilder: (context, animation, secondaryAnimation) {
  //       return Center(
  //         child: Material(
  //           color: Colors.transparent,
  //           child: Container(
  //             width: 320,
  //             padding: const EdgeInsets.all(16),
  //             decoration: BoxDecoration(
  //               color: Colors.white, borderRadius: BorderRadius.circular(16)),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const Text('Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
  //                 const SizedBox(height: 12),
  //                 const Text('View or download a PDF for this order.'),
  //                 const SizedBox(height: 16),
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: OutlinedButton.icon(
  //                         icon: const Icon(Icons.visibility_rounded),
  //                         onPressed: () => Navigator.of(context).pop(_DlgAction.view),
  //                         label: const Text('View'),
  //                       ),
  //                     ),
  //                     const SizedBox(width: 12),
  //                     Expanded(
  //                       child: ElevatedButton.icon(
  //                         icon: const Icon(Icons.download_rounded),
  //                         onPressed: () => Navigator.of(context).pop(_DlgAction.download),
  //                         label: const Text('Download'),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //     transitionBuilder: (context, animation, secondaryAnimation, child) {
  //       final curved = CurvedAnimation(
  //         parent: animation,
  //         curve: Curves.easeOutCubic,
  //         reverseCurve: Curves.easeInCubic,
  //       );
  //       return FadeTransition(
  //         opacity: curved,
  //         child: SlideTransition(
  //           position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
  //           child: child,
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390.0;
    final padBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadOrders,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 140 * s + padBottom),
            children: [
              // Title (unchanged)
            /*  Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: Text(
                      'Report History',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontSize: 20 * s,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              SizedBox(height: 10 * s),*/

              _FiltersBar(
                s: s,
                active: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
              SizedBox(height: 16 * s),

              if (_loading)
                Padding(
                  padding: EdgeInsets.only(top: 40 * s),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_filtered.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).size.height *0.25),
                  child: const Center(child: Text('No sales reports available yet!',style: TextStyle(      fontFamily: 'ClashGrotesk',fontWeight: FontWeight.bold),)),
                )
              else
                ..._filtered.map((r) => Padding(
                      padding: EdgeInsets.only(bottom: 12 * s),
                      child: _ReportCard(
                        s: s,
                        dateText: _prettyDate(r.createdAt),
                        vehicleText: _orderTitle(r), // show order title/summary
                        completed: true,
                        downloaded: r.downloaded,    // only affects label
                        onDownload: () async {
                          final act = await _showActionDialog(context);
                          if (act == _DlgAction.view) {
                            await _viewPdf(r);
                          } else if (act == _DlgAction.download) {
                            await _downloadPdf(r); // auto-save to file manager
                          }
                        },
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- Filters Bar (unchanged visuals) ---------------- */

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.s, required this.active, required this.onChanged});
  final double s;
  final _Filter active;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(_Filter f, String label) {
      final isActive = f == active;
      return GestureDetector(
        onTap: () => onChanged(f),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 8 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: isActive
                ? const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)])
                : null,
            color: isActive ? null : const Color(0xFFEFF2F8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : const Color(0xFF111827),
              fontSize: 13 * s,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(8 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * s),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          chip(_Filter.all, 'All'),
          chip(_Filter.today, 'Today'),
          chip(_Filter.last7, 'Last 7 Days'),
          chip(_Filter.thisMonth, 'This Month'),
        ],
      ),
    );
  }
}

/* ---------------- Report Card (unchanged visuals) ---------------- */

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.s,
    required this.dateText,
    required this.vehicleText,
    required this.completed,
    required this.downloaded,
    required this.onDownload,
  });

  final double s;
  final String dateText;
  final String vehicleText;
  final bool completed;
  final bool downloaded;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final canTap = onDownload != null;
    final label = downloaded ? 'Download\nAgain' : 'Download\nFull Report';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * s),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // gradient spine
          Container(
            width: 9 * s,
            height: 121 * s,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12 * s, 10 * s, 12 * s, 10 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title row + action button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Report Generated',
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            fontSize: 16 * s,
                          ),
                        ),
                      ),
                      _DownloadPill(
                        s: s,
                        enabled: canTap,
                        label: label,
                        onTap: onDownload,
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * s),
                  Row(
                    children: [
                      Icon(Icons.event_note_rounded, size: 16 * s, color: const Color(0xFF6B7280)),
                      SizedBox(width: 6 * s),
                      Text(
                        dateText,
                        style: TextStyle(color: const Color(0xFF6B7280), fontSize: 12.5 * s),
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * s),
                  Row(
                    children: [
                  //    Icon(Icons.directions_car_filled_rounded, size: 16 * s, color: const Color(0xFF6B7280)),
                 //     SizedBox(width: 6 * s),
                      Flexible(
                        child: Text(
                          'Order: $vehicleText',
                          style: TextStyle(color: const Color(0xFF6B7280), fontSize: 12.5 * s),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                 // SizedBox(height: 2 * s),
                  // Row(
                  //   children: [
                  //     Icon(Icons.circle, size: 10 * s, color: const Color(0xFF22C55E)),
                  //     SizedBox(width: 6 * s),
                  //     Text(
                  //       'Status: ${completed ? 'Completed' : 'Pending'}',
                  //       style: TextStyle(color: const Color(0xFF10B981), fontSize: 12.5 * s, fontWeight: FontWeight.w700),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadPill extends StatelessWidget {
  const _DownloadPill({
    required this.s,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final double s;
  final bool enabled;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 8 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12 * s),
        gradient: const LinearGradient(colors: [Color(0xFFEEF6FF), Color(0xFFEFF1FF)]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30 * s,
            height: 30 * s,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)]),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, size: 19, color: Colors.white),
          ),
          SizedBox(width: 8 * s),
          Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              fontSize: 11.5 * s,
              height: 1.0,
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : .5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: pill,
      ),
    );
  }
}


