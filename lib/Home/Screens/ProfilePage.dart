import 'package:flutter/material.dart';
import 'package:arryuwu/Home/Screens/HomeWitgets.dart'; // Asegúrate de que estos widgets existen y son los correctos.
import 'package:arryuwu/colors/palette.dart'; // Asegúrate de importar tu paleta

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor:
            Palette.primary, // Usando el color primario de tu paleta
      ),
      body: SingleChildScrollView(
        // Hace que todo el contenido sea desplazable
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Centrado de contenido
            children: [
              // Foto de perfil
              const CircleAvatar(
                radius: 50,
                backgroundColor: Palette.accent,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Palette.white,
                ),
              ),
              const SizedBox(height: 15),
              // Nombre y correo del usuario
              const Text(
                "Nombre del Usuario",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "usuario@correo.com",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),

              // Expanded para contener los botones de acción y opciones
              Column(
                children: [
                  // Botón para editar perfil
                  ActionButton(
                    label: 'Editar perfil',
                    onPressed: () {
                      // Acción para editar el perfil
                      print('Botón Editar perfil presionado');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Botón para cambiar la contraseña
                  ActionButton(
                    label: 'Cambiar contraseña',
                    onPressed: () {
                      // Acción para cambiar la contraseña
                      print('Botón Cambiar contraseña presionado');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Botón para cerrar sesión
                  ElevatedButton(
                    onPressed: () {
                      // Acción para cerrar sesión
                      print('Botón Cerrar sesión presionado');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.redAccent, // Color rojo para cerrar sesión
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Opciones adicionales (como configuraciones o notificaciones)
                  ListTile(
                    leading: const Icon(Icons.settings, color: Palette.primary),
                    title: const Text('Configuración de cuenta'),
                    onTap: () {
                      print("Configuración de cuenta presionado");
                      // Lógica para ir a configuración
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.notifications, color: Palette.primary),
                    title: const Text('Notificaciones'),
                    onTap: () {
                      print("Notificaciones presionado");
                      // Lógica para gestionar notificaciones
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.language, color: Palette.primary),
                    title: const Text('Idioma'),
                    onTap: () {
                      print("Idioma presionado");
                      // Lógica para cambiar idioma
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
