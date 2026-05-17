import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'service/pos_local_store.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = PosLocalStore();
  await store.initialize();
  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const App(),
    ),
  );
}
