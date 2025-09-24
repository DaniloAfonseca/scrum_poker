import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrum_poker/shared/managers/settings_manager.dart';
import 'package:scrum_poker/shared/models/jira_issue_response.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:scrum_poker/shared/widgets/snack_bar.dart';

class EditRoomStoryJiraSearch extends StatefulWidget {
  final String currentValue;
  final void Function({JiraIssue? jiraIssue, bool? hasAnyType, String? customText}) onSelectedChanged;
  const EditRoomStoryJiraSearch({super.key, required this.currentValue, required this.onSelectedChanged});

  @override
  State<EditRoomStoryJiraSearch> createState() => _EditRoomStoryJiraSearchState();
}

class _EditRoomStoryJiraSearchState extends State<EditRoomStoryJiraSearch> {
  final _searchController = SearchController();
  late ValueNotifier<Future<JiraIssueResponse?>> _suggestionsFutureNotifier;
  final searching = ValueNotifier<bool>(false);

  var hasAnyType = false;
  JiraIssue? jiraIssue;

  // A completer to manage the asynchronous search results for the FutureBuilder
  // This completer is specifically for the *current* debounced search request.
  Completer<JiraIssueResponse?>? _searchCompleter;

  final List<String?> _previousPageTokens = []; // To navigate "Previous"
  final int _pageSize = 20; // Number of items per page
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  Timer? _debounce;
  String _currentSearchValue = '';
  String? _currentPageToken;

  String? _storyPointFieldName;

  @override
  void initState() {
    _storyPointFieldName = SettingsManager().storyPointFieldName;

    // Initialize the notifier with a future that will be updated by _debouncedSearchInJira
    // or by the pagination buttons. Initially, perform a search based on the current text.
    _suggestionsFutureNotifier = ValueNotifier(_performJiraSearch(_searchController.text, nextPageToken: _currentPageToken, maxResults: _pageSize));

    // Listen to changes in the search controller to trigger debounced searches
    _searchController.addListener(_onSearchControllerTextChanged);

    _searchController.text = widget.currentValue;
    super.initState();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchControllerTextChanged); // IMPORTANT: remove listener
    _searchController.dispose();

    _debounce?.cancel();
    if (_searchCompleter != null && !_searchCompleter!.isCompleted) {
      _searchCompleter!.complete(null); // Complete any pending completer on dispose
    }
    _suggestionsFutureNotifier.dispose();

