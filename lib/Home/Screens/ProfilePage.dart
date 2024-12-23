import 'package:arryuwu/Home/Screens/HomeWitgets.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeHeader(), // Mostrar el header
            const SizedBox(height: 20),
            ActionButton(
              label: 'Editar perfil',
              onPressed: () {
                // Lógica para editar perfil
                print('Editar perfil');
              },
            ),
          ],
        ),
      ),
    );
  }
}
