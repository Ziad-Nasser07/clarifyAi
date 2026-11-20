import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../logic/research_cubit.dart';

class ResearchScreen extends StatefulWidget {
  final String libraryId;

  const ResearchScreen({super.key, required this.libraryId});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  final _topicController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cited Academic Research')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Research Topic (English or Arabic)',
                hintText: 'e.g., Applications of Dijkstra Algorithm in Computer Networks',
                prefixIcon: Icon(Icons.travel_explore),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                if (_topicController.text.trim().isEmpty) return;
                context.read<ResearchCubit>().searchTopic(
                  libraryId: widget.libraryId,
                  topic: _topicController.text.trim(),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Generate Cited Research'),
            ),
            const SizedBox(height: 20),
            BlocBuilder<ResearchCubit, ResearchState>(
              builder: (context, state) {
                if (state is ResearchLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (state is ResearchError) {
                  return Text(state.message, style: const TextStyle(color: Colors.red));
                } else if (state is ResearchSuccess) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Verified Research Summary',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: state.result.aiResponse));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Research copied to clipboard')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const Divider(),
                            MarkdownBody(data: state.result.aiResponse),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Verified Sources & References:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...state.result.sources.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final src = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                              foregroundColor: AppTheme.primary,
                              child: Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            title: Text(src['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(src['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.open_in_new, size: 18),
                            onTap: () => launchUrl(Uri.parse(src['url'] ?? '')),
                          ),
                        );
                      }),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }
}