import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:new_amst_flutter/Model/products_data.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

/* --------------------------- Theme --------------------------- */

const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kField = Color(0xFFF2F3F5);
const kCard = Colors.white;
const kShadow = Color(0x14000000);

const _kGrad = LinearGradient(
  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const _kCardDeco = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
);

/* --------------------------- Helpers --------------------------- */

/// Coerces any dynamic value to a best-effort int.
int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) {
    final s = v.trim();
    final asInt = int.tryParse(s);
    if (asInt != null) return asInt;
    final dot = s.indexOf('.');
    if (dot > 0) return int.tryParse(s.substring(0, dot)) ?? 0; // e.g. "12.0"
  }
  return 0;
}

class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;
    return Opacity(
      opacity: disabled ? 0.7 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: _kGrad,
          boxShadow: [BoxShadow(color: const Color(0xFF7F53FD).withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: disabled ? null : onPressed,
            child: SizedBox(
              height: 44,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* --------------------------- Data Model --------------------------- */

class TeaItem {
  final String key;
  final String? itemId;
  final String name;
  final String desc;
  final String brand;
  const TeaItem({
    required this.key,
    required this.itemId,
    required this.name,
    required this.desc,
    required this.brand,
  });
}

/// Map your local `kTeaProducts` list (List<Map<String,dynamic>>) to TeaItem.
List<TeaItem> mapLocalToTea(List<Map<String, dynamic>> raw) {
  final list = <TeaItem>[];
  for (var i = 0; i < raw.length; i++) {
    final m = raw[i];
    final id = '${m['id'] ?? ''}'.trim();
    final name = '${m['name'] ?? m['item_name'] ?? 'Unknown Product'}'.trim();
    final desc = '${m['item_desc'] ?? ''}'.trim();
    final brandRaw = '${m['brand'] ?? ''}'.trim();
    final brand = brandRaw.isNotEmpty ? brandRaw : 'Meezan';
    final key = id.isNotEmpty ? id : '$name|$brand|$i';
    list.add(TeaItem(key: key, itemId: id.isNotEmpty ? id : null, name: name, desc: desc, brand: brand));
  }
  return list;
}

/* --------------------------- Order Storage Model --------------------------- */

class OrderRecord {
  final String id;
  final DateTime createdAt;
  final List<Map<String, dynamic>> lines;

  // summary for ReportHistory / headers
  final String? title;      // e.g. "UR TEA BAG BLACK … +2 more"
  final String? shopName;   // optional if you add shop context later
  final int itemCount;      // distinct items in the order
  final int totalQty;       // sum of qty
  final bool downloaded;    // if user tapped Download in history

  OrderRecord({
    required this.id,
    required this.createdAt,
    required this.lines,
    this.title,
    this.shopName,
    this.itemCount = 0,
    this.totalQty = 0,
    this.downloaded = false,
  });

  OrderRecord copyWith({
    String? id,
    DateTime? createdAt,
    List<Map<String, dynamic>>? lines,
    String? title,
    String? shopName,
    int? itemCount,
    int? totalQty,
    bool? downloaded,
  }) {
    return OrderRecord(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      lines: lines ?? this.lines,
      title: title ?? this.title,
      shopName: shopName ?? this.shopName,
      itemCount: itemCount ?? this.itemCount,
      totalQty: totalQty ?? this.totalQty,
      downloaded: downloaded ?? this.downloaded,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "createdAt": createdAt.toIso8601String(),
        "lines": lines,
        "title": title,
        "shopName": shopName,
        "itemCount": itemCount,
        "totalQty": totalQty,
        "downloaded": downloaded,
      };

  static OrderRecord fromJson(Map<String, dynamic> j) {
    final List<Map<String, dynamic>> ls = (j["lines"] is List)
        ? (j["lines"] as List)
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList()
        : const <Map<String, dynamic>>[];

    // tolerant defaults for older saved shape — now safely coerce num → int
    final int totalQty = (j["totalQty"] is num)
        ? (j["totalQty"] as num).toInt()
        : ls.fold<int>(0, (a, e) => a + _toInt(e["qty"]));

    final int itemCount = (j["itemCount"] is num)
        ? (j["itemCount"] as num).toInt()
        : ls.length;

    return OrderRecord(
      id: "${j["id"] ?? ""}",
      createdAt: DateTime.tryParse("${j["createdAt"] ?? ""}") ?? DateTime.now(),
      lines: ls,
      title: j["title"] as String?,
      shopName: j["shopName"] as String?,
      itemCount: itemCount,
      totalQty: totalQty,
      downloaded: j["downloaded"] == true,
    );
  }
}

class OrdersStorage {
  final _box = GetStorage();
  final _key = 'local_orders';

  Future<void> addOrder(OrderRecord r) async {
    final list = await listOrders();
    list.insert(0, r);
    await _box.write(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<List<OrderRecord>> listOrders() async {
    final raw = _box.read(_key);
    if (raw == null) return [];
    try {
      final d = jsonDecode(raw);
      if (d is! List) return [];
      final list = d
          .whereType<Map>()
          .map((e) => OrderRecord.fromJson(e.cast<String, dynamic>()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() => _box.remove(_key);

  Future<void> setDownloaded(String id, bool downloaded) async {
    final list = await listOrders();
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    list[i] = list[i].copyWith(downloaded: downloaded);
    await _box.write(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}

/* --------------------------- Cart Storage (SKU only) --------------------------- */

class CartStorage {
  final _box = GetStorage();
  final String _keySku = 'sku_cart_default';

  Map<String, int> loadSku() {
    final raw = _box.read(_keySku);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, int>{};
      decoded.forEach((k, v) {
        if (k is String) out[k] = _toInt(v);
      });
      out.removeWhere((_, q) => q <= 0);
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveSku(Map<String, int> cart) async {
    final clean = Map.of(cart)..removeWhere((_, q) => q <= 0);
    await _box.write(_keySku, jsonEncode(clean));
  }

  Future<void> clear() async => _box.remove(_keySku);
}

/* --------------------------- Catalog (SKU only, no Stack) --------------------------- */

class LocalTeaCatalogSkuOnly extends StatefulWidget {
  const LocalTeaCatalogSkuOnly({super.key});
  @override
  State<LocalTeaCatalogSkuOnly> createState() => _LocalTeaCatalogSkuOnlyState();
}

class _LocalTeaCatalogSkuOnlyState extends State<LocalTeaCatalogSkuOnly> {
  final _search = TextEditingController();
  final _store = CartStorage();

  late final List<TeaItem> _all;
  final Map<String, int> _cartSku = {};
  String _selectedBrand = "All";

  @override
  void initState() {
    super.initState();
    // Ensure `kTeaProducts` (List<Map<String,dynamic>>) is defined in your project.
    _all = mapLocalToTea(kTeaProducts);
    _cartSku
      ..clear()
      ..addAll(_store.loadSku());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _getSku(String k) => _cartSku[k] ?? 0;
  Future<void> _persist() => _store.saveSku(_cartSku);

  void _incSku(TeaItem it) {
    setState(() => _cartSku[it.key] = _getSku(it.key) + 1);
    _persist();
  }

  void _decSku(TeaItem it) {
    setState(() {
      final q = _getSku(it.key);
      if (q > 1) {
        _cartSku[it.key] = q - 1;
      } else {
        _cartSku.remove(it.key);
      }
    });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final brands = <String>["All", ...{for (final i in _all) i.brand}.where((s) => s.isNotEmpty)];
    final q = _search.text.trim().toLowerCase();

    final filtered = _all.where((e) {
      final brandOk = _selectedBrand == "All" || e.brand == _selectedBrand;
      final searchOk = q.isEmpty || e.name.toLowerCase().contains(q) || e.desc.toLowerCase().contains(q);
      return brandOk && searchOk;
    }).toList();

    final totalSku = _cartSku.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Products', style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: kText),
      ),
      bottomNavigationBar: totalSku <= 0
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: _PrimaryGradButton(
                    text: 'VIEW LIST ($totalSku)',
                    onPressed: () async {
                      final res = await Navigator.of(context).push<Map<String, dynamic>>(
                        MaterialPageRoute(
                          builder: (_) => _CartScreenSkuOnly(allItems: _all, cartSku: _cartSku),
                        ),
                      );
                      if (res?['submitted'] == true) {
                        setState(() => _cartSku.clear());
                        await _store.clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order saved locally ✅')),
                          );
                        }
                      } else {
                        await _persist();
                      }
                    },
                  ),
                ),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Search (fixed height, padding)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                height: 52,
                decoration: _kCardDeco.copyWith(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDEFF2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Search products (e.g. UR, Green tea, 100)',
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.only(top: 2),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (_search.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.black45),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Brand chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: brands.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final label = brands[i];
                  final selected = _selectedBrand == label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedBrand = label),
                    selectedColor: const Color(0xFF7F53FD),
                    labelStyle: TextStyle(color: selected ? Colors.white : kText, fontWeight: FontWeight.w600),
                    backgroundColor: Colors.white,
                    shape: StadiumBorder(side: BorderSide(color: selected ? Colors.transparent : const Color(0xFFEDEFF2))),
                    elevation: selected ? 2 : 0,
                  );
                },
              ),
            ),

            // Counts
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text('${filtered.length} products',
                      style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (totalSku > 0)
                    const Text('In list:',
                        style: TextStyle(color: Color(0xFF7F53FD), fontWeight: FontWeight.w800, fontSize: 12)),
                  if (totalSku > 0) const SizedBox(width: 6),
                  if (totalSku > 0)
                    Text('SKU $totalSku',
                        style: const TextStyle(color: Color(0xFF7F53FD), fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
            ),

            // Product list (cards at 95% width)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final it = filtered[i];
                  return Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.95, // 95% width
                      child: _ProductCardSkuOnly(
                        name: it.name,
                        desc: it.desc,
                        brand: it.brand,
                        qty: _getSku(it.key),
                        onInc: () => _incSku(it),
                        onDec: () => _decSku(it),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------- Product Card (95% width, SKU only) --------------------------- */

class _ProductCardSkuOnly extends StatelessWidget {
  const _ProductCardSkuOnly({
    required this.name,
    required this.desc,
    required this.brand,
    required this.qty,
    required this.onInc,
    required this.onDec,
  });

  final String name;
  final String desc;
  final String brand;
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        gradient: _kGrad,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.6),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14.4),
          boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F53FD).withOpacity(.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF7F53FD).withOpacity(.25)),
                  ),
                  child: Text(brand, style: const TextStyle(color: kText, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(color: kText, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(color: kMuted),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            _QtyControlsSku(qty: qty, onInc: onInc, onDec: onDec),
          ],
        ),
      ),
    );
  }
}

class _QtyControlsSku extends StatelessWidget {
  const _QtyControlsSku({required this.qty, required this.onInc, required this.onDec});
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    if (qty <= 0) {
      return SizedBox(
        width: 96,
        child: _PrimaryGradButton(text: 'ADD', onPressed: onInc),
      );
    }
    return Container(
      decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDec,
            icon: const Icon(Icons.remove_rounded, size: 20, color: kText),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700, color: kText)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onInc,
            icon: const Icon(Icons.add_rounded, size: 20, color: kText),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- Cart (No Stack) --------------------------- */

class _CartScreenSkuOnly extends StatefulWidget {
  const _CartScreenSkuOnly({required this.allItems, required this.cartSku});
  final List<TeaItem> allItems;
  final Map<String, int> cartSku;

  @override
  State<_CartScreenSkuOnly> createState() => _CartScreenSkuOnlyState();
}

class _CartScreenSkuOnlyState extends State<_CartScreenSkuOnly> {
  bool _saving = false;

  List<_CartRow> get _rows {
    final keys = widget.cartSku.keys.toList()..sort();
    return [
      for (final k in keys)
        _CartRow(
          item: widget.allItems.firstWhere(
            (e) => e.key == k,
            orElse: () => const TeaItem(key: 'missing', itemId: null, name: 'Unknown', desc: '', brand: 'Meezan'),
          ),
          qty: widget.cartSku[k] ?? 0,
        )
    ]..removeWhere((r) => r.qty <= 0);
  }

  int get _total => widget.cartSku.values.fold(0, (a, b) => a + b);

  Future<void> _save() async {
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final lines = <Map<String, dynamic>>[
        for (final r in _rows)
          {
            'key': r.item.key,
            'itemId': r.item.itemId,
            'name': r.item.name,
            'brand': r.item.brand,
            'qty': r.qty,
          },
      ];

      final rec = OrderRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        lines: lines,
        // Optional summaries (can be used by ReportHistory screen)
        itemCount: _rows.length,
        totalQty: _total,
        title: _rows.isNotEmpty ? '${_rows.first.item.name}${_rows.length > 1 ? ' +${_rows.length - 1} more' : ''}' : null,
      );

      await OrdersStorage().addOrder(rec);
      if (!mounted) return;
      Navigator.pop(context, {'submitted': true});
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: kText),
        title: const Text('My List', style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: _PrimaryGradButton(
              text: 'CONFIRM & SAVE',
              onPressed: _rows.isEmpty || _saving ? null : _save,
              loading: _saving,
            ),
          ),
        ),
      ),
      body: _rows.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_grocery_store_outlined, size: 56, color: kMuted),
                const SizedBox(height: 8),
                Text('Your list is empty', style: t.titleMedium?.copyWith(color: kText)),
                const SizedBox(height: 4),
                Text('Add products from the catalog.', style: t.bodySmall?.copyWith(color: kMuted)),
              ]),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: _rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final row = _rows[i];
                return Container(
                  decoration: _kCardDeco,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.local_cafe_rounded, color: Color(0xFF7F53FD)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7F53FD).withOpacity(.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFF7F53FD).withOpacity(.25)),
                            ),
                            child: Text(row.item.brand,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
                          ),
                          const SizedBox(height: 6),
                          Text(row.item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.titleMedium?.copyWith(color: kText, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(row.item.desc,
                              maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: kMuted)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Text('Qty: ${row.qty}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
                          ),
                        ]),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _CartRow {
  final TeaItem item;
  final int qty;
  const _CartRow({required this.item, required this.qty});
}

