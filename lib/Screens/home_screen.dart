import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Screens/app_leave_screen.dart';
import 'package:new_amst_flutter/Screens/mark_attendance.dart'
    show MarkAttendanceView;

const kBg = Color(0xFFF6F7FA);
const kTxtDim = Color(0xFF6A6F7B);
const kTxtDark = Color(0xFF1F2937);
const kSearchBg = Color(0xFFF0F2F5);
const kIconMuted = Color(0xFF9CA3AF);
const kBikeText = Color(0xFF444B59);

const kGradBluePurple = LinearGradient(
  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const kCardCarGrad = LinearGradient(
  colors: [Color(0xFF1CC8FF), Color(0xFF6B63FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _bg = Color(0xFFF6F7FA);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const baseW = 393.0;
    final s = size.width / baseW;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 100 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 6 * s),
                  _Header(s: s),
                  SizedBox(height: 16 * s),
                  _SearchBar(s: s),
                  SizedBox(height: 25 * s),
                  MarkAttendanceWidget(s: s),
                  SizedBox(height: 30 * s),
                  InkWell(
                    onTap: () {},
                    child: SalesWidget(s: s),
                  ),
                       SizedBox(height: 25 * s),
                  InkWell(
                    onTap: () {
                    },
                    child: ApplyLeaveWidget(s: s))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 14 * s,
                color: Color(0xFF6A6F7B),
                height: 1.2,
              ),
              children: [
                TextSpan(
                  text: 'Good morning,\n',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontSize: 18 * s,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: 0.1 * s,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: _GradientText(
                    "Test User",
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontSize: 25 * s,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: 0.1 * s,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10 * s),
        Container(
          padding: EdgeInsets.all(2 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [ 
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8 * s,
                offset: Offset(0, 4 * s),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 30 * s,
            backgroundImage: const AssetImage('assets/avatar.png'),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44 * s,
      decoration: BoxDecoration(
        color: Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(14 * s),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 22 * s, color: Color(0xFF9CA3AF)),
          SizedBox(width: 8 * s),
          Expanded(
            child: Text(
              'Search',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 14 * s,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarkAttendanceWidget extends StatelessWidget {
  const MarkAttendanceWidget({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 219 * s,
      width: MediaQuery.of(context).size.width * 0.90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1CC8FF), Color(0xFF6B63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9 * s),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B63FF).withOpacity(0.25),
            blurRadius: 20 * s,
            offset: Offset(0, 10 * s),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -29 * s,
            top: 18 * s,
            child: SizedBox(
              width: 205 * s,
              height: 210 * s,
              child: Image.asset(
                'assets/new_attendance_icon-removebg-preview.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark\nAttendance',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    color: Colors.white,
                    fontSize: 29 * s,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 6 * s),
                Text(
                  'Make sure GPS is on and\nyou’re at the job site.',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 16.5 * s,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 34),
                InkWell(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const MarkAttendanceView(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: _ChipButtonWhite(
                    s: s,
                    icon: 'assets/attendance_icons.png',
                    label: 'Mark Attendance',
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



class ApplyLeaveWidget extends StatelessWidget {
  const ApplyLeaveWidget({required this.s, super.key});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 219 * s,
      width: MediaQuery.of(context).size.width * 0.90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0ED2F7), Color(0xFF7F53FD)], // same vibe
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9 * s),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F53FD).withOpacity(0.25),
            blurRadius: 20 * s,
            offset: Offset(0, 10 * s),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // right illustration
          Positioned(
            right: -29 * s,
            top: 18 * s,
            child: SizedBox(
              width: 205 * s,
              height: 210 * s,
              child: Image.asset(
                 'assets/new_attendance_icon-removebg-preview.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          // text + button
          Padding(
            padding: EdgeInsets.all(16 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply\nLeave',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    color: Colors.white,
                    fontSize: 29 * s,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 6 * s),
                Text(
                  'Choose type, dates and\nadd a short reason.',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 16.5 * s,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 34 * s),
                InkWell(
                  onTap: () {
                                     Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const ApplyLeaveScreen(),
                        fullscreenDialog: true,
                      ),
                    );//   Navigator.push(context, MaterialPageRoute(builder: (context)=> ApplyLeaveScreen()));

                  },
                  child: _ChipButtonWhite(
                    s: s,
                    icon: 'assets/attendance_icons.png',
                    label: 'Apply Leave',
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


class SalesWidget extends StatelessWidget {
  const SalesWidget({required this.s});
  final double s;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 219 * s,
      width: MediaQuery.of(context).size.width * 0.90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18 * s,
            offset: Offset(0, 10 * s),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -29 * s,
            top: 18 * s,
            child: SizedBox(
              width: 205 * s,
              height: 210 * s,
              child: Image.asset(
                'assets/new_sales-removebg-preview.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GradientText(
                  'Daily\nSales',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontSize: 29 * s,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 6 * s),
                Text(
                  'Enter daily sales\n& track your sales.',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    color: Color(0xFF444B59),
                    fontSize: 16.5 * s,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                _ChipButtonGradient(s: s, label: 'Enter your Sales'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipButtonWhite extends StatelessWidget {
  const _ChipButtonWhite({
    required this.s,
    required this.icon,
    required this.label,
  });
  final double s;
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40 * s,
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12 * s,
            offset: Offset(0, 6 * s),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(icon, height: 22 * s, width: 22 * s),
          SizedBox(width: 8 * s),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              color: Color(0xFF1F2937),
              fontSize: 16 * s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipButtonGradient extends StatelessWidget {
  const _ChipButtonGradient({required this.s, required this.label});
  final double s;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40 * s,
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
        ),
        borderRadius: BorderRadius.circular(5 * s),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F53FD).withOpacity(0.25),
            blurRadius: 12 * s,
            offset: Offset(0, 6 * s),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/sales_button_icon.png',
            height: 22 * s,
            width: 22 * s,
          ),

          SizedBox(width: 8 * s),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              color: Colors.white,
              fontSize: 16 * s,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.gradient, required this.style});
  final String text;
  final Gradient gradient;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => gradient.createShader(rect),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style.copyWith(fontFamily: 'ClashGrotesk')),
    );
  }
}
