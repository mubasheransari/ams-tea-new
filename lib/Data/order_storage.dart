// lib/storage/order_storage.dart

import 'dart:convert';
import 'package:get_storage/get_storage.dart';

// lib/storage/order_storage.dart

import 'dart:async';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

/// --------------------------- Helpers ---------------------------

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

/// --------------------------- Order Storage Model ---------------------------

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

    // tolerant defaults for older saved shape — safely coerce num/String → int
    final int totalQty = (j["totalQty"] is num)
        ? (j["totalQty"] as num).toInt()
        : ls.fold<int>(0, (a, e) => a + _toInt(e["qty"]));

    final int itemCount = (j["itemCount"] is num)
        ? (j["itemCount"] as num).toInt()
        : ls.length;

    return OrderRecord(
      id: "${j["id"] ?? ""}",
      createdAt:
          DateTime.tryParse("${j["createdAt"] ?? ""}") ?? DateTime.now(),
      lines: ls,
      title: j["title"] as String?,
      shopName: j["shopName"] as String?,
      itemCount: itemCount,
      totalQty: totalQty,
      downloaded: j["downloaded"] == true,
    );
  }
}

/// --------------------------- OrdersStorage ---------------------------

class OrdersStorage {
  OrdersStorage._() : _box = GetStorage();
  static final OrdersStorage _instance = OrdersStorage._();
  factory OrdersStorage() => _instance;

  final GetStorage _box;
  final String _key = 'local_orders';

  /// broadcast stream so charts / history auto-update
  final _controller = StreamController<List<OrderRecord>>.broadcast();

  /// Watch orders; use in `StreamBuilder` in your chart screen.
  Stream<List<OrderRecord>> watchOrders() async* {
    // emit current snapshot first
    yield listOrders();
    // then emit on each change
    yield* _controller.stream;
  }

  /// Synchronous read of all orders (for one-off usages).
  List<OrderRecord> listOrders() {
    final raw = _box.read(_key);
    if (raw == null) return [];

    try {
      final dynamic decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! List) return [];

      final list = decoded
          .whereType<Map>()
          .map((e) => OrderRecord.fromJson(e.cast<String, dynamic>()))
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  void _saveAll(List<OrderRecord> list) {
    final jsonList = list.map((e) => e.toJson()).toList();
    _box.write(_key, jsonEncode(jsonList));
    _controller.add(List.unmodifiable(list));
  }

  /// Call this when an order is completed.
  Future<void> addOrder(OrderRecord r) async {
    final list = listOrders();
    list.insert(0, r);
    _saveAll(list);
  }

  Future<void> clear() async {
    await _box.remove(_key);
    _controller.add(const <OrderRecord>[]);
  }

  Future<void> setDownloaded(String id, bool downloaded) async {
    final list = listOrders();
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    list[i] = list[i].copyWith(downloaded: downloaded);
    _saveAll(list);
  }
}

/// --------------------------- Cart Storage (SKU only) ---------------------------

class CartStorage {
  final _box = GetStorage();
  final String _keySku = 'sku_cart_default';

