import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';

bool isNetworkImagePath(String path) =>
    kIsWeb ||
    path.startsWith('http://') ||
    path.startsWith('https://') ||
    path.startsWith('uploads/');

/// Resolves a stored image reference into a URL the current API host can serve.
String resolveImageUrl(BuildContext context, String path) {
  final api = context.read<PosLocalStore?>()?.cloudApi;
  return api?.imageUrl(path) ?? path;
}

ImageProvider<Object> appImageProvider(BuildContext context, String path) {
  final api = context.read<PosLocalStore?>()?.cloudApi;
  final resolved = api?.imageUrl(path) ?? path;
  if (kIsWeb ||
      resolved.startsWith('http://') ||
      resolved.startsWith('https://')) {
    return NetworkImage(resolved, headers: api?.imageHeaders(resolved));
  }
  return FileImage(File(path));
}
