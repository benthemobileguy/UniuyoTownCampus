package com.bnotion.uniuyotowncampus.application;

import android.app.Application;

import com.bnotion.uniuyotowncampus.R;
import com.mapbox.mapboxsdk.Mapbox;

public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();

// Mapbox Access token
        Mapbox.getInstance(getApplicationContext(), getString(R.string.mapbox_access_token));
    }
}