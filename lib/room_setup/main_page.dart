import 'dart:math';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/room_setup/main_page_room.dart';
import 'package:scrum_poker/shared/models/user_room.dart';
import 'package:scrum_poker/shared/router/routes.dart';
import 'package:scrum_poker/shared/widgets/app_bar.dart';

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

  void sortToggle(int index) {
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
      appBar: const GiraffeAppBar(),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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
                        Tooltip(message: 'Sort by earliest date', child: Transform.rotate(origin: const Offset(-3, -3), angle: -0.5 * pi, child: const Icon(Icons.arrow_back_ios))),
                        Tooltip(message: 'Sort by latest date', child: Transform.rotate(origin: const Offset(-3, 1), angle: 0.5 * pi, child: const Icon(Icons.arrow_back_ios))),
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
                          indicatorSize: const Size(22, 22),
                          animationDuration: const Duration(milliseconds: 600),
                          style: const ToggleStyle(borderColor: Colors.transparent, indicatorColor: Colors.white, backgroundColor: Colors.black),
                          customStyleBuilder: (context, local, global) {
                            if (global.position <= 0.0) {
                              return const ToggleStyle(backgroundColor: Colors.red);
                            }
                            return ToggleStyle(
                              backgroundGradient: LinearGradient(
                                colors: [theme.primaryColor, Colors.red],
                                stops: [global.position - (1 - 2 * max(0, global.position - 0.5)) * 0.7, global.position + max(0, 2 * (global.position - 0.5)) * 0.7],
                              ),
                            );
                          },
                          borderWidth: 5.0,
                          height: 32.0,
                          onChanged: (b) => setState(() => showDeleted = b),
                          textBuilder:
                              (value) =>
                                  value
                                      ? Center(child: Text('All', style: theme.textTheme.labelLarge!.copyWith(color: Colors.white)))
                                      : Center(child: Text('Not deleted', style: theme.textTheme.labelLarge!.copyWith(color: Colors.white))),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            elevation: 5,
                          ),
                          onPressed: () {
                            context.go(Routes.editRoom);
                          },
                          child: const Text('Add Room'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (user != null)
                  SingleChildScrollView(
                    key: ValueKey(_selectedOrder[0]),
                    child: Column(spacing: 10, children: rooms.map((room) => MainPageRoom(key: ValueKey(room), userRoom: room, deletedChanged: () => setState(() {}))).toList()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
