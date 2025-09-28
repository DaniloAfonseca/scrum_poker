import 'dart:async';
import 'dart:math';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/managers/settings_manager.dart';
import 'package:scrum_poker/shared/models/jira_field.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:scrum_poker/shared/widgets/app_bar.dart';
import 'package:scrum_poker/shared/widgets/bottom_bar.dart';
import 'package:scrum_poker/shared/widgets/create_password.dart';
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';
import 'package:web/web.dart' as web;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _userNameController = TextEditingController();
  final _jiraUrlController = TextEditingController();
  final _fields = <JiraField>[];

  final SearchController _fieldSearchController = SearchController();
  bool _isLoadingFields = false;
  bool _showStoryPointsField = false;

  final _user = FirebaseAuth.instance.currentUser;
  final _settingsManager = SettingsManager();
  Timer? _debounce;
  bool _autoFlip = false;

  @override
  void initState() {
    _settingsManager.addListener(onSettingsChanged);
    initialise();
    super.initState();
  }

  @override
  void dispose() {
    _settingsManager.removeListener(onSettingsChanged);
    super.dispose();
  }

  /// listens for setting change
  void onSettingsChanged() {
    setState(() {
      if (_autoFlip != _settingsManager.autoFlip) {
        _autoFlip = _settingsManager.autoFlip;
        snackbarMessenger(message: 'Auto flip rooms is ${_autoFlip ? 'ON' : 'OFF'}');
      }
    });
  }

  Future<void> initialise() async {
    _userNameController.text = _user!.displayName ?? '';
    _jiraUrlController.text = _settingsManager.jiraUrl ?? '';
    _fields.clear();

    setState(() {
      _isLoadingFields = true;
      _showStoryPointsField = false;

      _autoFlip = _settingsManager.autoFlip;
    });

    try {
      final response = await JiraServices().getAllFields();
      if (response.success) {
        _fields.addAll(response.data!);
        _fields.sortBy((t) => t.name);
        final storyPointFieldName = _settingsManager.storyPointFieldName;
        setState(() {
          _fieldSearchController.text = _fields.firstWhereOrNull((t) => t.key == storyPointFieldName)?.name ?? '';
          _showStoryPointsField = true;
        });
      } else if (response.message != null && response.message!.isNotEmpty) {
        if (response.message == 'You don\'t have access token.') {
          snackbarMessenger(message: 'Please connect to jira to set story points field.', type: SnackBarType.error);
        } else {
          snackbarMessenger(message: response.message!, type: SnackBarType.error);
        }
      }
    } catch (e) {
      snackbarMessenger(message: e.toString(), type: SnackBarType.error);
    }

    setState(() {
      _isLoadingFields = false;
    });
  }

  Future<void> _updateUsername() async {
    if (_userNameController.text.isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    user!.updateDisplayName(_userNameController.text);

    snackbarMessenger(message: 'User name updated', type: SnackBarType.success);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GiraffeAppBar(
        onJiraConnection: (connected) {
          if (connected) {
            initialise();
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Hyperlink(text: 'Exit settings', onTap: () => web.window.history.back()),
              const SizedBox(height: 10),
              TextFormField(
                controller: _userNameController,
                onFieldSubmitted: (value) => _updateUsername(),
                decoration: const InputDecoration(
                  hintText: 'User name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'User name cannot be empty';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (_debounce?.isActive == true) {
                    _debounce?.cancel();
                  }
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    _updateUsername();
                    _debounce!.cancel();
                  });
                },
              ),

              const SizedBox(height: 10),
              const CreateNewPassword(),
              const SizedBox(height: 20),

              _isLoadingFields
                  ? const Center(child: CircularProgressIndicator())
                  : !_showStoryPointsField
                  ? const SizedBox.shrink()
                  : SearchViewTheme(
                      data: SearchViewThemeData(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: theme.canvasColor,
                        dividerColor: theme.dividerColor,
                        headerHeight: 46,
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4, minWidth: MediaQuery.of(context).size.width - 32), // Match width
                      ),
                      child: SearchBarTheme(
                        data: SearchBarThemeData(
                          hintStyle: WidgetStateProperty.all(theme.textTheme.bodyLarge!.copyWith(color: theme.textTheme.bodyLarge!.decorationColor)),
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
                          barBackgroundColor: WidgetStateProperty.all(theme.canvasColor),
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
                                  _settingsManager.updateSettingValue(SettingsValueEnum.storyPointsField, field.key); // Store the entire JiraField object (or just its ID)
                                },
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
              Tooltip(
                message: 'When auto-flip is turned on, players cards will flip when all players finish voting',
                child: AnimatedToggleSwitch<bool>.dual(
                  current: _autoFlip,
                  first: false,
                  second: true,
                  spacing: 120.0,
                  indicatorSize: const Size(22, 22),
                  animationDuration: const Duration(milliseconds: 600),
                  style: const ToggleStyle(borderColor: Colors.transparent, indicatorColor: Colors.white, backgroundColor: Colors.black),
                  customStyleBuilder: (context, local, global) {
                    if (global.position <= 0.0) {
                      return ToggleStyle(backgroundColor: theme.primaryColor);
                    }
                    if (global.position == 1) {
                      return const ToggleStyle(backgroundColor: Colors.green);
                    }
                    return ToggleStyle(
                      backgroundGradient: LinearGradient(
                        colors: [Colors.green, theme.primaryColor],
                        stops: [global.position - (1 - 2 * max(0, global.position - 0.5)) * 0.7, global.position + max(0, 2 * (global.position - 0.5)) * 0.7],
                      ),
                    );
                  },
                  borderWidth: 5.0,
                  height: 32.0,
                  onChanged: (b) => setState(() {
                    _autoFlip = b;
                    _settingsManager.updateSettingValue(SettingsValueEnum.autoFlip, _autoFlip);
                  }),
                  textBuilder: (value) => value
                      ? Center(
                          child: Text('Auto-flip', style: theme.textTheme.labelLarge!.copyWith(color: Colors.white)),
                        )
                      : Center(
                          child: Text('Do not auto-flip', style: theme.textTheme.labelLarge!.copyWith(color: Colors.white)),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: bottomBar(),
    );
  }
}
