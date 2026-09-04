import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vimes_test/firebase_options.dart';
import 'package:vimes_test/page/home/home_page.dart';
import 'package:vimes_test/page/login/login_page.dart';
import 'package:vimes_test/repositories/auth_repository.dart';
import 'package:vimes_test/repositories/document_repository.dart';
import 'package:vimes_test/repositories/grn_repositories.dart';
import 'package:vimes_test/repositories/product_repository.dart';
import 'package:vimes_test/repositories/user_repository.dart';
import 'package:vimes_test/repositories/user_session_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = FirebaseAuthRepository();
    final userRepo = FirestoreUserRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => authRepo),
        RepositoryProvider<UserRepository>(create: (_) => userRepo),
        RepositoryProvider<UserSessionRepository>(
          create: (_) => FirestoreUserSessionRepository(
            authRepository: authRepo,
            userRepository: userRepo,
          ),
        ),
        RepositoryProvider<GRNRepository>(
          create: (_) => FirestoreGRNRepository(),
        ),
        RepositoryProvider<DocumentRepository>(
          create: (_) => FirestoreDocumentRepository(),
        ),
        RepositoryProvider<ProductRepository>(
          create: (_) => FirestoreProductRepository(),
        ),
      ],
      child: MaterialApp(
        title: 'VIMES WMS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.scaffoldBg,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.accentPrimary,
            surface: AppColors.cardBg,
          ),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}
