import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/services/image_export_service.dart';

void main() {
  testWidgets(
    'returns null when the key is not attached to any render object',
    (tester) async {
      final key = GlobalKey();

      final result = await captureBoundaryAsPng(key);

      expect(result, isNull);
    },
  );
}
