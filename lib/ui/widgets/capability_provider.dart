import 'package:flutter/material.dart';
import 'package:track_mauzo/service/pos_local_store.dart';
import 'package:track_mauzo/ui/models/capability.dart';

class CapabilityProvider extends InheritedWidget {
  final Set<Capability> capabilities;

  const CapabilityProvider({
    super.key,
    required this.capabilities,
    required super.child,
  });

  static CapabilityProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CapabilityProvider>();
  }

  bool hasCapability(Capability capability) => capabilities.contains(capability);

  @override
  bool updateShouldNotify(CapabilityProvider oldWidget) {
    return capabilities != oldWidget.capabilities;
  }
}
