import GoogleMobileAds
import UIKit

/// Native ad factory for the messages list.
/// Corresponds to factoryId = 'listTile' in messages_screen.dart.
class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {

    func createNativeAd(
        _ nativeAd: GADNativeAd,
        customOptions: [AnyHashable: Any]? = nil
    ) -> GADNativeAdView? {

        let adView = GADNativeAdView()
        adView.backgroundColor = .systemBackground

        // --- "Ad" badge ---
        let badge = UILabel()
        badge.text = "Ad"
        badge.font = .systemFont(ofSize: 9, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1) // amber
        badge.layer.cornerRadius = 2
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false

        // --- Advertiser label ---
        let advertiserLabel = UILabel()
        advertiserLabel.font = .systemFont(ofSize: 11)
        advertiserLabel.textColor = UIColor(red: 0.61, green: 0.64, blue: 0.69, alpha: 1)
        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.advertiserView = advertiserLabel

        // --- Headline ---
        let headlineLabel = UILabel()
        headlineLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        headlineLabel.textColor = .label
        headlineLabel.numberOfLines = 1
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.headlineView = headlineLabel

        // --- Body ---
        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 12)
        bodyLabel.textColor = UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1)
        bodyLabel.numberOfLines = 1
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.bodyView = bodyLabel

        // --- CTA Button ---
        let ctaButton = UIButton(type: .system)
        ctaButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        ctaButton.isUserInteractionEnabled = false // adView handles tap
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        adView.callToActionView = ctaButton

        // --- Badge + advertiser row ---
        let topRow = UIStackView(arrangedSubviews: [badge, advertiserLabel])
        topRow.axis = .horizontal
        topRow.spacing = 6
        topRow.alignment = .center
        topRow.translatesAutoresizingMaskIntoConstraints = false

        // --- Left column: topRow + headline + body ---
        let leftStack = UIStackView(arrangedSubviews: [topRow, headlineLabel, bodyLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 2
        leftStack.translatesAutoresizingMaskIntoConstraints = false

        // --- Root row: leftStack + CTA ---
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

        // --- Bind data ---
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