  Map<String, int> loadSku() {
    final raw = _box.read(_keySku);
    if (raw == null) return {};
    try {
      final dynamic decoded = raw is String ? jsonDecode(raw) : raw;
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


/// --------------------------- Helpers ---------------------------

/// Coerces any dynamic value to a best-effort int.
// int _toInt(dynamic v) {
//   if (v is int) return v;
//   if (v is double) return v.toInt();
//   if (v is num) return v.toInt();
//   if (v is String) {
//     final s = v.trim();
//     final asInt = int.tryParse(s);
//     if (asInt != null) return asInt;
//     final dot = s.indexOf('.');
//     if (dot > 0) return int.tryParse(s.substring(0, dot)) ?? 0; // e.g. "12.0"
//   }
//   return 0;
// }

// /// --------------------------- Order Storage Model ---------------------------

// class OrderRecord {
//   final String id;
//   final DateTime createdAt;
//   final List<Map<String, dynamic>> lines;

//   // summary for ReportHistory / headers
//   final String? title;      // e.g. "UR TEA BAG BLACK … +2 more"
//   final String? shopName;   // optional if you add shop context later
//   final int itemCount;      // distinct items in the order
//   final int totalQty;       // sum of qty
//   final bool downloaded;    // if user tapped Download in history

//   OrderRecord({
//     required this.id,
//     required this.createdAt,
//     required this.lines,
//     this.title,
//     this.shopName,
//     this.itemCount = 0,
//     this.totalQty = 0,
//     this.downloaded = false,
//   });

//   OrderRecord copyWith({
//     String? id,
//     DateTime? createdAt,
//     List<Map<String, dynamic>>? lines,
//     String? title,
//     String? shopName,
//     int? itemCount,
//     int? totalQty,
//     bool? downloaded,
//   }) {
//     return OrderRecord(
//       id: id ?? this.id,
//       createdAt: createdAt ?? this.createdAt,
//       lines: lines ?? this.lines,
//       title: title ?? this.title,
//       shopName: shopName ?? this.shopName,
//       itemCount: itemCount ?? this.itemCount,
//       totalQty: totalQty ?? this.totalQty,
//       downloaded: downloaded ?? this.downloaded,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "createdAt": createdAt.toIso8601String(),
//         "lines": lines,
//         "title": title,
//         "shopName": shopName,
//         "itemCount": itemCount,
//         "totalQty": totalQty,
//         "downloaded": downloaded,
//       };

//   static OrderRecord fromJson(Map<String, dynamic> j) {
//     final List<Map<String, dynamic>> ls = (j["lines"] is List)
//         ? (j["lines"] as List)
//             .whereType<Map>()
//             .map((e) => e.cast<String, dynamic>())
//             .toList()
//         : const <Map<String, dynamic>>[];

//     // tolerant defaults for older saved shape — now safely coerce num → int
//     final int totalQty = (j["totalQty"] is num)
//         ? (j["totalQty"] as num).toInt()
//         : ls.fold<int>(0, (a, e) => a + _toInt(e["qty"]));

//     final int itemCount = (j["itemCount"] is num)
//         ? (j["itemCount"] as num).toInt()
//         : ls.length;

//     return OrderRecord(
//       id: "${j["id"] ?? ""}",
//       createdAt:
//           DateTime.tryParse("${j["createdAt"] ?? ""}") ?? DateTime.now(),
//       lines: ls,
//       title: j["title"] as String?,
//       shopName: j["shopName"] as String?,
//       itemCount: itemCount,
//       totalQty: totalQty,
//       downloaded: j["downloaded"] == true,
//     );
//   }
// }

// /// --------------------------- OrdersStorage ---------------------------

// class OrdersStorage {
//   final _box = GetStorage();
//   final String _key = 'local_orders';

//   Future<void> addOrder(OrderRecord r) async {
//     final list = await listOrders();
//     list.insert(0, r);
//     await _box.write(
//       _key,
//       jsonEncode(list.map((e) => e.toJson()).toList()),
//     );
//   }

//   Future<List<OrderRecord>> listOrders() async {
//     final raw = _box.read(_key);
//     if (raw == null) return [];
//     try {
//       final d = jsonDecode(raw);
//       if (d is! List) return [];
//       final list = d
//           .whereType<Map>()
//           .map((e) => OrderRecord.fromJson(e.cast<String, dynamic>()))
//           .toList();
//       list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//       return list;
//     } catch (_) {
//       return [];
//     }
//   }

//   Future<void> clear() => _box.remove(_key);

//   Future<void> setDownloaded(String id, bool downloaded) async {
//     final list = await listOrders();
//     final i = list.indexWhere((e) => e.id == id);
//     if (i < 0) return;
//     list[i] = list[i].copyWith(downloaded: downloaded);
//     await _box.write(
//       _key,
//       jsonEncode(list.map((e) => e.toJson()).toList()),
//     );
//   }
// }

// /// --------------------------- Cart Storage (SKU only) ---------------------------

// class CartStorage {
//   final _box = GetStorage();
//   final String _keySku = 'sku_cart_default';

//   Map<String, int> loadSku() {
//     final raw = _box.read(_keySku);
//     if (raw == null) return {};
//     try {
//       final decoded = jsonDecode(raw);
//       if (decoded is! Map) return {};
//       final out = <String, int>{};
//       decoded.forEach((k, v) {
//         if (k is String) out[k] = _toInt(v);
//       });
//       out.removeWhere((_, q) => q <= 0);
//       return out;
//     } catch (_) {
//       return {};
//     }
//   }

//   Future<void> saveSku(Map<String, int> cart) async {
//     final clean = Map.of(cart)..removeWhere((_, q) => q <= 0);
//     await _box.write(_keySku, jsonEncode(clean));
//   }

//   Future<void> clear() async => _box.remove(_keySku);
// }
