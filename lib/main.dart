import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final dioClient = DioClient();

  runApp(ClarifyAiApp(dioClient: dioClient));
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