package com.nuclearmotd.mobile

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

/**
 * Native ad factory for the messages list.
 * Corresponds to factoryId = 'listTile' in messages_screen.dart.
 * Inflates native_ad_list_tile.xml and binds the NativeAd fields to views.
 */
class ListTileNativeAdFactory(private val layoutInflater: LayoutInflater) :
    GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(
            R.layout.native_ad_list_tile, null
        ) as NativeAdView

        val headlineView = adView.findViewById<TextView>(R.id.tv_headline)
        val bodyView = adView.findViewById<TextView>(R.id.tv_body)
        val advertiserView = adView.findViewById<TextView>(R.id.tv_advertiser)
        val ctaView = adView.findViewById<Button>(R.id.btn_cta)

        // Headline (required)
        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        // Body (optional)
        if (nativeAd.body != null) {
            bodyView.text = nativeAd.body
            bodyView.visibility = View.VISIBLE
        } else {
            bodyView.visibility = View.GONE
        }
        adView.bodyView = bodyView

        // Advertiser (optional)
        if (nativeAd.advertiser != null) {
            advertiserView.text = nativeAd.advertiser
            advertiserView.visibility = View.VISIBLE
        } else {
            advertiserView.visibility = View.GONE
        }
        adView.advertiserView = advertiserView

        // Call-to-action (optional)
        if (nativeAd.callToAction != null) {
            ctaView.text = nativeAd.callToAction
            ctaView.visibility = View.VISIBLE
        } else {
            ctaView.visibility = View.GONE
        }
        adView.callToActionView = ctaView

        adView.setNativeAd(nativeAd)
        return adView
    }
}
