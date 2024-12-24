import 'package:arryuwu/Home/Screens/Home/HomeWitgets.dart';
import 'package:flutter/material.dart'; // Importa los widgets

class Notifypage extends StatelessWidget {
  const Notifypage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeader(), // Mostrar el header
            const SizedBox(height: 20),
            ActionButton(
              label: 'Ver Notificaciones',
              onPressed: () {
                // Lógica para ver detalles o navegar
                print('Ver detalles de actividad');
              },
            ),
          ],
        ),
      ),
    );
  }
}
