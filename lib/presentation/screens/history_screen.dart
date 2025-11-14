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
                  // Swipe LEFT to delete (endActionPane)
                  endActionPane: ActionPane(
                    motion: const StretchMotion(),
                    extentRatio: 0.28,
                    children: [
                      CustomSlidableAction(
                        onPressed: (_) async {
                          await context.read<HistoryProvider>().deleteEntry(e);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Deleted')),
                            );
                          }
                        },
                        autoClose: true,
                        child: Container(
                          // Expand to the full height of the slidable
                          constraints: const BoxConstraints.expand(),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade400,
                                Colors.red.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_forever_rounded,
                                  color: Colors.white, size: 28),
                              SizedBox(height: 6),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
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
