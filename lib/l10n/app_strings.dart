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
  String get startingApp => _pick('Starting TrackMauzo...', 'Inaanzisha TrackMauzo...');
  String get startupErrorTitle =>
      _pick('TrackMauzo could not start', 'TrackMauzo haikuweza kuanza');
  String get startupUnknownError =>
      _pick('Unknown startup error', 'Hitilafu isiyojulikana wakati wa kuanza');

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
  String get setupStoreProfile =>
      _pick('Set up store profile', 'Weka wasifu wa duka');
  String get businessOwner => _pick('Business Owner', 'Mmiliki wa Biashara');

  String get dashboardSubtitle =>
      _pick('Track today\'s activity at a glance', 'Fuata shughuli za leo kwa haraka');
  String get productsSubtitle =>
      _pick('Manage stock, pricing, and edits', 'Simamia bidhaa, bei, na mabadiliko');
  String get salesSubtitle =>
      _pick('Manage sales and cart activity', 'Simamia mauzo na kikapu');
  String get reportsSubtitle =>
      _pick('View insights, trends, and downloads', 'Ona maarifa, mwenendo, na upakuaji');
  String get today => _pick('Today', 'Leo');
  String get thisWeek => _pick('This Week', 'Wiki Hii');
  String get thisMonth => _pick('This Month', 'Mwezi Huu');
  String get allTime => _pick('All Time', 'Wakati Wote');
  String get openDrawer => _pick('Open Drawer', 'Fungua Droo');
  String get viewReports => _pick('View Reports', 'Angalia Ripoti');
  String get salesToday => _pick('Sales today', 'Mauzo ya leo');
  String get ordersToday => _pick('Orders today', 'Oda za leo');
  String get averageOrder => _pick('Average order', 'Wastani wa oda');
  String get bestSeller => _pick('Best seller', 'Bidhaa inayoongoza');
  String get updatedToday => _pick('Updated today', 'Imesasishwa leo');
  String get noItemsSoldYet => _pick('No items sold yet', 'Bado hakuna bidhaa zilizouzwa');
  String get order => _pick('Order', 'Oda');
  String get item => _pick('item', 'bidhaa');
  String get payment => _pick('payment', 'malipo');
  String get moreSubtitle =>
      _pick('Store profile, staff, and tools', 'Wasifu wa duka, wafanyakazi, na zana');

  String get quickActions => _pick('Quick Actions', 'Vitendo vya Haraka');
  String get operations => _pick('Operations', 'Uendeshaji');
  String get support => _pick('Support', 'Msaada');
  String get pharmacyActions => _pick('Pharmacy Actions', 'Vitendo vya Duka la Dawa');
  String get deviceActions => _pick('Device Actions', 'Vitendo vya Vifaa');
  String get retailActions => _pick('Retail Actions', 'Vitendo vya Rejareja');
  String get logout => _pick('Logout', 'Ondoka');

  String get scanPrescription => _pick('Scan Prescription', 'Changanua Dawa');
  String get expiryCheck => _pick('Expiry Check', 'Ukaguzi wa Kuisha');
  String get refillQueue => _pick('Refill Queue', 'Foleni ya Kujaza');
  String get medicineCatalog => _pick('Medicine Catalog', 'Katalogi ya Dawa');
  String get prescriptionSales => _pick('Prescription Sales', 'Mauzo ya Dawa');
  String get deviceCatalog => _pick('Device Catalog', 'Katalogi ya Vifaa');
  String get warrantyRegister => _pick('Register Warranty', 'Sajili Dhamana');
  String get warrantyClaims => _pick('Warranty Claims', 'Madai ya Dhamana');
  String get servicePlans => _pick('Service Plans', 'Mipango ya Huduma');
  String get customers => _pick('Customers', 'Wateja');
  String get expensesTracking => _pick('Expenses Tracking', 'Ufuatiliaji wa Matumizi');
  String get helpSupport => _pick('Help & Support', 'Msaada na Usaidizi');
  String get aboutApp => _pick('About App', 'Kuhusu Programu');

  String get language => _pick('Language', 'Lugha');
  String get preferredLanguage =>
      _pick('Select your preferred language', 'Chagua lugha unayopendelea');
  String get appearance => _pick('Appearance', 'Mwonekano');
  String get preferredTheme =>
      _pick('Choose your preferred theme', 'Chagua mandhari unayopendelea');
  String get lightMode => _pick('Light Mode', 'Mwanga');
  String get darkMode => _pick('Dark Mode', 'Giza');
  String get lightUi => _pick('Light UI', 'Mwonekano wa Mwanga');
  String get darkUi => _pick('Dark UI', 'Mwonekano wa Giza');
  String get security => _pick('Security', 'Usalama');
  String get backupRestore => _pick('Backup & Restore', 'Hifadhi Nakala na Rejesha');
  String get receiptSettings => _pick('Receipt Settings', 'Mipangilio ya Risiti');
  String get taxSettings => _pick('Tax Settings', 'Mipangilio ya Kodi');
  String get about => _pick('About', 'Kuhusu');
  String get appVersion => _pick('App version', 'Toleo la programu');
  String get currentStore => _pick('Current Store', 'Duka la Sasa');
  String get activeStore => _pick('Active Store', 'Duka Linalofanya Kazi');
  String get selectActiveStore =>
      _pick('Select Active Store', 'Chagua Duka Linalofanya Kazi');
  String get createNewStore => _pick('Create New Store', 'Tengeneza Duka Jipya');
  String get storeName => _pick('Store Name', 'Jina la Duka');
  String get unknownStore => _pick('Unknown Store', 'Duka Lisilojulikana');
  String get cancel => _pick('Cancel', 'Ghairi');
  String get create => _pick('Create', 'Tengeneza');
  String get totalSales => _pick('Total Sales', 'Jumla ya Mauzo');
  String get memberSince => _pick('Member Since', 'Amejiunga Tangu');
  String get noSalesYet => _pick('No sales yet', 'Bado hakuna mauzo');
  String get notSet => _pick('Not set', 'Haijawekwa');
  String get loggedOut => _pick('Logged Out', 'Umetoka');
  String get authNext =>
      _pick('You can connect the real auth flow next', 'Unaweza kuunganisha mfumo halisi wa kuingia baadaye');
  String get comingSoon => _pick('Coming soon', 'Inakuja hivi karibuni');
  String get customizePosExperience =>
      _pick('Customize your POS experience', 'Binafsisha matumizi ya POS');
  String get selectLanguageTitle =>
      _pick('Select your preferred language', 'Chagua lugha unayopendelea');
  String get selectThemeTitle =>
      _pick('Choose your preferred theme', 'Chagua mandhari unayopendelea');

  String get addNewStore => _pick('Add New Store', 'Ongeza Duka Jipya');
  String get yourStores => _pick('Your Stores', 'Maduka Yako');
  String get switchStore => _pick('Switch Store', 'Badili Duka');
  String get viewDetails => _pick('View Details', 'Angalia Maelezo');
  String get active => _pick('Active', 'Linafanya kazi');
  String get defaultStore => _pick('Default Store', 'Duka la Msingi');
  String get mainStore => _pick('Main Store', 'Duka Kuu');

  String get receiptComingSoon =>
      _pick('Receipt Settings is coming next', 'Mipangilio ya risiti itakuja hivi karibuni');
  String get taxComingSoon =>
      _pick('Tax Settings is coming next', 'Mipangilio ya kodi itakuja hivi karibuni');
  String get securityComingSoon =>
      _pick('Security is coming next', 'Usalama utakuja hivi karibuni');
  String get backupComingSoon =>
      _pick('Backup & Restore is coming next', 'Hifadhi nakala na rejesha itakuja hivi karibuni');

  String get priceRequired => _pick('This price is required', 'Bei hii inahitajika');
  String get validAmountRequired => _pick('Enter a valid amount', 'Weka kiasi sahihi');

  String get checkTheForm => _pick('Check The Form', 'Angalia Fomu');
  String get completeRequiredFields => _pick('Complete the required fields before saving', 'Jaza sehemu zinazohitajika kabla ya kuhifadhi');
  String get deleteProduct => _pick('Delete Product?', 'Futa Bidhaa?');
  String removeProductFromInventory(String name) => _pick('Remove "$name" from inventory? This cannot be undone.', 'Ondoa "$name" kutoka kwenye hifadhi? Hili haliwezi kutenduliwa.');
  String get cancel => _pick('Cancel', 'Ghairi');
  String get delete => _pick('Delete', 'Futa');
  String get productDeleted => _pick('Product Deleted', 'Bidhaa Imefutwa');
  String productRemovedFromInventory(String name) => _pick('$name has been removed from inventory', '$name imeondolewa kwenye hifadhi');
  String get imageSelected => _pick('Image Selected', 'Picha Imechaguliwa');
  String get productImageReady => _pick('Product image is ready to save', 'Picha ya bidhaa iko tayari kuhifadhiwa');
  String get uploadFailed => _pick('Upload Failed', 'Imeshindwa Kupakia');
  String get couldNotOpenGallery => _pick('Could not open the gallery on this device', 'Imeshindwa kufungua ghala kwenye kifaa hiki');
  String get medicineItem => _pick('Medicine Item', 'Dawa');
  String get deviceItem => _pick('Device Item', 'Kifaa');
  String get product => _pick('Product', 'Bidhaa');
  String addProduct(String title) => _pick('Add $title', 'Ongeza $title');
  String editProduct(String title) => _pick('Edit $title', 'Hariri $title');
  String get productName => _pick('Product Name', 'Jina la Bidhaa');
  String get enterProductName => _pick('Enter product name', 'Ingiza jina la bidhaa');
  String get productNameRequired => _pick('Product name is required', 'Jina la bidhaa linahitajika');
  String get purchasePrice => _pick('Purchase Price', 'Bei ya Kununua');
  String get sellingPrice => _pick('Selling Price', 'Bei ya Kuuza');
  String get category => _pick('Category', 'Kategoria');
  String get selectCategory => _pick('Select category', 'Chagua kategoria');
  String get categoryRequired => _pick('Category is required', 'Kategoria inahitajika');
  String get stockQuantity => _pick('Stock Quantity', 'Idadi ya Akiba');
  String get enterStockQuantity => _pick('Enter stock quantity', 'Ingiza idadi ya akiba');
  String get stockQuantityRequired => _pick('Stock quantity is required', 'Idadi ya akiba inahitajika');
  String get validStockQuantityRequired => _pick('Enter a valid stock quantity', 'Ingiza idadi halali ya akiba');
  String get productImage => _pick('Product Image', 'Picha ya Bidhaa');
  String get change => _pick('Change', 'Badilisha');
  String get uploadProductImage => _pick('Upload product image', 'Pakia picha ya bidhaa');
  String get tapToChooseImage => _pick('Tap to choose image from gallery', 'Gusa ili kuchagua picha kutoka kwenye ghala');
  String get imageFormatInfo => _pick('JPG, PNG up to 5MB', 'JPG, PNG hadi 5MB');
  String get save => _pick('Save', 'Hifadhi');
}
