import 'package:arryuwu/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Tipo de plan. Sirve para filtrar las ideas en la pantalla de actividades.
enum ActivityCategory {
  home('En casa', Icons.home_rounded),
  outdoors('Al aire libre', Icons.park_rounded),
  outing('Para salir', Icons.local_activity_rounded),
  adventure('Aventura', Icons.explore_rounded);

  final String label;
  final IconData icon;

  const ActivityCategory(this.label, this.icon);
}

/// Una idea de cita. Por ahora los datos son locales (no hay backend de actividades).
class Activity {
  final String title;
  final String subtitle;
  final String description;
  final ActivityCategory category;
  final IconData icon;
  final Color color;
  final String duration;
  final String cost;
  final List<String> ideas;

  const Activity({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.duration,
    required this.cost,
    required this.ideas,
  });

  /// Busca una actividad por título; si no existe arma una genérica para no dejar la pantalla vacía.
  static Activity byTitle(String title) => activities.firstWhere(
        (a) => a.title == title,
        orElse: () => Activity(
          title: title,
          subtitle: 'Una idea para ustedes',
          description: 'Dense un rato solo para ustedes dos: sin prisas, sin pendientes y con muchas ganas de pasarla bien.',
          category: ActivityCategory.home,
          icon: Icons.favorite_rounded,
          color: AppColors.pinkDeep,
          duration: 'Lo que quieran',
          cost: 'Gratis',
          ideas: const [
            'Apaguen las notificaciones un rato',
            'Platiquen de algo que nunca se hayan preguntado',
            'Tómense una foto para guardarla en Recuerdos',
          ],
        ),
      );
}

