import 'dart:typed_data';
import 'dart:ui' as ui;

/// Color measurements taken from a photograph.
///
/// These describe pixels only. They are not a species identification.
class VisibleImageSummary {
  const VisibleImageSummary({
    required this.decoded,
    required this.sampledPixels,
    required this.greenFraction,
    required this.nonGreenSaturatedFraction,
    required this.meanBrightness,
  });

  final bool decoded;
  final int sampledPixels;
  final double greenFraction;
  final double nonGreenSaturatedFraction;
  final double meanBrightness;

  static const VisibleImageSummary unreadable = VisibleImageSummary(
    decoded: false,
    sampledPixels: 0,
    greenFraction: 0,
    nonGreenSaturatedFraction: 0,
    meanBrightness: 0,
  );

  bool get mostlyGreenFoliage => decoded && greenFraction >= 0.45;

  bool get hasNonGreenColor => decoded && nonGreenSaturatedFraction >= 0.08;

  String get explanation {
    if (!decoded || sampledPixels == 0) {
      return 'The photo could not be measured. You can still match traits you observe. '
          'This app has no trained plant-recognition model, so it cannot name a species from the image alone.';
    }
    final buffer = StringBuffer()
      ..write(
        'Sampled $sampledPixels pixels. ',
      );
    if (mostlyGreenFoliage) {
      buffer.write(
        'Most of those pixels are green, which fits foliage in the frame. Green color is not used as a species trait. ',
      );
    } else {
      buffer.write(
        'The photo is not mostly green (${(greenFraction * 100).toStringAsFixed(0)}% of sampled pixels). ',
      );
    }
    if (hasNonGreenColor) {
      buffer.write(
        'Some pixels are strongly colored and not green. If you can see flowers or fruit, select that color yourself. ',
      );
    }
    buffer.write(
      'Average brightness is ${(meanBrightness * 100).toStringAsFixed(0)}%. '
      'These figures are color statistics, not an identification.',
    );
    return buffer.toString();
  }

  static VisibleImageSummary fromRgba(Uint8List rgba) {
    final pixels = rgba.length ~/ 4;
    if (pixels == 0) return unreadable;
    var green = 0;
    var nonGreen = 0;
    var brightnessTotal = 0.0;
    for (var index = 0; index < pixels; index++) {
      final offset = index * 4;
      final red = rgba[offset];
      final greenChannel = rgba[offset + 1];
      final blue = rgba[offset + 2];
      final maxChannel = [red, greenChannel, blue].reduce(
        (a, b) => a > b ? a : b,
      );
      final minChannel = [red, greenChannel, blue].reduce(
        (a, b) => a < b ? a : b,
      );
      final isGreen =
          greenChannel > red && greenChannel > blue && greenChannel > 50;
      if (isGreen) {
        green++;
      } else if (maxChannel - minChannel > 40 && maxChannel > 60) {
        nonGreen++;
      }
      brightnessTotal += (red + greenChannel + blue) / (3 * 255);
    }
    return VisibleImageSummary(
      decoded: true,
      sampledPixels: pixels,
      greenFraction: green / pixels,
      nonGreenSaturatedFraction: nonGreen / pixels,
      meanBrightness: brightnessTotal / pixels,
    );
  }

  static Future<VisibleImageSummary> fromBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      if (data == null) return unreadable;
      return fromRgba(data.buffer.asUint8List());
    } on Object {
      return unreadable;
    }
  }
}
