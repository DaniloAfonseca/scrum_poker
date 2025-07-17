import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:scrum_poker/shared/models/vote_result.dart';

class VotingPieChart extends StatelessWidget {
  final List<VoteResult> results;

  const VotingPieChart({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = results.fold<int>(0, (sum, item) => sum + item.count);

    // update percentage and color
    for (final result in results) {
      result.percentage = (result.count / total) * 100;
      result.color = _generateColor(result.vote.label);
    }

    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: results.length == 1 ? 0 : 40,
              sections:
                  results.map((result) {
                    return PieChartSectionData(color: result.color, value: result.count.toDouble(), showTitle: false, radius: result.percentage);
                  }).toList(),
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: Column(
            spacing: 10,
            children:
                results
                    .map(
                      (result) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Row(
                            spacing: 5,
                            children: [
                              CircleAvatar(radius: 5, backgroundColor: result.color),
                              if (result.vote.icon != null) Icon(result.vote.icon, size: 12, color: theme.textTheme.bodySmall?.color),
                              if (result.vote.icon == null) Text(result.vote.label, style: theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            spacing: 5,
                            children: [
                              Text('${(result.percentage ?? 0).toInt()}%', style: theme.textTheme.bodySmall),
                              Text('(${result.count} vote${result.count == 1 ? '' : 's'})', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Color _generateColor(String label) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal, Colors.brown];
    return colors[label.hashCode % colors.length];
  }
}
