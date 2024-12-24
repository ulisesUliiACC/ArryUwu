import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Datos de las tarjetas con íconos de Font Awesome
    final List<Map<String, dynamic>> activities = [
      {
        "icon": FontAwesomeIcons.star,
        "color": Colors.yellow,
        "title": "Actividades"
      },
      {
        "icon": FontAwesomeIcons.hiking,
        "color": Colors.green,
        "title": "Senderismo"
      },
      {
        "icon": FontAwesomeIcons.circleQuestion,
        "color": Colors.pinkAccent,
        "title": "Preguntas"
      },
      {
        "icon": FontAwesomeIcons.heart,
        "color": Colors.redAccent,
        "title": "Primera cita"
      },
      {
        "icon": FontAwesomeIcons.tree,
        "color": Colors.lightGreen,
        "title": "Paseo en el parque"
      },
      {
        "icon": FontAwesomeIcons.faceSmile,
        "color": Colors.blue,
        "title": "Día de relax"
      },
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Actividades",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 400, // Altura del carrusel
              child: PageView.builder(
                itemCount: (activities.length / 4).ceil(), // Número de páginas
                itemBuilder: (context, pageIndex) {
                  final start = pageIndex * 4;
                  final end = (start + 4 < activities.length)
                      ? start + 4
                      : activities.length;
                  final pageItems = activities.sublist(start, end);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: screenWidth / (2 * 200),
                      physics: const NeverScrollableScrollPhysics(),
                      children: pageItems.map((activity) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/activityDetail',
                              arguments: activity["title"],
                            );
                          },
                          child: _achievementCard(
                            icon: activity["icon"] as IconData,
                            color: activity["color"] as Color,
                            title: activity["title"] as String,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Actividades Completadas",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                final activitiesCompleted = [
                  "Salir al parque",
                  "Hacer un picnic",
                  "Cenar juntos"
                ];
                return ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green[600]),
                  title: Text(
                    activitiesCompleted[index],
                    style: const TextStyle(fontSize: 16),
                  ),
                  onTap: () {
                    print(
                        "Actividad seleccionada: ${activitiesCompleted[index]}");
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _achievementCard({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon,
                color: color, size: 50), // Usa FaIcon para Font Awesome
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
