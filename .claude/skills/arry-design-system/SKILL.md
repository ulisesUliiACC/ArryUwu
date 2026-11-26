---
name: arry-design-system
description: Sistema de diseño de Arry (app de pareja en Flutter, C:\ArryUwu) — paleta lavanda/rosa, tipografía, espaciados, radios, componentes base (campos, botones, tarjetas, estados de carga/vacío/error), accesibilidad y cómo verificar el resultado con capturas del celular vía adb. Úsala SIEMPRE que crees o modifiques cualquier pantalla o widget en lib/ (login, registro, home, actividades, recuerdos, preguntas, lienzo, perfil, menú), cuando toques colores, temas, fuentes o animaciones, y cuando el usuario diga "mejora el diseño", "se ve feo", "hazlo más bonito", "rediseña esta pantalla" o "agrega una pantalla nueva".
---

# Sistema de diseño de Arry

Arry es una app para parejas: vinculan sus cuentas con un código y comparten actividades, preguntas, recuerdos con fotos y un lienzo de dibujo. La interfaz debe sentirse **cálida, suave e íntima**, nunca corporativa: lavanda y rosa, esquinas redondeadas, mucho aire, microanimaciones con corazones (Lottie). Mercado: México, textos en español de México, tuteando ("Crea tu cuenta", no "Cree su cuenta").

## Estado actual (verifica antes de asumir que sigue así)

- Paleta en `lib/colors/palette.dart`; el tema real se arma a mano en `lib/main.dart`. `lib/colors/themes.dart` tiene `lightTheme`/`darkTheme` pero **no se usan**.
- Cada pantalla repite su propio `InputDecoration` con 4 bordes y colores sueltos (`0xFF755DC1`, `0xFF837E93`, `0xFF9F7BFF`, `Colors.deepPurple`, `Colors.pinkAccent`…). Hay ~6 morados distintos.
- Se usa `fontFamily: 'Poppins'` pero la fuente **no está empaquetada**, así que cae a Roboto.
- Íconos: `font_awesome_flutter` 11 → sus íconos son `FaIconData` y se dibujan con `FaIcon`, no con `Icon`. Los de Material (`Icons.*`) sí van en `Icon`.
- Flutter 3.50: el analizador marca `package:flutter/material.dart` como deprecado en favor de `material_ui`. Es solo *info*; **no migres** hasta que el usuario lo pida.

## Tokens

Centraliza todo en `lib/ui/theme/`. Las pantallas nunca escriben `Color(0x…)`, `Colors.*` (salvo `Colors.transparent`), tamaños de fuente ni radios sueltos: leen tokens o `Theme.of(context)`.

### Color (`app_colors.dart`)

| Token | Valor | Uso |
|---|---|---|
| `lavender` | `#8B93E6` | Marca, fondos de acento, íconos grandes, ilustraciones. **No para texto** (contraste 2.8:1 sobre blanco). |
| `lavenderDeep` | `#755DC1` | Botón primario, enlaces, títulos de sección, foco de campos. Texto blanco encima: 5.1:1 ✅ |
| `lavenderSoft` | `#D8DDF9` | Fondos de chips, tarjetas seleccionadas, barra inferior. |
| `pink` | `#FAACD8` | Acentos románticos: corazones, badges, fondos de tarjetas de pareja. No para texto. |
| `pinkDeep` | `#C2185B` | Acción "de pareja" (vincular, enviar a tu pareja) y texto rosa. Blanco encima: 5.9:1 ✅ |
| `background` | `#F2F6FF` | Fondo de `Scaffold`. |
| `surface` | `#FFFFFF` | Tarjetas, campos, hojas inferiores. |
| `ink` | `#2B2840` | Texto principal. |
| `inkMuted` | `#6B6880` | Texto secundario, placeholders, bordes de campo en reposo. |
| `error` | `#C62828` | Errores de validación y snackbars de error. |
| `success` | `#2E7D32` | Confirmaciones (código vinculado, guardado). |

Arma el `ColorScheme` con `ColorScheme.fromSeed(seedColor: lavenderDeep)` y sobrescribe `primary: lavenderDeep`, `secondary: pinkDeep`, `surface`, `error`. El modo oscuro es opcional; si lo haces, que use los mismos nombres de token.

### Tipografía

- Fuente: **Poppins** vía el paquete `google_fonts` (`GoogleFonts.poppinsTextTheme()`), o empaquetada en `assets/fonts/` y declarada en `pubspec.yaml`. Elige una y quita los `fontFamily: 'Poppins'` sueltos.
- Escala (usa `Theme.of(context).textTheme`, no tamaños a mano):
  - `headlineMedium` 28 / w700 — título de pantalla grande (bienvenida, login).
  - `titleLarge` 22 / w600 — títulos de tarjeta y de sección.
  - `titleMedium` 16 / w600 — etiquetas fuertes, botones.
  - `bodyLarge` 16 / w400 — texto normal.
  - `bodyMedium` 14 / w400 — texto secundario (`inkMuted`).
  - `labelSmall` 12 / w500 — chips, fechas, contadores.
- Respeta el escalado de texto del sistema: nada de alturas fijas que corten texto; prueba con texto al 130%.

### Espaciado, radios y sombras (`app_spacing.dart`)

