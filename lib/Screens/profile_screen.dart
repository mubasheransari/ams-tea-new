import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:new_amst_flutter/Bloc/auth_bloc.dart';
import 'package:new_amst_flutter/Data/token_store.dart';
import 'package:new_amst_flutter/Screens/auth_screen.dart';
import 'package:new_amst_flutter/Screens/request_leave.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:new_amst_flutter/Screens/auth_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _bg = Color(0xFFF6F7FB);
  static const _title = Color(0xFF111111);
  static const _sub = Color(0xFF7D8790);
  static const _divider = Color(0xFFE9ECF2);

  static const _gradHeader = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _chipGrad = LinearGradient(
    colors: [Color(0xFF73D1FF), Color(0xFF6A7CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String _formatTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .toLowerCase()
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 390.0;

    // 🧠 Pull user info from AuthBloc (same pattern as Home header)
    final loginModel = context.select((AuthBloc b) => b.state.loginModel);
    final info = loginModel?.userinfo;

    final code = info?.code?.toString() ?? '--';
    final empName = _formatTitleCase(info?.empnam ?? 'User');
    final empFName = _formatTitleCase(info?.empfnam ?? '');
    final desName = _formatTitleCase(info?.desnam ?? '');
    final desCode = (info?.descod ?? '').toString();
    final depName = _formatTitleCase(info?.depnam ?? '');
    final phone = info?.phone ?? '';
    final phone2 = info?.phone2 ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 24 * s),
          children: [
            // ===== Title =====
            SizedBox(
              height: 44 * s,
              child: Center(
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontSize: 24 * s,
                    fontWeight: FontWeight.w700,
                    color: _title,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14 * s),

            // ===== Gradient Header Card (no avatar, no edit) =====
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16 * s),
              decoration: BoxDecoration(
                gradient: _gradHeader,
                borderRadius: BorderRadius.circular(18 * s),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7F53FD).withOpacity(0.22),
                    blurRadius: 18 * s,
                    offset: Offset(0, 10 * s),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    empName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'ClashGrotesk',
                      fontSize: 22 * s,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6 * s),

                  // Designation + department
                  if (desName.isNotEmpty)
                    Text(
                      desCode.isNotEmpty ? '$desName  •  $desCode' : desName,
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontSize: 14.5 * s,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                  if (depName.isNotEmpty) SizedBox(height: 2 * s),
                  if (depName.isNotEmpty)
                    Text(
                      depName.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontSize: 13.5 * s,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.90),
                      ),
                    ),

                  SizedBox(height: 14 * s),

                  Wrap(
                    spacing: 10 * s,
                    runSpacing: 8 * s,
                    children: [
                      _pill(
                        s: s,
                        icon: Icons.badge_rounded,
                        label: 'Employee Code',
                        value: code,
                      ),
                      if (empFName.isNotEmpty)
                        _pill(
                          s: s,
                          icon: Icons.person_outline_rounded,
                          label: 'Father Name',
                          value: empFName,
                        ),
                      if (phone.isNotEmpty)
                        _pill(
                          s: s,
                          icon: Icons.phone_rounded,
                          label: 'Phone',
                          value: phone,
                        ),
                      if (phone2.isNotEmpty)
                        _pill(
                          s: s,
                          icon: Icons.phone_android_rounded,
                          label: 'Alternate',
                          value: phone2,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 18 * s),
            _dividerLine(s),

            // ===== Menu rows =====
            // InkWell(
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => LeaveTypeDebugPage(),
            //       ),
            //     );
            //   },
            //   child: _menuRow(
            //     s: s,
            //     icon: Icons.receipt_long_outlined,
            //     label: 'Recent Report',
            //   ),
            // ),
            // _dividerLine(s),
            // _menuRow(
            //   s: s,
            //   icon: Icons.add_location_alt_outlined,
            //   label: 'Location',
            // ),
            _dividerLine(s),

            // Logout row (gradient icon)
            InkWell(
              onTap: () async {
                const _kLoginModelKey = 'login_model_json';
                var storage = GetStorage();
                storage.remove(_kLoginModelKey);
                await TokenStore().clear();
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              },
              child: _menuRow(s: s, label: 'Log out', gradientIcon: true),
            ),
            _dividerLine(s),
          ],
        ),
      ),
    );
  }

  // ===== Helpers =====

  static Widget _dividerLine(double s) => Container(height: 1, color: _divider);

  static Widget _menuRow({
    required double s,
    String label = '',
    IconData? icon,
    bool gradientIcon = false,
  }) {
    final leftIcon = gradientIcon
        ? Container(
            width: 24 * s,
            height: 24 * s,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: _chipGrad,
            ),
            child: Icon(
              Icons.logout_rounded,
              size: 14 * s,
              color: Colors.white,
            ),
          )
        : Icon(icon, size: 22 * s, color: _title);

    return SizedBox(
      height: 58 * s,
      child: Row(
        children: [
          leftIcon,
          SizedBox(width: 14 * s),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 16 * s,
                fontWeight: FontWeight.w600,
                color: _title,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 22 * s,
            color: Colors.black.withOpacity(.75),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required double s,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 8 * s),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.40), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14 * s, color: Colors.white),
          SizedBox(width: 6 * s),
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: 'ClashGrotesk',
              fontSize: 14.5 * s,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 11.5 * s,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




// class ProfilePage extends StatelessWidget {
//   const ProfilePage({super.key});

//   static const _bg = Color(0xFFF6F7FB);
//   static const _title = Color(0xFF111111);
//   static const _sub = Color(0xFF7D8790);
//   static const _divider = Color(0xFFE9ECF2);

//   static const _chipGrad = LinearGradient(
//     colors: [Color(0xFF73D1FF), Color(0xFF6A7CFF)],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );

