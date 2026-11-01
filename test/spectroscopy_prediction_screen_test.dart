import 'dart:async';

import 'package:chem_buddy/data/services/spectroscopy_prediction_service.dart';
import 'package:chem_buddy/presentation/screens/spectroscopy_prediction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/spectroscopy_prediction_fixture.dart';

class PredictionStub extends SpectroscopyPredictionService {
  Object? error;
  Completer<SpectroscopyPrediction>? pending;
  @override
  Future<SpectroscopyPrediction> predict(
    SpectroscopyPredictionRequest request,
  ) async {
    if (error != null) throw error!;
    return pending == null ? ethanolPrediction() : pending!.future;
  }
}

void main() {
  Future<void> mount(WidgetTester tester, PredictionStub service) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: SpectroscopyPredictionScreen(service: service)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'ethanol');
    await tester.ensureVisible(find.byKey(const ValueKey('predict-gemini')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'predicted NMR and structure SVG render with explicit uncertainty on mobile',
    (tester) async {
      await mount(tester, PredictionStub());
      await tester.tap(find.byKey(const ValueKey('predict-gemini')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ethanol'), findsOneWidget);
      expect(
        find.textContaining('internal consistency, not experimental accuracy'),
        findsOneWidget,
      );
      expect(find.byType(SvgPicture), findsNWidgets(2));
      final carbon = find.text('¹³C NMR');
      await tester.ensureVisible(carbon);
      await tester.pumpAndSettle();
      await tester.tap(carbon);
      await tester.pumpAndSettle();
      expect(find.textContaining('58.00 ppm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'cloud error produces no fabricated SVG or leftover previous result',
    (tester) async {
      await mount(
        tester,
        PredictionStub()
          ..error = StateError('Sign in to use Gemini prediction.'),
      );
      await tester.tap(find.byKey(const ValueKey('predict-gemini')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('prediction-error')), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    },
  );
  testWidgets('cancelling discards a late response', (tester) async {
    final service = PredictionStub()
      ..pending = Completer<SpectroscopyPrediction>();
    await mount(tester, service);
    await tester.tap(find.byKey(const ValueKey('predict-gemini')));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    service.pending!.complete(ethanolPrediction());
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsNothing);
  });
}
