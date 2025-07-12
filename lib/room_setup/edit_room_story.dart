import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:scrum_poker/shared/models/enums.dart';
import 'package:scrum_poker/shared/models/jira_credentials.dart';
import 'package:scrum_poker/shared/models/jira_issue_response.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/router/go_router.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:scrum_poker/shared/widgets/hyperlink.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class EditRoomStory extends StatefulWidget {
  final Story? story;
  final FutureOr<void> Function() onDelete;
  final FutureOr<void> Function()? onMoveUp;
  final FutureOr<void> Function()? onMoveDown;
  final int nextOrder;
  final String roomId;
  final String userId;
  const EditRoomStory({super.key, this.story, required this.onDelete, this.onMoveUp, this.onMoveDown, required this.nextOrder, required this.userId, required this.roomId});

  @override
  State<EditRoomStory> createState() => _EditRoomStoryState();
}

class _EditRoomStoryState extends State<EditRoomStory> {
  final _menuKey = GlobalKey();
  final _searchController = SearchController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();

  late Story _story;
  bool _isEditing = false;
  bool _integratedWithJira = false;
  StoryType? _storyType;

  Timer? _debounce;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  // A completer to manage the asynchronous search results for the FutureBuilder
  // This completer is specifically for the *current* debounced search request.
  Completer<JiraIssueResponse?>? _searchCompleter;
  String _currentSearchQuery = '';
  String? _currentPageToken;
  final List<String?> _previousPageTokens = []; // To navigate "Previous"
  final int _pageSize = 20; // Number of items per page

  // ValueNotifier to hold and update the Future for FutureBuilder
  // This is what the ValueListenableBuilder will listen to.
  late ValueNotifier<Future<JiraIssueResponse?>> _suggestionsFutureNotifier;

  Box? _box;
  String? _jiraUrl;
  String? _storyPointFieldName;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _story =
        widget.story ??
        Story(id: const Uuid().v4(), description: '', status: StoryStatus.notStarted, added: true, order: widget.nextOrder, userId: widget.userId, roomId: widget.roomId);
    _isEditing = (widget.story?.added ?? false) || widget.story == null;

    _descriptionController.text = _story.description;
    _searchController.value = _descriptionController.value;
    _urlController.text = _story.url ?? '';
    _storyType = _story.storyType;

    _integratedWithJira = JiraCredentialsManager().currentCredentials != null;

    // Initialize the notifier with a future that will be updated by _debouncedSearchInJira
    // or by the pagination buttons. Initially, perform a search based on the current text.
    _suggestionsFutureNotifier = ValueNotifier(_performJiraSearch(_searchController.text, nextPageToken: _currentPageToken, maxResults: _pageSize));

    // Listen to changes in the search controller to trigger debounced searches
    _searchController.addListener(_onSearchControllerTextChanged);

    initialise();

