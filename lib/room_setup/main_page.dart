import 'dart:math';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/room_setup/user_room_widget.dart';
import 'package:scrum_poker/shared/models/user_room.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/services/auth_services.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

enum SortOrder { ascending, descending }

class _MainPageState extends State<MainPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool showDeleted = false;

  final List<bool> _selectedOrder = <bool>[true, false];

  @override
  void initState() {
    super.initState();

    // Redirect to login if not authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user == null) {
        context.go(Routes.login);
      }
    });
  }

  void signOut() {
    AuthServices().signOut().then((_) {
      navigatorKey.currentContext!.go(Routes.login);
    });
  }

  void sortToggle(index) {
    setState(() {
      // The button that is tapped is set to true, and the others to false.
      for (int i = 0; i < _selectedOrder.length; i++) {
        _selectedOrder[i] = i == index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        actionsPadding: const EdgeInsets.only(right: 16.0),
        title: Text('Scrum Poker', style: theme.textTheme.displayMedium),
        actions: [
          CircleAvatar(
            backgroundImage: user!.photoURL != null ? NetworkImage(user!.photoURL!, headers: {'Access-Control-Allow-Origin': '*'}) : null,
            child: user!.photoURL == null ? IconButton(icon: Icon(Icons.person_outline, color: Colors.white), onPressed: signOut) : InkWell(onTap: signOut),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          var rooms = snapshot.data!.docs.map((t) => UserRoom.fromJson(t.data())).toList();

          if (!showDeleted) {
            rooms = rooms.where((t) => t.dateDeleted == null).toList();
          }

          if (_selectedOrder[0]) {
            rooms.sort((a, b) => a.dateAdded!.compareTo(b.dateAdded!));
          } else {
            rooms.sort((a, b) => b.dateAdded!.compareTo(a.dateAdded!));
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ToggleButtons(
                      isSelected: _selectedOrder,
                      borderRadius: BorderRadius.circular(6),
                      onPressed: sortToggle,
                      children: [
                        Tooltip(message: 'Sort by earliest date', child: Transform.rotate(origin: Offset(-3, -3), angle: -0.5 * pi, child: Icon(Icons.arrow_back_ios))),
                        Tooltip(message: 'Sort by latest date', child: Transform.rotate(origin: Offset(-3, 1), angle: 0.5 * pi, child: Icon(Icons.arrow_back_ios))),
                      ],
                    ),
                    Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedToggleSwitch<bool>.dual(
                          current: showDeleted,
                          first: false,
                          second: true,
                          spacing: 70.0,
                          indicatorSize: Size(22, 22),
                          animationDuration: const Duration(milliseconds: 600),
                          style: const ToggleStyle(borderColor: Colors.transparent, indicatorColor: Colors.white, backgroundColor: Colors.black),
                          customStyleBuilder: (context, local, global) {
                            if (global.position <= 0.0) {
                              return ToggleStyle(backgroundColor: Colors.red);
                            }
                            return ToggleStyle(
                              backgroundGradient: LinearGradient(
                                colors: [Colors.blue[600]!, Colors.red],
                                stops: [global.position - (1 - 2 * max(0, global.position - 0.5)) * 0.7, global.position + max(0, 2 * (global.position - 0.5)) * 0.7],
                              ),
                            );
                          },
                          borderWidth: 5.0,
                          height: 32.0,
                          //loadingIconBuilder: (context, global) => CupertinoActivityIndicator(color: Color.lerp(Colors.red[800], green, global.position)),
                          onChanged: (b) => setState(() => showDeleted = b),
                          // iconBuilder:
                          //     (value) =>
                          //         value ? const Icon(Icons.power_outlined, color: Colors.green, size: 32.0) : Icon(Icons.power_settings_new_rounded, color: Colors.red[800], size: 32.0),
                          textBuilder:
                              (value) =>
                                  value
                                      ? Center(child: Text('All', style: theme.textTheme.labelLarge!.copyWith(color: Colors.white)))
                                      : Center(child: Text('Not deleted', style: theme.textTheme.labelLarge!.copyWith(color: Colors.white))),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            elevation: 5,
                          ),
                          onPressed: () {
                            context.go(Routes.editRoom);
                          },
                          child: Text('Add Room'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (user != null)
                  SingleChildScrollView(
                    key: ValueKey(_selectedOrder[0]),
                    child: Column(spacing: 10, children: rooms.map((room) => UserRoomWidget(key: ValueKey(room), userRoom: room, deletedChanged: () => setState(() {}))).toList()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
