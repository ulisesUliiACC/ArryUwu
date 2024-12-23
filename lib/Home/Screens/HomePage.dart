import 'package:arryuwu/Home/Screens/CodePage.dart';
import 'package:arryuwu/Home/Screens/HomeWitgets.dart';
import 'package:flutter/material.dart'; // Importa los widgets

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeader(), // Mostrar el header
            const SizedBox(height: 20),
            // Botón de acción con un callback
            ActionButton(
              label: 'Ver actividades',
              onPressed: () {
                // Acciones al presionar el botón (por ejemplo, navegar a otra pantalla)
                print('Botón presionado: Ver actividades');
              },
            ),
            const SizedBox(height: 20),
            LinkButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CodePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
