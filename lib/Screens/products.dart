import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_amst_flutter/Model/products_data.dart';

class TeaCatalogScreen extends StatefulWidget {
  const TeaCatalogScreen({super.key});

  @override
  State<TeaCatalogScreen> createState() => _TeaCatalogScreenState();
}

class _TeaCatalogScreenState extends State<TeaCatalogScreen> {
  final _search = TextEditingController();

  String _brandFilter = 'All';
  late final List<Product> _all;
  late final List<String> _brands;

  @override
  void initState() {
    super.initState();
    _all = kTeaProducts.map(Product.fromMap).toList()
      ..sort((a, b) {
        final byBrand = a.brand.compareTo(b.brand);
        return byBrand != 0 ? byBrand : a.name.compareTo(b.name);
      });

    _brands = [
      'All',
...({for (final p in _all) p.brand}.toList()
  ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()))),

    ];
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _search.text.trim().toLowerCase();
    final byBrand = _brandFilter == 'All'
        ? _all
        : _all.where((p) => p.brand == _brandFilter).toList();

    if (q.isEmpty) return byBrand;

    return byBrand.where((p) {
      // Match on name, id, brand, segment, item_name, item_desc
      return p.nameL.contains(q) ||
          p.id.contains(q) ||
          p.brandL.contains(q) ||
          p.segmentL.contains(q) ||
          p.itemNameL.contains(q) ||
          p.itemDescL.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tea Products'),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Column(
        children: [
          _Filters(
            controller: _search,
            brands: _brands,
            selectedBrand: _brandFilter,
            onBrandChanged: (v) => setState(() => _brandFilter = v),
            onChanged: (_) => setState(() {}),
            onClear: () {
              _search.clear();
              setState(() {});
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text(
                  'Showing ${items.length} item${items.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _ProductCard(product: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- Widgets --------------------------- */

class _Filters extends StatelessWidget {
  const _Filters({
    required this.controller,
    required this.brands,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final List<String> brands;
  final String selectedBrand;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7FB),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, ID, brand, segment…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear',
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE4E6EB)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Brand:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE4E6EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedBrand,
                        items: brands
                            .map((b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(b, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) onBrandChanged(v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final badgeColor = product.ctnStatus ? const Color(0xFF2F7D32) : const Color(0xFF9E9E9E);
    final badgeText = product.ctnStatus ? 'Active' : 'Inactive';

    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingIcon(brand: product.brand),
              const SizedBox(width: 12),
              Expanded(
                child: _MainInfo(product: product),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: badgeColor.withOpacity(.25)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.unitFlagQtyLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF616770),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.brand});
  final String brand;

  @override
  Widget build(BuildContext context) {
    // Simple brand-based icon; swap to your assets if you have logos.
    final icon = switch (brand.toLowerCase()) {
      _ when brand.contains('ULTRA') => Icons.local_cafe_rounded,
      _ when brand.contains('HARDUM') || brand.contains('HARDAM') => Icons.emoji_food_beverage_rounded,
      _ when brand.contains('BAITHAK') => Icons.coffee_rounded,
      _ => Icons.inventory_2_rounded,
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon),
    );
  }
}

class _MainInfo extends StatelessWidget {
  const _MainInfo({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final styleMuted = const TextStyle(fontSize: 12, color: Color(0xFF616770));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: -6,
          children: [
            _Chip(text: product.brand),
            _Chip(text: 'ID: ${product.id}'),
            if (product.ctnQty != null) _Chip(text: 'CTN: ${product.ctnQty}'),
            if (product.packQty != null) _Chip(text: 'Pack: ${product.packQty}'),
          ],
        ),
        const SizedBox(height: 8),
        Text(product.itemDesc, maxLines: 2, overflow: TextOverflow.ellipsis, style: styleMuted),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F5),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF363B40), fontWeight: FontWeight.w600),
      ),
    );
  }
}

/* --------------------------- Model --------------------------- */

class Product {
  final String id;
  final String name;
  final String brand;
  final String segment;
  final String itemName;
  final String itemDesc;
  final int? ctnQty;
  final int? packQty;
  final bool ctnStatus;
  final double? unitFlagQty;
  final double? perKgLtr;
  final double? perCtnNkg;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.segment,
    required this.itemName,
    required this.itemDesc,
    required this.ctnQty,
    required this.packQty,
    required this.ctnStatus,
    required this.unitFlagQty,
    required this.perKgLtr,
    required this.perCtnNkg,
  });

  String get nameL => name.toLowerCase();
  String get brandL => brand.toLowerCase();
  String get segmentL => segment.toLowerCase();
  String get itemNameL => itemName.toLowerCase();
  String get itemDescL => itemDesc.toLowerCase();

  String get unitFlagQtyLabel {
    if (unitFlagQty == null) return '';
    // Keep as integer when it is whole number; otherwise show decimals.
    final v = unitFlagQty!;
    return v == v.roundToDouble() ? '${v.toInt()} g' : '${v} kg/g';
  }

  factory Product.fromMap(Map<String, dynamic> m) {
    double? _d(String? s) {
      if (s == null || s.isEmpty) return null;
      return double.tryParse(s);
    }

    int? _i(String? s) {
      if (s == null || s.isEmpty) return null;
      return int.tryParse(s);
    }

    return Product(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? m['item_name'] ?? '').toString(),
      brand: (m['brand'] ?? '').toString(),
      segment: (m['segment'] ?? '').toString(),
      itemName: (m['item_name'] ?? '').toString(),
      itemDesc: (m['item_desc'] ?? '').toString(),
      ctnQty: _i((m['ctn_qty'] ?? '').toString()),
      packQty: _i((m['pack_qty'] ?? '').toString()),
      ctnStatus: ((m['ctn_status'] ?? '0').toString() == '1'),
      unitFlagQty: _d((m['unit_flag_qty'] ?? '').toString()),
      perKgLtr: _d((m['per_kg_ltr'] ?? '').toString()),
      perCtnNkg: _d((m['per_ctn_nkg'] ?? '').toString()),
    );
  }
}
