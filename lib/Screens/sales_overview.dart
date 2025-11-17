import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Data/order_storage.dart';
import 'package:fl_chart/fl_chart.dart';

const kText = Color(0xFF1E1E1E);



class SalesChartScreen extends StatelessWidget {
  const SalesChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F7FA),
        title: const Text(
          'Sales Overview',
          style: TextStyle(
            fontFamily: 'ClashGrotesk',
            fontWeight: FontWeight.w700,
          ),
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
class SalesChartSection extends StatelessWidget {
  const SalesChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderRecord>>(
      future: OrdersStorage().listOrders(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data ?? const <OrderRecord>[];
        if (data.isEmpty) {
          return _EmptySalesCard();
        }

        // ---------- Group by day & compute quantities ----------
        final Map<DateTime, int> qtyByDay = {};
        for (final o in data) {
          final d = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
          qtyByDay[d] = (qtyByDay[d] ?? 0) + o.totalQty;
        }

        final sortedKeys = qtyByDay.keys.toList()..sort();
        final points = <FlSpot>[];

        for (var i = 0; i < sortedKeys.length; i++) {
          final day = sortedKeys[i];
          final qty = qtyByDay[day] ?? 0;
          points.add(FlSpot(i.toDouble(), qty.toDouble()));
        }

        final totalQty =
            data.fold<int>(0, (sum, o) => sum + o.totalQty);
        final avgQty =
            qtyByDay.isEmpty ? 0 : (totalQty / qtyByDay.length).round();

        final maxY = points.map((e) => e.y).fold<double>(0, (a, b) => b > a ? b : a);
        final double yInterval =
            maxY <= 5 ? 1 : (maxY <= 10 ? 2 : (maxY <= 20 ? 5 : (maxY / 4).ceilToDouble()));

        return _SalesChartCard(
          points: points,
          dates: sortedKeys,
          totalQty: totalQty,
          avgQty: avgQty,
          maxY: maxY,
          yInterval: yInterval,
        );
      },
    );
  }
}

/// ---------- Empty State Card ----------
class _EmptySalesCard extends StatelessWidget {
  const _EmptySalesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFE0EAFF), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No sales yet.\nAdd some orders to see your beautiful chart here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- Fancy Card with Modern Chart ----------
class _SalesChartCard extends StatelessWidget {
  const _SalesChartCard({
    required this.points,
    required this.dates,
    required this.totalQty,
    required this.avgQty,
    required this.maxY,
    required this.yInterval,
  });

