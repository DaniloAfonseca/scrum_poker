import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrum_poker/shared/managers/settings_manager.dart';
import 'package:scrum_poker/shared/models/app_user.dart';
import 'package:scrum_poker/shared/models/story.dart';
import 'package:scrum_poker/shared/models/vote.dart';
import 'package:scrum_poker/shared/services/jira_services.dart';
import 'package:scrum_poker/shared/services/room_services.dart' as room_services;
import 'package:scrum_poker/shared/widgets/snack_bar.dart';
import 'package:scrum_poker/voting/story/voting_pie_chart.dart';
import 'package:scrum_poker/voting/story/voting_story_voted_cards.dart';

class VotingResults extends StatefulWidget {
  final AppUser? user;
  final List<Vote> votes;
  final Story currentStory;
  const VotingResults({super.key, required this.currentStory, required this.votes, this.user});

  @override
  State<VotingResults> createState() => _VotingResultsState();
}

class _VotingResultsState extends State<VotingResults> {
  String? _storyPointFieldName;
  final _formKey = GlobalKey<FormState>();
  final storyPointController = TextEditingController();

  @override
  void initState() {
    _storyPointFieldName = SettingsManager().storyPointFieldName;
    storyPointController.text = widget.currentStory.revisedEstimate?.toString() ?? widget.currentStory.estimate?.toString() ?? '';
    super.initState();
  }

  Future<void> updateStoryPoint(Story story) async {
    if (_formKey.currentState!.validate()) {
      story.revisedEstimate = double.parse(storyPointController.text);
      await room_services.updateRevisedEstimate(story);
      final response = await JiraServices().updateStoryPoints(story.jiraKey!, _storyPointFieldName!, story.revisedEstimate!);
      if (!response.success) {
        snackbarMessenger(message: response.message!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isLarge = mediaQuery.size.width > 900;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          spacing: 10,
          children: [
            if (isLarge)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: [
                  Expanded(
                    child: VotingStoryVotedCards(currentStory: widget.currentStory, votes: widget.votes),
                  ),
                  SizedBox(width: 350, child: getResults(theme)),
                ],
              ),
            if (!isLarge) ...[VotingStoryVotedCards(currentStory: widget.currentStory, votes: widget.votes), getResults(theme)],
            if (widget.user != null && _storyPointFieldName != null && _storyPointFieldName!.isNotEmpty)
              Form(
                key: _formKey,
                child: Row(
                  spacing: 10,
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextFormField(
                        controller: storyPointController,
                        decoration: const InputDecoration(label: Text('Update story points')),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please, introduce a value';
                          }
                          return null;
                        },
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        elevation: 5,
                      ),
                      onPressed: widget.currentStory.jiraKey == null
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                updateStoryPoint(widget.currentStory);
                              }
                            },
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget getResults(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: 400,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          decoration: BoxDecoration(
            border: Border.all(width: 2, color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            spacing: 10,
            children: [
              SizedBox(height: 40, child: Text('Results', style: theme.textTheme.headlineMedium)),
              Expanded(child: VotingPieChart(results: widget.currentStory.voteResults(widget.votes)!)),
              SizedBox(
                height: 40,
                child: Row(
                  spacing: 10,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${widget.votes.length} Players voted', style: theme.textTheme.headlineSmall),
                    Text('Avg: ${widget.currentStory.estimate}', style: theme.textTheme.headlineSmall),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
