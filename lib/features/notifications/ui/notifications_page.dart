import 'package:arryuwu/ui/widgets/entrance.dart';
import 'package:arryuwu/ui/widgets/state_views.dart';
import 'package:flutter/material.dart';

/// Pestaña de avisos. Aún no hay backend de avisos: se muestra un estado vacío cálido.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: const SafeArea(
        child: Entrance(
          child: AppMessageView(
            lottie: 'assets/lottie/heart.json',
            title: 'Todo tranquilo por aquí',
            subtitle: 'Pronto verás aquí lo que tu pareja comparte contigo: recuerdos nuevos, '
                'respuestas a sus preguntas y notas en el lienzo.',
          ),
        ),
      ),
    );
  }
}
