
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String localizedText(BuildContext context, String pt, String en) {
  return Localizations.localeOf(context).languageCode == 'en' ? en : pt;
}

class AuthGate extends StatelessWidget {
  final Widget home;

  const AuthGate({
    super.key,
    required this.home,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                localizedText(
                  context,
                  'Ocorreu um erro ao verificar sua conta.',
                  'An error occurred while checking your account.',
                ),
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          if (user.displayName == null || user.displayName!.trim().isEmpty) {
            return const NameSetupScreen();
          }

          return home;
        }

        return SignInScreen(
          providers: [
            EmailAuthProvider(),
            GoogleProvider(
              clientId:
                  '489636287397-s58sddbetglhkbdqvcb42e2mou7f4vnk.apps.googleusercontent.com',
            ),
          ],
          headerBuilder: (context, constraints, shrinkOffset) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calculate,
                    size: 70,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LizMath',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizedText(
                      context,
                      'Desafie sua mente.',
                      'Challenge your mind.',
                    ),
                  ),
                ],
              ),
            );
          },
          subtitleBuilder: (context, action) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                action == AuthAction.signIn
                    ? localizedText(
                        context,
                        'Entre na sua conta para continuar.',
                        'Sign in to continue.',
                      )
                    : localizedText(
                        context,
                        'Crie sua conta para começar.',
                        'Create your account to get started.',
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class NameSetupScreen extends StatefulWidget {
  const NameSetupScreen({super.key});

  @override
  State<NameSetupScreen> createState() => _NameSetupScreenState();
}

class _NameSetupScreenState extends State<NameSetupScreen> {
  final TextEditingController nameController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> saveName() async {
    final name = nameController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (name.isEmpty) {
      setState(() {
        errorMessage = localizedText(
          context,
          'Digite seu nome para continuar.',
          'Enter your name to continue.',
        );
      });
      return;
    }

    if (user == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(name);
      await user.reload();

    } catch (e) {
      setState(() {
        errorMessage = localizedText(
          context,
          'Não foi possível salvar seu nome. Tente novamente.',
          'Could not save your name. Please try again.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  localizedText(
                    context,
                    'Como podemos chamar você?',
                    'What should we call you?',
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  localizedText(
                    context,
                    'Digite seu nome para continuar.',
                    'Enter your name to continue.',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: localizedText(
                      context,
                      'Seu nome',
                      'Your name',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => saveName(),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLoading ? null : saveName,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            localizedText(
                              context,
                              'Continuar',
                              'Continue',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
