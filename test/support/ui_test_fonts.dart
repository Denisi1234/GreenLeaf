import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> configureUiTestFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  // Use the SDK's bundled Roboto for deterministic, offline UI tests.
  var directory = File(Platform.resolvedExecutable).parent;
  while (!File('${directory.path}/artifacts/material_fonts/roboto-regular.ttf')
          .existsSync() &&
      directory.path != directory.parent.path) {
    directory = directory.parent;
  }
  final cache = directory.path;
  final regular =
      await File('$cache/artifacts/material_fonts/roboto-regular.ttf')
          .readAsBytes();
  final bold = await File('$cache/artifacts/material_fonts/roboto-bold.ttf')
      .readAsBytes();
  final original = await rootBundle.load('AssetManifest.bin');
  const codec = StandardMessageCodec();
  final manifest =
      Map<Object?, Object?>.from(codec.decodeMessage(original)! as Map);
  final fonts = <String, ByteData>{};
  for (final weight in [
    'Thin',
    'ExtraLight',
    'Light',
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
    'Black'
  ]) {
    final path = 'test-fonts/Manrope-$weight.ttf';
    manifest[path] = [
      <String, Object?>{'asset': path}
    ];
    fonts[path] = ByteData.sublistView(
        ['SemiBold', 'Bold', 'ExtraBold', 'Black'].contains(weight)
            ? bold
            : regular);
  }
  final encodedManifest = codec.encodeMessage(manifest);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
    final path = const StringCodec().decodeMessage(message)!;
    if (path == 'AssetManifest.bin') return encodedManifest;
    if (fonts.containsKey(path)) return fonts[path];
    final file = File('build/unit_test_assets/$path');
    return await file.exists()
        ? ByteData.sublistView(await file.readAsBytes())
        : null;
  });
  rootBundle.evict('AssetManifest.bin');
  for (final family in ['Roboto', 'Ahem']) {
    final loader = FontLoader(family);
    loader.addFont(Future.value(ByteData.sublistView(regular)));
    await loader.load();
  }
  final iconLoader = FontLoader('MaterialIcons');
  iconLoader.addFont(Future.value(ByteData.sublistView(
      await File('$cache/artifacts/material_fonts/materialicons-regular.otf')
          .readAsBytes())));
  await iconLoader.load();
}
