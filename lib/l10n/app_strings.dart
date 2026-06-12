import 'package:flutter/material.dart';

class AppStrings {
  const AppStrings._(this.languageCode);

  final String languageCode;

  static String normalize(String code) {
    return code == 'en' ? 'en' : 'sw';
  }

  static AppStrings of(String code) {
    return AppStrings._(normalize(code));
  }

  bool get isSwahili => languageCode == 'sw';

  String _pick(String english, String swahili) {
    return isSwahili ? swahili : english;
  }

  String get appName => 'TrackMauzo';
  String get dashboard => _pick('Dashboard', 'Dashibodi');
  String get products => _pick('Products', 'Bidhaa');
  String get sales => _pick('Sales', 'Mauzo');
  String get reports => _pick('Reports', 'Ripoti');
  String get more => _pick('More', 'Zaidi');
  String get home => _pick('Home', 'Nyumbani');
  String get inventory => _pick('Inventory', 'Hifadhi');
  String get settings => _pick('Settings', 'Mipangilio');
  String get english => _pick('English (US)', 'Kiingereza (US)');
  String get swahili => _pick('Swahili', 'Kiswahili');
  String get storeProfile => _pick('Store Profile', 'Wasifu wa Duka');
  String get staffManagement => _pick('Staff Management', 'Usimamizi wa Wafanyakazi');
  String get multiStoreManagement =>
      _pick('Multi-Store Management', 'Usimamizi wa Maduka Mengi');
  String get dukaAi => _pick('DUKA AI', 'DUKA AI');
  String get subscriptionPlan => _pick('Subscription Plan', 'Mpango wa Usajili');
  String get logout => _pick('Logout', 'Ondoka');

  String get activeStore => _pick('Active Store', 'Duka Linalofanya Kazi');
  String get selectActiveStore =>
      _pick('Select Active Store', 'Chagua Duka Linalofanya Kazi');
  String get createNewStore => _pick('Create New Store', 'Tengeneza Duka Jipya');
  String get storeName => _pick('Store Name', 'Jina la Duka');
  String get unknownStore => _pick('Unknown Store', 'Duka Lisilojulikana');
  String get cancel => _pick('Cancel', 'Ghairi');
  String get create => _pick('Create', 'Tengeneza');
  String get save => _pick('Save', 'Hifadhi');

  String get priceRequired => _pick('This price is required', 'Bei hii inahitajika');
  String get validAmountRequired => _pick('Enter a valid amount', 'Weka kiasi sahihi');
  String get productDeleted => _pick('Product Deleted', 'Bidhaa Imefutwa');
  String get staffManagementTitle => _pick('Staff Management', 'Usimamizi wa Wafanyakazi');
  String get addStaff => _pick('Add Staff', 'Ongeza Mfanyakazi');
  String get editStaff => _pick('Edit Staff', 'Hariri Mfanyakazi');
  String get staffName => _pick('Staff Name', 'Jina la Mfanyakazi');
  String get emailAddress => _pick('Email Address', 'Baruapepe');
  String get phoneNumber => _pick('Phone Number', 'Namba ya Simu');
  String get role => _pick('Role', 'Nafasi');
  String get staffNameRequired => _pick('Staff name is required', 'Jina la mfanyakazi linahitajika');
  String get emailRequired => _pick('Email is required', 'Baruapepe inahitajika');
  String get phoneRequired => _pick('Phone number is required', 'Namba ya simu inahitajika');
  String get roleRequired => _pick('Role is required', 'Nafasi inahitajika');
  String get staffSaved => _pick('Staff saved', 'Mfanyakazi amehifadhiwa');
  String get staffDeleted => _pick('Staff deleted', 'Mfanyakazi amefutwa');
  String get deleteStaff => _pick('Delete Staff?', 'Futa Mfanyakazi?');
  String deleteStaffConfirmation(String name) => _pick('Remove "$name" from staff? This cannot be undone.', 'Ondoa "$name" kutoka kwa wafanyakazi? Hili haliwezi kutenduliwa.');
  String get passwordRequired => _pick('Password is required', 'Nenosiri linahitajika');
  String get passwordMinLength => _pick('Password must be at least 6 characters', 'Nenosiri lazima liwe na angalau herufi 6');
  String get saving => _pick('Saving...', 'Inahifadhi...');
  String get saveStaff => _pick('Save Staff', 'Hifadhi Mfanyakazi');

