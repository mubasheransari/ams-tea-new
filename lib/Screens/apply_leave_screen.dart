import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:new_amst_flutter/Screens/app_shell.dart';
import 'package:new_amst_flutter/Widgets/gradient_text.dart';
import 'package:new_amst_flutter/Widgets/watermarked_widget.dart';
import 'dart:ui' as ui;

class ApplyLeaveScreenNew extends StatefulWidget {
  const ApplyLeaveScreenNew({super.key});
  @override
  State<ApplyLeaveScreenNew> createState() => _ApplyLeaveScreenNewState();
}

class _ApplyLeaveScreenNewState extends State<ApplyLeaveScreenNew> {
  String? _req(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;
    String? _channelType;


    final _fromCtrl     = TextEditingController();
  final _toCtrl       = TextEditingController();
    DateTime? _fromDate;
  DateTime? _toDate;
   static final _fmt = DateFormat('dd-MMM-yyyy');


    Future<void> _pickDate(TextEditingController target, bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom ? (_fromDate ?? now) : (_toDate ?? _fromDate ?? now);
    final first = DateTime(now.year - 1);
    final last  = DateTime(now.year + 2);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: isFrom ? 'Select From Date' : 'Select To Date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7F53FD)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final s = _fmt.format(picked);
      setState(() {
        target.text = s;
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = picked;
            _toCtrl.text = s;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }
  int tab = 0;
  bool remember = true;

  final ScrollController _scrollCtrl = ScrollController();
  double _scrollY = 0.0;

  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();



  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      if (!_scrollCtrl.hasClients) return;
      if (tab != 1) return; // only track offset on SignUp
      final off = _scrollCtrl.offset;
      if (off != _scrollY) {
        setState(() => _scrollY = off);
      }
    });
  }

  @override
  void dispose() {

    _scrollCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: Stack(
        children: [
          const WatermarkTiledSmall(tileScale: 25.0),

          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width < 380 ? 16 : 22,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: _scrollCtrl,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Form(
                              key: _signupFormKey,
                              autovalidateMode: AutovalidateMode.disabled,
                              child: Column(
                                children: [
                                    _DateCard(
                                label: 'From Date',
                                controller: _fromCtrl,
                                onTap: () => _pickDate(_fromCtrl, true),
                                validator: _req,
                              ),
                              const SizedBox(height: 12),

                              _DateCard(
                                label: 'To Date',
                                controller: _toCtrl,
                                onTap: () => _pickDate(_toCtrl, false),
                                validator: _req,
                              ),
                                  const SizedBox(height: 12),

                       
                                  Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 32,
                                          width: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF2F3F5),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.store_mall_directory_rounded,
                                            size: 18,
                                            color: Color(0xFF1B1B1B),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // The dropdown
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _channelType,
                                            isExpanded: true,
                                            alignment: Alignment
                                                .centerLeft, // ← perfect left align
                                            style: const TextStyle(
                                              fontFamily: 'ClashGrotesk',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                              letterSpacing: 0.3,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isCollapsed:
                                                  true, // ← centers text vertically in 56h
                                              contentPadding: EdgeInsets
                                                  .zero, // ← no extra inset
                                              hintText: 'Select Channel Type',
                                              hintStyle: TextStyle(
                                                fontFamily: 'ClashGrotesk',
                                                color: Colors.black54,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            icon: Container(
                                              // ← modern chevron pill
                                              height: 87,
                                              width: 34,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEDE7FF),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.expand_more_rounded,
                                                size: 20,
                                                color: Color(0xFF7F53FD),
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ), 
                                            dropdownColor: Colors.white,
                                            menuMaxHeight: 320,
                                            items:
                                                const [
                                                      'Full Day',
                                                      'Half Day'
                                                    ]
                                                    .map(
                                                      (
                                                        e,
                                                      ) => DropdownMenuItem<String>(
                                                        value: e,
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 3,
                                                              ),
                                                          child: Text(
                                                            e,
                                                            style: const TextStyle(
                                                              fontFamily:
                                                                  'ClashGrotesk',
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing:
                                                                  0.3,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged: (v) => setState(
                                              () => _channelType = v,
                                            ),
                                            validator: (v) => v == null
                                                ? 'Please select'
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  SizedBox(
                                    width: 160,
                                    height: 40,
                                    child: _PrimaryGradientButton(
                                      text: 'SUMBIT',
                                      onPressed: _submit,
                                      //  loading: signupLoading,
                                    ),
                                  ),
                           
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 70,
            left: 57,
            right: 0,
            child: IgnorePointer(
              child: GradientText(
                'LEAVE APPLICATION FORM',
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                style: TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),

              // Center(
              //   child: Image.asset(
              //     "assets/logo_ams.png",
              //     height: 270,
              //     width: 270,
              //   ),
              // ),
            ),
          ),
        ],
      ),
    );
  }
}



class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  static const _grad = LinearGradient(
    colors: [Color(0xFF0ED2F7), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;

    return Opacity(
      opacity: disabled ? 0.8 : 1,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: _grad,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7F53FD).withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      text,
                      style: const TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

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

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.controller,
    required this.onTap,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: _kCardDeco,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF1B1B1B)),
            const SizedBox(width: 10),
            Expanded(
              child: AbsorbPointer(
                child: TextFormField(
                  controller: controller,
                  validator: validator,
                  decoration: InputDecoration(
                    hintText: label,
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintStyle: const TextStyle(
                      fontFamily: 'ClashGrotesk',
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'ClashGrotesk',
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF7F53FD)),
          ],
        ),
      ),
    );
  }
}

class _CnicField extends StatelessWidget {
  const _CnicField({required this.controller, required this.validator});
  final TextEditingController controller;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Image.asset(
            'assets/name_icon.png',
            height: 17,
            width: 17,
            color: const Color(0xFF1B1B1B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              key: const ValueKey('signup_cnic'),
              controller: controller,
              textAlign: TextAlign.start,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
                _CnicInputFormatter(),
              ],
              validator: validator,
              decoration: const InputDecoration(
                hintText: 'Employee CNIC',
                border: InputBorder.none,
                isCollapsed: true,
                hintStyle: TextStyle(
                  fontFamily: 'ClashGrotesk',
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Text(
              '4xxxx-xxxxxxx-x',
              style: TextStyle(
                color: Color(0xFF3B97A6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PkMobileField extends StatelessWidget {
  const _PkMobileField({
    required this.hint,
    required this.controller,
    required this.validator,
  });
  final String hint;
  final TextEditingController controller;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Image.asset(
            'assets/name_icon.png',
            height: 17,
            width: 17,
            color: const Color(0xFF1B1B1B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontFamily: 'ClashGrotesk',
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
              controller: controller,
              validator: validator,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isCollapsed: true,
                hintStyle: const TextStyle(
                  fontFamily: 'ClashGrotesk',
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: Text(
              '92XXXXXXXXXX',
              style: TextStyle(
                color: Color(0xFF3B97A6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------- Formatters ----------------- */

class _CnicInputFormatter extends TextInputFormatter {
  // Formats 13 digits → XXXXX-XXXXXXX-X (inserts dashes visually)
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 13; i++) {
      buf.write(digits[i]);
      if (i == 4 || i == 11) buf.write('-');
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
