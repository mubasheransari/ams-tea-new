import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_amst_flutter/Bloc/auth_bloc.dart';
import 'package:new_amst_flutter/Bloc/auth_event.dart';
import 'package:new_amst_flutter/Bloc/auth_state.dart';
import 'package:new_amst_flutter/Screens/splash_screen.dart';
import 'package:new_amst_flutter/Widgets/watermarked_widget.dart';


import 'dart:ui' as ui;


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int tab = 0; // 0 = Login, 1 = SignUp
  bool remember = true;

  // Separate form keys
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // login
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginObscure = true;

  // signup (per screenshot)
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
    super.dispose();
  }

  // ---------------- Validators ----------------
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
    // Accept 13 digits with or without dashes, format is XXXXX-XXXXXXX-X
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'CNIC is required';
    if (digits.length != 13) return 'Enter 13 digits';
    return null;
  }

  String? _pkMobile(String? v, {bool required = true}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return required ? 'Mobile is required' : null;
    // Accept: 03XXXXXXXXX (11) OR 92XXXXXXXXXX (12)
    final ok = RegExp(r'^(03\d{9}|92\d{10})$').hasMatch(s);
    return ok ? null : 'Use 03XXXXXXXXX or 92XXXXXXXXXX';
    // If you only want 92xxxxxxxxxx, change regex to: r'^92\d{10}$'
  }

  // ---------------- Submit ----------------
  void _submit() {
    final bloc = context.read<AuthBloc>();

    if (tab == 0) {
      if (!_loginFormKey.currentState!.validate()) return;
      bloc.add(
        LoginRequested(
          email: _loginEmailCtrl.text.trim(),
          password: _loginPassCtrl.text,
        ),
      );
    } else {
      if (!_signupFormKey.currentState!.validate()) return;

      final full = _nameCtrl.text.trim();
      String first = full, last = '';
      final sp = full.split(RegExp(r'\s+'));
      if (sp.length > 1) {
        first = sp.first;
        last = sp.sublist(1).join(' ');
      }

      // Send minimal payload (adjust to your backend)
      bloc.add(
        SignupRequested(
          firstName: first,
          lastName: last,
          email: _signupEmailCtrl.text.trim(),
          password: _signupPassCtrl.text,
        ),
      );

      // Optionally switch to login after successful request submission
      // setState(() => tab = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (p, c) =>
          p.loginStatus != c.loginStatus ||
          p.signupStatus != c.signupStatus ||
          p.error != c.error,
      listener: (context, state) {
        if (state.error != null && state.error!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
        if (state.loginStatus == AuthStatus.success) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        }
        if (state.signupStatus == AuthStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signup successful. Please login.')),
          );
        }
      },
      builder: (context, state) {
        final loginLoading = state.loginStatus == AuthStatus.loading;
        final signupLoading = state.signupStatus == AuthStatus.loading;

        return Scaffold(
          backgroundColor: const Color(0xFFF2F3F5),
          body: Stack(
            children: [
              Positioned(
                top: 20,
                left: MediaQuery.of(context).size.width * 0.245,
                child: Center(
                  child: Image.asset(
                    "assets/logo_ams.png",
                    height: 270,
                    width: 270,
                  ),
                ),
              ),
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
                            color: Colors.white.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.75),
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AuthToggle(
                                  activeIndex: tab,
                                  onChanged: (i) {
                                    _loginFormKey.currentState?.reset();
                                    _signupFormKey.currentState?.reset();
                                    setState(() => tab = i);
                                  },
                                ),
                                const SizedBox(height: 18),

                                // ---------------- LOGIN FORM ----------------
                                if (tab == 0)
                                  Form(
                                    key: _loginFormKey,
                                    autovalidateMode:
                                        AutovalidateMode.disabled,
                                    child: Column(
                                      children: [
                                        _InputCard(
                                          fieldKey:
                                              const ValueKey('login_email'),
                                          hint: 'Email',
                                          icon: 'assets/email_icon.png',
                                          controller: _loginEmailCtrl,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: _validateLoginEmail,
                                        ),
                                        const SizedBox(height: 12),
                                        _InputCard(
                                          fieldKey:
                                              const ValueKey('login_password'),
                                          hint: 'Password',
                                          icon: 'assets/password_icon.png',
                                          controller: _loginPassCtrl,
                                          obscureText: _loginObscure,
                                          onToggleObscure: () => setState(
                                            () => _loginObscure =
                                                !_loginObscure,
                                          ),
                                          validator: _validateLoginPassword,
                                        ),
                                        const SizedBox(height: 7),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8.0,
                                              ),
                                              child: TextButton(
                                                onPressed: () {},
                                                child: const Text(
                                                  'Forgot password',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'ClashGrotesk',
                                                    fontSize: 14.5,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: 160,
                                          height: 40,
                                          child: _PrimaryGradientButton(
                                            text: loginLoading
                                                ? 'Please wait...'
                                                : 'LOGIN',
                                            onPressed: loginLoading
                                                ? null
                                                : _submit,
                                            loading: loginLoading,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        _FooterSwitch(
                                          prompt:
                                              "Don’t have an account? ",
                                          action: "Create an account",
                                          onTap: () =>
                                              setState(() => tab = 1),
                                        ),
                                      ],
                                    ),
                                  ),

                                // ---------------- SIGNUP FORM ----------------
                                if (tab == 1)
                                  Form(
                                    key: _signupFormKey,
                                    autovalidateMode:
                                        AutovalidateMode.disabled,
                                    child: Column(
                                      children: [
                                        _InputCard(
                                          fieldKey:
                                              const ValueKey('emp_code'),
                                          hint: 'Employee Code',
                                          icon: 'assets/name_icon.png',
                                          controller: _empCodeCtrl,
                                          validator: _req,
                                        ),
                                        const SizedBox(height: 12),

                                        _InputCard(
                                          fieldKey:
                                              const ValueKey('signup_name'),
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
                                          fieldKey:
                                              const ValueKey('signup_address'),
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
                                          fieldKey:
                                              const ValueKey('signup_email'),
                                          hint: 'Employee Email',
                                          icon: 'assets/email_icon.png',
                                          controller: _signupEmailCtrl,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: _validateSignupEmail,
                                        ),
                                        const SizedBox(height: 12),

                                        _InputCard(
                                          fieldKey: const ValueKey(
                                              'signup_password'),
                                          hint: 'Employee Password',
                                          icon: 'assets/password_icon.png',
                                          controller: _signupPassCtrl,
                                          obscureText: _signupObscure,
                                          onToggleObscure: () => setState(
                                            () => _signupObscure =
                                                !_signupObscure,
                                          ),
                                          validator: _validateSignupPassword,
                                        ),
                                        const SizedBox(height: 12),

                                        _InputCard(
                                          fieldKey: const ValueKey(
                                              'signup_distribution'),
                                          hint: 'Distribution Name',
                                          icon: 'assets/name_icon.png',
                                          controller: _distCtrl,
                                          validator: _req,
                                        ),
                                        const SizedBox(height: 12),

                                        _InputCard(
                                          fieldKey: const ValueKey(
                                              'signup_territory'),
                                          hint: 'Territory',
                                          icon: 'assets/name_icon.png',
                                          controller: _territoryCtrl,
                                          validator: _req,
                                        ),
                                        const SizedBox(height: 12),

                                        // Dropdown (Select Channel Type)
                                        Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.06),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: DropdownButtonFormField<String>(
                                            value: _channelType,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Select Channel Type',
                                              isCollapsed: true,
                                              hintStyle: TextStyle(
                                                fontFamily: 'ClashGrotesk',
                                                color: Colors.black54,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            icon:
                                                const Icon(Icons.arrow_drop_down),
                                            items: const [
                                              'GT',
                                              'LMT',
                                              'IMT',
                                              'OOH',
                                              'HORECA',
                                              'BS',
                                              'N/A'
                                            ]
                                                .map((e) => DropdownMenuItem(
                                                      value: e,
                                                      child: Align(
                                                        alignment:
                                                            Alignment.centerLeft,
                                                        child: Text(
                                                          e,
                                                          style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            letterSpacing: 0.3,
                                                          ),
                                                        ),
                                                      ),
                                                    ))
                                                .toList(),
                                            onChanged: (v) =>
                                                setState(() => _channelType = v),
                                            validator: (v) =>
                                                v == null ? 'Please select' : null,
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        _PrimaryGradientButton(
                                          text: signupLoading
                                              ? 'Please wait...'
                                              : 'SignUp',
                                          onPressed: signupLoading
                                              ? null
                                              : _submit,
                                          loading: signupLoading,
                                        ),
                                        const SizedBox(height: 18),

                                        _FooterSwitch(
                                          prompt:
                                              "Already have an account? ",
                                          action: "Login",
                                          onTap: () =>
                                              setState(() => tab = 0),
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
            ],
          ),
        );
      },
    );
  }
}

/* ========================= UI pieces ========================= */

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
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AnimatedContainer(
                height: 48,
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
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AnimatedContainer(
                height: 48,
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
  final Key? fieldKey; // Unique field key

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
              textAlign: TextAlign.start, // left/start like _PkMobileField
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
          child: const Text(
            'Login',
            style: TextStyle(
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
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Image.asset('assets/name_icon.png', height: 17, width: 17, color: const Color(0xFF1B1B1B)),
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
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Image.asset('assets/name_icon.png', height: 17, width: 17, color: const Color(0xFF1B1B1B)),
          const SizedBox(width: 10),
              Expanded(
            child: TextFormField(
            //  key: fieldKey,
              textAlign: TextAlign.start, // left/start like _PkMobileField
              style: const TextStyle(
                fontFamily: 'ClashGrotesk',
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
              controller: controller,
             // keyboardType: keyboardType,
              validator: validator,
             // obscureText: obscureText,
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
          // Expanded(
          //   child: TextFormField(
          //     key: ValueKey(hint),
          //     controller: controller,
          //     textAlign: TextAlign.start,
          //     keyboardType: TextInputType.phone,
          //     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          //     validator: validator,
          //     decoration: InputDecoration(
          //       hintText: hint,
          //       border: InputBorder.none,
          //       isCollapsed: true,
          //       hintStyle: const TextStyle(
          //         fontFamily: 'ClashGrotesk',
          //         color: Colors.black54,
          //         fontSize: 16,
          //       ),
          //     ),
          //   ),
          // ),
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
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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


/*
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_amst_flutter/Bloc/auth_bloc.dart';
import 'package:new_amst_flutter/Bloc/auth_event.dart';
import 'package:new_amst_flutter/Bloc/auth_state.dart';
import 'package:new_amst_flutter/Screens/splash_screen.dart';
import 'package:new_amst_flutter/Widgets/watermarked_widget.dart';


import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// TODO: keep your own imports for AuthBloc, SplashScreen, WatermarkTiledSmall, etc.

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int tab = 0; // 0 = Login, 1 = SignUp
  bool remember = true;

  // --------- Form keys ---------
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // --------- Login ---------
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl  = TextEditingController();
  bool _loginObscure = true;

  // --------- SignUp (per screenshots) ---------
  final _empCodeCtrl   = TextEditingController();
  final _nameCtrl      = TextEditingController();
  final _cnicCtrl      = TextEditingController();
  final _addressCtrl   = TextEditingController();
  final _mob1Ctrl      = TextEditingController();
  final _mob2Ctrl      = TextEditingController(); // optional
  final _signupEmailCtrl = TextEditingController();
  final _signupPassCtrl  = TextEditingController();
  final _distCtrl      = TextEditingController();
  final _territoryCtrl = TextEditingController();
  String? _channelType; // dropdown
  bool _signupObscure = true;

  @override
  void dispose() {
    // login
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();

    // signup
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
    super.dispose();
  }

  // --------- Validators ---------
  String? _validateLoginEmail(String? v) {
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

  String? _validateSignupEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
    return ok ? null : 'Enter a valid email';
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

  String? _req(String? v, {String msg = 'Required'}) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  String? _cnic(String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.length != 13) return 'CNIC must be 13 digits';
    return null;
  }

  String? _pkMobile(String? v, {bool required = true}) {
    final s = (v ?? '').trim();
    if (!required && s.isEmpty) return null;
    final d = s.replaceAll(RegExp(r'\D'), '');
    if (d.length != 12 || !d.startsWith('92')) return 'Use 92XXXXXXXXXX';
    return null;
  }

  // --------- Submit ---------
  void _submit() {
    final bloc = context.read<AuthBloc>();

    if (tab == 0) {
      if (!_loginFormKey.currentState!.validate()) return;
      bloc.add(
        LoginRequested(
          email: _loginEmailCtrl.text.trim(),
          password: _loginPassCtrl.text,
        ),
      );
    } else {
      if (!_signupFormKey.currentState!.validate()) return;

      // Split name into first/last if you need it
      final full = _nameCtrl.text.trim();
      String first = full, last = '';
      final sp = full.split(RegExp(r'\s+'));
      if (sp.length > 1) {
        first = sp.first;
        last  = sp.sublist(1).join(' ');
      }

      // TODO: extend your event to include all fields if desired.
      bloc.add(
        SignupRequested(
          firstName: first,
          lastName: last,
          email: _signupEmailCtrl.text.trim(),
          password: _signupPassCtrl.text,
          // You can also pass:
          // empCode: _empCodeCtrl.text.trim(),
          // cnic: _cnicCtrl.text.trim(),
          // address: _addressCtrl.text.trim(),
          // mobile1: _mob1Ctrl.text.trim(),
          // mobile2: _mob2Ctrl.text.trim(),
          // distribution: _distCtrl.text.trim(),
          // territory: _territoryCtrl.text.trim(),
          // channelType: _channelType,
        ),
      );

      setState(() => tab = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (p, c) =>
          p.loginStatus != c.loginStatus ||
          p.signupStatus != c.signupStatus ||
          p.error != c.error,
      listener: (context, state) {
        if (state.error != null && state.error!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
        if (state.loginStatus == AuthStatus.success) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        }
        if (state.signupStatus == AuthStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signup successful. Please login.')),
          );
        }
      },
      builder: (context, state) {
        final loginLoading  = state.loginStatus  == AuthStatus.loading;
        final signupLoading = state.signupStatus == AuthStatus.loading;

        return Scaffold(
          backgroundColor: const Color(0xFFF2F3F5),
          body: Stack(
            children: [
              Positioned(
                top: 20,
                left: MediaQuery.of(context).size.width * 0.245,
                child: Center(
                  child: Image.asset(
                    "assets/logo_ams.png",
                    height: 270,
                    width: 270,
                  ),
                ),
              ),
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
                            color: Colors.white.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.75),
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AuthToggle(
                                  activeIndex: tab,
                                  onChanged: (i) {
                                    _loginFormKey.currentState?.reset();
                                    _signupFormKey.currentState?.reset();
                                    setState(() => tab = i);
                                  },
                                ),
                                const SizedBox(height: 18),

                                // ---------------- LOGIN FORM ----------------
                                if (tab == 0)
                                  Form(
                                    key: _loginFormKey,
                                    autovalidateMode: AutovalidateMode.disabled,
                                    child: Column(
                                      children: [
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
                                          fieldKey: const ValueKey('login_password'),
                                          hint: 'Password',
                                          icon: 'assets/password_icon.png',
                                          controller: _loginPassCtrl,
                                          obscureText: _loginObscure,
                                          onToggleObscure: () =>
                                              setState(() => _loginObscure = !_loginObscure),
                                          validator: _validateLoginPassword,
                                        ),
                                        const SizedBox(height: 7),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8.0),
                                              child: TextButton(
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
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: 160,
                                          height: 40,
                                          child: _PrimaryGradientButton(
                                            text: loginLoading
                                                ? 'Please wait...'
                                                : 'LOGIN',
                                            onPressed: loginLoading ? null : _submit,
                                            loading: loginLoading,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        _FooterSwitch(
                                          prompt: "Don’t have an account? ",
                                          action: "Create an account",
                                          onTap: () => setState(() => tab = 1),
                                        ),
                                      ],
                                    ),
                                  ),

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
                                          center: true,
                                        ),
                                        const SizedBox(height: 12),

                                        _InputCard(
                                          fieldKey: const ValueKey('signup_name'),
                                          hint: 'Employee Name',
                                          icon: 'assets/name_icon.png',
                                          controller: _nameCtrl,
                                          validator: _validateName,
                                          center: true,
                                        ),
                                        const SizedBox(height: 12),

                                        // CNIC with mask #####-#######-#
                                        _CnicField(
                                          controller: _cnicCtrl,
                                          validator: _cnic,
                                        ),
                                        const SizedBox(height: 12),

                                        _InputCard(
                                          fieldKey: const ValueKey('signup_address'),
                                          hint: 'Employee Address',
                                          icon: 'assets/name_icon.png',
                                          controller: _addressCtrl,
                                          validator: _req,
                                          center: true,
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
                                          validator: (v) => _pkMobile(v, required: false),
                                        ),
                                        const SizedBox(height: 12),

                                        _InputCard(
                                          fieldKey: const ValueKey('signup_email'),
                                          hint: 'Employee Email',
                                          icon: 'assets/email_icon.png',
                                          controller: _signupEmailCtrl,
                                          keyboardType: TextInputType.emailAddress,
                                          validator: _validateSignupEmail,
                                          center: true,
                                        ),
                                        const SizedBox(height: 12),

                                        _InputCard(
                                          fieldKey: const ValueKey('signup_password'),
                                          hint: 'Employee Password',
                                          icon: 'assets/password_icon.png',
                                          controller: _signupPassCtrl,
                                          obscureText: _signupObscure,
                                          onToggleObscure: () =>
                                              setState(() => _signupObscure = !_signupObscure),
                                          validator: _validateSignupPassword,
                                          center: true,
                                        ),
                                        const SizedBox(height: 12),

                                        _InputCard(
                                          fieldKey: const ValueKey('signup_distribution'),
                                          hint: 'Distribution Name',
                                          icon: 'assets/name_icon.png',
                                          controller: _distCtrl,
                                          validator: _req,
                                          center: true,
                                        ),
                                        const SizedBox(height: 12),

                                        _InputCard(
                                          fieldKey: const ValueKey('signup_territory'),
                                          hint: 'Territory',
                                          icon: 'assets/name_icon.png',
                                          controller: _territoryCtrl,
                                          validator: _req,
                                          center: true,
                                        ),
                                        const SizedBox(height: 12),

                                        // Dropdown: Select Channel Type
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
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: DropdownButtonFormField<String>(
                                            value: _channelType,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Select Channel Type',
                                              hintStyle: TextStyle(
                                                fontFamily: 'ClashGrotesk',
                                                color: Colors.black54,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            icon: const Icon(Icons.arrow_drop_down),
                                            items: const ['GT','LMT','IMT','OOH','HORECA','BS','N/A']
                                                .map((e) => DropdownMenuItem(
                                                      value: e,
                                                      child: Center(
                                                        child: Text(
                                                          e,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            letterSpacing: 0.3,
                                                          ),
                                                        ),
                                                      ),
                                                    ))
                                                .toList(),
                                            onChanged: (v) => setState(() => _channelType = v),
                                            validator: (v) => v == null ? 'Please select' : null,
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        _PrimaryGradientButton(
                                          text: signupLoading ? 'Please wait...' : 'SignUp',
                                          onPressed: signupLoading ? null : _submit,
                                          loading: signupLoading,
                                        ),
                                        const SizedBox(height: 18),

                                        _FooterSwitch(
                                          prompt: "Already have an account? ",
                                          action: "Login",
                                          onTap: () => setState(() => tab = 0),
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
            ],
          ),
        );
      },
    );
  }
}

/* ---------------- Widgets ---------------- */

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
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AnimatedContainer(
                height: 48,
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
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AnimatedContainer(
                height: 48,
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
    this.center = false,
  });

  final String hint;
  final String icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final Key? fieldKey;
  final bool center;

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
              textAlign: center ? TextAlign.center : TextAlign.start,
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
          child: const Text(
            'Login',
            style: TextStyle(
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

/* ---------- Specialized fields to match screenshot ---------- */

class _CnicField extends StatelessWidget {
  const _CnicField({
    required this.controller,
    required this.validator,
  });

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
          Image.asset('assets/name_icon.png', height: 17, width: 17, color: const Color(0xFF1B1B1B)),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              key: const ValueKey('signup_cnic'),
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
                _CnicInputFormatter(),
              ],
              validator: validator,
              decoration: const InputDecoration(
                hintText: 'Employee CNIC',
                border: InputBorder.none,
                isCollapsed: true,
                hintStyle: TextStyle(
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
          Image.asset('assets/name_icon.png', height: 17, width: 17, color: const Color(0xFF1B1B1B)),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              key: ValueKey(hint),
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

/* ---------- Formatters ---------- */

/// Formats CNIC as #####-#######-#
class _CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 13 ? digits.substring(0, 13) : digits;

    final buf = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      buf.write(limited[i]);
      if (i == 4 && limited.length > 5) buf.write('-');
      if (i == 11 && limited.length > 12) buf.write('-');
    }
    final txt = buf.toString();
    return TextEditingValue(
      text: txt,
      selection: TextSelection.collapsed(offset: txt.length),
    );
  }
}*/


// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});
//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   int tab = 0; // 0 = Login, 1 = SignUp
//   bool remember = true;

//   // Separate form keys
//   final _loginFormKey = GlobalKey<FormState>();
//   final _signupFormKey = GlobalKey<FormState>();

//   // login
//   final _loginEmailCtrl = TextEditingController();
//   final _loginPassCtrl = TextEditingController();
//   bool _loginObscure = true;

//   // signup
//   final _nameCtrl = TextEditingController();
//   final _signupEmailCtrl = TextEditingController();
//   final _signupPassCtrl = TextEditingController();
//   final _confirmCtrl = TextEditingController();
//   bool _signupObscure = true;
//   bool _confirmObscure = true;

//   @override
//   void dispose() {
//     _loginEmailCtrl.dispose();
//     _loginPassCtrl.dispose();
//     _nameCtrl.dispose();
//     _signupEmailCtrl.dispose();
//     _signupPassCtrl.dispose();
//     _confirmCtrl.dispose();
//     super.dispose();
//   }

//   // ---------------- Validators (separated) ----------------
//   String? _validateLoginEmail(String? v) {
//     final s = v?.trim() ?? '';
//     if (s.isEmpty) return 'Email is required';
//     final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
//     return ok ? null : 'Enter a valid email';
//   }

//   String? _validateSignupEmail(String? v) {
//     final s = v?.trim() ?? '';
//     if (s.isEmpty) return 'Email is required';
//     final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
//     return ok ? null : 'Enter a valid email';
//   }

//   String? _validateLoginPassword(String? v) {
//     if ((v ?? '').isEmpty) return 'Password is required';
//     if (v!.length < 6) return 'Use at least 6 characters';
//     return null;
//   }

//   String? _validateSignupPassword(String? v) {
//     if ((v ?? '').isEmpty) return 'Password is required';
//     if (v!.length < 8) return 'Use at least 8 characters';
//     // Optionally add complexity rules:
//     // if (!RegExp(r'(?=.*[A-Z])(?=.*\d)').hasMatch(v)) return 'Add a capital & number';
//     return null;
//   }

//   String? _validateName(String? v) {
//     final s = (v ?? '').trim();
//     if (s.isEmpty) return 'Name is required';
//     if (s.length < 2) return 'Enter a valid name';
//     return null;
//   }

//   String? _validateConfirm(String? v) {
//     final err = _validateSignupPassword(v);
//     if (err != null) return err;
//     if (v != _signupPassCtrl.text) return 'Passwords do not match';
//     return null;
//   }

//   // ---------------- Submit ----------------
//   void _submit() {
//     final bloc = context.read<AuthBloc>();

//     if (tab == 0) {
//       if (!_loginFormKey.currentState!.validate()) return;
//       bloc.add(
//         LoginRequested(
//           email: _loginEmailCtrl.text.trim(),
//           password: _loginPassCtrl.text,
//         ),
//       );
//     } else {
//       if (!_signupFormKey.currentState!.validate()) return;

//       final full = _nameCtrl.text.trim();
//       String first = full, last = '';
//       final sp = full.split(RegExp(r'\s+'));
//       if (sp.length > 1) {
//         first = sp.first;
//         last = sp.sublist(1).join(' ');
//       }

//       bloc.add(
//         SignupRequested(
//           firstName: first,
//           lastName: last,
//           email: _signupEmailCtrl.text.trim(),
//           password: _signupPassCtrl.text,
//         ),
//       );

//       // Optionally switch to login after successful request submission
//       setState(() => tab = 0);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;

//     return BlocConsumer<AuthBloc, AuthState>(
//       listenWhen: (p, c) =>
//           p.loginStatus != c.loginStatus ||
//           p.signupStatus != c.signupStatus ||
//           p.error != c.error,
//       listener: (context, state) {
//         if (state.error != null && state.error!.isNotEmpty) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(state.error!)),
//           );
//         }
//         if (state.loginStatus == AuthStatus.success) {
//           Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (_) => const SplashScreen()),
//             (route) => false,
//           );
//         }
//         if (state.signupStatus == AuthStatus.success) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Signup successful. Please login.')),
//           );
//         }
//       },
//       builder: (context, state) {
//         final loginLoading = state.loginStatus == AuthStatus.loading;
//         final signupLoading = state.signupStatus == AuthStatus.loading;

//         return Scaffold(
//           backgroundColor: const Color(0xFFF2F3F5),
//           body: Stack(
//             children: [
//               Positioned(
//                 top: 20,
//                 left: MediaQuery.of(context).size.width * 0.245,
//                 child: Center(
//                   child: Image.asset(
//                     "assets/logo_ams.png",
//                     height: 270,
//                     width: 270,
//                   ),
//                 ),
//               ),
//               WatermarkTiledSmall(tileScale: 25.0),
//               SafeArea(
//                 child: Center(
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: size.width < 380 ? 16 : 22,
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(28),
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//                         child: Container(
//                           width: double.infinity,
//                           padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.45),
//                             borderRadius: BorderRadius.circular(28),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.75),
//                               width: 1,
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.04),
//                                 blurRadius: 18,
//                                 offset: const Offset(0, 10),
//                               ),
//                             ],
//                           ),
//                           child: SingleChildScrollView(
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 _AuthToggle(
//                                   activeIndex: tab,
//                                   onChanged: (i) {
//                                     // reset validations/errors when switching
//                                     _loginFormKey.currentState?.reset();
//                                     _signupFormKey.currentState?.reset();
//                                     setState(() => tab = i);
//                                   },
//                                 ),
//                                 const SizedBox(height: 18),

//                                 // ---------------- LOGIN FORM ----------------
//                                 if (tab == 0)
//                                   Form(
//                                     key: _loginFormKey,
//                                     autovalidateMode:
//                                         AutovalidateMode.disabled,
//                                     child: Column(
//                                       children: [
//                                         _InputCard(
//                                           fieldKey:
//                                               const ValueKey('login_email'),
//                                           hint: 'Email',
//                                           icon: 'assets/email_icon.png',
//                                           controller: _loginEmailCtrl,
//                                           keyboardType:
//                                               TextInputType.emailAddress,
//                                           validator: _validateLoginEmail,
//                                         ),
//                                         const SizedBox(height: 12),
//                                         _InputCard(
//                                           fieldKey:
//                                               const ValueKey('login_password'),
//                                           hint: 'Password',
//                                           icon: 'assets/password_icon.png',
//                                           controller: _loginPassCtrl,
//                                           obscureText: _loginObscure,
//                                           onToggleObscure: () => setState(
//                                             () => _loginObscure =
//                                                 !_loginObscure,
//                                           ),
//                                           validator: _validateLoginPassword,
//                                         ),
//                                         const SizedBox(height: 7),
//                                         Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.end,
//                                           children: [
//                                             Padding(
//                                               padding: const EdgeInsets.only(
//                                                 left: 8.0,
//                                               ),
//                                               child: TextButton(
//                                                 onPressed: () {},
//                                                 child: const Text(
//                                                   'Forgot password',
//                                                   style: TextStyle(
//                                                     fontFamily:
//                                                         'ClashGrotesk',
//                                                     fontSize: 14.5,
//                                                     fontWeight:
//                                                         FontWeight.w700,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         SizedBox(
//                                           width: 160,
//                                           height: 40,
//                                           child: _PrimaryGradientButton(
//                                             text: loginLoading
//                                                 ? 'Please wait...'
//                                                 : 'Login'.toUpperCase(),
//                                             onPressed: loginLoading
//                                                 ? null
//                                                 : _submit,
//                                             loading: loginLoading,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 18),
//                                         _FooterSwitch(
//                                           prompt:
//                                               "Don’t have an account? ",
//                                           action: "Create an account",
//                                           onTap: () =>
//                                               setState(() => tab = 1),
//                                         ),
//                                       ],
//                                     ),
//                                   ),

//                                 // ---------------- SIGNUP FORM ----------------
//                                 if (tab == 1)
//                                   Form(
//                                     key: _signupFormKey,
//                                     autovalidateMode:
//                                         AutovalidateMode.disabled,
//                                     child: Column(
//                                       children: [
//                                         _InputCard(
//                                           fieldKey:
//                                               const ValueKey('signup_name'),
//                                           hint: 'Name',
//                                           icon: 'assets/name_icon.png',
//                                           controller: _nameCtrl,
//                                           validator: _validateName,
//                                         ),
//                                         const SizedBox(height: 12),
//                                         _InputCard(
//                                           fieldKey:
//                                               const ValueKey('signup_email'),
//                                           hint: 'Email Address',
//                                           icon: 'assets/email_icon.png',
//                                           controller: _signupEmailCtrl,
//                                           keyboardType:
//                                               TextInputType.emailAddress,
//                                           validator: _validateSignupEmail,
//                                         ),
//                                         const SizedBox(height: 12),
//                                         _InputCard(
//                                           fieldKey: const ValueKey(
//                                               'signup_password'),
//                                           hint: 'Password',
//                                           icon: 'assets/password_icon.png',
//                                           controller: _signupPassCtrl,
//                                           obscureText: _signupObscure,
//                                           onToggleObscure: () => setState(
//                                             () => _signupObscure =
//                                                 !_signupObscure,
//                                           ),
//                                           validator: _validateSignupPassword,
//                                         ),
//                                         const SizedBox(height: 12),
//                                         _InputCard(
//                                           fieldKey: const ValueKey(
//                                               'signup_confirm'),
//                                           hint: 'Confirm Password',
//                                           icon: 'assets/password_icon.png',
//                                           controller: _confirmCtrl,
//                                           obscureText: _confirmObscure,
//                                           onToggleObscure: () => setState(
//                                             () => _confirmObscure =
//                                                 !_confirmObscure,
//                                           ),
//                                           validator: _validateConfirm,
//                                         ),
//                                         const SizedBox(height: 12),
//                                         _PrimaryGradientButton(
//                                           text: signupLoading
//                                               ? 'Please wait...'
//                                               : 'SignUp',
//                                           onPressed: signupLoading
//                                               ? null
//                                               : _submit,
//                                           loading: signupLoading,
//                                         ),
//                                         const SizedBox(height: 18),
//                                         _FooterSwitch(
//                                           prompt:
//                                               "Already have an account? ",
//                                           action: "Login",
//                                           onTap: () =>
//                                               setState(() => tab = 0),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _AuthToggle extends StatelessWidget {
//   const _AuthToggle({required this.activeIndex, required this.onChanged});
//   final int activeIndex;
//   final ValueChanged<int> onChanged;

//   static const _grad = LinearGradient(
//     colors: [Color(0xFF0ED2F7), Color(0xFF7F53FD)],
//     begin: Alignment.centerLeft,
//     end: Alignment.centerRight,
//   );

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 48,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 16,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(2),
//               child: AnimatedContainer(
//                 height: 48,
//                 duration: const Duration(milliseconds: 220),
//                 decoration: BoxDecoration(
//                   gradient: activeIndex == 0 ? _grad : null,
//                   borderRadius: BorderRadius.circular(22),
//                 ),
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(22),
//                   onTap: () => onChanged(0),
//                   child: Center(
//                     child: Text(
//                       'Login',
//                       style: TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: activeIndex == 0
//                             ? Colors.white
//                             : const Color(0xFF0AA2FF),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(2),
//               child: AnimatedContainer(
//                 height: 48,
//                 duration: const Duration(milliseconds: 220),
//                 decoration: BoxDecoration(
//                   gradient: activeIndex == 1 ? _grad : null,
//                   borderRadius: BorderRadius.circular(22),
//                 ),
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(22),
//                   onTap: () => onChanged(1),
//                   child: Center(
//                     child: Text(
//                       'SignUp',
//                       style: TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontSize: 18,
//                         fontWeight: FontWeight.w500,
//                         color: activeIndex == 1
//                             ? Colors.white
//                             : const Color(0xFF0AA2FF),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _InputCard extends StatelessWidget {
//   const _InputCard({
//     required this.hint,
//     required this.icon,
//     this.controller,
//     this.keyboardType,
//     this.validator,
//     this.obscureText = false,
//     this.onToggleObscure,
//     this.fieldKey,
//   });

//   final String hint;
//   final String icon;
//   final TextEditingController? controller;
//   final TextInputType? keyboardType;
//   final String? Function(String?)? validator;
//   final bool obscureText;
//   final VoidCallback? onToggleObscure;
//   final Key? fieldKey; // Unique field key

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
//             icon,
//             height: 17,
//             width: 17,
//             color: const Color(0xFF1B1B1B),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: TextFormField(
//               key: fieldKey,
//               style: const TextStyle(
//                 fontFamily: 'ClashGrotesk',
//                 color: Colors.black,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 letterSpacing: 1,
//               ),
//               controller: controller,
//               keyboardType: keyboardType,
//               validator: validator,
//               obscureText: obscureText,
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
//           if (onToggleObscure != null)
//             IconButton(
//               onPressed: onToggleObscure,
//               icon: Icon(
//                 obscureText
//                     ? Icons.visibility_off_outlined
//                     : Icons.visibility_outlined,
//                 size: 22,
//                 color: const Color(0xFF1B1B1B),
//               ),
//             ),
//           const SizedBox(width: 6),
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

// class _BrandButton extends StatelessWidget {
//   const _BrandButton({
//     required this.label,
//     required this.asset,
//     required this.onTap,
//   });

//   final String label;
//   final String asset;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(22),
//       elevation: 4,
//       shadowColor: Colors.black.withOpacity(0.12),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(18),
//         child: SizedBox(
//           height: 48,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Image.asset(asset, height: 22, width: 22),
//               const SizedBox(width: 10),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   fontFamily: 'ClashGrotesk',
//                   fontSize: 16,
//                   color: Color(0xFF1B1B1B),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _FooterSwitch extends StatelessWidget {
//   const _FooterSwitch({
//     required this.prompt,
//     required this.action,
//     required this.onTap,
//   });

//   final String prompt;
//   final String action;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       alignment: WrapAlignment.center,
//       crossAxisAlignment: WrapCrossAlignment.center,
//       children: [
//         Text(
//           prompt,
//           style: const TextStyle(
//             fontFamily: 'ClashGrotesk',
//             fontSize: 14.5,
//             color: Color(0xFF1B1B1B),
//           ),
//         ),
//         GestureDetector(
//           onTap: onTap,
//           child: Text(
//             action,
//             style: const TextStyle(
//               fontFamily: 'ClashGrotesk',
//               fontSize: 14.5,
//               color: Color(0xFF1E9BFF),
//               decoration: TextDecoration.underline,
//               decorationThickness: 1.4,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class CenterLabelDivider extends StatelessWidget {
//   const CenterLabelDivider({
//     super.key,
//     required this.label,
//     this.lineColor = const Color(0xFFBDBDBD),
//     this.textColor = const Color(0xFF616161),
//     this.thickness = 1.0,
//     this.dotSize = 6.0,
//     this.gap = 10.0,
//     this.textStyle,
//   });

//   final String label;
//   final Color lineColor;
//   final Color textColor;
//   final double thickness;
//   final double dotSize;
//   final double gap;
//   final TextStyle? textStyle;

//   @override
//   Widget build(BuildContext context) {
//     final ts = textStyle ??
//         const TextStyle(
//           fontSize: 13.5,
//           fontWeight: FontWeight.w600,
//           color: Color(0xFF616161),
//           fontFamily: 'ClashGrotesk',
//         );

//     Widget dot() => Container(
//           width: dotSize,
//           height: dotSize,
//           decoration:
//               BoxDecoration(color: textColor, shape: BoxShape.circle),
//         );

//     return Row(
//       children: [
//         Expanded(
//           child: Divider(
//             color: lineColor,
//             thickness: thickness,
//             height: dotSize,
//           ),
//         ),
//         SizedBox(width: gap),
//         dot(),
//         const SizedBox(width: 8),
//         Text(label, style: ts),
//         const SizedBox(width: 8),
//         dot(),
//         SizedBox(width: gap),
//         Expanded(
//           child: Divider(
//             color: lineColor,
//             thickness: thickness,
//             height: dotSize,
//           ),
//         ),
//       ],
//     );
//   }
// }

