import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'features/ai_tutor/data/ai_tutor_repository.dart';
import 'features/ai_tutor/logic/ai_tutor_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/logic/auth_cubit.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/libraries/data/libraries_repository.dart';
import 'features/libraries/logic/libraries_cubit.dart';
import 'features/libraries/presentation/screens/home_libraries_screen.dart';
import 'features/smart_research/data/research_repository.dart';
import 'features/smart_research/logic/research_cubit.dart';
import 'firebase_options.dart';

void main() async {

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  Object? startupError;
  try {
    await dotenv.load(fileName: 'assets/app.env');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    startupError = error;
    debugPrint('ClarifyAI startup failed: $error\n$stackTrace');
  } finally {
    FlutterNativeSplash.remove();
  }

  if (startupError != null) {
    runApp(_StartupErrorApp(message: startupError.toString()));
    return;
  }

  runApp(ClarifyAiApp(dioClient: DioClient()));
}

class ClarifyAiApp extends StatelessWidget {
  final DioClient dioClient;

  const ClarifyAiApp({super.key, required this.dioClient});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(AuthRepository())),
        BlocProvider(create: (_) => LibrariesCubit(LibrariesRepository())),
        BlocProvider(create: (_) => AiTutorCubit(AiTutorRepository(dioClient.dio))),
        BlocProvider(create: (_) => ResearchCubit(ResearchRepository(dioClient.dio))),
      ],
      child: MaterialApp(
        title: 'ClarifyAI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: FirebaseAuth.instance.currentUser != null
            ? const HomeLibrariesScreen()
            : const LoginScreen(),
      ),
    );
  }
}
class _StartupErrorApp extends StatelessWidget {
  final String message;
  const _StartupErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('تعذر تشغيل ClarifyAI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
