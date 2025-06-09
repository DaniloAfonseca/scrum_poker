import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/dashboard/user_room.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/user.dart' as u;
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  u.User? user;
  bool showDeleted = false;

  @override
  void initState() {
    super.initState();

    // Redirect to login if not authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (firebaseUser == null) {
        context.go(Routes.login);
      } else {
        loadUser();
      }
    });
  }

  Future<void> loadUser() async {
    final dbUser = await FirebaseFirestore.instance.collection('users').doc(firebaseUser!.uid).snapshots().first;
    setState(() {
      user = u.User(id: firebaseUser!.uid, name: dbUser['name'], rooms: (dbUser['rooms'] as List<dynamic>).map((e) => Room.fromJson(e as Map<String, dynamic>)).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        actionsPadding: const EdgeInsets.only(right: 16.0),
        title: user == null ? const CircularProgressIndicator(color: Colors.white) : Text('Welcome ${user?.name}', style: theme.textTheme.displayLarge),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: IconButton(
              icon: Icon(Icons.person_outline, color: Colors.white),
              onPressed: () {
                AuthServices().signOut().then((_) {
                  navigatorKey.currentContext!.go(Routes.login);
                });
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedToggleSwitch<String>.rolling(
                  current: showDeleted ? 'All' : 'Not deleted',
                  values: ['All', 'Not deleted'],
                  onChanged:
                      (value) => setState(() {
                        showDeleted = value == 'All';
                      }),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.go(Routes.editRoom, extra: {'user': user!});
                  },
                  child: Text('Add Room'),
                ),
              ],
            ),
            if (user != null) Expanded(child: ListView(children: user!.rooms.map((room) => UserRoom(user: user!, room: room)).toList())),
          ],
        ),
      ),
    );
  }
}
