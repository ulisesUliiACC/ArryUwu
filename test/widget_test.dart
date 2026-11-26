import 'package:arryuwu/features/home/data/me.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Me.fromJson lee la pareja y calcula los días juntos', () {
    final since = DateTime.now().subtract(const Duration(days: 9));
    final me = Me.fromJson({
      'userName': 'ulises',
      'nombre': 'Ulises Alberto',
      'apellido': 'X',
      'email': 'u@example.test',
      'partner': {'userName': 'ana', 'nombre': 'Ana', 'linkedSince': since.toIso8601String()},
    });

    expect(me.firstName, 'Ulises');
    expect(me.partner!.displayName, 'Ana');
    expect(me.partner!.daysTogether, 10);
  });

  test('Sin pareja, partner es null y sin nombre se usa el usuario', () {
    final me = Me.fromJson({'userName': 'ulises', 'nombre': null, 'email': 'u@example.test'});
    expect(me.partner, isNull);
    expect(me.firstName, 'ulises');
  });
}
