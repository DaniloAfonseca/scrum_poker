import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/shared/managers/settings_manager.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';
import 'package:scrum_poker/shared/managers/theme_manager.dart';

class GiraffeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final GestureTapCallback? onSignOut;
  final bool? loginIn;
  const GiraffeAppBar({super.key, this.onSignOut, this.loginIn = false});

  @override
  State<GiraffeAppBar> createState() => _GiraffeAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _GiraffeAppBarState extends State<GiraffeAppBar> {
  final _avatarKey = GlobalKey();

  final user = FirebaseAuth.instance.currentUser;
  late Future<String?> _avatar;

  @override
  void initState() {
    super.initState();
    _avatar = AvatarService().getAvatarUrl();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeManager = ThemeManager();
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      actionsPadding: const EdgeInsets.only(right: 16.0),
      title: widget.loginIn == true ? null : const Image(image: AssetImage('images/logo_giraffe_dark_mode.png'), fit: BoxFit.fitWidth, width: 100),
      actions: [
        IconButton(
          onPressed: () {
            themeManager.setThemeMode(themeManager.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
          },
          icon: Icon(themeManager.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          tooltip: themeManager.themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
        ),
        if (widget.loginIn != true) ...[
          const SizedBox(width: 10),
          user == null
              ? CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  key: _avatarKey,
                  child: IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white),
                    onPressed: () {
                      _showMenu(context);
                    },
                  ),
                )
              : FutureBuilder<String?>(
                  future: _avatar,
                  builder: (_, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircleAvatar(
                        key: _avatarKey,
                        child: CircularProgressIndicator(color: theme.primaryColor),
                      );
                    } else if (snapshot.hasError) {
                      return CircleAvatar(
                        backgroundColor: theme.primaryColor,
                        key: _avatarKey,
                        child: IconButton(
                          icon: const Icon(Icons.person_outline, color: Colors.white),
                          onPressed: () => _showMenu(context),
                        ),
                      );
                    } else if (snapshot.hasData && snapshot.data != null) {
                      return CircleAvatar(
                        backgroundColor: theme.primaryColor,
                        key: _avatarKey,
                        backgroundImage: NetworkImage(snapshot.data!),
                        child: InkWell(onTap: () => _showMenu(context)),
                      );
                    } else {
                      return CircleAvatar(
                        backgroundColor: theme.primaryColor,
                        key: _avatarKey,
                        child: IconButton(
                          icon: const Icon(Icons.person_outline, color: Colors.white),
                          onPressed: () {
                            _showMenu(context);
                          },
                        ),
                      );
                    }
                  },
                ),
        ],
      ],
    );
  }

  void _showMenu<T>(BuildContext context) {
    RenderBox box = _avatarKey.currentContext!.findRenderObject() as RenderBox;
    Offset position = box.localToGlobal(Offset.zero);
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx - 60, position.dy + 40, position.dx, position.dy),
      items: [
        PopupMenuItem(
          child: ListTile(leading: const Icon(Icons.logout_outlined), title: const Text('Sign Out'), onTap: signOut),
        ),
        if (user != null && widget.loginIn != true)
          PopupMenuItem(
            child: ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Settings'), onTap: () => navigatorKey.currentContext!.go(Routes.settings)),
          ),
      ],
    );
  }

  void signOut() async {
    SettingsManager().deleteAppUser();
    widget.onSignOut?.call();
    if (user != null) {
      AuthServices().signOut().then((_) {
        navigatorKey.currentContext!.go(Routes.login);
      });
    }
  }
}

class AvatarService {
  static final AvatarService _instance = AvatarService._internal();
  factory AvatarService() => _instance;

  AvatarService._internal();

  String? _avatarUrl;
  Future<String?>? _avatarUrlFuture;
  final user = FirebaseAuth.instance.currentUser;

  Future<String?> getAvatarUrl() async {
    if (_avatarUrl != null) return _avatarUrl;
    if (_avatarUrlFuture != null) return _avatarUrlFuture;

    _avatarUrlFuture = _fetchAvatarUrl();
    _avatarUrl = await _avatarUrlFuture;
    _avatarUrlFuture = null;
    return _avatarUrl;
  }

  Future<String?> _fetchAvatarUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      return null;
    }
    try {
      final avatarPath = user.email!.split('@');
      final ref = FirebaseStorage.instance.ref().child('avatars/${avatarPath[0]}_avatar.png');
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
