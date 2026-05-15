package com.bnotion.uniuyotowncampus.application

import android.app.Application
import com.bnotion.uniuyotowncampus.BuildConfig
import com.bnotion.uniuyotowncampus.R
import com.mapbox.common.MapboxOptions
import com.mapbox.navigation.base.options.NavigationOptions
import com.mapbox.navigation.core.lifecycle.MapboxNavigationApp
import timber.log.Timber

class MyApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // Initialize Timber for logging
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        }

        // Set Mapbox access token before any Mapbox components are created
        val accessToken = getString(R.string.mapbox_access_token)
        MapboxOptions.accessToken = accessToken

        // Setup MapboxNavigationApp with NavigationOptions
        if (!MapboxNavigationApp.isSetup()) {
            MapboxNavigationApp.setup(
                NavigationOptions.Builder(this)
                    .build()
            )
        }

        Timber.d("MapboxNavigationApp initialized successfully")
    }
}
