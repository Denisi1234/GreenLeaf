import 'dart:convert';
import 'dart:io';

/// Generates per-locale Dart catalog files from standard `.arb` files in
/// `lib/l10n/arb/`.
///
/// Usage:
///   dart run tool/generate_l10n.dart
Future<void> main() async {
  final arbDir = Directory('lib/l10n/arb');
  final outDir = Directory('lib/l10n/generated');

  if (!arbDir.existsSync()) {
    stderr.writeln('Error: ${arbDir.path} does not exist.');
    exitCode = 1;
    return;
  }
  outDir.createSync(recursive: true);

  final arbFiles = arbDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in arbFiles) {
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final locale = (decoded['@@locale'] as String?) ??
        file.uri.pathSegments.last
            .replaceFirst(RegExp(r'^app_'), '')
            .replaceFirst(RegExp(r'\.arb$'), '');

    final entries = <String, String>{};
    for (final entry in decoded.entries) {
      if (entry.key.startsWith('@')) continue;
      entries[entry.key] = entry.value.toString();
    }

    final sortedKeys = entries.keys.toList()..sort();
    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
      ..writeln('// Source: lib/l10n/arb/${file.uri.pathSegments.last}')
      ..writeln('// Regenerate with: dart run tool/generate_l10n.dart')
      ..writeln()
      ..writeln('const ${locale}UiCatalog = <String, String>{');

    for (final key in sortedKeys) {
      final k = _escapeDartString(key);
      final v = _escapeDartString(entries[key]!);
      buffer.writeln("  '$k': '$v',");
    }
    buffer.writeln('};');

    final outFile = File('${outDir.path}/${locale}_catalog.g.dart');
    outFile.writeAsStringSync(buffer.toString());
    stdout.writeln('Generated ${outFile.path} (${entries.length} keys)');
  }
}

String _escapeDartString(String input) {
  return input
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
}