  String get notifications => _pick('Notifications', 'Arifa');
  String get noNotifications => _pick('No notifications', 'Hakuna arifa');
  String get nothingToShow => _pick('Nothing to show right now.', 'Hakuna kitu cha kuonyesha kwa sasa.');
  String get markAllAsRead => _pick('Mark all as read', 'Weka zote zionekane zimesomwa');
  String get newSaleRecorded => _pick('New sale recorded', 'Mauzo mapya yameandikwa');
  String get lowStockAlert => _pick('Low stock alert', 'Arifa ya akiba ndogo');
  String get monthlyStatementReady => _pick('Monthly statement ready', 'Taarifa ya mwezi iko tayari');
  String get systemUpdateCompleted => _pick('System update completed', 'Sasisho la mfumo limekamilika');
  String newSaleMessage(String amount, String table) => _pick('TSh $amount from Table $table', 'TSh $amount kutoka Meza $table');
  String lowStockMessage(String item) => _pick('$item is under the reorder level', '$item iko chini ya kiwango cha kuagiza');
  String get statementReadyMessage => _pick('Your statement is ready to view', 'Taarifa yako iko tayari kuonekana');
  String get systemUpdateMessage => _pick('Your POS system was updated successfully', 'Mfumo wako wa POS umesasishwa kwa mafanikio');

  String get allCategories => _pick('All', 'Zote');
  String get clearSearch => _pick('Clear Search', 'Futa Utafutaji');
  String get noProductsFound => _pick('No products found', 'Bidhaa hazikupatikana');
  String get tryAdjustingSearch => _pick('Try adjusting your search query', 'Jaribu kurekebisha utafutaji wako');
  String get checkout => _pick('Checkout', 'Malipo');
  String get checkoutRetail => _pick('Checkout', 'Lipa');
  String get checkoutRestaurant => _pick('Open Table', 'Fungua Meza');
  String get checkoutPharmacy => _pick('Process Prescription', 'Kamilisha Dawa');
  String get checkoutElectronics => _pick('Process Warranty', 'Kamilisha Dhamana');
  String get checkoutWarehouse => _pick('Process Order', 'Kamilisha Oda');
  String get checkoutSupermarket => _pick('Loyalty Checkout', 'Lipa na Pointi');

  String get reportHub => _pick('Report Hub', 'Kituo cha Ripoti');
  String get reportsSubtitle => _pick('View insights, trends, and downloads', 'Tazama maarifa, mwenendo, na vipakuzi');
  String get downloadReport => _pick('Download Report', 'Pakua Ripoti');
  String get exportData => _pick('Export Data', 'Hamisha Takwimu');
  String get period => _pick('Period', 'Muda');
  String get periodToday => _pick('Today', 'Leo');
  String get periodWeek => _pick('This Week', 'Wiki Hii');
  String get periodMonth => _pick('This Month', 'Mwezi Huu');
  String get periodAllTime => _pick('All Time', 'Wakati Wote');
  String get shortToday => _pick('Today', 'Leo');
  String get shortWeek => _pick('Week', 'Wiki');
  String get shortMonth => _pick('Month', 'Mwezi');
  String get shortAll => _pick('All', 'Zote');
  String get viewAll => _pick('View All', 'Tazama Yote');
  String get noSalesYet => _pick('No completed sales in this period.', 'Bado hakuna mauzo katika kipindi hiki.');
  String get top => _pick('Top', 'Juu');
  String get revenue => _pick('Revenue', 'Mapato');
}
