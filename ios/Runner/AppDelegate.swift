import Flutter
import UIKit
import FirebaseMessaging
import UserNotifications
import google_mobile_ads

// MARK: - Native Ad Factory
// Kept in AppDelegate.swift so Xcode picks it up without needing project.pbxproj changes.
// Corresponds to factoryId: 'listTile' in messages_screen.dart (messages list native ads).
class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> NativeAdView? {
    let adView = NativeAdView()
    adView.backgroundColor = .systemBackground

    // "Ad" badge
    let badge = UILabel()
    badge.text = "Ad"
    badge.font = .systemFont(ofSize: 9, weight: .bold)
    badge.textColor = .white
    badge.backgroundColor = UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1)
    badge.layer.cornerRadius = 2
    badge.clipsToBounds = true
    badge.translatesAutoresizingMaskIntoConstraints = false

    // Advertiser
    let advertiserLabel = UILabel()
    advertiserLabel.font = .systemFont(ofSize: 11)
    advertiserLabel.textColor = .secondaryLabel
    advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
    adView.advertiserView = advertiserLabel

    // Headline
    let headlineLabel = UILabel()
    headlineLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    headlineLabel.textColor = .label
    headlineLabel.numberOfLines = 1
    headlineLabel.translatesAutoresizingMaskIntoConstraints = false
    adView.headlineView = headlineLabel

    // Body
    let bodyLabel = UILabel()
    bodyLabel.font = .systemFont(ofSize: 12)
    bodyLabel.textColor = .secondaryLabel
    bodyLabel.numberOfLines = 1
    bodyLabel.translatesAutoresizingMaskIntoConstraints = false
    adView.bodyView = bodyLabel

    // CTA button
    let ctaButton = UIButton(type: .system)
    ctaButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
    ctaButton.isUserInteractionEnabled = false
    ctaButton.translatesAutoresizingMaskIntoConstraints = false
    adView.callToActionView = ctaButton

    // Badge + advertiser row
    let topRow = UIStackView(arrangedSubviews: [badge, advertiserLabel])
    topRow.axis = .horizontal
    topRow.spacing = 6
    topRow.alignment = .center
    topRow.translatesAutoresizingMaskIntoConstraints = false

    // Left column
    let leftStack = UIStackView(arrangedSubviews: [topRow, headlineLabel, bodyLabel])
    leftStack.axis = .vertical
    leftStack.spacing = 2
    leftStack.translatesAutoresizingMaskIntoConstraints = false

    // Root row
    let rootStack = UIStackView(arrangedSubviews: [leftStack, ctaButton])
    rootStack.axis = .horizontal
    rootStack.spacing = 8
    rootStack.alignment = .center
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    adView.addSubview(rootStack)
    NSLayoutConstraint.activate([
      rootStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
      rootStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
      rootStack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
      rootStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -8),
    ])

    // Bind data
    headlineLabel.text = nativeAd.headline
    bodyLabel.text = nativeAd.body
    bodyLabel.isHidden = nativeAd.body == nil
    advertiserLabel.text = nativeAd.advertiser
    advertiserLabel.isHidden = nativeAd.advertiser == nil
    ctaButton.setTitle(nativeAd.callToAction, for: .normal)
    ctaButton.isHidden = nativeAd.callToAction == nil

    adView.nativeAd = nativeAd
    return adView
  }
}

// MARK: - AppDelegate
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // FirebaseApp.configure() is intentionally NOT called here.
    // FlutterFire handles Firebase initialization via Firebase.initializeApp() in Dart.

    // Register native ad factory — matches factoryId: 'listTile' in messages_screen.dart
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self, factoryId: "listTile", nativeAdFactory: ListTileNativeAdFactory())

    // Register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    }
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle APNs token - pass to Firebase Messaging
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
