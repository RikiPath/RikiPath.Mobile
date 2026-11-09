import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/widgets/sakura_3d_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all Sakura 3D illustrations load with transparent pixels', () async {
    for (final icon in Sakura3DIconType.values) {
      final data = await rootBundle.load(icon.assetPath);
      expect(data.lengthInBytes, lessThan(150000), reason: icon.assetPath);

      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 128,
        targetHeight: 128,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        expect(image.width, greaterThanOrEqualTo(128), reason: icon.assetPath);
        expect(image.height, greaterThanOrEqualTo(128), reason: icon.assetPath);
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        expect(pixels, isNotNull, reason: icon.assetPath);
        final rgba = pixels!.buffer.asUint8List();
        expect(
          Iterable<int>.generate(
            rgba.length ~/ 4,
          ).any((index) => rgba[index * 4 + 3] < 255),
          isTrue,
          reason: '${icon.assetPath} has an opaque baked-in background',
        );
      } finally {
        image.dispose();
        codec.dispose();
      }
    }
  });
}
