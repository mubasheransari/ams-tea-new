import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_amst_flutter/Bloc/auth_event.dart';
import 'package:new_amst_flutter/Bloc/auth_state.dart';
import 'package:new_amst_flutter/Repository/repository.dart';
import 'package:new_amst_flutter/Widgets/watermarked_widget.dart';
import 'dart:ui' as ui;

import 'package:new_amst_flutter/bloc/auth_bloc.dart';

void showToast(BuildContext context, String message, {bool success = true}) {
  final mq = MediaQuery.of(context);
  final keyboard = mq.viewInsets.bottom; // ignore keyboard area
  final availableH = mq.size.height - keyboard;
  final bottomOffset = (availableH / 2) - 28; // ~ half screen - 1/2 snackbar
  final safeBottom = bottomOffset.clamp(16.0, availableH - 80.0);

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        safeBottom,
      ), // push to vertical center
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 10,
      backgroundColor: success
          ? const Color(0xFF10B981)
          : const Color(0xFFEF4444),
      content: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int tab = 0;
  bool remember = true;

  final _scrollCtrl = ScrollController();
  double _scrollY = 0.0;

  // Form keys
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // login
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginObscure = true;

  // signup
  final _empCodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mob1Ctrl = TextEditingController();
  final _mob2Ctrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPassCtrl = TextEditingController();
  final _distCtrl = TextEditingController();
  final _territoryCtrl = TextEditingController();
  String? _channelType;

  bool _signupObscure = true;

  // loading flags
  bool _loginLoading = false;
  bool _signupLoading = false;

  final _repo = Repository();

  @override
  void initState() {
    super.initState();
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
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _empCodeCtrl.dispose();
    _nameCtrl.dispose();
    _cnicCtrl.dispose();
    _addressCtrl.dispose();
    _mob1Ctrl.dispose();
    _mob2Ctrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPassCtrl.dispose();
    _distCtrl.dispose();
    _territoryCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ----------------- validators -----------------
  String? _validateLoginEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'Enter a valid email';
  }

  String? _validateSignupEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'Enter a valid email';
  }

  String? _validateLoginPassword(String? v) {
    if ((v ?? '').isEmpty) return 'Password is required';
    if (v!.length < 6) return 'Use at least 6 characters';
    return null;
  }

  String? _validateSignupPassword(String? v) {
    if ((v ?? '').isEmpty) return 'Password is required';
    if (v!.length < 8) return 'Use at least 8 characters';
    return null;
  }

  String? _validateName(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Name is required';
    if (s.length < 2) return 'Enter a valid name';
    return null;
  }

  String? _req(String? v) {
    if ((v ?? '').trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _cnic(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'CNIC is required';
    if (digits.length != 13) return 'Enter 13 digits';
    return null;
  }

  String? _pkMobile(String? v, {bool required = true}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return required ? 'Mobile is required' : null;
    final ok = RegExp(r'^(03\d{9}|92\d{10})$').hasMatch(s);
    return ok ? null : 'Use 03XXXXXXXXX or 92XXXXXXXXXX';
  }

  // ----------------- submit handlers -----------------
  Future<void> _submitLogin() async {
    
    //  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AppShell()));
    // if (!(_loginFormKey.currentState?.validate() ?? false)) return;

    // setState(() => _loginLoading = true);
    // final http.Response res =
    //     await _repo.login(_loginEmailCtrl.text.trim(), _loginPassCtrl.text);
    // setState(() => _loginLoading = false);

    // final parsed = Repository.parseApiMessage(res.body, res.statusCode);
    // showToast(context, parsed.message, success: parsed.ok);

    // if (parsed.ok && mounted) {
    //   // TODO: navigate to your app shell
    //   // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AppShell()));
    // }

    await Repository().login(
      email: "mubashera38@gmail.com",
      pass: "123",
      latitude: "24.8870845",
      longitude: "66.9788333",
      actType: "LOGIN",
      action: "IN",
      attTime: "11:20:52",
      attDate: "13-Nov-2025",
      appVersion: "2.0.2",
      add: "fyghfshfohfor",
      deviceId: "0d6bb3238ca24544",
    );
  }

  Future<void> _submitSignup() async {
    if (!(_signupFormKey.currentState?.validate() ?? false)) return;

    setState(() => _signupLoading = true);
    final res = await _repo.registerUser(
      code: _empCodeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      cnic: _cnicCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      mobile1: _mob1Ctrl.text.trim(),
      mobile2: _mob2Ctrl.text.trim(),
      email: _signupEmailCtrl.text.trim(),
      password: _signupPassCtrl.text,
      distribution: _distCtrl.text.trim(),
      territory: _territoryCtrl.text.trim(),
      channel: _channelType ?? '',
      latitude: "0",
      longitude: "0",
      deviceId: "0",
      regToken: "0",
    );
    setState(() => _signupLoading = false);

    final parsed = Repository.parseApiMessage(res.body, res.statusCode);

    if (parsed.message.contains('Already') == false) {
      showToast(context, "Account Created Sucessfully", success: parsed.ok);
    } else {
      showToast(context, parsed.message, success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double baseTop = tab == 0 ? 23.0 : 0.0;
    final double logoTop = tab == 1 ? (baseTop - _scrollY) : baseTop;

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
                            if (tab == 1) const SizedBox(height: 150),

                            _AuthToggle(
                              activeIndex: tab,
                              onChanged: (i) {
                                _loginFormKey.currentState?.reset();
                                _signupFormKey.currentState?.reset();
                                if (_scrollCtrl.hasClients) {
                                  _scrollCtrl.jumpTo(0);
                                }
                                setState(() {
                                  tab = i;
                                  _scrollY = 0;
                                });
                              },
                            ),
                            const SizedBox(height: 18),

                            // ---------------- LOGIN ----------------
                            if (tab == 0)
                              Form(
                                key: _loginFormKey,
                                autovalidateMode: AutovalidateMode.disabled,
                                child: Column(
                                  children: [
                                    // BlocConsumer<GlobalBloc, GlobalState>(
                                    //   listener: (context, state) {
                                    //     if (state.status ==
                                    //         LoginStatus.success) {
                                    //       Navigator.pushAndRemoveUntil(
                                    //         context,
                                    //         MaterialPageRoute(
                                    //           builder: (context) =>
                                    //               const HomeUpdated(),
                                    //         ),
                                    //         (route) => false,
                                    //       );
                                    //       toastWidget(
                                    //         "✅ Authenticated Successfully!",
                                    //         Colors.green,
                                    //       );

                                    //       box.write(
                                    //         "email",
                                    //         emailController.text.trim(),
                                    //       );
                                    //       box.write(
                                    //         "password",
                                    //         passwordController.text.trim(),
                                    //       );
                                    //       box.write('isLoggedIn', true);
                                    //     } else if (state.status ==
                                    //         LoginStatus.failure) {
                                    //       toastWidget(
                                    //         "Incorrect Email or Password",
                                    //         Colors.red,
                                    //       );
                                    //     }
                                    //   },
                                    //   builder: (context, state) {
                                    //     final isLoading =
                                    //         state.status == LoginStatus.loading;
                                    //     final t = Theme.of(context).textTheme;

                                    //     return Center(
                                    //       child: SizedBox(
                                    //         width:
                                    //             MediaQuery.of(
                                    //               context,
                                    //             ).size.width *
                                    //             0.42,
                                    //         height: 45,
                                    //         child: ElevatedButton(
                                    //           style: ElevatedButton.styleFrom(
                                    //             backgroundColor:
                                    //                 _NewLoginScreenState
                                    //                     .cPrimary,
                                    //             shape: RoundedRectangleBorder(
                                    //               borderRadius:
                                    //                   BorderRadius.circular(10),
                                    //             ),
                                    //           ),
                                    //           onPressed: isLoading
                                    //               ? null
                                    //               : () {
                                    //                   FocusScope.of(
                                    //                     context,
                                    //                   ).unfocus();
                                    //                   final email =
                                    //                       emailController.text
                                    //                           .trim();
                                    //                   final password =
                                    //                       passwordController
                                    //                           .text
                                    //                           .trim();
                                    //                   final emailRegex = RegExp(
                                    //                     r'^[^@]+@[^@]+\.[^@]+',
                                    //                   );

                                    //                   if (email.isEmpty ||
                                    //                       password.isEmpty) {
                                    //                     toastWidget(
                                    //                       "Please Enter Complete Form Data!",
                                    //                       Colors.red,
                                    //                     );
                                    //                     return;
                                    //                   } else if (!emailRegex
                                    //                       .hasMatch(email)) {
                                    //                     toastWidget(
                                    //                       "Please Enter Valid Email Address",
                                    //                       Colors.red,
                                    //                     );
                                    //                     return;
                                    //                   }

                                    //                   context
                                    //                       .read<GlobalBloc>()
                                    //                       .add(
                                    //                         LoginEvent(
                                    //                           email: email,
                                    //                           password:
                                    //                               password,
                                    //                         ),
                                    //                       );
                                    //                 },
                                    //           child: isLoading
                                    //               ? const SizedBox(
                                    //                   width: 22,
                                    //                   height: 22,
                                    //                   child: CircularProgressIndicator(
                                    //                     strokeWidth: 2.4,
                                    //                     valueColor:
                                    //                         AlwaysStoppedAnimation<
                                    //                           Color
                                    //                         >(Colors.white),
                                    //                   ),
                                    //                 )
                                    //               : Text(
                                    //                   'Login'.toUpperCase(),
                                    //                   style: TextStyle(
                                    //                     fontSize: 18,
                                    //                     color: Colors.white,
                                    //                     fontWeight:
                                    //                         FontWeight.bold,
                                    //                   ),
                                    //                 ),
                                    //         ),
                                    //       ),
                                    //     );
                                    //   },
                                    // ),
                                    _InputCard(
                                      fieldKey: const ValueKey('login_email'),
                                      hint: 'Email',
                                      icon: 'assets/email_icon.png',
                                      controller: _loginEmailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: _validateLoginEmail,
                                    ),
                                    const SizedBox(height: 12),
                                    _InputCard(
                                      fieldKey: const ValueKey(
                                        'login_password',
                                      ),
                                      hint: 'Password',
                                      icon: 'assets/password_icon.png',
                                      controller: _loginPassCtrl,
                                      obscureText: _loginObscure,
                                      onToggleObscure: () => setState(
                                        () => _loginObscure = !_loginObscure,
                                      ),
                                      validator: _validateLoginPassword,
                                    ),
                                    const SizedBox(height: 7),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {},
                                          child: const Text(
                                            'Forgot password',
                                            style: TextStyle(
                                              fontFamily: 'ClashGrotesk',
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      width: 160,
                                      height: 40,
                                      child:
                                          BlocConsumer<
                                              AuthBloc,
                                            AuthState
                                          >(
                                            listener: (context, state) {
                                           
                                            },
                                            builder: (context, state) {
                                              return _PrimaryGradientButton(
                                                text: _loginLoading
                                                    ? 'PLEASE WAIT...'
                                                    : 'LOGIN',
                                                onPressed: _loginLoading
                                                    ? null: (){
context.read<AuthBloc>().state.add(LoginEvent(_loginEmailCtrl.text, _loginPassCtrl.text));
                                                    },
                                                 //   : _submitLogin,
                                                loading: _loginLoading,
                                              );
                                            },
                                          ),
                                    ),
                                    const SizedBox(height: 18),
                                    _FooterSwitch(
                                      prompt: "Don’t have an account? ",
                                      action: "Create an account",
                                      onTap: () => setState(() {
                                        if (_scrollCtrl.hasClients)
                                          _scrollCtrl.jumpTo(0);
                                        tab = 1;
                                        _scrollY = 0;
                                      }),
                                    ),
                                  ],
                                ),
                              ),

                            // ---------------- SIGNUP ----------------
                            if (tab == 1)
                              Form(
                                key: _signupFormKey,
                                autovalidateMode: AutovalidateMode.disabled,
                                child: Column(
                                  children: [
                                    _InputCard(
                                      fieldKey: const ValueKey('emp_code'),
                                      hint: 'Employee Code',
                                      icon: 'assets/name_icon.png',
                                      controller: _empCodeCtrl,
                                      validator: _req,
                                    ),
                                    const SizedBox(height: 12),

                                    _InputCard(
                                      fieldKey: const ValueKey('signup_name'),
                                      hint: 'Employee Name',
                                      icon: 'assets/name_icon.png',
                                      controller: _nameCtrl,
                                      validator: _validateName,
                                    ),
                                    const SizedBox(height: 12),

                                    _CnicField(
                                      controller: _cnicCtrl,
                                      validator: _cnic,
                                    ),
                                    const SizedBox(height: 12),

                                    _InputCard(
                                      fieldKey: const ValueKey(
                                        'signup_address',
                                      ),
                                      hint: 'Employee Address',
                                      icon: 'assets/name_icon.png',
                                      controller: _addressCtrl,
                                      validator: _req,
                                    ),
                                    const SizedBox(height: 12),

                                    _PkMobileField(
                                      hint: 'Employee Mobile 1',
                                      controller: _mob1Ctrl,
                                      validator: _pkMobile,
                                    ),
                                    const SizedBox(height: 12),

                                    _PkMobileField(
                                      hint: 'Employee Mobile 2',
                                      controller: _mob2Ctrl,
                                      validator: (v) =>
                                          _pkMobile(v, required: false),
                                    ),
                                    const SizedBox(height: 12),

                                    _InputCard(
                                      fieldKey: const ValueKey('signup_email'),
                                      hint: 'Employee Email',
                                      icon: 'assets/email_icon.png',
                                      controller: _signupEmailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: _validateSignupEmail,
                                    ),
                                    const SizedBox(height: 12),

                                    _InputCard(
                                      fieldKey: const ValueKey(
                                        'signup_password',
                                      ),
                                      hint: 'Employee Password',
                                      icon: 'assets/password_icon.png',
                                      controller: _signupPassCtrl,
                                      obscureText: _signupObscure,
                                      onToggleObscure: () => setState(
                                        () => _signupObscure = !_signupObscure,
                                      ),
                                      validator: _validateSignupPassword,
                                    ),
                                    const SizedBox(height: 12),

                                    _InputCard(
                                      fieldKey: const ValueKey(
                                        'signup_distribution',
                                      ),
                                      hint: 'Distribution Name',
                                      icon: 'assets/name_icon.png',
                                      controller: _distCtrl,
                                      validator: _req,
                                    ),
                                    const SizedBox(height: 12),

                                    _InputCard(
                                      fieldKey: const ValueKey(
                                        'signup_territory',
                                      ),
                                      hint: 'Territory',
                                      icon: 'assets/name_icon.png',
                                      controller: _territoryCtrl,
                                      validator: _req,
                                    ),
                                    const SizedBox(height: 12),

                                    // Channel Type dropdown
                                    Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.06,
                                            ),
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
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons
                                                  .store_mall_directory_rounded,
                                              size: 18,
                                              color: Color(0xFF1B1B1B),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: DropdownButtonFormField<String>(
                                              value: _channelType,
                                              isExpanded: true,
                                              alignment: Alignment.centerLeft,
                                              style: const TextStyle(
                                                fontFamily: 'ClashGrotesk',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                                letterSpacing: 0.3,
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                isCollapsed: true,
                                                contentPadding: EdgeInsets.zero,
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
                                                height: 87,
                                                width: 34,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFEDE7FF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.expand_more_rounded,
                                                  size: 20,
                                                  color: Color(0xFF7F53FD),
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              dropdownColor: Colors.white,
                                              menuMaxHeight: 320,
                                              items:
                                                  const [
                                                        'GT',
                                                        'LMT',
                                                        'IMT',
                                                        'OOH',
                                                        'HORECA',
                                                        'BS',
                                                        'N/A',
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
                                                                color: Colors
                                                                    .black,
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
                                        text: _signupLoading
                                            ? 'PLEASE WAIT...'
                                            : 'SIGNUP',
                                        onPressed: _signupLoading
                                            ? null
                                            : _submitSignup,
                                        loading: _signupLoading,
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    _FooterSwitch(
                                      prompt: "Already have an account? ",
                                      action: "Login",
                                      onTap: () => setState(() {
                                        if (_scrollCtrl.hasClients)
                                          _scrollCtrl.jumpTo(0);
                                        tab = 0;
                                        _scrollY = 0;
                                      }),
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

          // logo (uses your existing asset)
          Positioned(
            top: logoTop,
            left: 57,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Image.asset(
                  "assets/logo_ams.png",
                  height: 270,
                  width: 270,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------- UI bits you already had ----------------- */

class _AuthToggle extends StatelessWidget {
  const _AuthToggle({required this.activeIndex, required this.onChanged});
  final int activeIndex;
  final ValueChanged<int> onChanged;

  static const _grad = LinearGradient(
    colors: [Color(0xFF0ED2F7), Color(0xFF7F53FD)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              height: 44,
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                gradient: activeIndex == 0 ? _grad : null,
                borderRadius: BorderRadius.circular(22),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => onChanged(0),
                child: Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: activeIndex == 0
                          ? Colors.white
                          : const Color(0xFF0AA2FF),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedContainer(
              height: 44,
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                gradient: activeIndex == 1 ? _grad : null,
                borderRadius: BorderRadius.circular(22),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => onChanged(1),
                child: Center(
                  child: Text(
                    'SignUp',
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: activeIndex == 1
                          ? Colors.white
                          : const Color(0xFF0AA2FF),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.hint,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.onToggleObscure,
    this.fieldKey,
  });

  final String hint;
  final String icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final Key? fieldKey;

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
            icon,
            height: 17,
            width: 17,
            color: const Color(0xFF1B1B1B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              key: fieldKey,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontFamily: 'ClashGrotesk',
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              obscureText: obscureText,
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
          if (onToggleObscure != null)
            IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 22,
                color: const Color(0xFF1B1B1B),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _FooterSwitch extends StatelessWidget {
  const _FooterSwitch({
    required this.prompt,
    required this.action,
    required this.onTap,
  });
  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: const TextStyle(
            fontFamily: 'ClashGrotesk',
            fontSize: 14.5,
            color: Color(0xFF1B1B1B),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 14.5,
              color: Color(0xFF1E9BFF),
              decoration: TextDecoration.underline,
              decorationThickness: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/* ----------------- Special Fields ----------------- */

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
