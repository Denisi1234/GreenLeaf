import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';

bool isNetworkImagePath(String path) =>
    kIsWeb || path.startsWith('http://') || path.startsWith('https://');

ImageProvider<Object> appImageProvider(BuildContext context, String path) {
  if (isNetworkImagePath(path)) {
    final api = context.read<PosLocalStore?>()?.cloudApi;
    return NetworkImage(path, headers: api?.imageHeaders(path));
  }
  return FileImage(File(path));
}
