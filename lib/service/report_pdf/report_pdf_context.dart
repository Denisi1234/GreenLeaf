import 'package:intl/intl.dart';
import '../../l10n/app_strings.dart';
import '../pos_local_store.dart';

/// Immutable metadata captured when an export starts, shared by all PDF paths.
class ReportPdfContext {
  ReportPdfContext({
    this.businessName = '',
    this.preparedBy = '',
    String languageCode = 'en',
    this.currency = 'TSh',
    DateTime? generatedAt,
    this.reference,
    this.dateFormat = 'MMM d, yyyy',
    this.uses24HourTime = true,
    this.period = '',
    this.filterSummary = '',
  })  : generatedAt = generatedAt ?? DateTime.now(),
        languageCode = AppStrings.normalize(languageCode);

  factory ReportPdfContext.fromStore(
    PosLocalStore store, {
    String? languageCode,
    String period = '',
    String filterSummary = '',
    DateTime? generatedAt,
    String? reference,
  }) =>
      ReportPdfContext(
        businessName: store.activeStoreName,
        preparedBy: store.currentUser?.name ?? store.profile.ownerName,
        languageCode: languageCode ?? store.languageCode,
        currency: store.profile.currency,
        generatedAt: generatedAt,
        reference: reference,
        dateFormat: store.storePreferences.dateFormat,
        uses24HourTime: store.storePreferences.uses24HourTime,
        period: period,
        filterSummary: filterSummary,
      );

  final String businessName;
  final String preparedBy;
  final String languageCode;
  final String currency;
  final DateTime generatedAt;
  final String? reference;
  final String dateFormat;
  final bool uses24HourTime;
  final String period;
  final String filterSummary;
  AppStrings get strings => AppStrings.of(languageCode);
  String get reportReference =>
      reference ??
      'RPT-${generatedAt.microsecondsSinceEpoch.toRadixString(36).toUpperCase()}';
  String get dateLabel => DateFormat(
        '$dateFormat ${uses24HourTime ? 'HH:mm' : 'h:mm a'}',
        strings.languageCode,
      ).format(generatedAt);

  ReportPdfContext withPeriod(String value) => ReportPdfContext(
        businessName: businessName,
        preparedBy: preparedBy,
        languageCode: languageCode,
        currency: currency,
        generatedAt: generatedAt,
        reference: reference,
        dateFormat: dateFormat,
        uses24HourTime: uses24HourTime,
        period: period.isEmpty ? value : period,
        filterSummary: filterSummary,
      );

  /// PDF-only labels supplement the app catalog without changing stored data.
  String label(String english) {
    if (!strings.isSwahili) return english;
    final tax = RegExp(r'^Tax calculated at ([0-9.]+)% (included in|added to) prices\.$').firstMatch(english);
    if (tax != null) {
      return 'Kodi ya ${tax[1]}% ${tax[2] == 'included in' ? 'imejumuishwa kwenye' : 'imeongezwa kwenye'} bei.';
    }
    if (english.startsWith('Tax identification number: ')) {
      final number = english.substring(27);
      return 'Namba ya utambulisho wa kodi: ${number == 'not set.' ? 'haijawekwa.' : number}';
    }
    if (english.endsWith(' collected')) {
      return '${strings.text(english.substring(0, english.length - 10))} iliyokusanywa';
    }
    return _sw[english] ?? strings.text(english);
  }

  String paragraph(String value) {
    final parts = strings.paragraph(value).split('. ');
    return [
      for (var i = 0; i < parts.length; i++)
        label(i < parts.length - 1 ? '${parts[i]}.' : parts[i])
    ].join(' ');
  }

