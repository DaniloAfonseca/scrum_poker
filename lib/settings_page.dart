import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:scrum_poker/shared/models/jira_field.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:scrum_poker/shared/widgets/app_bar.dart';
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';
import 'package:web/web.dart' as web;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Box? _box;
  final _jiraUrlController = TextEditingController();
  final _fields = <JiraField>[];
  bool _loadingFields = false;
  JiraField? _storyPointField;

  @override
  void initState() {
    initialise();
    super.initState();
  }

  Future<void> initialise() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox('ScrumPoker');
    }

    _jiraUrlController.text = _box!.get('jiraUrl') ?? '';
    _fields.clear();

    setState(() {
      _loadingFields = true;
    });

    try {
      final response = await JiraServices().getAllFields();
      if (response.success) {
        _fields.addAll(response.data!);
        _fields.sortBy((t) => t.name);
        final storyPointFieldName = _box!.get('storyPointFieldName');
        setState(() {
          _storyPointField = _fields.firstWhereOrNull((t) => t.key == storyPointFieldName);
        });
      } else if (response.message != null && response.message!.isNotEmpty) {
        snackbarMessenger(navigatorKey.currentContext!, message: response.message!, type: SnackBarType.error);
      }
    } catch (e) {
      snackbarMessenger(navigatorKey.currentContext!, message: e.toString(), type: SnackBarType.error);
    }

    setState(() {
      _loadingFields = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GiraffeAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Hyperlink(text: 'Exit settings', textColor: Colors.blueAccent, onTap: () => web.window.history.back()),
            SizedBox(height: 10),
            Flexible(
              child: TextFormField(
                controller: _jiraUrlController,
                decoration: InputDecoration(
                  labelText: 'Jira URL',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  _box!.put('jiraUrl', value);
                },
              ),
            ),
            DropdownMenu<JiraField>(
              width: MediaQuery.of(context).size.width - 32,
              hintText: 'Story points field',
              enableSearch: false,
              dropdownMenuEntries: _fields.map((t) => DropdownMenuEntry<JiraField>(value: t, label: t.name)).toList(),
              // isDense: true,
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              // value: _storyPointField,
              // items: _fields.map((t) => DropdownMenuItem<JiraField>(value: t, child: Text(t.name))).toList(),
              onSelected: (value) {
                setState(() {
                  _storyPointField = value;
                });
                _box!.put('storyPointFieldName', value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