const activities = <Activity>[
  Activity(
    title: 'Cena romántica en casa',
    subtitle: 'Cocinen juntos algo nuevo',
    description:
        'Elijan una receta que ninguno haya preparado antes y cocínenla a cuatro manos. Lo importante no es que quede perfecta, sino reírse en el intento.',
    category: ActivityCategory.home,
    icon: Icons.restaurant_rounded,
    color: AppColors.pinkDeep,
    duration: '2 h',
    cost: r'$',
    ideas: [
      'Escojan la receta juntos sin ver el precio de los ingredientes',
      'Armen una playlist de canciones que les recuerden a ustedes',
      'Velas, mantel bonito y celulares lejos de la mesa',
      'Preparen un postre sorpresa para el otro',
    ],
  ),
  Activity(
    title: 'Noche de películas',
    subtitle: 'Cobijas, palomitas y maratón',
    description:
        'Conviertan la sala en su cine privado. Cada quien elige una película que el otro no haya visto y la presenta como si fuera crítico de cine.',
    category: ActivityCategory.home,
    icon: Icons.movie_rounded,
    color: AppColors.lavenderDeep,
    duration: '3 h',
    cost: 'Gratis',
    ideas: [
      'Hagan un fuerte de cobijas y cojines',
      'Preparen palomitas con dos sabores distintos',
      'Califiquen cada película del 1 al 10 al terminar',
    ],
  ),
  Activity(
    title: 'Noche de juegos',
    subtitle: 'Competencia amistosa',
    description:
        'Saquen los juegos de mesa, la baraja o la lotería. El que pierda cumple un pequeño reto que el otro elija.',
    category: ActivityCategory.home,
    icon: Icons.casino_rounded,
    color: AppColors.success,
    duration: '2 h',
    cost: 'Gratis',
    ideas: [
      'Pongan en juego quién lava los trastes',
      'Inventen un juego nuevo con sus propias reglas',
      'Lleven la cuenta del marcador en el Lienzo',
    ],
  ),
  Activity(
    title: 'Carta para el futuro',
    subtitle: 'Un mensaje para dentro de un año',
    description:
        'Cada quien escribe una carta para que la lean juntos dentro de un año: lo que sienten hoy, lo que sueñan y lo que esperan vivir.',
    category: ActivityCategory.home,
    icon: Icons.mail_rounded,
    color: AppColors.pinkDeep,
    duration: '1 h',
    cost: 'Gratis',
    ideas: [
      'Guárdenlas en un sobre con la fecha de apertura',
      'Incluyan una foto de hoy',
      'Anoten tres metas que quieran cumplir juntos',
    ],
  ),
  Activity(
    title: 'Picnic en el parque',
    subtitle: 'Comida rica bajo un árbol',
    description:
        'Preparen una canasta con sus botanas favoritas, una manta y algo de música. Busquen un rincón con sombra y dejen que la tarde pase sin prisa.',
    category: ActivityCategory.outdoors,
    icon: Icons.park_rounded,
    color: AppColors.success,
    duration: 'Una tarde',
    cost: r'$',
    ideas: [
      'Cada quien lleva un antojo sorpresa',
      'Lleven un libro y léanse en voz alta',
      'Tómense una foto para su colección de Recuerdos',
    ],
  ),
  Activity(
    title: 'Senderismo',
    subtitle: 'Caminen hacia un buen mirador',
    description:
        'Elijan una ruta sencilla con una vista bonita al final. Caminar juntos invita a platicar de todo y llegar a la cima se siente como un logro en equipo.',
    category: ActivityCategory.outdoors,
    icon: Icons.hiking_rounded,
    color: AppColors.success,
    duration: 'Medio día',
    cost: 'Gratis',
    ideas: [
      'Salgan temprano para evitar el sol fuerte',
      'Lleven agua, fruta y bloqueador',
      'Al llegar a la cima, cuéntense algo que nunca se hayan dicho',
    ],
  ),
  Activity(
    title: 'Ver el atardecer',
    subtitle: 'El cielo pintado para ustedes',
    description:
        'Busquen una azotea, un mirador o la playa más cercana y vean juntos cómo se oculta el sol. Es corto, sencillo y siempre se siente especial.',
    category: ActivityCategory.outdoors,
    icon: Icons.wb_twilight_rounded,
    color: AppColors.pinkDeep,
    duration: '1 h',
    cost: 'Gratis',
    ideas: [
      'Lleven un café o un chocolate caliente',
      'Pongan la canción que más les guste a los dos',
      'Hagan un timelapse con el celular',
    ],
  ),
  Activity(
    title: 'Ruta de antojitos',
    subtitle: 'Tacos, esquites y algo dulce',
    description:
        'Armen un recorrido por los puestos y fondas de su colonia o de un barrio que no conozcan. Califiquen cada parada y elijan a su ganador.',
    category: ActivityCategory.outing,
    icon: Icons.lunch_dining_rounded,
    color: AppColors.lavenderDeep,
    duration: '3 h',
    cost: r'$$',
    ideas: [
      'Máximo un antojo por parada para aguantar toda la ruta',
      'Cada quien propone un lugar sorpresa',
      'Terminen con un postre o un pan dulce',
    ],
  ),
  Activity(
    title: 'Música en vivo',
    subtitle: 'Un concierto o una tocada',
    description:
        'Busquen un concierto, una tocada en un bar o música en una plaza. Bailar juntos, aunque sea un poquito, siempre suma.',
    category: ActivityCategory.outing,
    icon: Icons.music_note_rounded,
    color: AppColors.pinkDeep,
    duration: 'Una noche',
    cost: r'$$',
    ideas: [
      'Escuchen antes las canciones del artista',
      'Elijan cuál será "su canción" de la noche',
      'Graben un video corto para recordarlo',
    ],
  ),
  Activity(
    title: 'Museo y café',
    subtitle: 'Cultura con plática',
    description:
        'Visiten un museo o una galería y después platiquen de lo que más les gustó con un café. Es un plan tranquilo que da muchísimo de qué hablar.',
    category: ActivityCategory.outing,
    icon: Icons.museum_rounded,
    color: AppColors.lavenderDeep,
    duration: 'Una tarde',
    cost: r'$',
    ideas: [
      'Muchos museos son gratis los domingos',
      'Cada quien elige la obra favorita del otro',
      'Dibujen su obra favorita en el Lienzo',
    ],
  ),
  Activity(
    title: 'Escapada de fin de semana',
    subtitle: 'Un pueblo mágico cerca',
    description:
        'Elijan un destino a pocas horas de casa y escápense un fin de semana. Cambiar de aire juntos les da historias nuevas para contar.',
    category: ActivityCategory.adventure,
    icon: Icons.luggage_rounded,
    color: AppColors.lavenderDeep,
    duration: '2 días',
    cost: r'$$$',
    ideas: [
      'Hagan una lista de tres cosas que quieran probar allá',
      'Dejen un día sin planes para improvisar',
      'Compren un recuerdito pequeño para su casa',
    ],
  ),
  Activity(
    title: 'Algo por primera vez',
    subtitle: 'Una experiencia nueva para los dos',
    description:
        'Clase de baile, cerámica, escalada o patinaje: elijan algo que ninguno haya hecho. Aprender juntos los acerca y les deja recuerdos muy divertidos.',
    category: ActivityCategory.adventure,
    icon: Icons.auto_awesome_rounded,
    color: AppColors.pinkDeep,
    duration: '2 h',
    cost: r'$$',
    ideas: [
      'Hagan una lista de cosas que siempre han querido intentar',
      'Échense porras aunque les salga mal',
      'Guarden una foto del antes y el después',
    ],
  ),
];
