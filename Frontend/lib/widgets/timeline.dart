import 'package:flutter/material.dart';

class TimelineStep {
  final String title;
  final String date;
  final bool done;

  TimelineStep({required this.title, required this.date, this.done = false});
}

class TimelineWidget extends StatelessWidget {
  final List<TimelineStep> steps;

  const TimelineWidget({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: steps.map((step) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Icon(Icons.circle, color: step.done ? Colors.green : Colors.grey),
                Text(step.date, style: TextStyle(color: Colors.red)),
                Text(step.title, style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
