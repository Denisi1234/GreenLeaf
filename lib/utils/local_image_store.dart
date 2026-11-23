import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies a freshly picked image out of the OS cache into app storage.
///
/// Gallery picks usually land in a temporary cache directory that the platform
/// may evict at any time. Persisting the bytes keeps a local preview valid even
/// before the image has synced to the server, and on devices that stay offline.
Future<String> persistPickedImage(XFile file, String prefix) async {
  if (kIsWeb) return file.path;
  try {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'images'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final extension = p.extension(file.path);
    final target = p.join(
      directory.path,
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    await file.saveTo(target);
    return target;
  } catch (_) {
    return file.path;
  }
}
