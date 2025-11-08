import 'package:flutter/material.dart';
import 'package:emotion_sense/data/models/age_gender_data.dart';

class AgeGenderCard extends StatelessWidget {
  const AgeGenderCard({super.key, required this.data});
  final AgeGenderData? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Not detected',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${data!.ageRange} yrs',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${data!.gender} • ${(data!.confidence * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