  static const _sw = {
    'Tax is disabled.': 'Kodi imezimwa.',
    'Enable it in Settings → Tax settings to populate tax figures.': 'Washa kodi kwenye Mipangilio - Mipangilio ya kodi ili kuona takwimu zake.',
    'Turn it on in Settings → Tax settings.': 'Washa kodi kwenye Mipangilio - Mipangilio ya kodi.',
    'Issued on credit': 'Imetolewa kwa mkopo',
    'Unknown': 'Haijulikani',
    'Draft': 'Rasimu',
    'Submitted': 'Imewasilishwa',
    'Approved': 'Imeidhinishwa',
    'Reimbursed': 'Imelipwa',
    'No ledger activity yet.': 'Hakuna shughuli za leja bado.',
    'Sales, expenses, purchases and journal entries populate this report.': 'Mauzo, matumizi, manunuzi na miamala ya jarida hujaza ripoti hii.',
    'No ledger balances yet.': 'Hakuna salio la leja bado.',
    'Record sales and expenses to build the balance sheet.': 'Rekodi mauzo na matumizi kutengeneza taarifa ya hali ya fedha.',
    'Derived from sales, expenses, purchases, payments and manual journal entries.': 'Imetokana na mauzo, matumizi, manunuzi, malipo na miamala ya jarida iliyowekwa kwa mkono.',
    'Straight line depreciation, calculated to date.': 'Uchakavu kwa kiwango sawa kwa mwaka, uliokokotolewa hadi sasa.',
    'No statement lines imported.': 'Hakuna rekodi za taarifa ya benki zilizoingizwa.',
    'Add or paste statement lines to reconcile bank and mobile money.': 'Ongeza au bandika rekodi kupatanisha benki na pesa kwa simu.',
    'No bank statement lines yet.': 'Hakuna rekodi za taarifa ya benki bado.',
    'Import or add statement lines to reconcile.': 'Ingiza au ongeza rekodi za taarifa ya benki ili kupatanisha.',
    'Compared across all stores.': 'Ulinganisho wa maduka yote.',
    'Date filters apply to sales, expenses, receivings and shifts where relevant.': 'Vichujio vya tarehe hutumika kwa mauzo, matumizi, bidhaa zilizopokelewa na zamu inapohusika.',
    'Check': 'Ukaguzi',
    'Store name': 'Jina la duka',
    'Date': 'Tarehe',
    'Prepared by': 'Mhusika / Msimamizi',
    'Reference': 'Namba ya kumbukumbu',
    'Period': 'Kipindi',
    'Filters': 'Vichujio',
    'No.': 'Na.',
    'Report results': 'Matokeo ya ripoti',
    'All dates': 'Tarehe zote',
    'Current snapshot': 'Hali ya sasa',
    'Page': 'Ukurasa',
    'of': 'kati ya',
    '(cont.)': '(ende.)',
    'No records available for the selected filters.':
        'Hakuna rekodi kwa vichujio vilivyochaguliwa.',
    'Customer Report': 'Ripoti ya wateja',
    'Expense Report': 'Ripoti ya matumizi',
    'Statement of account': 'Taarifa ya deni na malipo',
    'Customers': 'Wateja',
    'Total spent': 'Jumla ya matumizi',
    'Outstanding balance': 'Deni lililobaki',
    'Total expenses': 'Jumla ya matumizi',
    'Total charges': 'Jumla ya madeni',
    'Total paid': 'Jumla ya malipo',
    'Customer': 'Mteja',
    'Phone': 'Simu',
    'Email': 'Barua pepe',
    'Address': 'Anwani',
    'Status': 'Hali',
    'Outstanding': 'Lina deni',
    'Settled': 'Limelipwa',
    'Charge (+)': 'Deni (+)',
    'Payment (-)': 'Malipo (-)',
    'Reference / Note': 'Kumbukumbu / Maelezo',
    'Credit sale': 'Mauzo ya mkopo',
    'Payment': 'Malipo',
    'Type': 'Aina',
    'Records': 'Rekodi',
    'Summary': 'Muhtasari',
    'Notes': 'Maelezo',
    'Search': 'Utafutaji',
    'Selection': 'Chaguo',
    'Cost of goods sold': 'Gharama ya bidhaa zilizouzwa',
    'Recorded expenses': 'Matumizi yaliyorekodiwa',
    'Operating': 'Uendeshaji',
    'Financing': 'Ufadhili',
    'Investing': 'Uwekezaji',
    'Cash from drawer top-ups': 'Fedha zilizoongezwa kwenye kasha',
    'Drawings and payouts': 'Fedha zilizochukuliwa na kutolewa',
    'Fixed asset purchases': 'Manunuzi ya mali za kudumu',
    'Matched statement lines': 'Rekodi za benki zilizopatanishwa',
    'Unmatched statement lines': 'Rekodi za benki zisizopatanishwa',
    'Difference': 'Tofauti',
    'Tax collected': 'Kodi iliyokusanywa',
    'Tax paid on expenses': 'Kodi iliyolipwa kwenye matumizi',
    'Net tax payable': 'Kodi halisi ya kulipa',
    'Based on POS sales and recorded expenses.':
        'Inategemea mauzo na matumizi yaliyorekodiwa kwenye mfumo.',
    'General ledger adjustments are unavailable.':
        'Marekebisho ya leja kuu hayapatikani.',
  };
}
