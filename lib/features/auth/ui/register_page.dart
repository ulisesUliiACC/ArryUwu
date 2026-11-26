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

/// Registro. El corazón se va "llenando" conforme completas los campos.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userName = TextEditingController();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AnimationController _heart = AnimationController(vsync: this);
  bool _loading = false;

  List<TextEditingController> get _fields => [_userName, _nombre, _apellido, _email, _password];

  double get _progress => _fields.where((c) => c.text.trim().isNotEmpty).length / _fields.length;

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    _heart.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    // Avanza la animación hasta la fracción de campos llenos.
    _heart.animateTo(_progress, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    setState(() {});
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).register(
            userName: _userName.text.trim(),
            nombre: _nombre.text.trim(),
            apellido: _apellido.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      HapticFeedback.mediumImpact();
      TextInput.finishAutofillContext();
    } on ApiException catch (e) {
      if (mounted) showAppSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _nameRule(String? v, String campo) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Escribe tu $campo';
    if (value.length < 2 || value.length > 50) return 'Entre 2 y 50 caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = (_progress * 5).round();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _loading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Entrance(
                    child: Center(
                      child: Lottie.asset(
                        'assets/lottie/heart.json',
                        controller: _heart,
                        height: 130,
                        onLoaded: (c) => _heart.duration = c.duration,
                      ),
                    ),
                  ),
                  Entrance(
                    index: 1,
                    child: Text('Crea tu cuenta', style: text.headlineMedium, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Entrance(
                    index: 2,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        done == 5 ? '¡Listo! Ya puedes crearla 💜' : '$done de 5 datos',
                        key: ValueKey(done),
                        style: text.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(
                    index: 3,
                    child: AppTextField(
                      controller: _userName,
                      label: 'Nombre de usuario',
                      icon: Icons.alternate_email_rounded,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newUsername],
                      enabled: !_loading,
                      onChanged: _onChanged,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Elige un nombre de usuario';
                        if (value.contains(' ')) return 'Sin espacios';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 4,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _nombre,
                            label: 'Nombre',
                            icon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.givenName],
                            enabled: !_loading,
                            onChanged: _onChanged,
                            validator: (v) => _nameRule(v, 'nombre'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppTextField(
                            controller: _apellido,
                            label: 'Apellido',
                            icon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.familyName],
                            enabled: !_loading,
                            onChanged: _onChanged,
                            validator: (v) => _nameRule(v, 'apellido'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 5,
                    child: AppTextField(
                      controller: _email,
                      label: 'Correo',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      enabled: !_loading,
                      onChanged: _onChanged,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Escribe tu correo';
                        final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(value);
                        return ok ? null : 'Ese correo no parece válido';
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Entrance(
                    index: 6,
                    child: AppTextField(
                      controller: _password,
                      label: 'Contraseña',
                      icon: Icons.lock_outline_rounded,
                      password: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      enabled: !_loading,
                      onChanged: _onChanged,
                      onSubmitted: (_) => _submit(),
                      validator: (v) =>
                          (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Entrance(
                    index: 6,
                    child: Text('Usa al menos 8 caracteres.', style: text.labelSmall),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(
                    index: 7,
                    child: AppPrimaryButton(label: 'Crear cuenta', loading: _loading, onPressed: _submit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
