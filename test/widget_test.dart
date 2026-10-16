import 'package:flutter_test/flutter_test.dart';
import 'package:myfirstminiproj/main.dart';

void main() {
  testWidgets('Игра запускается с полем 3x3', (tester) async {
    await tester.pumpWidget(const CatGameApp());
    expect(find.text('Уровень 1'), findsOneWidget);
    expect(find.text('?'), findsNWidgets(9));
  });
}
