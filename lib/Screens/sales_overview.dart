import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:new_amst_flutter/Data/order_storage.dart';

class SalesChartScreen extends StatelessWidget {
  const SalesChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales Overview',
          style: TextStyle(fontFamily: 'ClashGrotesk'),
        ),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SalesChartSection(),
        ),
      ),
    );
  }
}

/// This is the widget you should embed inside HomeScreen.
/// In HomeScreen: use `const SalesChartSection()` instead of `SalesChartScreen()`.
class SalesChartSection extends StatelessWidget {
  const SalesChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderRecord>>(
      stream: OrdersStorage().watchOrders(), // 🔥 auto-updates when addOrder is called
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data ?? const <OrderRecord>[];
        if (data.isEmpty) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 3,
            child: const SizedBox(
              height: 240,
              child: Center(
                child: Text(
                  'No sales yet.\nAdd some orders to see the chart.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }

        // ---------- Group orders by day ----------
        final Map<DateTime, int> qtyByDay = {};
        for (final o in data) {
          final d = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
          qtyByDay[d] = (qtyByDay[d] ?? 0) + o.totalQty;
        }

        final sortedDays = qtyByDay.keys.toList()..sort();
        final points = <FlSpot>[];

        for (var i = 0; i < sortedDays.length; i++) {
          final day = sortedDays[i];
          final qty = qtyByDay[day] ?? 0;
          points.add(FlSpot(i.toDouble(), qty.toDouble()));
        }

        // ---------- Stats for header chips ----------
        final today = DateTime.now();
        final todayKey = DateTime(today.year, today.month, today.day);
        final int todayQty = qtyByDay[todayKey] ?? 0;

        final last7Start = todayKey.subtract(const Duration(days: 6));
        int last7Total = 0;
        qtyByDay.forEach((day, qty) {
          if (!day.isBefore(last7Start) && !day.isAfter(todayKey)) {
            last7Total += qty;
          }
        });

        // ---------- Y axis interval ----------
        final maxY = points.map((e) => e.y).fold<double>(0, (a, b) => b > a ? b : a);
        final double yInterval =
            maxY <= 5 ? 1 : (maxY <= 10 ? 2 : (maxY <= 20 ? 5 : (maxY / 4).ceilToDouble()));

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            // fixed height so it behaves inside scroll / column
            child: SizedBox(
              height: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Title row ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily Sales',
                        style: TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFFF3F4FF),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF6366F1), // Indigo accent
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${sortedDays.length} days',
                              style: const TextStyle(
                                fontFamily: 'ClashGrotesk',
                                fontSize: 11,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ---- Summary chips ----
                  Row(
                    children: [
                      _StatChip(
                        label: 'Today',
                        value: '$todayQty',
                        color: const Color(0xFF22C55E), // green
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Last 7 days',
                        value: '$last7Total',
                        color: const Color(0xFF6366F1), // indigo
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ---- Chart ----
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (points.length - 1).toDouble(),
                        minY: 0,
                        maxY: maxY == 0 ? 5 : maxY * 1.3,
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: false,
                          horizontalInterval: yInterval,
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: yInterval,
                              getTitlesWidget: (value, meta) {
                                if (value < 0) return const SizedBox.shrink();
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'ClashGrotesk',
                                    color: Colors.black54,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= sortedDays.length) {
                                  return const SizedBox.shrink();
                                }
                                final d = sortedDays[i];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${d.day}/${d.month}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'ClashGrotesk',
                                      color: Colors.black54,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            spots: points,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                            color: const Color(0xFF6366F1),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF6366F1).withOpacity(0.35),
                                  const Color(0xFF6366F1).withOpacity(0.05),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small pill chip used for "Today" / "Last 7 days"
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 11,
              color: color.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
