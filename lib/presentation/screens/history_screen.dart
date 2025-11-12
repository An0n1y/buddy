import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:emotion_sense/presentation/providers/history_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:emotion_sense/presentation/screens/image_viewer_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: FutureBuilder(
        future: context.read<HistoryProvider>().ensureLoaded(),
        builder: (context, snapshot) {
          final provider = context.watch<HistoryProvider>();
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.entries.isEmpty) {
            return const Center(child: Text('No captures yet'));
          }
          return ListView.builder(
            itemCount: provider.entries.length,
            itemBuilder: (context, i) {
              final e = provider
                  .entries[provider.entries.length - 1 - i]; // newest first
              final dt = DateFormat('yyyy-MM-dd HH:mm').format(e.timestamp);
              final ageGender = e.ageGender == null
                  ? 'Age/Gender: —'
                  : '${e.ageGender!.ageRange}, ${e.ageGender!.gender} (${(e.ageGender!.confidence * 100).toInt()}%)';
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Slidable(
                  key: ValueKey(e.imagePath),
                  startActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.25,
                    children: [
                      SlidableAction(
                        onPressed: (_) async {
                          await context.read<HistoryProvider>().deleteEntry(e);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Deleted')),
                            );
                          }
                        },
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: Card(
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ImageViewerScreen(path: e.imagePath),
                          ),
                        );
                      },
                      leading: Image.file(
                        File(e.imagePath),
                        fit: BoxFit.cover,
                        width: 56,
                        height: 56,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported),
                      ),
                      title: Text(
                          '${e.emotion.name.toUpperCase()}  ${(e.confidence * 100).toInt()}%'),
                      subtitle: Text('$dt\n$ageGender'),
                      isThreeLine: true,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
