/// Tema de cada carta: da el tono y la etiqueta que se ve arriba de la pregunta.
enum QuestionTopic {
  nosotros('Nosotros', '💞'),
  recuerdos('Recuerdos', '📸'),
  suenos('Sueños', '✨'),
  risas('Para reír', '😄'),
  profundas('Profundas', '🌙'),
  tuya('Tu pregunta', '✍️');

  final String label;
  final String emoji;

  const QuestionTopic(this.label, this.emoji);
}

class Question {
  final String text;
  final QuestionTopic topic;

  const Question(this.text, this.topic);
}

/// Baraja local de preguntas para conocerse más (sin backend).
const questionBank = <Question>[
  // Nosotros
  Question('¿Qué fue lo primero que te llamó la atención de mí?', QuestionTopic.nosotros),
  Question('¿En qué momento supiste que te gustaba de verdad?', QuestionTopic.nosotros),
  Question('¿Qué pequeño detalle mío te hace sonreír sin que me dé cuenta?', QuestionTopic.nosotros),
  Question('¿Cuál es tu forma favorita de pasar un domingo juntos?', QuestionTopic.nosotros),
  Question('¿Qué canción te recuerda a nosotros?', QuestionTopic.nosotros),
  Question('¿Qué te gustaría que hiciéramos más seguido?', QuestionTopic.nosotros),
  Question('Si nuestra historia fuera película, ¿cómo se llamaría?', QuestionTopic.nosotros),

  // Recuerdos
  Question('¿Cuál es tu recuerdo favorito de nuestra primera cita?', QuestionTopic.recuerdos),
  Question('¿Qué día juntos repetirías tal cual, sin cambiarle nada?', QuestionTopic.recuerdos),
  Question('¿Cuál es el lugar donde más te has reído conmigo?', QuestionTopic.recuerdos),
  Question('¿Qué comida te recuerda a tu infancia?', QuestionTopic.recuerdos),
  Question('¿Qué regalo te ha hecho más ilusión en la vida?', QuestionTopic.recuerdos),
  Question('¿Cuál fue la travesura más grande que hiciste de niño o niña?', QuestionTopic.recuerdos),

  // Sueños
  Question('¿A qué lugar del mundo te gustaría que viajáramos juntos?', QuestionTopic.suenos),
  Question('¿Cómo te imaginas nuestra casa dentro de unos años?', QuestionTopic.suenos),
  Question('¿Qué te gustaría aprender si tuvieras todo el tiempo del mundo?', QuestionTopic.suenos),
  Question('¿Qué aventura te gustaría que viviéramos este año?', QuestionTopic.suenos),
  Question('Si pudiéramos abrir un negocio juntos, ¿de qué sería?', QuestionTopic.suenos),
  Question('¿Cómo sería tu día perfecto de principio a fin?', QuestionTopic.suenos),

  // Para reír
  Question('Si fuéramos un dúo de superhéroes, ¿cuáles serían nuestros poderes?', QuestionTopic.risas),
  Question('¿Qué antojo raro defenderías a muerte?', QuestionTopic.risas),
  Question('¿Qué animal crees que sería yo y por qué?', QuestionTopic.risas),
  Question('¿Cuál es la canción que cantas a todo pulmón cuando nadie te oye?', QuestionTopic.risas),
  Question('Si mañana fuéramos famosos, ¿por qué sería?', QuestionTopic.risas),
  Question('¿Qué taco elegirías para el resto de tu vida?', QuestionTopic.risas),

  // Profundas
  Question('¿Qué te hace sentir realmente en paz?', QuestionTopic.profundas),
  Question('¿Qué es algo que todavía no me has contado de ti?', QuestionTopic.profundas),
  Question('¿Cómo te gusta que te apoye cuando tienes un mal día?', QuestionTopic.profundas),
  Question('¿De qué logro tuyo te sientes más orgulloso u orgullosa?', QuestionTopic.profundas),
  Question('¿Qué significa para ti sentirte amado o amada?', QuestionTopic.profundas),
  Question('¿Qué te gustaría que nunca cambiara entre nosotros?', QuestionTopic.profundas),
];
