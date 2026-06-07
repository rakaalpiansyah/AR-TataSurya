import 'package:ar_tatasurya_project/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menampilkan home screen AR Tata Surya', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('AR Tata Surya'), findsOneWidget);
    expect(find.text('Mulai Eksplorasi AR'), findsOneWidget);
    expect(find.text('Materi edukatif'), findsOneWidget);
  });
}
