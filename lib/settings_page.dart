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

  final SearchController _fieldSearchController = SearchController();
  bool _isLoadingFields = false;

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
      _isLoadingFields = true;
    });

    try {
      final response = await JiraServices().getAllFields();
      if (response.success) {
        _fields.addAll(response.data!);
        _fields.sortBy((t) => t.name);
        final storyPointFieldName = _box!.get('storyPointFieldName');
        setState(() {
          _fieldSearchController.text = _fields.firstWhereOrNull((t) => t.key == storyPointFieldName)?.name ?? '';
        });
      } else if (response.message != null && response.message!.isNotEmpty) {
        snackbarMessenger(navigatorKey.currentContext!, message: response.message!, type: SnackBarType.error);
      }
    } catch (e) {
      snackbarMessenger(navigatorKey.currentContext!, message: e.toString(), type: SnackBarType.error);
    }

    setState(() {
      _isLoadingFields = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GiraffeAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Hyperlink(text: 'Exit settings', onTap: () => web.window.history.back()),
            SizedBox(height: 10),
            Flexible(
              child: TextFormField(
                controller: _jiraUrlController,
                decoration: InputDecoration(labelText: 'Jira URL'),
                onChanged: (value) {
                  _box!.put('jiraUrl', value);
                },
              ),
            ),
            _isLoadingFields
                ? const Center(child: CircularProgressIndicator())
                : SearchViewTheme(
                  data: SearchViewThemeData(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.grey.shade50,
                    dividerColor: Colors.blueGrey.shade200,
                    headerHeight: 46,
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4, minWidth: MediaQuery.of(context).size.width - 32), // Match width
                  ),
                  child: SearchBarTheme(
                    data: SearchBarThemeData(
                      hintStyle: WidgetStateProperty.all(theme.textTheme.bodyLarge!.copyWith(color: Colors.grey)),
                      backgroundColor: WidgetStateProperty.all(Colors.grey.shade50),
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      elevation: WidgetStateProperty.all(0),
                      side: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.focused)) {
                          return const BorderSide(color: Colors.blueAccent, width: 2.0);
                        }
                        return BorderSide(color: Colors.blueGrey.shade200);
                      }),
                    ),
                    child: SearchAnchor.bar(
                      searchController: _fieldSearchController,
                      barHintText: 'Search Story points field',
                      barBackgroundColor: WidgetStateProperty.all(Colors.grey.shade50),
                      barOverlayColor: WidgetStateProperty.all(Colors.transparent),
                      barLeading: const Icon(Icons.search),
                      barTrailing: [], // No trailing icon by default
                      constraints: const BoxConstraints(minHeight: 46),
                      suggestionsBuilder: (context, controller) {
                        final filteredFields = _fields.where((e) => e.name.toLowerCase().contains(controller.text.toLowerCase()));
                        if (filteredFields.isEmpty) {
                          return [const ListTile(title: Text('No matching fields found'))];
                        }
                        return filteredFields.map((field) {
                          return ListTile(
                            title: Text(field.name),
                            onTap: () {
                              _fieldSearchController.text = field.name; // Update text
                              // Close the search view and pass the selected value
                              controller.closeView(field.name);
                              _box!.put('storyPointFieldName', field.key); // Store the entire JiraField object (or just its ID)
                            },
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
