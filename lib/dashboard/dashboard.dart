import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scrum_poker/dashboard/user_room.dart';
import 'package:scrum_poker/shared/models/room.dart';
import 'package:scrum_poker/shared/models/user.dart' as u;
import 'package:scrum_poker/shared/router/routes.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final auth = FirebaseAuth.instance;
  final user = u.User(email: 'danilo.afonseca@gmail.com', name: 'Danilo');
  final rooms = [Room(name: 'Room 1', dateAdded: DateTime.now(), id: '', stories: [])];

  @override
  void initState() {
    super.initState();

    // Redirect to login if not authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (auth.currentUser == null) {
        context.go(Routes.login);
      } else {
        context.go(Routes.room);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Text('Welcome ${user.name}', style: theme.textTheme.displayLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.go(Routes.editRoom);
                  },
                  child: Text('Add Room'),
                ),
              ],
            ),
            Expanded(child: ListView(children: rooms.map((room) => UserRoom(room: room)).toList())),
          ],
        ),
      ),
    );
  }
}
