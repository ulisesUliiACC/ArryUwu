import 'package:arryuwu/core/api_client.dart';
import 'package:arryuwu/features/auth/data/auth_controller.dart';
import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:arryuwu/ui/widgets/app_button.dart';
import 'package:arryuwu/ui/widgets/app_text_field.dart';
import 'package:arryuwu/ui/widgets/entrance.dart';
import 'package:arryuwu/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).login(_userController.text, _passwordController.text);
      TextInput.finishAutofillContext();
      // El router lleva al Home en cuanto cambia la sesión.
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Entrance(
                      child: Center(
                        child: Lottie.asset('assets/lottie/AnimacionPantalla.json', height: 170),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Entrance(
                      index: 1,
                      child: Text('Hola de nuevo', style: text.headlineMedium, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Entrance(
                      index: 2,
                      child: Text('Entra para ver lo que tu pareja compartió',
                          style: text.bodyMedium, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Entrance(
                      index: 3,
                      child: AppTextField(
                        controller: _userController,
                        label: 'Correo o usuario',
                        icon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username, AutofillHints.email],
                        enabled: !_loading,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Escribe tu correo o tu usuario' : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Entrance(
                      index: 4,
                      child: AppTextField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        icon: Icons.lock_outline_rounded,
                        password: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        enabled: !_loading,
                        onSubmitted: (_) => _submit(),
                        validator: (v) => (v == null || v.isEmpty) ? 'Escribe tu contraseña' : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Entrance(
                      index: 5,
                      child: AppPrimaryButton(label: 'Entrar', loading: _loading, onPressed: _submit),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Entrance(
                      index: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('¿Aún no tienes cuenta?', style: text.bodyMedium),
                          TextButton(
                            onPressed: _loading ? null : () => context.push('/register'),
                            child: const Text('Crear cuenta'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
