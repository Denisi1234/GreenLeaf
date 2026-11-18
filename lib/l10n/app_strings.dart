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
  String get inventory => _pick('Items', 'Vitu');
  String get settings => _pick('Settings', 'Mipangilio');
  String get english => _pick('English (US)', 'Kiingereza (US)');
  String get swahili => _pick('Swahili', 'Kiswahili');
  String get storeProfile => _pick('Store Profile', 'Wasifu wa Duka');
  String get staffManagement =>
      _pick('Staff Management', 'Usimamizi wa Wafanyakazi');
  String get dukaAi => _pick('DUKA AI', 'DUKA AI');
  String get subscriptionPlan =>
      _pick('Subscription Plan', 'Mpango wa Usajili');
  String get logout => _pick('Logout', 'Ondoka');

  String get storeName => _pick('Store Name', 'Jina la Duka');
  String get cancel => _pick('Cancel', 'Ghairi');
  String get create => _pick('Create', 'Tengeneza');
  String get save => _pick('Save', 'Hifadhi');

  String get priceRequired =>
      _pick('This price is required', 'Bei hii inahitajika');
  String get validAmountRequired =>
      _pick('Enter a valid amount', 'Weka kiasi sahihi');
  String get productDeleted => _pick('Product Deleted', 'Bidhaa Imefutwa');
  String get staffManagementTitle =>
      _pick('Staff Management', 'Usimamizi wa Wafanyakazi');
  String get addStaff => _pick('Add Staff', 'Ongeza Mfanyakazi');
  String get editStaff => _pick('Edit Staff', 'Hariri Mfanyakazi');
  String get staffName => _pick('Staff Name', 'Jina la Mfanyakazi');
  String get emailAddress => _pick('Email Address', 'Baruapepe');
  String get phoneNumber => _pick('Phone Number', 'Namba ya Simu');
  String get role => _pick('Role', 'Nafasi');
  String get staffNameRequired =>
      _pick('Staff name is required', 'Jina la mfanyakazi linahitajika');
  String get emailRequired =>
      _pick('Email is required', 'Baruapepe inahitajika');
  String get phoneRequired =>
      _pick('Phone number is required', 'Namba ya simu inahitajika');
  String get roleRequired => _pick('Role is required', 'Nafasi inahitajika');
  String get staffSaved => _pick('Staff saved', 'Mfanyakazi amehifadhiwa');
  String get staffDeleted => _pick('Staff deleted', 'Mfanyakazi amefutwa');
  String get deleteStaff => _pick('Delete Staff?', 'Futa Mfanyakazi?');
  String deleteStaffConfirmation(String name) => _pick(
      'Remove "$name" from staff? This cannot be undone.',
      'Ondoa "$name" kutoka kwa wafanyakazi? Hili haliwezi kutenduliwa.');
  String get passwordRequired =>
      _pick('Password is required', 'Nenosiri linahitajika');
  String get passwordMinLength => _pick(
      'Password must be at least 6 characters',
      'Nenosiri lazima liwe na angalau herufi 6');
  String get saving => _pick('Saving...', 'Inahifadhi...');
  String get saveStaff => _pick('Save Staff', 'Hifadhi Mfanyakazi');

  String get notifications => _pick('Notifications', 'Arifa');
  String get noNotifications => _pick('No notifications', 'Hakuna arifa');
  String get nothingToShow => _pick(
      'Nothing to show right now.', 'Hakuna kitu cha kuonyesha kwa sasa.');
  String get markAllAsRead =>
      _pick('Mark all as read', 'Weka zote zionekane zimesomwa');
  String get newSaleRecorded =>
      _pick('New sale recorded', 'Mauzo mapya yameandikwa');
  String get lowStockAlert => _pick('Low stock alert', 'Arifa ya akiba ndogo');
  String get monthlyStatementReady =>
      _pick('Monthly statement ready', 'Taarifa ya mwezi iko tayari');
  String get systemUpdateCompleted =>
      _pick('System update completed', 'Sasisho la mfumo limekamilika');
  String newSaleMessage(String amount, String table) =>
      _pick('TSh $amount from Table $table', 'TSh $amount kutoka Meza $table');
  String lowStockMessage(String item) => _pick(
      '$item is under the reorder level',
      '$item iko chini ya kiwango cha kuagiza');
  String get statementReadyMessage => _pick(
      'Your statement is ready to view', 'Taarifa yako iko tayari kuonekana');
  String get systemUpdateMessage => _pick(
      'Your POS system was updated successfully',
      'Mfumo wako wa POS umesasishwa kwa mafanikio');

  String get allCategories => _pick('All', 'Zote');
  String get clearSearch => _pick('Clear Search', 'Futa Utafutaji');
  String get noProductsFound =>
      _pick('No products found', 'Bidhaa hazikupatikana');
  String get tryAdjustingSearch => _pick(
      'Try adjusting your search query', 'Jaribu kurekebisha utafutaji wako');
  String get checkout => _pick('Checkout', 'Malipo');
  String get checkoutRetail => _pick('Checkout', 'Lipa');
  String get checkoutRestaurant => _pick('Open Table', 'Fungua Meza');
  String get checkoutPharmacy =>
      _pick('Process Prescription', 'Kamilisha Dawa');
  String get checkoutElectronics =>
      _pick('Process Warranty', 'Kamilisha Dhamana');
  String get checkoutWarehouse => _pick('Process Order', 'Kamilisha Oda');
  String get checkoutSupermarket => _pick('Loyalty Checkout', 'Lipa na Pointi');

  String get reportHub => _pick('Report Hub', 'Kituo cha Ripoti');
  String get reportsSubtitle => _pick('View insights, trends, and downloads',
      'Tazama maarifa, mwenendo, na vipakuzi');
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
  String get noSalesYet => _pick('No completed sales in this period.',
      'Bado hakuna mauzo katika kipindi hiki.');
  String get top => _pick('Top', 'Juu');
  String get revenue => _pick('Revenue', 'Mapato');

  String get setupStoreProfile =>
      _pick('Set up store profile', 'Weka wasifu wa duka');
  String get businessOwner => _pick('Business Owner', 'Mmiliki wa Biashara');
  String get dashboardSubtitle => _pick('Track today\'s activity at a glance',
      'Fuata shughuli za leo kwa haraka');
  String get productsSubtitle => _pick(
      'Manage stock, pricing, and edits', 'Simamia bidhaa, bei, na mabadiliko');
  String get salesSubtitle =>
      _pick('Manage sales and cart activity', 'Simamia mauzo na kikapu');
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
  String get noItemsSoldYet =>
      _pick('No items sold yet', 'Bado hakuna bidhaa zilizouzwa');
  String get order => _pick('Order', 'Oda');
  String get item => _pick('item', 'bidhaa');
  String get payment => _pick('payment', 'malipo');
  String get moreSubtitle => _pick('Store profile, staff, and tools',
      'Wasifu wa duka, wafanyakazi, na zana');
  String get operations => _pick('Operations', 'Uendeshaji');
  String get pharmacyActions =>
      _pick('Pharmacy Actions', 'Vitendo vya Duka la Dawa');
  String get deviceActions => _pick('Device Actions', 'Vitendo vya Vifaa');
  String get retailActions => _pick('Retail Actions', 'Vitendo vya Rejareja');
  String get scanPrescription => _pick('Scan Prescription', 'Changanua Dawa');
  String get expiryCheck => _pick('Expiry Check', 'Ukaguzi wa Kuisha');
  String get refillQueue => _pick('Refill Queue', 'Foleni ya Kujaza');
  String get medicineCatalog => _pick('Medicine Catalog', 'Katalogi ya Dawa');
  String get prescriptionSales => _pick('Prescription Sales', 'Mauzo ya Dawa');
  String get deviceCatalog => _pick('Device Catalog', 'Katalogi ya Vifaa');
  String get warrantyClaims => _pick('Warranty Claims', 'Madai ya Dhamana');
  String get customers => _pick('Customers', 'Wateja');
  String get debitLedger => _pick('Debit & Credit', 'Madeni na Malipo');
  String get expensesTracking =>
      _pick('Expenses Tracking', 'Ufuatiliaji wa Matumizi');
  String get helpSupport => _pick('Help & Support', 'Msaada na Usaidizi');
  String get aboutApp => _pick('About App', 'Kuhusu Programu');
  String get language => _pick('Language', 'Lugha');
  String get preferredLanguage =>
      _pick('Select your preferred language', 'Chagua lugha unayopendelea');
  String get appearance => _pick('Appearance', 'Mwonekano');
  String get preferredTheme =>
      _pick('Choose your preferred theme', 'Chagua mandhari unayopendelea');
  String get security => _pick('Security', 'Usalama');
  String get backupRestore =>
      _pick('Backup & Restore', 'Hifadhi Nakala na Rejesha');
  String get appVersion => _pick('App version', 'Toleo la programu');
  String get businessInfo => _pick('Information', 'Taarifa');
  String get localeSettings => _pick('Locale', 'Lugha na eneo');
  String get receiptSettings => _pick('Receipt', 'Risiti');
  String get systemSettings => _pick('System', 'Mfumo');
  String get storeLogo => _pick('Store logo', 'Nembo ya duka');
  String get chooseLogo => _pick('Choose image', 'Chagua picha');
  String get logoUnavailable => _pick(
      'Could not open the image picker.', 'Haikuweza kufungua kichagua picha.');
  String get businessAddress => _pick('Address', 'Anwani');
  String get addressRequired =>
      _pick('Enter the store address.', 'Weka anwani ya duka.');
  String get storeNameRequired =>
      _pick('Enter the store name.', 'Weka jina la duka.');
  String get invalidEmail =>
      _pick('Enter a valid email address.', 'Weka baruapepe sahihi.');
  String get showStoreContact =>
      _pick('Show store contact details', 'Onyesha mawasiliano ya duka');
  String get receiptContactHint => _pick(
        'Include the address and phone number from the Information tab.',
        'Jumuisha anwani na namba ya simu kutoka kwenye kichupo cha Taarifa.',
      );
  String get receiptFooter =>
      _pick('Receipt footer', 'Ujumbe wa mwisho wa risiti');
  String get receiptFooterHint => _pick(
        'Enter a message or leave blank to use the default.',
        'Weka ujumbe au acha wazi ili kutumia ujumbe wa kawaida.',
      );
  String get receiptSettingsHint => _pick(
        'These settings apply to receipt previews, PDFs, and WhatsApp messages.',
        'Mipangilio hii inatumika kwenye hakikisho la risiti, PDF na ujumbe wa WhatsApp.',
      );
  String get dataStorage => _pick('Data storage', 'Hifadhi ya data');
  String get localStorage =>
      _pick('This device (SQLite)', 'Kifaa hiki (SQLite)');
  String get cloudSync => _pick('Cloud sync', 'Usawazishaji wa wingu');
  String get cloudStorage => _pick('Business server', 'Seva ya biashara');
  String get connected => _pick('Connected', 'Imeunganishwa');
  String get serverAddress => _pick('Server address', 'Anwani ya seva');
  String get refreshData => _pick('Refresh data', 'Onyesha data mpya');
  String get disconnected => _pick('Disconnected', 'Haijaunganishwa');
  String get settingsSaved =>
      _pick('Settings saved.', 'Mipangilio imehifadhiwa.');
  String get settingsSaveFailed =>
      _pick('Could not save. Try again.', 'Haikuweza kuhifadhi. Jaribu tena.');
  String get currentStore => _pick('Current Store', 'Duka la Sasa');
  String get notSet => _pick('Not set', 'Haijawekwa');
  String get loggedOut => _pick('Logged Out', 'Umetoka');
  String get authNext => _pick('You can connect the real auth flow next',
      'Unaweza kuunganisha mfumo halisi wa kuingia baadaye');

  // Auth
  String get welcome =>
      _pick('Welcome to TrackMauzo', 'Karibu kwenye TrackMauzo');
  String get welcomeSubtitle => _pick(
      'Track sales, stock, and customers for your shop',
      'Fuatilia mauzo, bidhaa, na wateja kwa duka lako');
  String get getStarted => _pick('Get Started', 'Anza');
  String get alreadyHaveAccount =>
      _pick('Already have an account?', 'Je, una akaunti yalisijazo?');
  String get createAccount => _pick('Create an account', 'Funga akaunti');
  String get signIn => _pick('Sign in', 'Ingia');
  String signInWith(String provider) =>
      _pick('Sign in with $provider', 'Ingia kwa $provider');
  String get noAccount => _pick('Don\'t have an account?', 'Huna akaunti?');
  String get createOne => _pick('Create one', 'Funga moja');
  String get email => _pick('Email', 'Baruapepe');
  String get username => _pick('Username', 'Jina la Mtumiaji');
  String get password => _pick('Password', 'Nenosiri');
  String get confirmPassword =>
      _pick('Confirm password', 'Thibitisha Nenosiri');
  String get fullName => _pick('Full Name', 'Jina Kamili');
  String get enterEmail => _pick('Enter your email', 'Ingiza baruapepe yako');
  String get enterUsername =>
      _pick('Enter username', 'Ingiza jina la mtumiaji');
  String get enterPassword => _pick('Enter password', 'Ingiza nenosiri');
  String get enterConfirmPassword =>
      _pick('Confirm your password', 'Thibitisha nenosiri yako');
  String get enterFullName =>
      _pick('Enter your full name', 'Ingiza jina kamili yako');
  String get enterPhoneNumber =>
      _pick('Enter your phone number', 'Ingiza namba yako ya simu');
  String get usernameRequired =>
      _pick('Username is required', 'Jina la mtumiaji linahitajika');
  String get passwordsDoNotMatch =>
      _pick('Passwords do not match', 'Nenosiri hazifanani');
  String get loggingIn => _pick('Signing in...', 'Inaingia...');
  String get creatingAccount =>
      _pick('Creating account...', 'Inafunga akaunti...');
  String get loginFailed => _pick('Invalid phone number or password',
      'Namba ya simu au nenosiri si sahihi');
  String get userNotFound => _pick('No account found with this phone number',
      'Hakuna akaunti iliyopatikana na namba hii ya simu');
  String get phoneTaken => _pick(
      'An account with this phone number already exists',
      'Akaunti yenye namba hii ya simu ipo tayari');
  String get forgotPassword => _pick('Forgot password?', 'Umesahau nenosiri?');
  String get resetPassword => _pick('Reset Password', 'Weka Nenosiri Upya');
  String get resetPasswordSubtitle => _pick(
      'Enter your registered phone number and your new password.',
      'Ingiza namba yako ya simu uliyojisajili nayo na nenosiri jipya.');
  String get passwordResetSuccess => _pick(
      'Password reset successfully! You can now sign in.',
      'Nenosiri limewekwa upya kwa mafanikio! Sasa unaweza kuingia.');
  String get backToSignIn => _pick('Back to Sign in', 'Rudi kwenye Kuingia');
  String get newPassword => _pick('New Password', 'Nenosiri Jipya');
  String get enterNewPassword =>
      _pick('Enter your new password', 'Ingiza nenosiri lako jipya');
  String get accountCreated =>
      _pick('Account created successfully', 'Akaunti imefungwa kwa mafanikio');
  String get welcomeBack => _pick('Welcome back', 'Karibu tena');
  String get back => _pick('Back', 'Rudi');
  String get authHeroTitle => _pick('Run your shop with total clarity.',
      'Endesha duka lako kwa uwazi kamili.');
  String get authHeroSubtitle => _pick(
      'Sales, stock, customers and reports in one calm, reliable workspace.',
      'Mauzo, bidhaa, wateja na ripoti katika mazingira moja tulivu na ya kuaminika.');
  String get authFeatureSell => _pick('Sell fast, online or offline',
      'Uza haraka, mtandaoni au nje ya mtandao');
  String get authFeatureStock =>
      _pick('Stock that stays accurate', 'Akiba inayobaki sahihi');
  String get authFeatureSync => _pick(
      'Sync across all your devices', 'Sawazisha kwenye vifaa vyako vyote');
  String get authSecureSync => _pick('Private and secure on every device',
      'Faragha na salama kwenye kila kifaa');
  String get signInSubtitle => _pick('Sign in to continue to your workspace.',
      'Ingia kuendelea na kazi zako.');
  String get createAccountSubtitle => _pick(
      'Set up your shop account in a minute.',
      'Weka akaunti ya duka lako kwa dakika moja.');
  String get accountDetails => _pick('Account details', 'Taarifa za akaunti');
  String get selectRole => _pick('Select role', 'Chagua nafasi');
  String get usernameTaken => _pick('That username is already taken',
      'Jina hili la mtumiaji tayari linatumika');
  String continueAs(String name) =>
      _pick('Continue as $name', 'Endelea kama $name');
  String get termsAgreement => _pick(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      'Kwenye kuendelea, unakaribisha Mashurii ya Huduma na Sera faragha yetu');
  String get comingSoon => _pick('Coming soon', 'Inakuja hivi karibuni');
  String get checkTheForm => _pick('Check The Form', 'Angalia Fomu');
  String get completeRequiredFields => _pick(
      'Complete the required fields before saving',
      'Jaza sehemu zinazohitajika kabla ya kuhifadhi');
  String get deleteProduct => _pick('Delete Product?', 'Futa Bidhaa?');
  String removeProductFromInventory(String name) => _pick(
      'Remove "$name" from inventory? This cannot be undone.',
      'Ondoa "$name" kutoka kwenye hifadhi? Hili haliwezi kutenduliwa.');
  String get delete => _pick('Delete', 'Futa');
  String productRemovedFromInventory(String name) => _pick(
      '$name has been removed from inventory',
      '$name imeondolewa kwenye hifadhi');
  String get imageSelected => _pick('Image Selected', 'Picha Imechaguliwa');
  String get productImageReady => _pick('Product image is ready to save',
      'Picha ya bidhaa iko tayari kuhifadhiwa');
  String get uploadFailed => _pick('Upload Failed', 'Imeshindwa Kupakia');
  String get couldNotOpenGallery => _pick(
      'Could not open the gallery on this device',
      'Imeshindwa kufungua ghala kwenye kifaa hiki');
  String get medicineItem => _pick('Medicine Item', 'Dawa');
  String get deviceItem => _pick('Device Item', 'Kifaa');
  String get product => _pick('Product', 'Bidhaa');
  String addProduct(String title) => _pick('Add $title', 'Ongeza $title');
  String editProduct(String title) => _pick('Edit $title', 'Hariri $title');
  String get productName => _pick('Product Name', 'Jina la Bidhaa');
  String get enterProductName =>
      _pick('Enter product name', 'Ingiza jina la bidhaa');
  String get productNameRequired =>
      _pick('Product name is required', 'Jina la bidhaa linahitajika');
  String get purchasePrice => _pick('Purchase Price', 'Bei ya Kununua');
  String get sellingPrice => _pick('Selling Price', 'Bei ya Kuuza');
  String get category => _pick('Category', 'Kategoria');
  String get selectCategory => _pick('Select category', 'Chagua kategoria');
  String get categoryRequired =>
      _pick('Category is required', 'Kategoria inahitajika');
  String get stockQuantity => _pick('Stock Quantity', 'Idadi ya Akiba');
  String get enterStockQuantity =>
      _pick('Enter stock quantity', 'Ingiza idadi ya akiba');
  String get stockQuantityRequired =>
      _pick('Stock quantity is required', 'Idadi ya akiba inahitajika');
  String get validStockQuantityRequired =>
      _pick('Enter a valid stock quantity', 'Ingiza idadi halali ya akiba');
  String get productImage => _pick('Product Image', 'Picha ya Bidhaa');
  String get change => _pick('Change', 'Badilisha');
  String get uploadProductImage =>
      _pick('Upload product image', 'Pakia picha ya bidhaa');
  String get tapToChooseImage => _pick('Tap to choose image from gallery',
      'Gusa ili kuchagua picha kutoka kwenye ghala');
  String get imageFormatInfo =>
      _pick('JPG, PNG up to 5MB', 'JPG, PNG hadi 5MB');
  String get advancedReports => _pick('Advanced reports', 'Ripoti za kina');
  String get allPlansIncludeMultiPlatformAccess => _pick(
      'All plans include access on multiple platforms.',
      'Mipango yote inapatikana kwenye mifumo mbalimbali.');
  String get android => _pick('Android', 'Android');
  String get annually => _pick('Annually', 'Kwa mwaka');
  String get averageOrderInsight => _pick(
      'Average value of a completed sale today.',
      'Thamani ya wastani ya mauzo yaliyokamilika leo.');
  String get averageTicket => _pick('Average sale', 'Wastani wa mauzo');
  String get avgBasket => _pick('Average basket', 'Wastani wa kikapu');
  String get basicReports => _pick('Basic reports', 'Ripoti za msingi');
  String get bestSellerInsight => _pick(
      'The product with the most units sold today.',
      'Bidhaa iliyouza vipande vingi zaidi leo.');
  String get brandDataNotTrackedYet => _pick(
      'Brand data is not tracked yet', 'Taarifa za chapa bado hazifuatiliwi');
  String get business => _pick('Business', 'Biashara');
  String get businessDescription => _pick(
      'For growing businesses that need more users and reports.',
      'Kwa biashara zinazokua na zinazohitaji watumiaji na ripoti zaidi.');
  String get choosePlan => _pick('Choose plan', 'Chagua mpango');
  String get completedSales => _pick('Completed sales', 'Mauzo yaliyokamilika');
  String get currentPlan => _pick('Current plan', 'Mpango wa sasa');
  String get customerManagement =>
      _pick('Customer management', 'Usimamizi wa wateja');
  String get emailSupport => _pick('Email support', 'Usaidizi kwa baruapepe');
  String get expiringSoon => _pick('Expiring soon', 'Zinakaribia kuisha muda');
  String get expiryTrackingNotSet => _pick('Expiry tracking is not set up',
      'Ufuatiliaji wa tarehe za mwisho haujawekwa');
  String get fromCurrentStockPricing => _pick(
      'Based on current stock prices', 'Kulingana na bei za sasa za bidhaa');
  String get grossRevenue => _pick('Gross revenue', 'Mapato ghafi');
  String get highValueSales =>
      _pick('High-value sales', 'Mauzo ya thamani kubwa');
  String get inventoryManagement =>
      _pick('Inventory management', 'Usimamizi wa bidhaa');
  String get ios => _pick('iOS', 'iOS');
  String get itemsNeedRestocking =>
      _pick('Items need restocking', 'Bidhaa zinahitaji kuongezwa');
  String get latestActivity =>
      _pick('Latest activity', 'Shughuli za hivi karibuni');
  String get liveUpdates => _pick('Live updates', 'Taarifa za moja kwa moja');
  String get lowStock => _pick('Low stock', 'Bidhaa chache');
  String get mac => _pick('Mac', 'Mac');
  String get manageUpToOneThousandProducts =>
      _pick('Manage up to 1,000 products', 'Simamia hadi bidhaa 1,000');
  String get manageUpToTenThousandProducts =>
      _pick('Manage up to 10,000 products', 'Simamia hadi bidhaa 10,000');
  String get marginMix => _pick('Margin mix', 'Uwiano wa faida');
  String get metricReadyForCloserLook => _pick(
      'View the details behind this metric.',
      'Angalia maelezo ya kipimo hiki.');
  String get monthly => _pick('Monthly', 'Kwa mwezi');
  String get noActiveSales =>
      _pick('No active sales', 'Hakuna mauzo yanayoendelea');
  String get nothingSoldYet =>
      _pick('Nothing sold yet', 'Hakuna bidhaa iliyouzwa bado');
  String get orders => _pick('Orders', 'Oda');
  String get ordersAboveFiftyThousand =>
      _pick('Orders above TSh 50,000', 'Oda za zaidi ya TSh 50,000');
  String get ordersTodayInsight => _pick(
      'Number of completed sales today.', 'Idadi ya mauzo yaliyokamilika leo.');
  String get perOrder => _pick('Per order', 'Kwa kila oda');
  String get prescriptionRefillsNotTracked => _pick(
      'Prescription refills are not tracked', 'Ujazaji wa dawa haujafuatiliwa');
  String get priorityEmailChatSupport => _pick(
      'Priority email and chat support',
      'Usaidizi wa kipaumbele kwa baruapepe na gumzo');
  String get readyForYourFirstCheckoutOfTheDay => _pick(
      'Ready for your first sale of the day',
      'Tayari kwa mauzo yako ya kwanza leo');
  String get retailDashboardSubtitle => _pick(
      'Track sales and expenses to see how your store is performing.',
      'Fuatilia mauzo na gharama ili kuona utendaji wa duka lako.');
  String get salesGrowthOverview =>
      _pick('Sales growth overview', 'Muhtasari wa ukuaji wa mauzo');
  String get salesTodayInsight => _pick('Revenue from completed sales today.',
      'Mapato ya mauzo yaliyokamilika leo.');
  String get saveSeventeenPercent => _pick('Save 17%', 'Okoa 17%');
  String get securePaymentsCancelAnytime => _pick(
      'Secure payments. Cancel anytime.',
      'Malipo salama. Ghairi wakati wowote.');
  String get seeAll => _pick('See all', 'Tazama yote');
  String get serviceClaimsNotTracked =>
      _pick('Service claims are not tracked', 'Madai ya huduma hayafuatiliwi');
  String get soldToday => _pick('sold today', 'zimeuzwa leo');
  String get starter => _pick('Starter', 'Mwanzo');
  String get starterDescription => _pick('For getting started with your store.',
      'Kwa kuanza kusimamia duka lako.');
  String get subscriptionPlansSubtitle => _pick(
      'Choose a plan for your business.',
      'Chagua mpango unaofaa biashara yako.');
  String get subscriptionPlansSubtitleTwo => _pick(
      'Find the features you need to run your store.',
      'Pata vipengele unavyohitaji kuendesha duka lako.');
  String get subscriptionPlansTitle =>
      _pick('Subscription plans', 'Mipango ya usajili');
  String get todayOperations => _pick('Operations today', 'Shughuli za leo');
  String get todayPerformance => _pick('Performance today', 'Utendaji wa leo');
  String get todayRevenue => _pick('Revenue today', 'Mapato ya leo');
  String get topCategory => _pick('Top category', 'Kategoria inayoongoza');
  String get totalOrders => _pick('Total orders', 'Jumla ya oda');
  String get totalRevenue => _pick('Total revenue', 'Jumla ya mapato');
  String get unlockSmartSalesInsights => _pick(
      'Explore your sales and expenses', 'Chunguza mauzo na gharama zako');
  String get upToFiveUsers => _pick('Up to 5 users', 'Hadi watumiaji 5');
  String get upToOneUser => _pick('1 user', 'Mtumiaji 1');
  String get updatedJustNow =>
      _pick('Updated just now', 'Imesasishwa sasa hivi');
  String get vsYesterday =>
      _pick('Compared with yesterday', 'Ikilinganishwa na jana');
  String get web => _pick('Web', 'Wavuti');
  String get windows => _pick('Windows', 'Windows');
  String get cashDrawer => _pick('Cash drawer', 'Droo ya pesa');
  String get cashDrawerOpenedSuccessfully =>
      _pick('Cash drawer opened successfully.', 'Droo ya pesa imefunguliwa.');
}