//   @override
//   Widget build(BuildContext context) {
//     final s = MediaQuery.of(context).size.width / 390.0;

//     return Scaffold(
//       backgroundColor: _bg,
//       body: SafeArea(
//         child: ListView(
//           padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 24 * s),
//           children: [
//             SizedBox(
//               height: 44 * s,
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Text(
//                     'Profile',
//                     style: TextStyle(
//                       fontFamily: 'ClashGrotesk',
//                       fontSize: 20 * s,
//                       fontWeight: FontWeight.w700,
//                       color: _title,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 14 * s),

//             Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   width: 96 * s,
//                   height: 96 * s,
//                   child: Stack(
//                     children: [
//                       Container(
//                         width: 96 * s,
//                         height: 96 * s,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFFEDEFF3), Colors.white],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(.06),
//                               blurRadius: 16 * s,
//                               offset: Offset(0, 8 * s),
//                             ),
//                           ],
//                         ),
//                         child: Padding(
//                           padding: EdgeInsets.all(3 * s),
//                           child: ClipOval(
//                             child: Image.asset(
//                               'assets/avatar.png',
//                               fit: BoxFit.cover,
//                               width: 90 * s,
//                               height: 90 * s,
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         right: 4 * s,
//                         bottom: 4 * s,
//                         child: Container(
//                           width: 24 * s,
//                           height: 24 * s,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             shape: BoxShape.circle,
//                             border: Border.all(color: _divider),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(.08),
//                                 blurRadius: 8 * s,
//                                 offset: Offset(0, 3 * s),
//                               ),
//                             ],
//                           ),
//                           child: Icon(Icons.photo_camera_outlined,
//                               size: 14 * s, color: _title),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: 14 * s),
//                 // Name + handle + button
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                                 "Test User",  
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           fontFamily: 'ClashGrotesk',
//                           fontSize: 20 * s,
//                           fontWeight: FontWeight.w700,
//                           color: _title,
//                         ),
//                       ),
//                       SizedBox(height: 4 * s),
//                       Text(
//                         'testuser@yopmail.com',
//                         style: TextStyle(
//                           fontFamily: 'ClashGrotesk',
//                           fontSize: 14 * s,
//                           fontWeight: FontWeight.w600,
//                           color: _sub,
//                         ),
//                       ),
//                       SizedBox(height: 10 * s),
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Container(
//                           height: 40 * s,
//                           padding: EdgeInsets.symmetric(horizontal: 16 * s),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12 * s),
//                             gradient: _chipGrad,
//                             boxShadow: [
//                               BoxShadow(
//                                 color:
//                                     const Color(0xFF6A7CFF).withOpacity(.20),
//                                 blurRadius: 12 * s,
//                                 offset: Offset(0, 6 * s),
//                               ),
//                             ],
//                           ),
//                           alignment: Alignment.center,
//                           child: Text(
//                             'Edit Profile',
//                             style: TextStyle(
//                               fontFamily: 'ClashGrotesk',
//                               fontSize: 14.5 * s,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             SizedBox(height: 18 * s),
//             _dividerLine(s),


//             // ===== Menu rows (exact labels as in design)
//             // _menuRow(
//             //   s: s,
//             //   icon: Icons.engineering_outlined,
//             //   label: 'Sponsored vendors',
//             // ),
//            // _dividerLine(s),
//             InkWell(
//               onTap: (){
//                 Navigator.push(context, MaterialPageRoute(builder: (context)=> LeaveTypeDebugPage()));
//               },
//               child: _menuRow(
//                 s: s,
//                 icon: Icons.receipt_long_outlined,
//                 label: 'Recent Report',
//               ),
//             ),
//             _dividerLine(s),
//             _menuRow(
//               s: s,
//               icon: Icons.add_location_alt_outlined,
//               label: 'Location',
//             ),
//             // _dividerLine(s),
//             // _menuRow(
//             //   s: s,
//             //   icon: Icons.inventory_2_outlined,
//             //   label: 'Clear cashe', // keep spelling to match screenshot
//             // ),
//             _dividerLine(s),

//             // Logout row with gradient left icon
//             InkWell(
//               onTap: ()async{
//                 await TokenStore().clear();
//                 Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
//   MaterialPageRoute(builder: (_) => const AuthScreen()),
//   (route) => false,
// );
//               },
//               child: _menuRow(
//                 s: s,
//                 label: 'Log out',
//                 gradientIcon: true,
//               ),
//             ),
//             _dividerLine(s),
//           ],
//         ),
//       ),
//     );
//   }

//   static Widget _dividerLine(double s) => Container(
//         height: 1,
//         color: _divider,
//       );

//   static Widget _menuRow({
//     required double s,
//     String label = '',
//     IconData? icon,
//     bool gradientIcon = false,
//   }) {
//     final leftIcon = gradientIcon
//         ? Container(
//             width: 24 * s,
//             height: 24 * s,
//             decoration: const BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: _chipGrad,
//             ),
//             child: Icon(Icons.logout_rounded,
//                 size: 14 * s, color: Colors.white),
//           )
//         : Icon(icon, size: 22 * s, color: _title);

//     return SizedBox(
//       height: 58 * s,
//       child: Row(
//         children: [
//           leftIcon,
//           SizedBox(width: 14 * s),
//           Expanded(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontFamily: 'ClashGrotesk',
//                 fontSize: 16 * s,
//                 fontWeight: FontWeight.w600,
//                 color: _title,
//               ),
//             ),
//           ),
//           Icon(Icons.chevron_right_rounded,
//               size: 22 * s, color: Colors.black.withOpacity(.75)),
//         ],
//       ),
//     );
//   }
// }
