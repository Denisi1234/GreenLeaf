import 'package:intl/intl.dart';

import '../service/pos_local_store.dart';

class DailySalesReportService {
  static const Duration eastAfricaOffset = Duration(hours: 3);

  /// Computes East Africa Time (UTC+3)
  static DateTime eastAfricaNow() =>
      DateTime.now().toUtc().add(eastAfricaOffset);

  /// Builds the daily end-of-day summary message.
  ///
  /// Format:
  /// Habari ya jioni [Owner], mauzo yako ya leo ni TSH [X]. Mauzo ya wiki hii ni TSH [Y], yamepungua/yameongezeka kutoka TSH [Z] wiki iliyopita. Asante kwa kutumia TrackMauzo.
  static String buildDailyReportMessage({
    required PosLocalStore store,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? eastAfricaNow();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate start of current week (Monday)
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final thisWeekStart = today.subtract(Duration(days: weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(milliseconds: 1));

    double todaySales = 0.0;
    double thisWeekSales = 0.0;
    double lastWeekSales = 0.0;

    for (final order in store.orders) {
      if (order.status.toLowerCase() == 'voided') continue;

      final orderDate = DateTime.tryParse(order.dateTime);
      if (orderDate == null) continue;

      // Adjust to East Africa local date for matching
      final orderLocal =
          orderDate.isUtc ? orderDate.add(eastAfricaOffset) : orderDate;
      final orderDay =
          DateTime(orderLocal.year, orderLocal.month, orderLocal.day);

      // Today's sales
      if (orderDay.isAtSameMomentAs(today)) {
        todaySales += order.total;
      }

      // This week's sales (from Monday to now)
      if (!orderLocal.isBefore(thisWeekStart)) {
        thisWeekSales += order.total;
      }
      // Last week's sales (Monday to Sunday of previous week)
      else if (!orderLocal.isBefore(lastWeekStart) &&
          orderLocal.isBefore(lastWeekEnd)) {
        lastWeekSales += order.total;
      }
    }

    final currencyFormat = NumberFormat('#,##0');
    final todayFormatted = currencyFormat.format(todaySales.round());
    final thisWeekFormatted = currencyFormat.format(thisWeekSales.round());
    final lastWeekFormatted = currencyFormat.format(lastWeekSales.round());

    // Resolve owner admin name
    String ownerName = store.profile.ownerName.trim();
    if (ownerName.isEmpty && store.currentUser != null) {
      ownerName = store.currentUser!.name.trim();
    }
    if (ownerName.isEmpty) {
      // Check if there is an owner role staff member
      final ownerStaff = store.staffMembers.where(
        (s) =>
            s.roleId.toLowerCase().contains('owner') ||
            (store
                    .staffRoleById(s.roleId)
                    ?.title
                    .toLowerCase()
                    .contains('owner') ??
                false),
      );
      if (ownerStaff.isNotEmpty) {
        ownerName = ownerStaff.first.name.trim();
      }
    }
    if (ownerName.isEmpty) {
      ownerName = 'Mkuu';
    }

    // Comparison against last week
    String comparisonText;
    if (lastWeekSales <= 0 && thisWeekSales <= 0) {
      comparisonText = '';
    } else if (lastWeekSales <= 0) {
      comparisonText = ' (wiki iliyopita haikuwa na mauzo yaliyorekodiwa)';
    } else if (thisWeekSales >= lastWeekSales) {
      final diff =
          currencyFormat.format((thisWeekSales - lastWeekSales).round());
      comparisonText =
          ', yameongezeka kutoka TSH $lastWeekFormatted wiki iliyopita (+TSH $diff)';
    } else {
      final diff =
          currencyFormat.format((lastWeekSales - thisWeekSales).round());
      comparisonText =
          ', yamepungua kutoka TSH $lastWeekFormatted wiki iliyopita (-TSH $diff)';
    }

    return 'Habari ya jioni $ownerName, mauzo yako ya leo ni TSH $todayFormatted. Mauzo ya wiki hii ni TSH $thisWeekFormatted$comparisonText. Asante kwa kutumia TrackMauzo.';
  }

  /// Sends the daily SMS report to the owner's phone.
  static Future<DailySmsResult> sendDailyReport({
    required PosLocalStore store,
    String? overridePhone,
  }) async {
    // Resolve phone
    var phone = (overridePhone != null && overridePhone.trim().isNotEmpty)
        ? overridePhone.trim()
        : store.profile.contactNumber.trim();

    if (phone.isEmpty && store.currentUser != null) {
      phone = store.currentUser!.phone.trim();
    }
    if (phone.isEmpty) {
      final ownerStaff = store.staffMembers.where(
        (s) =>
            s.roleId.toLowerCase().contains('owner') ||
            (store
                    .staffRoleById(s.roleId)
                    ?.title
                    .toLowerCase()
                    .contains('owner') ??
                false),
      );
      if (ownerStaff.isNotEmpty) {
        phone = ownerStaff.first.phone.trim();
      }
    }

    if (phone.isEmpty) {
      return const DailySmsResult(
        success: false,
        message:
            'Hakuna namba ya simu ya mmiliki iliyowekwa kwenye Store Profile au Staff.',
      );
    }

    final api = store.cloudApi;
    if (api == null) {
      return const DailySmsResult(
        success: false,
        message:
            'Kutuma ripoti kwa SMS kunahitaji muunganisho wa mtandao na seva.',
      );
    }

    final smsText = buildDailyReportMessage(store: store);
    bool sent;
    try {
      sent = await api.sendSms(phone: phone, text: smsText);
    } catch (_) {
      sent = false;
    }

    if (sent) {
      return DailySmsResult(
        success: true,
        message: 'Ripoti ya leo imetumwa kwa SMS kwenda $phone kwa mafanikio.',
        smsText: smsText,
      );
    } else {
      return DailySmsResult(
        success: false,
        message:
            'Kushindwa kutuma SMS kupitia seva. Tafadhali thibitisha salio au mtandao.',
        smsText: smsText,
      );
    }
  }
}

class DailySmsResult {
  const DailySmsResult({
    required this.success,
    required this.message,
    this.smsText,
  });

  final bool success;
  final String message;
  final String? smsText;
}
