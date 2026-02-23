package com.nuclearmotd.mobile

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Enable edge-to-edge for Android 15+ backward compatibility
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register native ad factory — matches factoryId: 'listTile' in messages_screen.dart
        flutterEngine.plugins.get(GoogleMobileAdsPlugin::class.java)?.also {
            it.registerNativeAdFactory("listTile", ListTileNativeAdFactory(layoutInflater))
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        flutterEngine.plugins.get(GoogleMobileAdsPlugin::class.java)?.also {
            it.unregisterNativeAdFactory("listTile")
        }
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
