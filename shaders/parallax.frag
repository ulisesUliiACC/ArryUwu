#version 460 core
// Efecto 3D de los recuerdos: desplaza cada píxel según su profundidad (blanco = cerca, negro = lejos)
// y la inclinación del celular. Las zonas cercanas se mueven más que el fondo, como si la foto tuviera volumen.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;       // tamaño del área de dibujo (floats 0,1)
uniform vec2 uImageSize;  // tamaño de la foto            (floats 2,3)
uniform vec2 uTilt;       // inclinación en [-1, 1]       (floats 4,5)
uniform float uStrength;  // intensidad, ~0.04            (float 6)
uniform sampler2D uImage; // sampler 0: la foto
uniform sampler2D uDepth; // sampler 1: el mapa de profundidad

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;

  // Ajuste tipo "cover": llena el área sin deformar la foto.
  float viewAspect = uSize.x / uSize.y;
  float imgAspect = uImageSize.x / uImageSize.y;
  vec2 scale = imgAspect > viewAspect
      ? vec2(viewAspect / imgAspect, 1.0)
      : vec2(1.0, imgAspect / viewAspect);

  // Un poco de zoom para que al moverse no se vean los bordes.
  float margin = 1.0 - 2.0 * uStrength;
  uv = (uv - 0.5) * scale * margin + 0.5;

  // Búsqueda iterativa: aproxima de qué punto de la foto viene este píxel tras el desplazamiento.
  vec2 offset = uTilt * uStrength;
  vec2 p = uv;
  for (int i = 0; i < 5; i++) {
    float d = texture(uDepth, p).r;
    p = uv + offset * (d - 0.35);
  }
  fragColor = texture(uImage, clamp(p, 0.0, 1.0));
}