  final List<FlSpot> points;
  final List<DateTime> dates;
  final int totalQty;
  final int avgQty;
  final double maxY;
  final double yInterval;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0ED2F7), Color(0xFF7F53FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F53FD).withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Header & KPIs ----------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Sales',
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.show_chart_rounded,
                            size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Last period',
                          style: TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _KpiChip(
                    label: 'Total Qty',
                    value: '$totalQty',
                  ),
                  const SizedBox(width: 8),
                  _KpiChip(
                    label: 'Avg / Day',
                    value: '$avgQty',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ---------- Chart ----------
              Expanded(
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (points.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY == 0 ? 5 : maxY * 1.3,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withOpacity(0.12),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 10,
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.x.toInt();
                            final d = dates[idx];
                            return LineTooltipItem(
                              '${d.day}/${d.month}\nQty: ${spot.y.toInt()}',
                              const TextStyle(
                                fontFamily: 'ClashGrotesk',
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value < 0) return const SizedBox.shrink();
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'ClashGrotesk',
                                color: Colors.white.withOpacity(0.8),
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
                            if (i < 0 || i >= dates.length) {
                              return const SizedBox.shrink();
                            }
                            final d = dates[i];
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${d.day}/${d.month}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'ClashGrotesk',
                                  color: Colors.white.withOpacity(0.85),
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
                        barWidth: 3.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: Colors.white.withOpacity(0.3),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.33),
                              Colors.white.withOpacity(0.02),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFEF9C3),
                            Color(0xFFFFFFFF),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),
              // ---------- Legend ----------
              Row(
                children: [
                  Container(
                    height: 10,
                    width: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Qty sold',
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill KPIs
class _KpiChip extends StatelessWidget {
  const _KpiChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}





// class SalesChartScreen extends StatelessWidget {
//   const SalesChartScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Sales Overview',
//           style: TextStyle(fontFamily: 'ClashGrotesk'),
//         ),
//       ),
//       body: const SafeArea(
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: SalesChartSection(),
//         ),
//       ),
//     );
//   }
// }

// /// This is the widget you should embed inside HomeScreen.
// class SalesChartSection extends StatelessWidget {
//   const SalesChartSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<OrderRecord>>(
//       future: OrdersStorage().listOrders(),
//       builder: (context, snap) {
//         if (snap.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final data = snap.data ?? const <OrderRecord>[];
//         if (data.isEmpty) {
//           return Card(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             elevation: 3,
//             child: const SizedBox(
//               height: 220,
//               child: Center(
//                 child: Text(
//                   'No sales yet.\nAdd some orders to see the chart.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontFamily: 'ClashGrotesk',
//                     color: Colors.black54,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }

//         // --- Group orders by date & compute total qty per day ---
//         final Map<DateTime, int> qtyByDay = {};
//         for (final o in data) {
//           final d = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
//           qtyByDay[d] = (qtyByDay[d] ?? 0) + o.totalQty;
//         }

//         final sortedKeys = qtyByDay.keys.toList()..sort();
//         final points = <FlSpot>[];

//         for (var i = 0; i < sortedKeys.length; i++) {
//           final day = sortedKeys[i];
//           final qty = qtyByDay[day] ?? 0;
//           points.add(FlSpot(i.toDouble(), qty.toDouble()));
//         }

//         final maxY = points.map((e) => e.y).fold<double>(0, (a, b) => b > a ? b : a);
//         final double yInterval =
//             maxY <= 5 ? 1 : (maxY <= 10 ? 2 : (maxY <= 20 ? 5 : (maxY / 4).ceilToDouble()));

//         return Card(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           elevation: 4,
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             // Constrain height so it works inside Columns / ScrollViews
//             child: SizedBox(
//               height: 220,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Daily Sales (Qty)',
//                     style: TextStyle(
//                       fontFamily: 'ClashGrotesk',
//                       fontWeight: FontWeight.w700,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Expanded(
//                     child: LineChart(
//                       LineChartData(
//                         minX: 0,
//                         maxX: (points.length - 1).toDouble(),
//                         minY: 0,
//                         maxY: maxY == 0 ? 5 : maxY * 1.2,
//                         gridData: FlGridData(
//                           show: true,
//                           drawHorizontalLine: true,
//                           drawVerticalLine: false,
//                         ),
//                         borderData: FlBorderData(show: false),
//                         titlesData: FlTitlesData(
//                           leftTitles: AxisTitles(
//                             sideTitles: SideTitles(
//                               showTitles: true,
//                               reservedSize: 32,
//                               interval: yInterval,
//                               getTitlesWidget: (value, meta) {
//                                 if (value < 0) return const SizedBox.shrink();
//                                 return Text(
//                                   value.toInt().toString(),
//                                   style: const TextStyle(
//                                     fontSize: 10,
//                                     fontFamily: 'ClashGrotesk',
//                                     color: Colors.black54,
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                           rightTitles: const AxisTitles(
//                             sideTitles: SideTitles(showTitles: false),
//                           ),
//                           topTitles: const AxisTitles(
//                             sideTitles: SideTitles(showTitles: false),
//                           ),
//                           bottomTitles: AxisTitles(
//                             sideTitles: SideTitles(
//                               showTitles: true,
//                               interval: 1,
//                               getTitlesWidget: (value, meta) {
//                                 final i = value.toInt();
//                                 if (i < 0 || i >= sortedKeys.length) {
//                                   return const SizedBox.shrink();
//                                 }
//                                 final d = sortedKeys[i];
//                                 return Padding(
//                                   padding: const EdgeInsets.only(top: 4),
//                                   child: Text(
//                                     '${d.day}/${d.month}',
//                                     style: const TextStyle(
//                                       fontSize: 10,
//                                       fontFamily: 'ClashGrotesk',
//                                       color: Colors.black54,
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                         ),
//                         lineBarsData: [
//                           LineChartBarData(
//                             isCurved: true,
//                             spots: points,
//                             barWidth: 3,
//                             isStrokeCapRound: true,
//                             dotData: FlDotData(show: true),
//                             belowBarData: BarAreaData(
//                               show: true,
//                               // default gradient / color from fl_chart; no explicit colors to keep it simple
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

