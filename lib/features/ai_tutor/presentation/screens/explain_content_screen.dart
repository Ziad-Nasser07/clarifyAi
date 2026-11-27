import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_helper.dart';
import '../../logic/ai_tutor_cubit.dart';

class ExplainContentScreen extends StatefulWidget {
  final String libraryId;

  const ExplainContentScreen({super.key, required this.libraryId});

  @override
  State<ExplainContentScreen> createState() => _ExplainContentScreenState();
}

class _ExplainContentScreenState extends State<ExplainContentScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  File? _selectedFile;
  String _preferredLang = 'en';

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await FileHelper.pickImage(source: source);
    if (file != null) {
      setState(() => _selectedFile = file as File);
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Content Tutor'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: DropdownButton<String>(
              value: _preferredLang,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
              onChanged: (val) => setState(() => _preferredLang = val ?? 'en'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 36, color: AppTheme.primary),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload Lecture Slide, Problem Photo, or PDF',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _UploadOptionButton(
                          icon: Icons.camera_alt_outlined,
                          label: 'Camera',
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                        _UploadOptionButton(
                          icon: Icons.image_outlined,
                          label: 'Gallery',
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                        _UploadOptionButton(
                          icon: Icons.picture_as_pdf_outlined,
                          label: 'PDF File',
                          onTap: _pickPdf,
                        ),
                      ],
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFile!.path.split('/').last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _selectedFile = null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Paste text or type a specific question about your attachment...',
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedFile == null && _textController.text.trim().isEmpty) return;
                  context.read<AiTutorCubit>().explain(
                    libraryId: widget.libraryId,
                    file: _selectedFile,
                    userText: _textController.text.trim(),
                    preferredLanguage: _preferredLang,
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Explain & Simplify'),
              ),
              const SizedBox(height: 20),
              BlocConsumer<AiTutorCubit, AiTutorState>(
                listener: (context, state) {
                  if (state is AiTutorExplained &&
                      (state.isLoadingVideos || state.videos.isNotEmpty)) {
                    _scrollToBottom();
                  }
                },
                builder: (context, state) {
                  if (state is AiTutorLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (state is AiTutorError) {
                    return Text(state.message, style: const TextStyle(color: Colors.red));
                  } else if (state is AiTutorExplained) {
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
                                  const Row(
                                    children: [
                                      Icon(Icons.auto_awesome, color: AppTheme.secondary, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'AI Simplified Explanation',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 20),
                                    tooltip: 'Copy Explanation',
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: state.session.aiResponse),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Explanation copied to clipboard'),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const Divider(),
                              RepaintBoundary(
                                child: MarkdownBody(
                                  data: state.session.aiResponse,
                                  softLineBreak: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                          onPressed: (state.isLoadingVideos || state.isStreaming)
                              ? null
                              : () => context
                              .read<AiTutorCubit>()
                              .getYoutubeSuggestions(widget.libraryId),
                          icon: const Icon(Icons.play_circle_fill, color: Colors.red),
                          label: Text(
                            state.isStreaming
                                ? 'Generating explanation...'
                                : 'Still unclear? Watch Top 3 YouTube Tutorials',
                          ),
                        ),
                        if (state.isLoadingVideos)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        if (state.videoError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'تعذر تحميل فيديوهات YouTube: ${state.videoError}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        if (state.videos.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Recommended Video Explanations:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          ...state.videos.map((video) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      video.thumbnailUrl,
                                      width: 95,
                                      height: 60,
                                      cacheWidth: 250,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                video.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                video.channelName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              onTap: () => launchUrl(
                                Uri.parse(video.videoUrl),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                          )),
                        ]
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _UploadOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}