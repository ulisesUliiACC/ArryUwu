import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DetailActivityPage extends StatelessWidget {
  final String title;

  const DetailActivityPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Título del carrusel
            const Text(
              "Actividades Pendientes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Carrusel con cuadrícula
            CarouselSlider(
              options: CarouselOptions(
                height: 400,
                enlargeCenterPage: true,
                enableInfiniteScroll: true,
                autoPlay: false,
                viewportFraction: 0.9,
              ),
              items: _gridCarouselItems(context),
            ),
            const SizedBox(height: 20),

            // Botones y progreso
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Agregar Actividad"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _showAddActivityDialog(context);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.shuffle),
              label: const Text("Actividad Random"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _showRandomActivityDialog(context);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Progreso de Actividades",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: 0.5, // Ajusta este valor dinámicamente
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(Colors.green),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Generar elementos del carrusel con cuadrículas
  List<Widget> _gridCarouselItems(BuildContext context) {
    // Datos para las tarjetas
    final activities = [
      {"icon": Icons.local_dining, "color": Colors.pinkAccent, "title": "Cena romántica"},
      {"icon": Icons.hiking, "color": Colors.green, "title": "Excursión"},
      {"icon": Icons.beach_access, "color": Colors.blueAccent, "title": "Playa"},
      {"icon": Icons.cake, "color": Colors.orangeAccent, "title": "Cumpleaños"},
      {"icon": Icons.favorite, "color": Colors.redAccent, "title": "Primera cita"},
      {"icon": Icons.music_note, "color": Colors.purple, "title": "Concierto"},
      {"icon": Icons.star, "color": Colors.yellow, "title": "Logro especial"},
      {"icon": Icons.flight_takeoff, "color": Colors.teal, "title": "Viaje"},
    ];

    // Dividir las actividades en páginas de 4x4
    final pages = List.generate(
      (activities.length / 4).ceil(),
      (index) => activities.skip(index * 4).take(4).toList(),
    );

    return pages.map((page) {
      return GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 columnas
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: page.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final activity = page[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailActivityPage(
                    title: activity["title"] as String,
                  ),
                ),
              );
            },
            child: _activityCard(
              icon: activity["icon"] as IconData,
              color: activity["color"] as Color,
              title: activity["title"] as String,
            ),
          );
        },
      );
    }).toList();
  }

  // Tarjeta de actividad
  Widget _activityCard({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Mostrar diálogo para agregar actividad
  void _showAddActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Actividad'),
          content: const Text('Aquí puedes agregar una nueva actividad.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Mostrar diálogo para actividad random
  void _showRandomActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Actividad Random'),
          content: const Text('Aquí se mostrará una actividad aleatoria.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
