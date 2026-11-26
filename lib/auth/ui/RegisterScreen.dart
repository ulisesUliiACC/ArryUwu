import 'package:arryuwu/Home/HomeScreen.dart';
import 'package:arryuwu/auth/data/auth_service.dart';
import 'package:arryuwu/core/api_client.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  late AnimationController _lottieController; // Controlador para la animación
  bool _canAnimate = false; // Controla si la animación puede avanzar

  List<TextEditingController> get _controllers => [
        _userNameController,
        _nombreController,
        _apellidoController,
        _emailController,
        _passwordController,
      ];

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _lottieController.dispose();
    super.dispose();
  }

  // El corazón avanza cuando todos los campos están llenos
  void _updateAnimationState() {
    setState(() {
      if (_controllers.every((c) => c.text.isNotEmpty)) {
        _canAnimate = true;
        _lottieController.forward();
      } else {
        _canAnimate = false;
        _lottieController.reset();
      }
    });
  }

  /// Registra la cuenta y entra directamente con esas credenciales.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(
        userName: _userNameController.text,
        nombre: _nombreController.text,
        apellido: _apellidoController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      await AuthService.login(_userNameController.text, _passwordController.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration(String label, FaIconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(width: 1, color: color),
        );
    return InputDecoration(
      labelText: label,
      prefixIcon: FaIcon(icon),
      suffixIcon: suffix,
      enabledBorder: border(const Color(0xFF837E93)),
      focusedBorder: border(const Color(0xFF9F7BFF)),
      errorBorder: border(Colors.red),
      focusedErrorBorder: border(Colors.red),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required FaIconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        onChanged: (_) => _updateAnimationState(),
        decoration: _decoration(label, icon, suffix: suffix),
        validator: validator,
      ),
    );
  }

  // Mismas reglas que RegisterRequest en el backend
  String? Function(String?) _nameValidator(String campo) => (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return 'Por favor, ingrese su $campo';
        if (v.length < 2 || v.length > 50) {
          return 'El $campo debe tener entre 2 y 50 caracteres';
        }
        return null;
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla de Registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Lottie.asset(
                    'assets/lottie/heart.json',
                    controller: _lottieController,
                    repeat: !_canAnimate, // Repite el latido si no puede avanzar
                    onLoaded: (composition) {
                      _lottieController
                        ..duration = composition.duration
                        ..repeat(); // Repite el latido por defecto
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _field(
                  controller: _userNameController,
                  label: 'Nombre de Usuario',
                  icon: FontAwesomeIcons.user,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Por favor, ingrese un nombre de usuario';
                    if (v.contains(' ')) return 'Sin espacios, por favor';
                    return null;
                  },
                ),
                _field(
                  controller: _nombreController,
                  label: 'Nombre',
                  icon: FontAwesomeIcons.idCard,
                  validator: _nameValidator('nombre'),
                ),
                _field(
                  controller: _apellidoController,
                  label: 'Apellido',
                  icon: FontAwesomeIcons.idCard,
                  validator: _nameValidator('apellido'),
                ),
                _field(
                  controller: _emailController,
                  label: 'Email',
                  icon: FontAwesomeIcons.envelope,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese un correo electrónico';
                    }
                    final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Por favor, ingrese un correo electrónico válido';
                    }
                    return null;
                  },
                ),
                _field(
                  controller: _passwordController,
                  label: 'Contraseña',
                  icon: FontAwesomeIcons.key,
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: FaIcon(_obscurePassword
                        ? FontAwesomeIcons.eye
                        : FontAwesomeIcons.eyeSlash),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese una contraseña';
                    }
                    if (value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(150, 50),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear Cuenta'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