- Espaciado en múltiplos de 4: `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 24`, `xxl 32`. Margen lateral de pantalla: `lg` (16) en teléfono.
- Radios: `sm 12` (campos, chips), `md 16` (botones, tarjetas), `lg 24` (hojas inferiores, tarjetas destacadas), círculo para avatares.
- Sombras suaves y tintadas, nunca negras duras: `BoxShadow(color: lavenderDeep.withValues(alpha: 0.12), blurRadius: 16, offset: Offset(0, 6))`. Usa `withValues(alpha:)`, no `withOpacity` (deprecado).

## Componentes base (`lib/ui/widgets/`)

Antes de crear un widget, busca si ya existe uno aquí. Si una pantalla necesita una variante, extiende el componente; no copies su código.

- **Campos de texto**: el estilo vive en `ThemeData.inputDecorationTheme` (relleno `surface`, borde `inkMuted` 1px, foco `lavenderDeep` 2px, error `error`, radio `sm`). En pantalla solo se pasa `labelText`, `prefixIcon` y `suffixIcon`. Prohibido repetir los 4 `OutlineInputBorder` por campo.
- **`AppPrimaryButton`**: ancho completo, alto mínimo 52, radio `md`, fondo `lavenderDeep`, texto `titleMedium` blanco. Recibe `loading`: cuando es `true` muestra un `CircularProgressIndicator` blanco de 20 px y se deshabilita.
- **`AppSecondaryButton`**: borde `lavenderDeep`, fondo transparente. Para "Registrarse", "Cancelar", etc.
- **`AppCard`**: fondo `surface`, radio `md`, sombra suave, padding `lg`.
- **Estados** (toda pantalla que carga datos los tiene los tres):
  - Cargando: esqueletos o el Lottie `loading_animation.json`, nunca una pantalla en blanco.
  - Vacío: ilustración/Lottie + una frase cálida + la acción para llenarlo ("Aún no tienen recuerdos. ¡Agreguen el primero!").
  - Error: mensaje del backend (`ApiException.message`) + botón "Reintentar".
- **Snackbars**: `SnackBarBehavior.floating`, radio `sm`, `error` para fallos y `success` para confirmaciones.

## Movimiento

- Lottie ya disponible: `AnimacionPantalla.json` (login), `heart.json` (registro), `loading_animation.json` (splash/carga). Reutilízalos antes de agregar otros; cualquier Lottie nuevo va en `assets/lottie/` y en `pubspec.yaml`.
- Transiciones de 200–300 ms con `Curves.easeOutCubic`. Usa `AnimatedSwitcher`, `AnimatedContainer` y `Hero` (por ejemplo la foto de un recuerdo de la lista al detalle).
- Vibración ligera (`HapticFeedback.lightImpact()`) solo en momentos de pareja: vincular código, enviar algo al otro.

## Accesibilidad (no negociable)

- Contraste mínimo 4.5:1 para texto normal y 3:1 para texto grande e íconos. Por eso `lavender` y `pink` no llevan texto.
- Objetivos táctiles de al menos 48×48 dp.
- Todo `IconButton` lleva `tooltip`; las imágenes con significado llevan `semanticLabel`.
- No transmitas información solo con color (un error lleva texto, no solo borde rojo).

## Estructura de pantalla

- `Scaffold` con fondo `background`, `SafeArea`, y contenido en `SingleChildScrollView` o listas con `padding: EdgeInsets.all(AppSpacing.lg)`.
- `AppBar` limpia: fondo `background`, sin sombra (`scrolledUnderElevation` suave), título `titleLarge` en `ink`.
- Una sola acción primaria por pantalla, abajo y visible sin hacer scroll cuando sea posible.
- No metas lógica de red en los widgets: llama servicios de `lib/auth/data/` o `lib/core/api_client.dart` y maneja `ApiException`.

## Verificar en el celular (obligatorio después de cada cambio visual)

Herramientas en esta PC: Flutter en `C:\flutter\bin`, adb en `%LOCALAPPDATA%\Android\Sdk\platform-tools`. El backend corre en Docker en el puerto 8080 y el celular lo ve por USB con `adb reverse`.

```bash
export PATH="/c/flutter/bin:$LOCALAPPDATA/Android/Sdk/platform-tools:$PATH"
cd /c/ArryUwu
flutter analyze                                  # 0 errores y 0 warnings antes de seguir
adb devices                                      # debe aparecer el celular como "device"
adb reverse tcp:8080 tcp:8080
flutter build apk --debug --dart-define=API_URL=http://localhost:8080
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p com.arryuwu.arryuwu -c android.intent.category.LAUNCHER 1
adb shell input keyevent KEYCODE_WAKEUP         # si la pantalla está apagada la captura sale negra
adb exec-out screencap -p > "$TMP/arry-shot.png"   # luego ábrela con la herramienta Read para verla
```

- Si la captura sale toda negra, el celular está apagado o bloqueado: despiértalo con `KEYCODE_WAKEUP`; si tiene PIN, pide al usuario que lo desbloquee (nunca intentes adivinar ni escribir el PIN).

- Para llegar a una pantalla concreta puedes tocar con `adb shell input tap X Y` o escribir con `adb shell input text "..."`. Calcula las coordenadas sobre la captura anterior (`adb shell wm size` da la resolución).
- Guarda las capturas en el directorio temporal, no dentro del proyecto.
- Revisa cada captura contra esta skill: contraste, alineación a la cuadrícula de 4, una acción primaria, estados de carga/vacío/error, texto sin cortar.
- Si no hay celular conectado, dilo y entrega solo con `flutter analyze` limpio; no afirmes que "se ve bien" sin haberlo visto.
