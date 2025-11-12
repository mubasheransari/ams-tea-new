import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:new_amst_flutter/Widgets/gradient_text.dart';
import 'dart:ui' as ui;

import 'package:new_amst_flutter/Widgets/watermarked_widget.dart';




class ApplyLeaveScreenNew extends StatefulWidget {
  const ApplyLeaveScreenNew({super.key});
  @override
  State<ApplyLeaveScreenNew> createState() => _ApplyLeaveScreenNewState();
}

class _ApplyLeaveScreenNewState extends State<ApplyLeaveScreenNew> {
  String? _req(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;

  String _paymentType = 'full'; // 'full' or 'half'
  String? _channelType; // 'Full Day' | 'Half Day'

  // dates
  final _selectHalfDayLeaveDate = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  static final _fmt = DateFormat('dd-MMM-yyyy');

  Future<void> _pickDate(TextEditingController target, bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom ? (_fromDate ?? now) : (_toDate ?? _fromDate ?? now);
    final first = DateTime(now.year - 1);
    final last = DateTime(now.year + 2);

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

  final _signupFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _channelType = 'Full Day'; 
    _scrollCtrl.addListener(() {
      if (!_scrollCtrl.hasClients) return;
      if (tab != 1) return; 
      final off = _scrollCtrl.offset;
      if (off != _scrollY) {
        setState(() => _scrollY = off);
      }
    });
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    //if (!_signupFormKey.currentState!.validate()) return;



    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => const AppShell()),
    // );

    print("SELECTED OPTION $_paymentType");
    print("SELECTED OPTION $_paymentType");
    print("SELECTED OPTION $_paymentType");
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: Stack(
        children: [
           WatermarkTiledSmall(tileScale: 25.0),

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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Selection pills (Full / Half)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: PaymentChoiceTile(
                                          label: 'Full day',
                                          code: 'full',
                                          selected: _paymentType == 'full',
                                          onTap: () => setState(() {
                                            _paymentType = 'full';
                                            _channelType = 'Full Day';
                                          }),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: PaymentChoiceTile(
                                          label: 'Half day',
                                          code: 'half',
                                          selected: _paymentType == 'half',
                                          onTap: () => setState(() {
                                            _paymentType = 'half';
                                            _channelType = 'Half Day';
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                       _paymentType == "full"?           _DateCard(
                                    label: 'From Date',
                                    controller: _fromCtrl,
                                    onTap: () => _pickDate(_fromCtrl, true),
                                    validator: _req,
                                  ):SizedBox(),

                                      _paymentType == "half"?           _DateCard(
                                    label: 'Select Date',
                                    controller: _selectHalfDayLeaveDate,
                                    onTap: () => _pickDate(_selectHalfDayLeaveDate, true),
                                    validator: _req,
                                  ):SizedBox(),
                                  const SizedBox(height: 12),

                                

                            _paymentType == "full"?        _DateCard(
                                    label: 'To Date',
                                    controller: _toCtrl,
                                    onTap: () => _pickDate(_toCtrl, false),
                                    validator: _req,
                                  ):SizedBox(),
                                  const SizedBox(height: 12),


                                  SizedBox(
                                    width: 160,
                                    height: 44,
                                    child: _PrimaryGradientButton(
                                      text: 'SUBMIT',
                                      onPressed: _submit,
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

          // Title overlay
          Positioned(
            top: 100,
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
                style: const TextStyle(
                  fontFamily: 'ClashGrotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.59,
                ),
              ),
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
            child: SizedBox(
              height: 44,
              child: Center(
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        text,
                        style: const TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
    BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
  ],
);

/* ------------------------ Choice Tile ------------------------ */

class PaymentChoiceTile extends StatelessWidget {
  const PaymentChoiceTile({
    super.key,
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  static const _grad = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    if (selected) {
      // Selected: gradient fill
      return InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            gradient: _grad,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7F53FD).withOpacity(.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Not selected: gradient outline + gradient icon/text
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: _grad, // border gradient
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7F53FD).withOpacity(.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(1.6), // outline thickness
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _GradientIcon(
                icon: Icons.radio_button_unchecked,
                size: 18,
                gradient: _grad,
              ),
              const SizedBox(width: 8),
              _GradientText(
                label: label,
                gradient: _grad,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------- Gradient Helpers -------------------- */

class _GradientText extends StatelessWidget {
  const _GradientText({
    required this.label,
    required this.gradient,
    this.style,
  });

  final String label;
  final Gradient gradient;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => gradient.createShader(r),
      blendMode: BlendMode.srcIn,
      child: Text(
        label,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}

class _GradientIcon extends StatelessWidget {
  const _GradientIcon({
    required this.icon,
    required this.size,
    required this.gradient,
  });

  final IconData icon;
  final double size;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => gradient.createShader(r),
      blendMode: BlendMode.srcIn,
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}


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
            const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: Color(0xFF1B1B1B),
            ),
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
            const Icon(
              Icons.edit_calendar_rounded,
              size: 18,
              color: Color(0xFF7F53FD),
            ),
          ],
        ),
      ),
    );
  }
}








// class ApplyLeaveScreenNew extends StatefulWidget {
//   const ApplyLeaveScreenNew({super.key});
//   @override
//   State<ApplyLeaveScreenNew> createState() => _ApplyLeaveScreenNewState();
// }

// class _ApplyLeaveScreenNewState extends State<ApplyLeaveScreenNew> {
//   String? _req(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;
//   String? _channelType;
// String _paymentType = 'full';

//   final _fromCtrl = TextEditingController();
//   final _toCtrl = TextEditingController();
//   DateTime? _fromDate;
//   DateTime? _toDate;
//   static final _fmt = DateFormat('dd-MMM-yyyy');

//   Future<void> _pickDate(TextEditingController target, bool isFrom) async {
//     final now = DateTime.now();
//     final initial = isFrom ? (_fromDate ?? now) : (_toDate ?? _fromDate ?? now);
//     final first = DateTime(now.year - 1);
//     final last = DateTime(now.year + 2);

//     final picked = await showDatePicker(
//       context: context,
//       initialDate: initial,
//       firstDate: first,
//       lastDate: last,
//       helpText: isFrom ? 'Select From Date' : 'Select To Date',
//       builder: (context, child) => Theme(
//         data: Theme.of(context).copyWith(
//           colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7F53FD)),
//         ),
//         child: child!,
//       ),
//     );
//     if (picked != null) {
//       final s = _fmt.format(picked);
//       setState(() {
//         target.text = s;
//         if (isFrom) {
//           _fromDate = picked;
//           if (_toDate != null && _toDate!.isBefore(picked)) {
//             _toDate = picked;
//             _toCtrl.text = s;
//           }
//         } else {
//           _toDate = picked;
//         }
//       });
//     }
//   }

//   int tab = 0;
//   bool remember = true;

//   final ScrollController _scrollCtrl = ScrollController();
//   double _scrollY = 0.0;

//   final _loginFormKey = GlobalKey<FormState>();
//   final _signupFormKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     super.initState();
//     _scrollCtrl.addListener(() {
//       if (!_scrollCtrl.hasClients) return;
//       if (tab != 1) return; // only track offset on SignUp
//       final off = _scrollCtrl.offset;
//       if (off != _scrollY) {
//         setState(() => _scrollY = off);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _scrollCtrl.dispose();
//     super.dispose();
//   }

//   void _submit() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => AppShell()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF2F3F5),
//       body: Stack(
//         children: [
//           const WatermarkTiledSmall(tileScale: 25.0),

//           SafeArea(
//             child: Center(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: size.width < 380 ? 16 : 22,
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(28),
//                   child: BackdropFilter(
//                     filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.10),
//                         borderRadius: BorderRadius.circular(28),
//                         border: Border.all(
//                           color: Colors.white.withOpacity(0.10),
//                           width: 1,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.04),
//                             blurRadius: 18,
//                             offset: const Offset(0, 10),
//                           ),
//                         ],
//                       ),
//                       child: SingleChildScrollView(
//                         controller: _scrollCtrl,
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Form(
//                               key: _signupFormKey,
//                               autovalidateMode: AutovalidateMode.disabled,
//                               child: Column(
//                                 children: [


// // in build():
// Row(
//   children: [
//     Expanded(
//       child: PaymentChoiceTile(
//         label: 'Full day',
//         code:  'full',
//         selected: _paymentType == 'full',
//         onTap: () => setState(() => _paymentType = 'full'),
//       ),
//     ),
//     const SizedBox(width: 12),
//     Expanded(
//       child: PaymentChoiceTile(
//         label: 'Half day',
//         code:  'half',
//         selected: _paymentType == 'half',
//         onTap: () => setState(() => _paymentType = 'half'),
//       ),
//     ),
//   ],
// ),

//                                   const SizedBox(height: 12),
//                                   _DateCard(
//                                     label: 'From Date',
//                                     controller: _fromCtrl,
//                                     onTap: () => _pickDate(_fromCtrl, true),
//                                     validator: _req,
//                                   ),
//                                   const SizedBox(height: 12),

//                                   _DateCard(
//                                     label: 'To Date',
//                                     controller: _toCtrl,
//                                     onTap: () => _pickDate(_toCtrl, false),
//                                     validator: _req,
//                                   ),
//                                   const SizedBox(height: 12),

//                                   Container(
//                                     height: 56,
//                                     decoration: BoxDecoration(
//                                       color: Colors.white,
//                                       borderRadius: BorderRadius.circular(16),
//                                       boxShadow: [
//                                         BoxShadow(
//                                           color: Colors.black.withOpacity(0.06),
//                                           blurRadius: 12,
//                                           offset: const Offset(0, 6),
//                                         ),
//                                       ],
//                                     ),
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 12,
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         Container(
//                                           height: 32,
//                                           width: 32,
//                                           alignment: Alignment.center,
//                                           decoration: BoxDecoration(
//                                             color: const Color(0xFFF2F3F5),
//                                             borderRadius: BorderRadius.circular(
//                                               10,
//                                             ),
//                                           ),
//                                           child: const Icon(
//                                             Icons.store_mall_directory_rounded,
//                                             size: 18,
//                                             color: Color(0xFF1B1B1B),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 10),

//                                         // The dropdown
//                                         Expanded(
//                                           child: DropdownButtonFormField<String>(
//                                             value: _channelType,
//                                             isExpanded: true,
//                                             alignment: Alignment
//                                                 .centerLeft, // ← perfect left align
//                                             style: const TextStyle(
//                                               fontFamily: 'ClashGrotesk',
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.w600,
//                                               color: Colors.black,
//                                               letterSpacing: 0.3,
//                                             ),
//                                             decoration: const InputDecoration(
//                                               border: InputBorder.none,
//                                               isCollapsed:
//                                                   true, // ← centers text vertically in 56h
//                                               contentPadding: EdgeInsets
//                                                   .zero, // ← no extra inset
//                                               hintText: 'Select Channel Type',
//                                               hintStyle: TextStyle(
//                                                 fontFamily: 'ClashGrotesk',
//                                                 color: Colors.black54,
//                                                 fontSize: 16,
//                                                 fontWeight: FontWeight.w600,
//                                                 letterSpacing: 0.3,
//                                               ),
//                                             ),
//                                             icon: Container(
//                                               // ← modern chevron pill
//                                               height: 87,
//                                               width: 34,
//                                               alignment: Alignment.center,
//                                               decoration: BoxDecoration(
//                                                 color: const Color(0xFFEDE7FF),
//                                                 borderRadius:
//                                                     BorderRadius.circular(12),
//                                               ),
//                                               child: const Icon(
//                                                 Icons.expand_more_rounded,
//                                                 size: 20,
//                                                 color: Color(0xFF7F53FD),
//                                               ),
//                                             ),
//                                             borderRadius: BorderRadius.circular(
//                                               14,
//                                             ),
//                                             dropdownColor: Colors.white,
//                                             menuMaxHeight: 320,
//                                             items: const ['Full Day', 'Half Day']
//                                                 .map(
//                                                   (
//                                                     e,
//                                                   ) => DropdownMenuItem<String>(
//                                                     value: e,
//                                                     alignment:
//                                                         Alignment.centerLeft,
//                                                     child: Padding(
//                                                       padding:
//                                                           const EdgeInsets.symmetric(
//                                                             vertical: 3,
//                                                           ),
//                                                       child: Text(
//                                                         e,
//                                                         style: const TextStyle(
//                                                           fontFamily:
//                                                               'ClashGrotesk',
//                                                           fontSize: 14,
//                                                           fontWeight:
//                                                               FontWeight.w600,
//                                                           letterSpacing: 0.3,
//                                                           color: Colors.black,
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 )
//                                                 .toList(),
//                                             onChanged: (v) => setState(
//                                               () => _channelType = v,
//                                             ),
//                                             validator: (v) => v == null
//                                                 ? 'Please select'
//                                                 : null,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),

//                                   const SizedBox(height: 20),

//                                   SizedBox(
//                                     width: 160,
//                                     height: 40,
//                                     child: _PrimaryGradientButton(
//                                       text: 'SUMBIT',
//                                       onPressed: _submit,
//                                       //  loading: signupLoading,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           Positioned(
//             top: 100,
//             left: 57,
//             right: 0,
//             child: IgnorePointer(
//               child: GradientText(
//                 'LEAVE APPLICATION FORM',
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//                   begin: Alignment.centerLeft,
//                   end: Alignment.centerRight,
//                 ),
//                 style: TextStyle(
//                   fontFamily: 'ClashGrotesk',
//                   fontSize: 20,
//                   fontWeight: FontWeight.w900,
//                   height: 1.59,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PrimaryGradientButton extends StatelessWidget {
//   const _PrimaryGradientButton({
//     required this.text,
//     required this.onPressed,
//     this.loading = false,
//   });

//   final String text;
//   final VoidCallback? onPressed;
//   final bool loading;

//   static const _grad = LinearGradient(
//     colors: [Color(0xFF0ED2F7), Color(0xFF7F53FD)],
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//   );

//   @override
//   Widget build(BuildContext context) {
//     final disabled = loading || onPressed == null;

//     return Opacity(
//       opacity: disabled ? 0.8 : 1,
//       child: Container(
//         height: 54,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(28),
//           gradient: _grad,
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFF7F53FD).withOpacity(0.25),
//               blurRadius: 18,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Material(
//           color: Colors.transparent,
//           child: InkWell(
//             borderRadius: BorderRadius.circular(28),
//             onTap: disabled ? null : onPressed,
//             child: Center(
//               child: loading
//                   ? const SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                   : Text(
//                       text,
//                       style: const TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// const _kCardDeco = BoxDecoration(
//   color: Colors.white,
//   borderRadius: BorderRadius.all(Radius.circular(16)),
//   boxShadow: [
//     BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
//   ],
// );

// /// ===================== TILE (fixed) =====================
// class PaymentChoiceTile extends StatelessWidget {
//   final String label;
//   final String code;
//   final bool selected;
//   final VoidCallback onTap;

//   const PaymentChoiceTile({
//     super.key,
//     required this.label,
//     required this.code,
//     required this.selected,
//     required this.onTap,
//   });

//   static const _grad = LinearGradient(
//     colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//   );

//   @override
//   Widget build(BuildContext context) {
//     final radius = BorderRadius.circular(12);

//     // Selected: gradient fill + check + LABEL
//     if (selected) {
//       return InkWell(
//         borderRadius: radius,
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//           decoration: BoxDecoration(
//             gradient: _grad,
//             borderRadius: radius,
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFF7F53FD).withOpacity(.18),
//                 blurRadius: 16,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.check_circle, size: 18, color: Colors.white),
//               const SizedBox(width: 8),
//               Text(
//                 label, // <- show the actual option name
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w700,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     // Not selected: gradient outline + gradient icon/text
//     return InkWell(
//       borderRadius: radius,
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: _grad, // outline gradient
//           borderRadius: radius,
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFF7F53FD).withOpacity(.12),
//               blurRadius: 12,
//               offset: const Offset(0, 6),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.all(1.6), // outline thickness
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//           decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: const [
//               _GradientIcon(
//                 icon: Icons.radio_button_unchecked,
//                 size: 18,
//                 gradient: _grad,
//               ),
//               SizedBox(width: 8),
//               _GradientText(
//                 // label rendered via gradient
//                 textGetter: null, // ignored when using const, see builder below
//                 gradient: _grad,
//                 style: TextStyle(fontWeight: FontWeight.w700),
//               ),
//             ],
//           ),
//         ),
//       ),
//     )._withLabel(label); // attach label without breaking consts above
//   }
// }

// /// Small extension to inject label into the not-selected layout cleanly
// extension _LabelPatch on Widget {
//   Widget _withLabel(String label) {
//     return Builder(
//       builder: (context) {
//         // Replace the _GradientText placeholder with one that has the label
//         return (this is Container)
//             ? (this as Container)._mapGradientText(label)
//             : this;
//       },
//     );
//   }
// }

// extension on Container {
//   Widget _mapGradientText(String label) {
//     return _replaceGradientText(this, label);
//   }

//   Widget _replaceGradientText(Widget w, String label) {
//     if (w is _GradientText) {
//       return _GradientText(
//         textGetter: () => label,
//         gradient: w.gradient,
//         style: w.style,
//       );
//     }
//     if (w is MultiChildRenderObjectWidget) {
//       final children = (w as dynamic).children as List<Widget>?;
//       if (children != null) {
//         return _rebuildWithChildren(
//           w,
//           children.map((c) => _replaceGradientText(c, label)).toList(),
//         );
//       }
//     }
//     if (w is SingleChildRenderObjectWidget) {
//       final child = (w as dynamic).child as Widget?;
//       if (child != null) {
//         return _rebuildWithChild(w, _replaceGradientText(child, label));
//       }
//     }
//     return w;
//   }

//   Widget _rebuildWithChildren(Widget w, List<Widget> kids) {
//     if (w is Row)
//       return Row(
//         mainAxisAlignment: w.mainAxisAlignment,
//         crossAxisAlignment: w.crossAxisAlignment,
//         mainAxisSize: w.mainAxisSize,
//         children: kids,
//       );
//     if (w is Column)
//       return Column(
//         mainAxisAlignment: w.mainAxisAlignment,
//         crossAxisAlignment: w.crossAxisAlignment,
//         mainAxisSize: w.mainAxisSize,
//         children: kids,
//       );
//     if (w is Stack)
//       return Stack(
//         alignment: w.alignment,
//         textDirection: w.textDirection,
//         fit: w.fit,
//         clipBehavior: w.clipBehavior,
//         children: kids,
//       );
//     // fallback: return original
//     return w;
//   }

//   Widget _rebuildWithChild(Widget w, Widget child) {
//     if (w is Container)
//       return Container(
//         key: w.key,
//         alignment: w.alignment,
//         padding: w.padding,
//         color: w.color,
//         decoration: w.decoration,
//         foregroundDecoration: w.foregroundDecoration,
//         width: w.width,
//         height: w.height,
//         constraints: w.constraints,
//         margin: w.margin,
//         transform: w.transform,
//         transformAlignment: w.transformAlignment,
//         clipBehavior: w.clipBehavior,
//         child: child,
//       );
//     if (w is Padding) return Padding(padding: w.padding, child: child);
//     if (w is Center)
//       return Center(
//         widthFactor: w.widthFactor,
//         heightFactor: w.heightFactor,
//         child: child,
//       );
//     if (w is Align)
//       return Align(
//         alignment: w.alignment,
//         widthFactor: w.widthFactor,
//         heightFactor: w.heightFactor,
//         child: child,
//       );
//     if (w is DecoratedBox)
//       return DecoratedBox(
//         decoration: w.decoration,
//         position: w.position,
//         child: child,
//       );
//     if (w is SizedBox)
//       return SizedBox(width: w.width, height: w.height, child: child);
//     if (w is ClipRRect)
//       return ClipRRect(
//         borderRadius: w.borderRadius,
//         clipBehavior: w.clipBehavior,
//         child: child,
//       );
//     if (w is ShaderMask)
//       return ShaderMask(
//         shaderCallback: w.shaderCallback,
//         blendMode: w.blendMode,
//         child: child,
//       );
//     return w;
//   }
// }

// /// ===================== GRADIENT HELPERS =====================
// class _GradientText extends StatelessWidget {
//   const _GradientText({
//     required this.textGetter,
//     required this.gradient,
//     this.style,
//   });

//   final String Function()? textGetter; // allows late label injection
//   final Gradient gradient;
//   final TextStyle? style;

//   @override
//   Widget build(BuildContext context) {
//     final text = textGetter?.call() ?? '';
//     return ShaderMask(
//       shaderCallback: (r) => gradient.createShader(r),
//       blendMode: BlendMode.srcIn,
//       child: Text(
//         text,
//         style: (style ?? const TextStyle()).copyWith(color: Colors.white),
//       ),
//     );
//   }

//   // Same gradient used in tile
//   static const _grad = LinearGradient(
//     colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//   );
// }

// class _GradientIcon extends StatelessWidget {
//   const _GradientIcon({
//     required this.icon,
//     required this.size,
//     required this.gradient,
//   });

//   final IconData icon;
//   final double size;
//   final Gradient gradient;

//   @override
//   Widget build(BuildContext context) {
//     return ShaderMask(
//       shaderCallback: (r) => gradient.createShader(r),
//       blendMode: BlendMode.srcIn,
//       child: Icon(icon, size: size, color: Colors.white),
//     );
//   }
// }

// /// ===================== DEMO GROUP (selection working) =====================
// /// Drop this widget anywhere to test the selection behavior.
// class PaymentChoiceGroup extends StatefulWidget {
//   const PaymentChoiceGroup({super.key});

//   @override
//   State<PaymentChoiceGroup> createState() => _PaymentChoiceGroupState();
// }

// class _PaymentChoiceGroupState extends State<PaymentChoiceGroup> {
//   String? _selectedCode = 'card'; // default selection

//   final _options = const <({String label, String code})>[
//     (label: 'Card', code: 'card'),
//     (label: 'Apple Pay', code: 'apple'),
//     (label: 'Google Pay', code: 'gpay'),
//     (label: 'Wallet', code: 'wallet'),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         for (final opt in _options) ...[
//           PaymentChoiceTile(
//             label: opt.label,
//             code: opt.code,
//             selected: _selectedCode == opt.code,
//             onTap: () => setState(() => _selectedCode = opt.code),
//           ),
//           const SizedBox(height: 10),
//         ],
//         const SizedBox(height: 6),
//         Text(
//           'Selected: ${_selectedCode ?? '-'}',
//           style: const TextStyle(fontWeight: FontWeight.w600),
//         ),
//       ],
//     );
//   }
// }

// // class _PaymentChoiceTile extends StatelessWidget {
// //   final String label;
// //   final String code;
// //   final bool selected;
// //   final VoidCallback onTap;

// //   const _PaymentChoiceTile({
// //     required this.label,
// //     required this.code,
// //     required this.selected,
// //     required this.onTap,
// //     Key? key,
// //   }) : super(key: key);

// //   static const _grad = LinearGradient(
// //     colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
// //     begin: Alignment.centerLeft,
// //     end: Alignment.centerRight,
// //   );

// //   @override
// //   Widget build(BuildContext context) {
// //     final radius = BorderRadius.circular(12);

// //     // Selected: gradient fill
// //     if (selected) {
// //       return InkWell(
// //         borderRadius: radius,
// //         onTap: onTap,
// //         child: Container(
// //           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
// //           decoration: BoxDecoration(
// //             gradient: _grad,
// //             borderRadius: radius,
// //             boxShadow: [
// //               BoxShadow(
// //                 color: const Color(0xFF7F53FD).withOpacity(.18),
// //                 blurRadius: 16,
// //                 offset: const Offset(0, 8),
// //               ),
// //             ],
// //           ),
// //           child: Row(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: const [
// //               Icon(Icons.check_circle, size: 18, color: Colors.white),
// //               SizedBox(width: 6),
// //               Text(
// //                 // label text in white on gradient
// //                 // (use rich/locale if needed)
// //                 'Selected', // will be replaced below
// //                 style: TextStyle(
// //                   fontWeight: FontWeight.w600,
// //                   color: Colors.white,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       );
// //     }

// //     // Not selected: gradient outline + gradient text/icon
// //     return InkWell(
// //       borderRadius: radius,
// //       onTap: onTap,
// //       child: Container(
// //         decoration: BoxDecoration(
// //           gradient: _grad,        // border gradient
// //           borderRadius: radius,
// //           boxShadow: [
// //             BoxShadow(
// //               color: const Color(0xFF7F53FD).withOpacity(.12),
// //               blurRadius: 12,
// //               offset: const Offset(0, 6),
// //             ),
// //           ],
// //         ),
// //         padding: const EdgeInsets.all(1.5), // outline thickness
// //         child: Container(
// //           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
// //           decoration: BoxDecoration(
// //             color: Colors.white,
// //             borderRadius: radius,
// //           ),
// //           child: Row(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             children: [
// //               const _GradientIcon(
// //                 icon: Icons.radio_button_unchecked,
// //                 size: 18,
// //                 gradient: _grad,
// //               ),
// //               const SizedBox(width: 6),
// //               _GradientText(
// //                 label,
// //                 gradient: _grad,
// //                 style: const TextStyle(fontWeight: FontWeight.w600),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// /// Gradient text helper (keeps your theme text sizing)

// // class _PaymentChoiceTile extends StatelessWidget {
// //   final String label;
// //   final String code;
// //   final bool selected;
// //   final VoidCallback onTap;

// //   const _PaymentChoiceTile({
// //     required this.label,
// //     required this.code,
// //     required this.selected,
// //     required this.onTap,
// //     Key? key,
// //   }) : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     return InkWell(
// //       borderRadius: BorderRadius.circular(12),
// //       onTap: onTap,
// //       child: Container(
// //         padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
// //         decoration: BoxDecoration(
// //           borderRadius: BorderRadius.circular(12),
// //           color: selected ? const Color(0xFFFFF1E6) : Colors.white,
// //           border: Border.all(color:  const Color(0xFFE5E7EB), width: selected ? 1.5 : 1),
// //           boxShadow: const [BoxShadow(color: Color(0xFFE5E7EB), blurRadius: 10, offset: Offset(0, 4))],
// //         ),
// //         child: Row(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             if (selected) const Icon(Icons.check_circle, size: 18, color: Color(0xFFE5E7EB))
// //             else const Icon(Icons.radio_button_unchecked, size: 18, color: Color(0xFFE5E7EB)),
// //             const SizedBox(width: 6),
// //             Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Color(0xFFE5E7EB) : Color(0xFFE5E7EB))),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// class _DateCard extends StatelessWidget {
//   const _DateCard({
//     required this.label,
//     required this.controller,
//     required this.onTap,
//     this.validator,
//   });

//   final String label;
//   final TextEditingController controller;
//   final VoidCallback onTap;
//   final String? Function(String?)? validator;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 56,
//       decoration: _kCardDeco,
//       padding: const EdgeInsets.symmetric(horizontal: 14),
//       child: InkWell(
//         onTap: onTap,
//         child: Row(
//           children: [
//             const Icon(
//               Icons.calendar_month_rounded,
//               size: 18,
//               color: Color(0xFF1B1B1B),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: AbsorbPointer(
//                 child: TextFormField(
//                   controller: controller,
//                   validator: validator,
//                   decoration: InputDecoration(
//                     hintText: label,
//                     border: InputBorder.none,
//                     isCollapsed: true,
//                     hintStyle: const TextStyle(
//                       fontFamily: 'ClashGrotesk',
//                       color: Colors.black54,
//                       fontSize: 16,
//                     ),
//                   ),
//                   style: const TextStyle(
//                     fontFamily: 'ClashGrotesk',
//                     color: Colors.black,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//             const Icon(
//               Icons.edit_calendar_rounded,
//               size: 18,
//               color: Color(0xFF7F53FD),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _CnicField extends StatelessWidget {
//   const _CnicField({required this.controller, required this.validator});
//   final TextEditingController controller;
//   final String? Function(String?) validator;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 56,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           const SizedBox(width: 14),
//           Image.asset(
//             'assets/name_icon.png',
//             height: 17,
//             width: 17,
//             color: const Color(0xFF1B1B1B),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: TextFormField(
//               key: const ValueKey('signup_cnic'),
//               controller: controller,
//               textAlign: TextAlign.start,
//               keyboardType: TextInputType.number,
//               inputFormatters: [
//                 FilteringTextInputFormatter.digitsOnly,
//                 LengthLimitingTextInputFormatter(13),
//                 _CnicInputFormatter(),
//               ],
//               validator: validator,
//               decoration: const InputDecoration(
//                 hintText: 'Employee CNIC',
//                 border: InputBorder.none,
//                 isCollapsed: true,
//                 hintStyle: TextStyle(
//                   fontFamily: 'ClashGrotesk',
//                   color: Colors.black,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ),
//           const Padding(
//             padding: EdgeInsets.only(right: 10),
//             child: Text(
//               '4xxxx-xxxxxxx-x',
//               style: TextStyle(
//                 color: Color(0xFF3B97A6),
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PkMobileField extends StatelessWidget {
//   const _PkMobileField({
//     required this.hint,
//     required this.controller,
//     required this.validator,
//   });
//   final String hint;
//   final TextEditingController controller;
//   final String? Function(String?) validator;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 56,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           const SizedBox(width: 14),
//           Image.asset(
//             'assets/name_icon.png',
//             height: 17,
//             width: 17,
//             color: const Color(0xFF1B1B1B),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: TextFormField(
//               textAlign: TextAlign.start,
//               style: const TextStyle(
//                 fontFamily: 'ClashGrotesk',
//                 color: Colors.black,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 letterSpacing: 1,
//               ),
//               controller: controller,
//               validator: validator,
//               decoration: InputDecoration(
//                 hintText: hint,
//                 border: InputBorder.none,
//                 isCollapsed: true,
//                 hintStyle: const TextStyle(
//                   fontFamily: 'ClashGrotesk',
//                   color: Colors.black54,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ),
//           const Padding(
//             padding: EdgeInsets.only(right: 10),
//             child: Text(
//               '92XXXXXXXXXX',
//               style: TextStyle(
//                 color: Color(0xFF3B97A6),
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /* ----------------- Formatters ----------------- */

// class _CnicInputFormatter extends TextInputFormatter {
//   // Formats 13 digits → XXXXX-XXXXXXX-X (inserts dashes visually)
//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
//     final buf = StringBuffer();
//     for (int i = 0; i < digits.length && i < 13; i++) {
//       buf.write(digits[i]);
//       if (i == 4 || i == 11) buf.write('-');
//     }
//     final text = buf.toString();
//     return TextEditingValue(
//       text: text,
//       selection: TextSelection.collapsed(offset: text.length),
//     );
//   }
// }
