import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/quantity_formatter.dart';

/// Professional Real Mobile Push & Local Notification Service
class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Android Notification Channels
  static const String salesChannelId = 'sales_channel';
  static const String salesChannelName = 'Sales & Transactions';
  static const String salesChannelDesc =
      'Notifications for completed sales and payments';

  static const String alertsChannelId = 'alerts_channel';
  static const String alertsChannelName = 'Inventory & Critical Alerts';
  static const String alertsChannelDesc =
      'Notifications for low inventory stock and store alerts';

  static const String generalChannelId = 'general_channel';
  static const String generalChannelName = 'General Updates';
  static const String generalChannelDesc =
      'General system and store notifications';

  Future<void> initialize({
    void Function(NotificationResponse)? onNotificationTap,
  }) async {
    if (_initialized) return;

    try {
      // Android settings - ic_launcher is guaranteed to exist
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Darwin / iOS settings
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Linux settings
      const linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open notification');

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
      );

      // Request permissions for Android 13+
      await requestPermissions();

      // Create high-importance Android channels
      await _createAndroidChannels();

      _initialized = true;
      debugPrint('[AppNotificationService] Initialized successfully');
    } catch (e) {
      debugPrint('[AppNotificationService] Initialization skipped: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS || Platform.isMacOS) {
      final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<void> _createAndroidChannels() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) return;

    // High priority sales channel
    await androidImplementation.createNotificationChannel(
      const AndroidNotificationChannel(
        salesChannelId,
        salesChannelName,
        description: salesChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Alerts channel
    await androidImplementation.createNotificationChannel(
      const AndroidNotificationChannel(
        alertsChannelId,
        alertsChannelName,
        description: alertsChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // General updates channel
    await androidImplementation.createNotificationChannel(
      const AndroidNotificationChannel(
        generalChannelId,
        generalChannelName,
        description: generalChannelDesc,
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );
  }

  /// Show a real system notification for a recorded sale
  Future<void> showSaleNotification({
    required String receiptNo,
    required double totalAmount,
    String? currency = 'TSh',
  }) async {
    final formattedAmount = '$currency ${totalAmount.toStringAsFixed(2)}';
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Mauzo Mapya Yamerekodiwa 💰',
      body:
          'Stakabadhi #$receiptNo ya $formattedAmount imekamilika kikamilifu.',
      channelId: salesChannelId,
      channelName: salesChannelName,
      channelDescription: salesChannelDesc,
      payload: 'receipt:$receiptNo',
    );
  }

  /// Show a real system notification for low inventory
  Future<void> showLowStockNotification({
    required String productName,
    required num remainingQuantity,
    String unit = '',
  }) async {
    final qtyText = unit.trim().isNotEmpty
        ? formatStockWithUnit(remainingQuantity.toDouble(), unit)
        : formatQuantity(remainingQuantity.toDouble());
    await showNotification(
      id: productName.hashCode.abs() % 100000,
      title: 'Tahadhari ya Bidhaa Kuisha ⚠️',
      body: 'Bidhaa "$productName" imebaki $qtyText tu stoo!',
      channelId: alertsChannelId,
      channelName: alertsChannelName,
      channelDescription: alertsChannelDesc,
      payload: 'inventory:$productName',
    );
  }

  /// Generic display method for real OS push notifications
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = generalChannelId,
    String channelName = generalChannelName,
    String channelDescription = generalChannelDesc,
    String? payload,
    Importance importance = Importance.max,
    Priority priority = Priority.high,
  }) async {
    if (!_initialized) return;
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[AppNotificationService] Failed to display notification: $e');
    }
  }

  /// Cancel all displayed notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
