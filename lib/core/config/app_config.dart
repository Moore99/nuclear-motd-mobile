/// App configuration constants
class AppConfig {
  AppConfig._();

  static const String appName = 'Nuclear MOTD';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Environment detection
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: isProduction ? 'production' : 'development',
  );

  // API Configuration - UPDATED FOR PRODUCTION
  static const String productionUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://nuclear-motd.com',  // Production server
  );

  // FIXED: Updated development URL to use server IP instead of local network
  static const String developmentUrl = 'https://nuclear-motd.com';  // Production server for testing

  // Use appropriate URL based on environment
  static String get apiBaseUrl {
    if (environment == 'production') {
      return productionUrl;
    } else if (environment == 'staging') {
      return const String.fromEnvironment('STAGING_URL', defaultValue: 'https://staging.nuclear-motd.com/api');
    }
    return developmentUrl;
  }

  // API Endpoints (mobile API endpoints)
  static const String authLogin = '/auth/login';
  static const String authSignup = '/auth/signup';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authVerifyResetToken = '/auth/verify-reset-token';
  static const String dashboard = '/dashboard';
  static const String messages = '/messages';
  static const String messagesSearch = '/messages/search';
  static const String profile = '/profile';
  static const String schedule = '/schedule';
  static const String topics = '/topics';
  static const String topicsSubscribe = '/topics/subscribe';
  static const String contentSubmit = '/content/submit';
  static const String appInfo = '/app-info';
  static const String health = '/health';
  static const String unreadCount = '/unread-count';

  // Sponsor/Ad endpoints
  static const String sponsors = '/sponsors/active';
  static const String sponsorImpression = '/track/sponsor/impression';
  static const String sponsorClick = '/track/sponsor/click';

  // AdMob Configuration
  // Production IDs (replace with your actual IDs)
  static const String _adMobAppIdAndroidProd = String.fromEnvironment(
    'ADMOB_APP_ID_ANDROID',
    defaultValue: 'ca-app-pub-5119215558360251~8772312709',
  );
  static const String _adMobAppIdIOSProd = String.fromEnvironment(
    'ADMOB_APP_ID_IOS',
    defaultValue: 'ca-app-pub-5119215558360251~3072331258',
  );

  // Test IDs for development
  static const String _bannerAdUnitIdAndroidTest = 'ca-app-pub-3940256099942544/6300978111';
  static const String _bannerAdUnitIdIOSTest = 'ca-app-pub-3940256099942544/2934735716';
  static const String _nativeAdUnitIdAndroidTest = 'ca-app-pub-3940256099942544/2247696110';
  static const String _nativeAdUnitIdIOSTest = 'ca-app-pub-3940256099942544/3986624511';

  // Production IDs (replace with your actual IDs)
  static const String _bannerAdUnitIdAndroidProd = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: 'ca-app-pub-5119215558360251/4367356778',
  );
  static const String _bannerAdUnitIdIOSProd = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
    defaultValue: 'ca-app-pub-5119215558360251/4265847636',
  );
  static const String _nativeAdUnitIdAndroidProd = String.fromEnvironment(
    'ADMOB_NATIVE_ANDROID',
    defaultValue: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY',
  );
  static const String _nativeAdUnitIdIOSProd = String.fromEnvironment(
    'ADMOB_NATIVE_IOS',
    defaultValue: 'ca-app-pub-5119215558360251/6979640884',
  );

  // Use test IDs in development, production IDs in release
  static String get adMobAppIdAndroid => isProduction ? _adMobAppIdAndroidProd : _bannerAdUnitIdAndroidTest;
  static String get adMobAppIdIOS => isProduction ? _adMobAppIdIOSProd : _bannerAdUnitIdIOSTest;
  static String get bannerAdUnitIdAndroid => isProduction ? _bannerAdUnitIdAndroidProd : _bannerAdUnitIdAndroidTest;
  static String get bannerAdUnitIdIOS => isProduction ? _bannerAdUnitIdIOSProd : _bannerAdUnitIdIOSTest;
  static String get nativeAdUnitIdAndroid => isProduction ? _nativeAdUnitIdAndroidProd : _nativeAdUnitIdAndroidTest;
  static String get nativeAdUnitIdIOS => isProduction ? _nativeAdUnitIdIOSProd : _nativeAdUnitIdIOSTest;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Cache settings
  static const Duration messageCacheDuration = Duration(hours: 1);
  static const Duration topicCacheDuration = Duration(hours: 24);

  // UI Settings
  static const int messagesPerPage = 20;
  static const double maxContentWidth = 600.0;

  // Debug info
  static Map<String, dynamic> get debugInfo => {
    'appName': appName,
    'appVersion': appVersion,
    'buildNumber': appBuildNumber,
    'environment': environment,
    'isProduction': isProduction,
    'apiBaseUrl': apiBaseUrl,
  };
}


