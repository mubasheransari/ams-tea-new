import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Model/super_journeyplan_model.dart';

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
  boxShadow: [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ],
);


class JourneyPlanSupervisorScreen extends StatefulWidget {
  const JourneyPlanSupervisorScreen({super.key});

  @override
  State<JourneyPlanSupervisorScreen> createState() =>
      _JourneyPlanSupervisorScreenState();
}

class _JourneyPlanSupervisorScreenState
    extends State<JourneyPlanSupervisorScreen> {
  final _search = TextEditingController();
  late List<JourneyPlanSupervisor> _all;

  @override
  void initState() {
    super.initState();
    _all = List<JourneyPlanSupervisor>.from(kJourneyPlan);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();

    final filtered = _all.where((e) {
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q);
    }).toList();

    final visitedCount = _all.where((e) => e.isVisited).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kText),
        title: const Text(
          'Journey Plan',
          style: TextStyle(
            color: kText,
            fontWeight: FontWeight.w700,
            fontFamily: 'ClashGrotesk',
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
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
                          hintText: 'Search outlet (e.g. Imtiaz, Naheed)',
                          hintStyle: TextStyle(
                            color: Colors.black54,
                            fontFamily: 'ClashGrotesk',
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.only(top: 2),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          fontFamily: 'ClashGrotesk',
                        ),
                      ),
                    ),
                    if (_search.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.black45,
                        ),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Counts row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} outlets',
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'ClashGrotesk',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Visited: $visitedCount / ${_all.length}',
                    style: const TextStyle(
                      color: Color(0xFF7F53FD),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      fontFamily: 'ClashGrotesk',
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final jp = filtered[i];
                  return Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.95,
                      child: _JourneyPlanCard(
                        supervisor: jp,
                        onToggleVisited: () {
                          setState(() {
                            jp.isVisited = !jp.isVisited;
                          });
                        },
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


class _JourneyPlanCard extends StatelessWidget {
  const _JourneyPlanCard({
    required this.supervisor,
    required this.onToggleVisited,
  });

  final JourneyPlanSupervisor supervisor;
  final VoidCallback onToggleVisited;

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
          boxShadow: const [
            BoxShadow(
              color: kShadow,
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Left icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF7F53FD).withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.store_mall_directory_rounded,
                color: Color(0xFF7F53FD),
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supervisor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(
                      color: kText,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ClashGrotesk',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: kMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${supervisor.lat}, ${supervisor.lng}',
                          style: t.bodySmall?.copyWith(
                            color: kMuted,
                            fontFamily: 'ClashGrotesk',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Visited / Pending pill
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onToggleVisited,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: supervisor.isVisited
                      ? const Color(0xFF22C55E).withOpacity(0.12)
                      : const Color(0xFFF97316).withOpacity(0.12),
                  border: Border.all(
                    color: supervisor.isVisited
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF97316),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      supervisor.isVisited
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: supervisor.isVisited
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF97316),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      supervisor.isVisited ? 'Visited' : 'Pending',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'ClashGrotesk',
                        color: kText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