    super.dispose();
  }

  void _onSearchControllerTextChanged() {
    // Only trigger a new debounced search if the search view is active
    // and the text has actually changed (to prevent unnecessary calls on e.g. focus)
    if (_searchController.isOpen && _searchController.text != _currentSearchValue) {
      _debouncedSearchInJira(_searchController.text);
    }
  }

  // This method will be called by the `_onSearchControllerTextChanged` and pagination.
  // It triggers the actual search with debouncing.
  Future<JiraIssueResponse?> _debouncedSearchInJira(String value) {
    // If the query has changed, reset the page to the first page
    if (_currentSearchValue != value) {
      _currentPageToken = null; // Start from the first page
      _previousPageTokens.clear(); // Clear history
      _currentSearchValue = value;
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
      setState(() {
        searching.value = true;
      });

      final result = await _performJiraSearch(value, nextPageToken: _currentPageToken, maxResults: _pageSize);
      if (!_searchCompleter!.isCompleted) {
        // Only complete if not already completed (e.g., by a new search)
        _searchCompleter!.complete(result);
      }
      // Update the ValueNotifier with the new future.
      // This will cause the ValueListenableBuilder in the suggestionsBuilder to rebuild.
      _suggestionsFutureNotifier.value = Future.value(result);
      setState(() {
        searching.value = false;
      });
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
      setState(() {
        searching.value = true;
      });
      // Directly trigger a search for the new page and update the notifier
      _suggestionsFutureNotifier.value = _performJiraSearch(_currentSearchValue, nextPageToken: _currentPageToken, maxResults: _pageSize);
      setState(() {
        searching.value = false;
      });
    });
  }

  // Function to navigate to the next page
  void _goToNextPage(String? currentNextPageToken) {
    if (currentNextPageToken == null) return;
    setState(() {
      _previousPageTokens.add(currentNextPageToken);
      _currentPageToken = currentNextPageToken;
      setState(() {
        searching.value = true;
      });
      // Directly trigger a search for the new page and update the notifier
      _suggestionsFutureNotifier.value = _performJiraSearch(_currentSearchValue, nextPageToken: _currentPageToken, maxResults: _pageSize);
      setState(() {
        searching.value = false;
      });
    });
  }

  Future<JiraIssueResponse?> _performJiraSearch(String value, {String? nextPageToken, int maxResults = 50}) async {
    if (value.isEmpty) {
      return null;
    }

    value = value.replaceAll('"', '');

    try {
      final response = await JiraServices().searchIssues(
        query: '(summary ~ "${value.replaceAll('-', ' ')}*" OR key = "$value") AND issuetype in ("Story", "Bug") AND statusCategory not in ("Done", "In Progress") order by key',
        fields: [if (_storyPointFieldName != null) '$_storyPointFieldName', '-comment', 'summary', 'statusCategory', 'issuetype'],
        nextPageToken: nextPageToken,
        maxResults: maxResults,
      );

      if (response.success) {
        return response.data!;
      } else if (response.message != null && response.message!.isNotEmpty) {
        snackbarMessenger(message: response.message!, type: SnackBarType.error);
      }
      return null;
    } catch (e) {
      snackbarMessenger(message: 'Error fetching Jira issues: $e', type: SnackBarType.error);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SearchViewTheme(
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
          searchController: _searchController,
          barHintText: 'Story title',
          barOverlayColor: WidgetStateProperty.all(Colors.transparent),
          barLeading: const Icon(Icons.search),
          barTrailing: [],
          constraints: const BoxConstraints(minHeight: 46),
          suggestionsBuilder: (context, controller) {
            return [
              ValueListenableBuilder<bool>(
                valueListenable: searching,
                builder: (context, value, child) {
                  return ValueListenableBuilder<Future<JiraIssueResponse?>>(
                    valueListenable: _suggestionsFutureNotifier,
                    builder: (context, currentFuture, child) {
                      return FutureBuilder<JiraIssueResponse?>(
                        future: currentFuture, // This is the future we're listening to
                        builder: (context, snapshot) {
                          if (value || snapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(title: Text('Loading...'));
                          } else if (snapshot.hasError) {
                            return ListTile(title: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.issues.isEmpty) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.4 - 100,
                                  child: const ListTile(title: Text('No results found')),
                                ),

                                _buildPaginationControls(snapshot.data?.nextPageToken),
                              ],
                            );
                          }

                          final anyHasType = snapshot.data!.issues.any((t) => t.fields!.issueType != null);
                          final nextPageToken = snapshot.data!.nextPageToken;

                          final storyList = snapshot.data!.issues
                              .map(
                                (t) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),

                                    leading: !anyHasType
                                        ? null
                                        : t.fields!.issueType?.name == 'Bug'
                                        ? const Icon(Icons.bug_report_outlined, color: Colors.red)
                                        : t.fields!.issueType?.name == 'Story'
                                        ? const Icon(Icons.turned_in_not_outlined, color: Colors.green)
                                        : const SizedBox(width: 24),
                                    title: Row(
                                      spacing: 10,
                                      children: [
                                        Flexible(child: Text('${t.key} - ${t.fields!.summary}')),
                                        if (t.storyPoints != null)
                                          Tooltip(
                                            message: 'Story points',
                                            child: Container(
                                              color: theme.dividerColor,
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                              child: Text(t.storyPoints.toString(), style: theme.textTheme.bodyLarge!.copyWith(color: theme.primaryColor)),
                                            ),
                                          ),
                                      ],
                                    ),
                                    onTap: () {
                                      setState(() {
                                        jiraIssue = t;
                                        hasAnyType = anyHasType;
                                        controller.closeView('${t.fields!.summary}');
                                      });
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
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [Flexible(child: ListView(shrinkWrap: true, children: storyList))],
                                  ),
                                ),
                              ),
                              _buildPaginationControls(nextPageToken),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ];
          },
          onOpen: () {
            setState(() {
              jiraIssue = null;
              hasAnyType = false;
            });
          },
          onClose: () {
            widget.onSelectedChanged(jiraIssue: jiraIssue, hasAnyType: hasAnyType, customText: _searchController.text);
          },
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
          TextButton(
            onPressed: canGoPrevious ? _goToPreviousPage : null,
            child: Text('Previous', style: TextStyle(color: canGoPrevious ? Colors.blue : Colors.grey)),
          ),
          TextButton(
            onPressed: canGoNext ? () => _goToNextPage(currentNextPageToken) : null,
            child: Text('Next', style: TextStyle(color: canGoNext ? Colors.blue : Colors.grey)),
          ),
        ],
      ),
    );
  }
}