    super.initState();
  }

  Future<void> initialise() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox('ScrumPoker');
    }

    setState(() {
      _jiraUrl = _box!.get('jiraUrl') ?? '';
      _storyPointFieldName = _box!.get('storyPointFieldName');
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchControllerTextChanged); // IMPORTANT: remove listener
    _searchController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();

    _debounce?.cancel();
    if (_searchCompleter != null && !_searchCompleter!.isCompleted) {
      _searchCompleter!.complete(null); // Complete any pending completer on dispose
    }
    _suggestionsFutureNotifier.dispose();

    super.dispose();
  }

  void edit() {
    _descriptionController.text = _story.description;
    _urlController.text = _story.url ?? '';
    setState(() {
      _isEditing = true;
    });
  }

  Future<JiraIssueResponse?> _performJiraSearch(String value, {String? nextPageToken, int maxResults = 50}) async {
    if (value.isEmpty) {
      return null;
    }

    try {
      final response = await JiraServices().searchIssues(
        query: '(summary ~ "$value*" OR key = "$value") AND issuetype in ("Story", "Bug") AND statusCategory not in ("Done", "In Progress") order by key',
        fields: [if (_storyPointFieldName != null) '$_storyPointFieldName', '-comment', 'summary', 'statusCategory', 'issuetype'],
        nextPageToken: nextPageToken,
        maxResults: maxResults,
      );

      if (response.success) {
        return response.data!;
      } else if (response.message != null && response.message!.isNotEmpty) {
        snackbarMessenger(navigatorKey.currentContext!, message: response.message!, type: SnackBarType.error);
      }
      return null;
    } catch (e) {
      snackbarMessenger(navigatorKey.currentContext!, message: 'Error fetching Jira issues: $e', type: SnackBarType.error);
      return null;
    }
  }

  void _onSearchControllerTextChanged() {
    // Only trigger a new debounced search if the search view is active
    // and the text has actually changed (to prevent unnecessary calls on e.g. focus)
    if (_searchController.isOpen && _searchController.text != _currentSearchQuery) {
      _debouncedSearchInJira(_searchController.text);
    }
  }

  // This method will be called by the `_onSearchControllerTextChanged` and pagination.
  // It triggers the actual search with debouncing.
  Future<JiraIssueResponse?> _debouncedSearchInJira(String value) {
    // If the query has changed, reset the page to the first page
    if (_currentSearchQuery != value) {
      _currentPageToken = null; // Start from the first page
      _previousPageTokens.clear(); // Clear history
      _currentSearchQuery = value;
    }

    // Cancel the previous debounce timer if it exists
    _debounce?.cancel();

    // If there's an active completer from a previous search, complete it with null
    // to prevent it from resolving later with outdated data.
    if (_searchCompleter != null && !_searchCompleter!.isCompleted) {
      _searchCompleter!.complete(null);
    }

    // Create a new completer for this search request
    _searchCompleter = Completer<JiraIssueResponse?>();

    // Start a new debounce timer
    _debounce = Timer(_debounceDuration, () async {
      final result = await _performJiraSearch(value, nextPageToken: _currentPageToken, maxResults: _pageSize);
      if (!_searchCompleter!.isCompleted) {
        // Only complete if not already completed (e.g., by a new search)
        _searchCompleter!.complete(result);
      }
      // Update the ValueNotifier with the new future.
      // This will cause the ValueListenableBuilder in the suggestionsBuilder to rebuild.
      _suggestionsFutureNotifier.value = Future.value(result);
    });

    return _searchCompleter!.future; // This future is what the completer will resolve
  }

  // Function to navigate to the previous page
  void _goToPreviousPage() {
    setState(() {
      if (_previousPageTokens.isNotEmpty) {
        _currentPageToken = _previousPageTokens.removeLast(); // Get the token for the *previous* page
      } else {
        _currentPageToken = null; // Go back to the very first page if no history
      }
      // Directly trigger a search for the new page and update the notifier
      _suggestionsFutureNotifier.value = _performJiraSearch(_currentSearchQuery, nextPageToken: _currentPageToken, maxResults: _pageSize);
    });
  }

  // Function to navigate to the next page
  void _goToNextPage(String? currentNextPageToken) {
    if (currentNextPageToken == null) return;
    setState(() {
      _previousPageTokens.add(currentNextPageToken);
      _currentPageToken = currentNextPageToken;
      // Directly trigger a search for the new page and update the notifier
      _suggestionsFutureNotifier.value = _performJiraSearch(_currentSearchQuery, nextPageToken: _currentPageToken, maxResults: _pageSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: _isEditing ? Colors.white : Colors.blueAccent,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 5, blurRadius: 7, offset: const Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                spacing: 10,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditing) ...[
                    Row(
                      spacing: 5,
                      children: [
                        if (_story.storyType?.icon != null) Icon(_story.storyType!.icon, color: _story.storyType!.color),
                        Text(_story.description, style: theme.textTheme.headlineLarge!.copyWith(color: Colors.white)),
                      ],
                    ),

                    if (_story.url != null)
                      Hyperlink(
                        text: widget.story!.url!,
                        textColor: Colors.white,
                        hyperlinkColor: Colors.white,
                        onTap: () async {
                          final Uri uri = Uri.parse(widget.story!.url!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            throw 'Could not launch ${widget.story!.url!}';
                          }
                        },
                      ),
                  ],
                  if (_isEditing) ...[
                    _integratedWithJira
                        ? SearchViewTheme(
                          data: SearchViewThemeData(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: Colors.grey.shade50,
                            dividerColor: Colors.blueGrey.shade200,
                            headerHeight: 46,
                            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4, minWidth: 360),
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
                              searchController: _searchController,
                              barHintText: 'Story title',
                              barBackgroundColor: WidgetStateProperty.all(Colors.grey.shade50),
                              barOverlayColor: WidgetStateProperty.all(Colors.transparent),
                              barLeading: const Icon(Icons.search),
                              barTrailing: [],
                              constraints: const BoxConstraints(minHeight: 46),
                              suggestionsBuilder: (context, controller) {
                                return [
                                  ValueListenableBuilder<Future<JiraIssueResponse?>>(
                                    valueListenable: _suggestionsFutureNotifier,
                                    builder: (context, currentFuture, child) {
                                      return FutureBuilder<JiraIssueResponse?>(
                                        future: currentFuture, // This is the future we're listening to
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const ListTile(title: Text('Loading...'));
                                          } else if (snapshot.hasError) {
                                            return ListTile(title: Text('Error: ${snapshot.error}'));
                                          } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.issues.isEmpty) {
                                            return Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(height: MediaQuery.of(context).size.height * 0.4 - 100, child: const ListTile(title: Text('No results found'))),

                                                _buildPaginationControls(snapshot.data?.nextPageToken),
                                              ],
                                            );
                                          }

                                          final anyHasType = snapshot.data!.issues.any((t) => t.fields!.issueType != null);
                                          final nextPageToken = snapshot.data!.nextPageToken;

                                          final storyList =
                                              snapshot.data!.issues
                                                  .map(
                                                    (t) => Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      child: ListTile(
                                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                        leading:
                                                            !anyHasType
                                                                ? null
                                                                : t.fields!.issueType?.name == 'Bug'
                                                                ? const Icon(Icons.bug_report_outlined, color: Colors.red)
                                                                : t.fields!.issueType?.name == 'Story'
                                                                ? const Icon(Icons.turned_in_not_outlined, color: Colors.green)
                                                                : const SizedBox(width: 24),
                                                        title: Text('${t.id} - ${t.fields!.summary}'),
                                                        trailing: t.storyPoints != null ? Text('${t.storyPoints!}') : null,
                                                        onTap: () {
                                                          _descriptionController.text = '${t.id} - ${t.fields!.summary}';
                                                          if (_jiraUrl?.endsWith('/') == true) {
                                                            _jiraUrl = _jiraUrl!.substring(0, _jiraUrl!.length - 1);
                                                          }
                                                          if (_jiraUrl != null && _jiraUrl!.isNotEmpty) {
                                                            _urlController.text = '$_jiraUrl/${t.key}';
                                                          }

                                                          setState(() {
                                                            _storyType =
                                                                !anyHasType
                                                                    ? null
                                                                    : t.fields!.issueType?.name == 'Bug'
                                                                    ? StoryType.bug
                                                                    : t.fields!.issueType?.name == 'Story'
                                                                    ? StoryType.workItem
                                                                    : StoryType.others;
                                                          });
                                                          controller.closeView('${t.id} - ${t.fields!.summary}');
                                                        },
                                                      ),
                                                    ),
                                                  )
                                                  .toList();

                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: MediaQuery.of(context).size.height * 0.4 - 100,
                                                child: SingleChildScrollView(
                                                  child: Column(mainAxisSize: MainAxisSize.min, children: [Flexible(child: ListView(shrinkWrap: true, children: storyList))]),
                                                ),
                                              ),
                                              _buildPaginationControls(nextPageToken),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ];
                              },
                              onClose: () {
                                if (_searchController.text.isEmpty) {
                                  _descriptionController.text = '';
                                  _urlController.text = '';
                                  setState(() {
                                    _storyType = null;
                                  });
                                }
                              },
                            ),
                          ),
                        )
                        : TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Story title',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.text,
                          validator:
                              _integratedWithJira
                                  ? (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Invalid story description';
                                    }
                                    return null;
                                  }
                                  : null,
                        ),
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'Story URL',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value != null && !Uri.parse(value).isAbsolute) {
                          return 'Invalid URL';
                        }
                        return null;
                      },
                    ),
                    if (_integratedWithJira)
                      DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<StoryType>(
                          decoration: InputDecoration(
                            labelText: 'Story type',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.blueGrey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          value: _storyType,
                          items:
                              StoryType.values
                                  .map((t) => DropdownMenuItem<StoryType>(value: t, child: Row(children: [if (t.icon != null) Icon(t.icon, color: t.color), Text(t.description)])))
                                  .toList(),
                          onChanged: (v) {
                            setState(() {
                              _storyType = v;
                            });
                          },
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            elevation: 5,
                          ),
                          child: const Text('Update'),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _story.description = _descriptionController.value.text;
                              _story.url = _urlController.value.text;
                              _story.added = false;
                              _story.storyType = _storyType;
                              setState(() {
                                _isEditing = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            elevation: 5,
                          ),
                          child: const Text('Cancel'),
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!_isEditing)
              IconButton(
                key: _menuKey,
                onPressed: () {
                  RenderBox box = _menuKey.currentContext!.findRenderObject() as RenderBox;
                  Offset position = box.localToGlobal(Offset.zero);
                  showMenu(
                    context: context,
                    items: [
                      PopupMenuItem(onTap: edit, child: const Row(children: [Icon(Icons.edit, color: Colors.blueAccent), SizedBox(width: 5), Text('Edit')])),
                      PopupMenuItem(onTap: widget.onDelete, child: const Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 5), Text('Delete')])),
                      if (widget.onMoveUp != null)
                        PopupMenuItem(
                          onTap: widget.onMoveUp,
                          child: const Row(children: [Icon(Icons.move_up_outlined, color: Colors.blueAccent), SizedBox(width: 5), Text('Move up')]),
                        ),
                      if (widget.onMoveDown != null)
                        PopupMenuItem(
                          onTap: widget.onMoveDown,
                          child: const Row(children: [Icon(Icons.move_down_outlined, color: Colors.blueAccent), SizedBox(width: 5), Text('Move down')]),
                        ),
                    ],
                    position: RelativeRect.fromLTRB(position.dx - 60, position.dy + 40, position.dx, position.dy),
                  );
                },
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to build pagination controls
  Widget _buildPaginationControls(String? currentNextPageToken) {
    final bool canGoPrevious = _previousPageTokens.isNotEmpty;
    final bool canGoNext = currentNextPageToken != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: canGoPrevious ? _goToPreviousPage : null, child: Text('Previous', style: TextStyle(color: canGoPrevious ? Colors.blue : Colors.grey))),
          TextButton(onPressed: canGoNext ? () => _goToNextPage(currentNextPageToken) : null, child: Text('Next', style: TextStyle(color: canGoNext ? Colors.blue : Colors.grey))),
        ],
      ),
    );
  }
}