/* --------------------------- Small gradient button (internal) --------------------------- */

class _PrimaryGradButton extends StatelessWidget {
  const _PrimaryGradButton({required this.text, required this.onPressed, this.loading = false});
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;
    return Opacity(
      opacity: disabled ? 0.7 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: _kGrad,
          boxShadow: [BoxShadow(color: const Color(0xFF7F53FD).withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: disabled ? null : onPressed,
            child: SizedBox(
              height: 44,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------------------------------------------------
   NOTE:
   - Call `await GetStorage.init();` once (e.g., in main()) before using.
   - Ensure `kTeaProducts` is defined (List<Map<String,dynamic>>).
---------------------------------------------------------------- */



/*
/// ---------------------------------------------------------------------------
///  THEME
/// ---------------------------------------------------------------------------
const kOrange = Color(0xFFEA7A3B);
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kField = Color(0xFFF2F3F5);
const kCard = Colors.white;
const kShadow = Color(0x14000000);

/// ---------------------------------------------------------------------------
///  MODELS & MAPPERS (local only)
//  - TeaItem: flattened view from local map
//  - QtyMode: SKU / CTN / Both
/// ---------------------------------------------------------------------------
class TeaItem {
  final String key;        // stable local key
  final String? itemId;    // id
  final String name;
  final String desc;
  final String brand;
  final int ctnSize;       // packs per CTN if known

  const TeaItem({
    required this.key,
    required this.itemId,
    required this.name,
    required this.desc,
    required this.brand,
    this.ctnSize = 0,
  });
}

enum QtyMode { sku, ctn, both }

List<TeaItem> mapLocalToTea(List<Map<String, dynamic>> raw) {
  final list = <TeaItem>[];
  for (var i = 0; i < raw.length; i++) {
    final m = raw[i];
    final id = '${m['id'] ?? ''}'.trim();
    final name = '${m['name'] ?? m['item_name'] ?? 'Unknown Product'}'.trim();
    final desc = '${m['item_desc'] ?? ''}'.trim();
    final brandRaw = '${m['brand'] ?? ''}'.trim();
    final brand = brandRaw.isNotEmpty ? brandRaw : 'Meezan';

    // Try to infer CTN size from pack_qty / ctn_qty / unit_flag_qty
    final ctnSize = int.tryParse('${m['pack_qty'] ?? m['ctn_qty'] ?? m['unit_flag_qty'] ?? ''}'
            .replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;

    final key = id.isNotEmpty ? id : '$name|$brand|$i';
    list.add(TeaItem(
      key: key,
      itemId: id.isNotEmpty ? id : null,
      name: name,
      desc: desc,
      brand: brand,
      ctnSize: ctnSize,
    ));
  }
  return list;
}

/// ---------------------------------------------------------------------------
///  CART & ORDERS — local persistence (GetStorage)
/// ---------------------------------------------------------------------------
class CartStorage {
  final _box = GetStorage();
  String _skuKey() => 'local_cart_sku';
  String _ctnKey() => 'local_cart_ctn';

  Map<String, int> loadSku() {
    final raw = _box.read(_skuKey());
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final m = <String, int>{};
      decoded.forEach((k, v) {
        if (k is String) m[k] = (v is int) ? v : int.tryParse('$v') ?? 0;
      });
      m.removeWhere((_, q) => q <= 0);
      return m;
    } catch (_) {
      return {};
    }
  }

  Map<String, int> loadCtn() {
    final raw = _box.read(_ctnKey());
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final m = <String, int>{};
      decoded.forEach((k, v) {
        if (k is String) m[k] = (v is int) ? v : int.tryParse('$v') ?? 0;
      });
      m.removeWhere((_, q) => q <= 0);
      return m;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveSku(Map<String, int> cart) async =>
      _box.write(_skuKey(), jsonEncode(Map.of(cart)..removeWhere((_, q) => q <= 0)));

  Future<void> saveCtn(Map<String, int> cart) async =>
      _box.write(_ctnKey(), jsonEncode(Map.of(cart)..removeWhere((_, q) => q <= 0)));

  Future<void> clearAll() async {
    await _box.remove(_skuKey());
    await _box.remove(_ctnKey());
  }
}

class OrderRecord {
  final String id;
  final DateTime createdAt;
  final List<Map<String, dynamic>> lines; // {key, name, brand, sku, ctn}

  OrderRecord({
    required this.id,
    required this.createdAt,
    required this.lines,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'lines': lines,
      };

  static OrderRecord fromJson(Map<String, dynamic> j) => OrderRecord(
        id: '${j['id'] ?? ''}',
        createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}') ?? DateTime.now(),
        lines: (j['lines'] as List?)?.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() ?? const [],
      );
}

class OrdersStorage {
  final _box = GetStorage();
  final _key = 'local_orders';

  Future<void> addOrder(OrderRecord r) async {
    final all = await listOrders();
    all.insert(0, r);
    await _box.write(_key, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<List<OrderRecord>> listOrders() async {
    final raw = _box.read(_key);
    if (raw == null) return [];
    try {
      final d = jsonDecode(raw);
      if (d is! List) return [];
      return d.whereType<Map>().map((e) => OrderRecord.fromJson(e.cast<String, dynamic>())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() => _box.remove(_key);
}

/// ---------------------------------------------------------------------------
///  WIDGET: LocalTeaCatalog  (search + chips + qty mode + list + cart)
/// ---------------------------------------------------------------------------
class LocalTeaCatalog extends StatefulWidget {
  final bool allowCredit; // show Credit/Cash toggle in cart
  const LocalTeaCatalog({super.key, this.allowCredit = true});

  @override
  State<LocalTeaCatalog> createState() => _LocalTeaCatalogState();
}

class _LocalTeaCatalogState extends State<LocalTeaCatalog> {
  final _search = TextEditingController();
  String _selectedBrand = "All";
  QtyMode _qtyMode = QtyMode.sku;

  final _cartSku = <String, int>{};
  final _cartCtn = <String, int>{};

  final _store = CartStorage();
  late final List<TeaItem> _all;

  @override
  void initState() {
    super.initState();
    _all = mapLocalToTea(kTeaProducts);
    // load saved carts (optional)
    final savedSku = _store.loadSku();
    final savedCtn = _store.loadCtn();
    _cartSku..clear()..addAll(savedSku);
    _cartCtn..clear()..addAll(savedCtn);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _getSku(String k) => _cartSku[k] ?? 0;
  int _getCtn(String k) => _cartCtn[k] ?? 0;
  Future<void> _persist() async { await _store.saveSku(_cartSku); await _store.saveCtn(_cartCtn); }

  void _incSku(TeaItem it) { setState(() => _cartSku[it.key] = _getSku(it.key) + 1); _store.saveSku(_cartSku); }
  void _decSku(TeaItem it) {
    setState(() {
      final q = _getSku(it.key);
      if (q > 1) _cartSku[it.key] = q - 1; else _cartSku.remove(it.key);
    });
    _store.saveSku(_cartSku);
  }
  void _incCtn(TeaItem it) { setState(() => _cartCtn[it.key] = _getCtn(it.key) + 1); _store.saveCtn(_cartCtn); }
  void _decCtn(TeaItem it) {
    setState(() {
      final q = _getCtn(it.key);
      if (q > 1) _cartCtn[it.key] = q - 1; else _cartCtn.remove(it.key);
    });
    _store.saveCtn(_cartCtn);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final brands = <String>["All", ...{for (final i in _all) i.brand}.where((s) => s.isNotEmpty)];
    final q = _search.text.trim().toLowerCase();
    final filtered = _all.where((e) {
      final brandOk = _selectedBrand == "All" || e.brand == _selectedBrand;
      final searchOk = q.isEmpty || e.name.toLowerCase().contains(q) || e.desc.toLowerCase().contains(q);
      return brandOk && searchOk;
    }).toList();

    final totalSku = _cartSku.values.fold(0, (a, b) => a + b);
    final totalCtn = _cartCtn.values.fold(0, (a, b) => a + b);
    final totalAll = totalSku + totalCtn;

    String qtyLabel() {
      if (totalSku > 0 && totalCtn > 0) return 'SKU: $totalSku • CTN: $totalCtn';
      if (totalCtn > 0) return 'CTN: $totalCtn';
      return 'SKU: $totalSku';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text("Products", style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: kText),
                  onPressed: () async {
                    final res = await Navigator.of(context).push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder: (_) => _LocalCartScreen(
                          allItems: _all,
                          cartSku: _cartSku,
                          cartCtn: _cartCtn,
                          allowCredit: widget.allowCredit,
                          onIncSku: (it) { _incSku(it); setState(() {}); },
                          onDecSku: (it) { _decSku(it); setState(() {}); },
                          onIncCtn: (it) { _incCtn(it); setState(() {}); },
                          onDecCtn: (it) { _decCtn(it); setState(() {}); },
                        ),
                      ),
                    );
                    if (res?['submitted'] == true) {
                      setState(() {
                        _cartSku.clear();
                        _cartCtn.clear();
                      });
                      await _store.clearAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order saved locally ✅')),
                        );
                      }
                    } else {
                      await _persist();
                    }
                  },
                ),
                if (totalAll > 0)
                  Positioned(
                    right: 6,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(999)),
                      child: Text('$totalAll',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: kShadow, blurRadius: 12, offset: Offset(0, 6))],
                border: Border.all(color: const Color(0xFFEDEFF2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: kMuted.withOpacity(.9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search products (e.g. Gold, Green Tea, 475g)',
                        hintStyle: TextStyle(color: kMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_search.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: kMuted),
                      onPressed: () { _search.clear(); setState(() {}); },
                    ),
                ],
              ),
            ),
          ),

          // Brand chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: brands.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final label = brands[i];
                final selected = _selectedBrand == label;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedBrand = label),
                  selectedColor: kOrange,
                  labelStyle: TextStyle(color: selected ? Colors.white : kText, fontWeight: FontWeight.w600),
                  backgroundColor: Colors.white,
                  shape: StadiumBorder(side: BorderSide(color: selected ? Colors.transparent : const Color(0xFFEDEFF2))),
                  elevation: selected ? 2 : 0,
                );
              },
            ),
          ),

          // Qty mode selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Expanded(child: _QtyModeTile(label: 'SKU',  selected: _qtyMode == QtyMode.sku,  onTap: () => setState(() => _qtyMode = QtyMode.sku))),
                const SizedBox(width: 8),
                Expanded(child: _QtyModeTile(label: 'CTN',  selected: _qtyMode == QtyMode.ctn,  onTap: () => setState(() => _qtyMode = QtyMode.ctn))),
                const SizedBox(width: 8),
                Expanded(child: _QtyModeTile(label: 'Both', selected: _qtyMode == QtyMode.both, onTap: () => setState(() => _qtyMode = QtyMode.both))),
              ],
            ),
          ),

          // Counts row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Text('${filtered.length} products', style: t.bodySmall?.copyWith(color: kMuted)),
                const Spacer(),
                if (totalAll > 0)
                  Text('In list: ${qtyLabel()}', style: t.bodySmall?.copyWith(color: kOrange, fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = filtered[i];
                return _ProductCard(
                  name: item.name,
                  desc: item.ctnSize > 0 ? '${item.desc} • ${item.ctnSize} per CTN' : item.desc,
                  brand: item.brand,
                  qtySku: _getSku(item.key),
                  qtyCtn: _getCtn(item.key),
                  mode: _qtyMode,
                  onIncSku: () => _incSku(item),
                  onDecSku: () => _decSku(item),
                  onIncCtn: () => _incCtn(item),
                  onDecCtn: () => _decCtn(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  PRODUCT CARD + SMALL UI BITS
/// ---------------------------------------------------------------------------
class _ProductCard extends StatelessWidget {
  final String name;
  final String desc;
  final String brand;

  final int qtySku;
  final int qtyCtn;
  final QtyMode mode;

  final VoidCallback onIncSku;
  final VoidCallback onDecSku;
  final VoidCallback onIncCtn;
  final VoidCallback onDecCtn;

  const _ProductCard({
    required this.name,
    required this.desc,
    required this.brand,
    required this.qtySku,
    required this.qtyCtn,
    required this.mode,
    required this.onIncSku,
    required this.onDecSku,
    required this.onIncCtn,
    required this.onDecCtn,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    Widget controls() {
      switch (mode) {
        case QtyMode.sku:
          return _QtyControlsSingle(label: 'SKU', qty: qtySku, onInc: onIncSku, onDec: onDecSku);
        case QtyMode.ctn:
          return _QtyControlsSingle(label: 'CTN', qty: qtyCtn, onInc: onIncCtn, onDec: onDecCtn);
        case QtyMode.both:
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyControlsSingle(label: 'SKU', qty: qtySku, onInc: onIncSku, onDec: onDecSku),
              const SizedBox(width: 8),
              _QtyControlsSingle(label: 'CTN', qty: qtyCtn, onInc: onIncCtn, onDec: onDecCtn),
            ],
          );
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {},
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [kOrange, Color(0xFFFFB07A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Container(
          margin: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14.4),
            boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _TagPill(text: brand),
                  const SizedBox(height: 6),
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(color: kText, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: kMuted)),
                ]),
              ),
              const SizedBox(width: 12),
              controls(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String text;
  const _TagPill({required this.text, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kOrange.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kOrange.withOpacity(.25)),
      ),
      child: Text(text, style: const TextStyle(color: kText, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _QtyControlsSingle extends StatelessWidget {
  final String label;
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _QtyControlsSingle({
    required this.label,
    required this.qty,
    required this.onInc,
    required this.onDec,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (qty <= 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: kOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onInc,
            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(visualDensity: VisualDensity.compact, onPressed: onDec,
                  icon: const Icon(Icons.remove_rounded, size: 20, color: kText)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700, color: kText)),
              ),
              IconButton(visualDensity: VisualDensity.compact, onPressed: onInc,
                  icon: const Icon(Icons.add_rounded, size: 20, color: kText)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyModeTile extends StatelessWidget {
  const _QtyModeTile({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1E6) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? kOrange : const Color(0xFFE5E7EB)),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? kText : kMuted)),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  CART SCREEN (local only)
/// ---------------------------------------------------------------------------
class _LocalCartScreen extends StatefulWidget {
  final List<TeaItem> allItems;
  final Map<String, int> cartSku;
  final Map<String, int> cartCtn;

  final bool allowCredit;

  final void Function(TeaItem) onIncSku;
  final void Function(TeaItem) onDecSku;
  final void Function(TeaItem) onIncCtn;
  final void Function(TeaItem) onDecCtn;

  const _LocalCartScreen({
    required this.allItems,
    required this.cartSku,
    required this.cartCtn,
    required this.allowCredit,
    required this.onIncSku,
    required this.onDecSku,
    required this.onIncCtn,
    required this.onDecCtn,
    Key? key,
  }) : super(key: key);

  @override
  State<_LocalCartScreen> createState() => _LocalCartScreenState();
}

class _LocalCartScreenState extends State<_LocalCartScreen> {
  bool _isSaving = false;
  String _paymentType = 'CR'; // CR/CS just for UI parity

  List<_CartRow> get _rows {
    final keys = <String>{...widget.cartSku.keys, ...widget.cartCtn.keys}.toList()..sort();
    final rows = <_CartRow>[];
    for (final k in keys) {
      final item = widget.allItems.firstWhere(
        (e) => e.key == k,
        orElse: () => const TeaItem(key: 'missing', itemId: null, name: 'Unknown', desc: '', brand: 'Meezan'),
      );
      rows.add(_CartRow(item: item, sku: widget.cartSku[k] ?? 0, ctn: widget.cartCtn[k] ?? 0));
    }
    rows.sort((a, b) => a.item.name.compareTo(b.item.name));
    return rows;
  }

  int get _totalSku => widget.cartSku.values.fold(0, (a, b) => a + b);
  int get _totalCtn => widget.cartCtn.values.fold(0, (a, b) => a + b);
  int get _totalAll => _totalSku + _totalCtn;

  Future<void> _saveOrderLocally() async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      final lines = <Map<String, dynamic>>[];
      for (final r in _rows) {
        if (r.sku <= 0 && r.ctn <= 0) continue;
        lines.add({
          'key': r.item.key,
          'itemId': r.item.itemId,
          'name': r.item.name,
          'brand': r.item.brand,
          'sku': r.sku,
          'ctn': r.ctn,
          'paymentType': widget.allowCredit ? _paymentType : 'CS',
        });
      }

      final rec = OrderRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        lines: lines,
      );
      await OrdersStorage().addOrder(rec);

      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.pop<Map<String, dynamic>>(context, {'submitted': true});
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kText),
        title: Text('My List', style: t.titleLarge?.copyWith(color: kText, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kOrange, Color(0xFFFFB07A)], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: kShadow, blurRadius: 14, offset: Offset(0, 8))],
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Items in your list: SKU $_totalSku • CTN $_totalCtn (Total $_totalAll)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          if (_rows.isEmpty)
            Expanded(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_grocery_store_outlined, size: 56, color: kMuted),
                  const SizedBox(height: 8),
                  Text('Your list is empty', style: t.titleMedium?.copyWith(color: kText)),
                  const SizedBox(height: 4),
                  Text('Add products from the catalog.', style: t.bodySmall?.copyWith(color: kMuted)),
                ]),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                itemCount: _rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final row = _rows[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: kShadow, blurRadius: 12, offset: Offset(0, 6))],
                      border: Border.all(color: const Color(0xFFEDEFF2)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.local_cafe_rounded, color: kOrange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _TagPill(text: row.item.brand),
                            const SizedBox(height: 6),
                            Text(row.item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: t.titleMedium?.copyWith(color: kText, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(row.item.desc, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: t.bodySmall?.copyWith(color: kMuted)),
                            const SizedBox(height: 8),
                            Row(children: [
                              _MiniBadge(label: 'SKU', value: row.sku),
                              const SizedBox(width: 8),
                              _MiniBadge(label: 'CTN', value: row.ctn),
                            ]),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QtyControlsTiny(
                              label: 'SKU',
                              qty: row.sku,
                              onInc: () { widget.onIncSku(row.item); setState(() {}); },
                              onDec: () { widget.onDecSku(row.item); setState(() {}); },
                            ),
                            const SizedBox(height: 8),
                            _QtyControlsTiny(
                              label: 'CTN',
                              qty: row.ctn,
                              onInc: () { widget.onIncCtn(row.item); setState(() {}); },
                              onDec: () { widget.onDecCtn(row.item); setState(() {}); },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // payment + save
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 52),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.allowCredit) ...[
                  const Text('Payment type', style: TextStyle(fontWeight: FontWeight.w600, color: kText)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _PaymentChoiceTile(label: 'Credit', code: 'CR', selected: _paymentType == 'CR',
                          onTap: () => setState(() => _paymentType = 'CR'))),
                      const SizedBox(width: 12),
                      Expanded(child: _PaymentChoiceTile(label: 'Cash', code: 'CS', selected: _paymentType == 'CS',
                          onTap: () => setState(() => _paymentType = 'CS'))),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _rows.isEmpty || _isSaving ? null : _saveOrderLocally,
                    child: _isSaving
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Text('Confirm & Save', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// cart helpers
class _CartRow {
  final TeaItem item;
  final int sku;
  final int ctn;
  const _CartRow({required this.item, required this.sku, required this.ctn});
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final int value;
  const _MiniBadge({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
    );
  }
}

class _QtyControlsTiny extends StatelessWidget {
  final String label;
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;
  const _QtyControlsTiny({required this.label, required this.qty, required this.onInc, required this.onDec});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: kMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(visualDensity: VisualDensity.compact, onPressed: onDec,
                  icon: const Icon(Icons.remove_rounded, size: 18, color: kText)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700, color: kText)),
              ),
              IconButton(visualDensity: VisualDensity.compact, onPressed: onInc,
                  icon: const Icon(Icons.add_rounded, size: 18, color: kText)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentChoiceTile extends StatelessWidget {
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentChoiceTile({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? const Color(0xFFFFF1E6) : Colors.white,
          border: Border.all(color: selected ? kOrange : const Color(0xFFE5E7EB), width: selected ? 1.5 : 1),
          boxShadow: const [BoxShadow(color: kShadow, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) const Icon(Icons.check_circle, size: 18, color: kOrange)
            else const Icon(Icons.radio_button_unchecked, size: 18, color: kMuted),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? kText : kMuted)),
          ],
        ),
      ),
    );
  }
}
*/
// class TeaCatalogScreen extends StatefulWidget {
//   const TeaCatalogScreen({super.key});

//   @override
//   State<TeaCatalogScreen> createState() => _TeaCatalogScreenState();
// }

// class _TeaCatalogScreenState extends State<TeaCatalogScreen> {
//   final _search = TextEditingController();

//   String _brandFilter = 'All';
//   late final List<Product> _all;
//   late final List<String> _brands;

//   @override
//   void initState() {
//     super.initState();
//     _all = kTeaProducts.map(Product.fromMap).toList()
//       ..sort((a, b) {
//         final byBrand = a.brand.compareTo(b.brand);
//         return byBrand != 0 ? byBrand : a.name.compareTo(b.name);
//       });

//     _brands = [
//       'All',
// ...({for (final p in _all) p.brand}.toList()
//   ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()))),

//     ];
//   }

//   @override
//   void dispose() {
//     _search.dispose();
//     super.dispose();
//   }

//   List<Product> get _filtered {
//     final q = _search.text.trim().toLowerCase();
//     final byBrand = _brandFilter == 'All'
//         ? _all
//         : _all.where((p) => p.brand == _brandFilter).toList();

//     if (q.isEmpty) return byBrand;

//     return byBrand.where((p) {
//       // Match on name, id, brand, segment, item_name, item_desc
//       return p.nameL.contains(q) ||
//           p.id.contains(q) ||
//           p.brandL.contains(q) ||
//           p.segmentL.contains(q) ||
//           p.itemNameL.contains(q) ||
//           p.itemDescL.contains(q);
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final items = _filtered;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Tea Products'),
//         centerTitle: true,
//         systemOverlayStyle: SystemUiOverlayStyle.light,
//       ),
//       body: Column(
//         children: [
//           _Filters(
//             controller: _search,
//             brands: _brands,
//             selectedBrand: _brandFilter,
//             onBrandChanged: (v) => setState(() => _brandFilter = v),
//             onChanged: (_) => setState(() {}),
//             onClear: () {
//               _search.clear();
//               setState(() {});
//             },
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
//             child: Row(
//               children: [
//                 Text(
//                   'Showing ${items.length} item${items.length == 1 ? '' : 's'}',
//                   style: const TextStyle(fontWeight: FontWeight.w500),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: ListView.separated(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//               itemCount: items.length,
//               separatorBuilder: (_, __) => const SizedBox(height: 10),
//               itemBuilder: (ctx, i) => _ProductCard(product: items[i]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* --------------------------- Widgets --------------------------- */

// class _Filters extends StatelessWidget {
//   const _Filters({
//     required this.controller,
//     required this.brands,
//     required this.selectedBrand,
//     required this.onBrandChanged,
//     required this.onChanged,
//     required this.onClear,
//   });

//   final TextEditingController controller;
//   final List<String> brands;
//   final String selectedBrand;
//   final ValueChanged<String> onBrandChanged;
//   final ValueChanged<String> onChanged;
//   final VoidCallback onClear;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: const Color(0xFFF7F7FB),
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
//         child: Column(
//           children: [
//             TextField(
//               controller: controller,
//               onChanged: onChanged,
//               decoration: InputDecoration(
//                 hintText: 'Search by name, ID, brand, segment…',
//                 prefixIcon: const Icon(Icons.search),
//                 suffixIcon: controller.text.isEmpty
//                     ? null
//                     : IconButton(
//                         onPressed: onClear,
//                         icon: const Icon(Icons.close),
//                         tooltip: 'Clear',
//                       ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: const BorderSide(color: Color(0xFFE4E6EB)),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 const Text('Brand:', style: TextStyle(fontWeight: FontWeight.w600)),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       border: Border.all(color: const Color(0xFFE4E6EB)),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         isExpanded: true,
//                         value: selectedBrand,
//                         items: brands
//                             .map((b) => DropdownMenuItem(
//                                   value: b,
//                                   child: Text(b, overflow: TextOverflow.ellipsis),
//                                 ))
//                             .toList(),
//                         onChanged: (v) {
//                           if (v != null) onBrandChanged(v);
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ProductCard extends StatelessWidget {
//   const _ProductCard({required this.product});

//   final Product product;

//   @override
//   Widget build(BuildContext context) {
//     final badgeColor = product.ctnStatus ? const Color(0xFF2F7D32) : const Color(0xFF9E9E9E);
//     final badgeText = product.ctnStatus ? 'Active' : 'Inactive';

//     return Card(
//       elevation: 0.5,
//       clipBehavior: Clip.antiAlias,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//       child: InkWell(
//         onTap: () {},
//         child: Padding(
//           padding: const EdgeInsets.all(14),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _LeadingIcon(brand: product.brand),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _MainInfo(product: product),
//               ),
//               const SizedBox(width: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: badgeColor.withOpacity(.1),
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: badgeColor.withOpacity(.25)),
//                     ),
//                     child: Text(
//                       badgeText,
//                       style: TextStyle(
//                         color: badgeColor,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: .2,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     '${product.unitFlagQtyLabel}',
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: Color(0xFF616770),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _LeadingIcon extends StatelessWidget {
//   const _LeadingIcon({required this.brand});
//   final String brand;

//   @override
//   Widget build(BuildContext context) {
//     // Simple brand-based icon; swap to your assets if you have logos.
//     final icon = switch (brand.toLowerCase()) {
//       _ when brand.contains('ULTRA') => Icons.local_cafe_rounded,
//       _ when brand.contains('HARDUM') || brand.contains('HARDAM') => Icons.emoji_food_beverage_rounded,
//       _ when brand.contains('BAITHAK') => Icons.coffee_rounded,
//       _ => Icons.inventory_2_rounded,
//     };

//     return Container(
//       width: 44,
//       height: 44,
//       decoration: BoxDecoration(
//         color: const Color(0xFFF3F4F7),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Icon(icon),
//     );
//   }
// }

// class _MainInfo extends StatelessWidget {
//   const _MainInfo({required this.product});
//   final Product product;

//   @override
//   Widget build(BuildContext context) {
//     final styleMuted = const TextStyle(fontSize: 12, color: Color(0xFF616770));
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           product.name,
//           maxLines: 2,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(
//             fontWeight: FontWeight.w700,
//             fontSize: 14,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Wrap(
//           spacing: 8,
//           runSpacing: -6,
//           children: [
//             _Chip(text: product.brand),
//             _Chip(text: 'ID: ${product.id}'),
//             if (product.ctnQty != null) _Chip(text: 'CTN: ${product.ctnQty}'),
//             if (product.packQty != null) _Chip(text: 'Pack: ${product.packQty}'),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Text(product.itemDesc, maxLines: 2, overflow: TextOverflow.ellipsis, style: styleMuted),
//       ],
//     );
//   }
// }

// class _Chip extends StatelessWidget {
//   const _Chip({required this.text});
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 24,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF2F3F5),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       alignment: Alignment.center,
//       child: Text(
//         text,
//         style: const TextStyle(fontSize: 11, color: Color(0xFF363B40), fontWeight: FontWeight.w600),
//       ),
//     );
//   }
// }

// /* --------------------------- Model --------------------------- */

// class Product {
//   final String id;
//   final String name;
//   final String brand;
//   final String segment;
//   final String itemName;
//   final String itemDesc;
//   final int? ctnQty;
//   final int? packQty;
//   final bool ctnStatus;
//   final double? unitFlagQty;
//   final double? perKgLtr;
//   final double? perCtnNkg;

//   Product({
//     required this.id,
//     required this.name,
//     required this.brand,
//     required this.segment,
//     required this.itemName,
//     required this.itemDesc,
//     required this.ctnQty,
//     required this.packQty,
//     required this.ctnStatus,
//     required this.unitFlagQty,
//     required this.perKgLtr,
//     required this.perCtnNkg,
//   });

//   String get nameL => name.toLowerCase();
//   String get brandL => brand.toLowerCase();
//   String get segmentL => segment.toLowerCase();
//   String get itemNameL => itemName.toLowerCase();
//   String get itemDescL => itemDesc.toLowerCase();

//   String get unitFlagQtyLabel {
//     if (unitFlagQty == null) return '';
//     // Keep as integer when it is whole number; otherwise show decimals.
//     final v = unitFlagQty!;
//     return v == v.roundToDouble() ? '${v.toInt()} g' : '${v} kg/g';
//   }

//   factory Product.fromMap(Map<String, dynamic> m) {
//     double? _d(String? s) {
//       if (s == null || s.isEmpty) return null;
//       return double.tryParse(s);
//     }

//     int? _i(String? s) {
//       if (s == null || s.isEmpty) return null;
//       return int.tryParse(s);
//     }

//     return Product(
//       id: (m['id'] ?? '').toString(),
//       name: (m['name'] ?? m['item_name'] ?? '').toString(),
//       brand: (m['brand'] ?? '').toString(),
//       segment: (m['segment'] ?? '').toString(),
//       itemName: (m['item_name'] ?? '').toString(),
//       itemDesc: (m['item_desc'] ?? '').toString(),
//       ctnQty: _i((m['ctn_qty'] ?? '').toString()),
//       packQty: _i((m['pack_qty'] ?? '').toString()),
//       ctnStatus: ((m['ctn_status'] ?? '0').toString() == '1'),
//       unitFlagQty: _d((m['unit_flag_qty'] ?? '').toString()),
//       perKgLtr: _d((m['per_kg_ltr'] ?? '').toString()),
//       perCtnNkg: _d((m['per_ctn_nkg'] ?? '').toString()),
//     );
//   }
// }
