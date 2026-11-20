import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../data/models/subject_library_model.dart';
import '../../logic/libraries_cubit.dart';
import 'library_details_screen.dart';

class HomeLibrariesScreen extends StatefulWidget {
  const HomeLibrariesScreen({super.key});

  @override
  State<HomeLibrariesScreen> createState() => _HomeLibrariesScreenState();
}

class _HomeLibrariesScreenState extends State<HomeLibrariesScreen> {
  String _searchQuery = '';

  void _showAddLibraryDialog(BuildContext context) {
    final controller = TextEditingController();
    final colors = [0xFF4F46E5, 0xFF0D9488, 0xFFE11D48, 0xFFD97706, 0xFF7C3AED];
    int selectedColor = colors[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Subject Library', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'e.g., Logic, OOP, Computer Networks',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Choose Accent Color:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: colors.map((c) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: CircleAvatar(
                      backgroundColor: Color(c),
                      radius: 18,
                      child: selectedColor == c
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  context.read<LibrariesCubit>().addLibrary(
                    controller.text.trim(),
                    selectedColor,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back, $userName', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const Text('My Study Libraries'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search your subjects...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SubjectLibraryModel>>(
              stream: context.read<LibrariesCubit>().librariesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allLibraries = snapshot.data ?? [];
                final libraries = allLibraries
                    .where((lib) => lib.subjectName.toLowerCase().contains(_searchQuery))
                    .toList();

                if (libraries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No study libraries found.\nTap "+ New Subject" to organize your courses!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: libraries.length,
                  itemBuilder: (context, index) {
                    final lib = libraries[index];
                    final accentColor = Color(lib.colorValue);

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LibraryDetailsScreen(library: lib),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.menu_book_rounded, color: accentColor, size: 26),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lib.subjectName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Tap to open workspace',
                                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddLibraryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Subject'),
      ),
    );
  }
}