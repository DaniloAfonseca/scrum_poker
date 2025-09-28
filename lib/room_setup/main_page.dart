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
import 'package:scrum_poker/shared/widgets/bottom_bar.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

enum SortOrder { ascending, descending }

class _MainPageState extends State<MainPage> {
  final _user = FirebaseAuth.instance.currentUser;

  bool _showDeleted = false;
  bool _showClosed = false;

  bool _hasDeleted = true;
  bool _hasClosed = true;

  final List<bool> _selectedOrder = <bool>[true, false];

  @override
  void initState() {
    FirebaseFirestore.instance.collection('users').doc(_user!.uid).collection('rooms').where('isDeleted', isEqualTo: true).limit(1).snapshots().listen(_onHasDeletedRoomsData);
    FirebaseFirestore.instance.collection('users').doc(_user.uid).collection('rooms').where('status', isEqualTo: 'closed').limit(1).snapshots().listen(_onHasClosedRoomsData);

    _checkFlags();
    super.initState();

    // Redirect to login if not authenticated
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   if (_user == null) {
    //     context.go(Routes.login);
    //     return;
    //   }
    // });
  }

  /// Sets hasDeleted and hasClosed flags
  void _checkFlags() {
    setState(() {
      room_services.hasDeletedRooms(_user!.uid).then((v) => _hasDeleted = v);
      room_services.hasClosedRooms(_user.uid).then((v) => _hasClosed = v);
    });
  }

  /// Updates has deleted flag when the value changes in the database
  /// 
  /// [event] the event containing the data
  void _onHasDeletedRoomsData(QuerySnapshot<Map<String, dynamic>> event) {
    _hasDeleted = event.docs.isNotEmpty;
  }

  /// Updates has closed flag when the value changes in the database
  /// 
  /// [event] the event containing the data
  void _onHasClosedRoomsData(QuerySnapshot<Map<String, dynamic>> event) {
    _hasClosed = event.docs.isNotEmpty;
  }

  /// Toggles sort
  /// 
  /// [index] the index used to set the order
  void _sortToggle(int index) {
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
        stream: !_showDeleted
            ? !_showClosed
                  ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user!.uid)
                        .collection('rooms')
                        .where('isDeleted', isEqualTo: false)
                        .where('status', whereIn: ['notStarted', 'started'])
                        .snapshots()
                  : FirebaseFirestore.instance.collection('users').doc(_user!.uid).collection('rooms').where('isDeleted', isEqualTo: false).snapshots()
            : !_showClosed
            ? FirebaseFirestore.instance.collection('users').doc(_user!.uid).collection('rooms').where('status', whereIn: ['notStarted', 'started']).snapshots()
            : FirebaseFirestore.instance.collection('users').doc(_user!.uid).collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var rooms = snapshot.data!.docs.map((t) => UserRoom.fromJson(t.data())).toList();

          //hasDeleted = rooms.any((t) => t.dateDeleted != null);
          // if (!showDeleted) {
          //   rooms = rooms.where((t) => t.dateDeleted == null).toList();
          // }

          //hasClosed = rooms.any((t) => t.status == RoomStatus.ended);
          // if (!showClosed) {
          //   rooms = rooms.where((t) => t.status != RoomStatus.ended).toList();
          // }

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
                      onPressed: _sortToggle,
                      children: [
                        Tooltip(
                          message: 'Sort by earliest date',
                          child: Transform.rotate(origin: const Offset(-3, -3), angle: -0.5 * pi, child: const Icon(Icons.arrow_back_ios)),
                        ),
                        Tooltip(
                          message: 'Sort by latest date',
                          child: Transform.rotate(origin: const Offset(-3, 1), angle: 0.5 * pi, child: const Icon(Icons.arrow_back_ios)),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: !_hasDeleted ? 'There\'s no deleted room' : '',
                          child: AnimatedToggleSwitch<bool>.dual(
                            current: _showDeleted,
                            first: false,
                            second: true,
                            active: _hasDeleted,
                            spacing: 95.0,
                            indicatorSize: const Size(22, 22),
                            animationDuration: const Duration(milliseconds: 600),
                            style: const ToggleStyle(borderColor: Colors.transparent, indicatorColor: Colors.white, backgroundColor: Colors.black),
                            customStyleBuilder: (context, local, global) {
                              if (global.position <= 0.0) {
                                return ToggleStyle(backgroundColor: _hasDeleted ? Colors.green : Colors.grey);
                              }
                              return ToggleStyle(
                                backgroundGradient: LinearGradient(
                                  colors: [Colors.red, Colors.green],
                                  stops: [global.position - (1 - 2 * max(0, global.position - 0.5)) * 0.7, global.position + max(0, 2 * (global.position - 0.5)) * 0.7],
                                ),
                              );
                            },
                            borderWidth: 5.0,
                            height: 32.0,
                            onChanged: _hasDeleted ? (b) => setState(() => _showDeleted = b) : null,
                            textBuilder: (value) => value
                                ? Center(
                                    child: Text('Include deleted', style: theme.textTheme.labelLarge!.copyWith(color: Colors.white)),
                                  )
                                : Center(
                                    child: Text('Not deleted', style: theme.textTheme.labelLarge!.copyWith(color: Colors.white)),
                                  ),
                          ),
                        ),
                        Tooltip(
                          message: !_hasClosed ? 'There\'s no closed room' : '',
                          child: AnimatedToggleSwitch<bool>.dual(
                            current: _showClosed,
                            first: false,
                            second: true,
                            active: _hasClosed,
                            spacing: 95.0,
                            indicatorSize: const Size(22, 22),
                            animationDuration: const Duration(milliseconds: 600),
                            style: const ToggleStyle(borderColor: Colors.transparent, indicatorColor: Colors.white, backgroundColor: Colors.black),
                            customStyleBuilder: (context, local, global) {
                              if (global.position <= 0.0) {
                                return ToggleStyle(backgroundColor: theme.primaryColor);
                              }
                              return ToggleStyle(
                                backgroundGradient: LinearGradient(
                                  colors: [Colors.red, theme.primaryColor],
                                  stops: [global.position - (1 - 2 * max(0, global.position - 0.5)) * 0.7, global.position + max(0, 2 * (global.position - 0.5)) * 0.7],
                                ),
                              );
                            },
                            borderWidth: 5.0,
                            height: 32.0,
                            onChanged: (b) => setState(() => _showClosed = b),
                            textBuilder: (value) => value
                                ? Center(
                                    child: Text('Include closed', style: theme.textTheme.labelLarge!.copyWith(color: Colors.white)),
                                  )
                                : Center(
                                    child: Text('Not closed', style: theme.textTheme.labelLarge!.copyWith(color: Colors.white)),
                                  ),
                          ),
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
                SingleChildScrollView(
                  key: ValueKey(_selectedOrder[0]),
                  child: Column(
                    spacing: 10,
                    children: rooms.map((room) => MainPageRoom(key: ValueKey(room), userRoom: room, deletedChanged: () => setState(() {}))).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: bottomBar(),
    );
  }
}
