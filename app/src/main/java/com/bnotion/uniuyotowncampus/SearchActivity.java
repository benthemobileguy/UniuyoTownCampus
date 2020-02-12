package com.bnotion.uniuyotowncampus;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.content.ContextCompat;

import android.app.AlarmManager;
import android.app.Dialog;
import android.app.PendingIntent;
import android.app.TimePickerDialog;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.graphics.BitmapFactory;
import android.graphics.PointF;
import android.graphics.RectF;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.bnotion.uniuyotowncampus.application.BroadcastAlarm;
import com.bnotion.uniuyotowncampus.model.Property;
import com.google.gson.JsonElement;
import com.mapbox.geojson.Feature;
import com.mapbox.geojson.FeatureCollection;
import com.mapbox.geojson.Point;
import com.mapbox.mapboxsdk.Mapbox;
import com.mapbox.mapboxsdk.annotations.MarkerOptions;
import com.mapbox.mapboxsdk.camera.CameraPosition;
import com.mapbox.mapboxsdk.camera.CameraUpdateFactory;
import com.mapbox.mapboxsdk.geometry.LatLng;
import com.mapbox.mapboxsdk.maps.MapView;
import com.mapbox.mapboxsdk.maps.MapboxMap;
import com.mapbox.mapboxsdk.maps.OnMapReadyCallback;
import com.mapbox.mapboxsdk.maps.Style;
import com.mapbox.mapboxsdk.plugins.annotation.SymbolManager;
import com.mapbox.mapboxsdk.plugins.markerview.MarkerView;
import com.mapbox.mapboxsdk.plugins.markerview.MarkerViewManager;
import com.mapbox.mapboxsdk.style.expressions.Expression;
import com.mapbox.mapboxsdk.style.layers.FillLayer;
import com.mapbox.mapboxsdk.style.layers.PropertyFactory;
import com.mapbox.mapboxsdk.style.layers.SymbolLayer;
import com.mapbox.mapboxsdk.style.sources.GeoJsonSource;
import com.mapbox.turf.TurfMeta;

import java.net.URI;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import timber.log.Timber;

import static android.view.ViewGroup.LayoutParams.WRAP_CONTENT;
import static com.mapbox.mapboxsdk.style.expressions.Expression.get;
import static com.mapbox.mapboxsdk.style.expressions.Expression.literal;
import static com.mapbox.mapboxsdk.style.expressions.Expression.match;
import static com.mapbox.mapboxsdk.style.expressions.Expression.stop;
import static com.mapbox.mapboxsdk.style.layers.PropertyFactory.fillOpacity;
import static com.mapbox.mapboxsdk.style.layers.PropertyFactory.iconAllowOverlap;
import static com.mapbox.mapboxsdk.style.layers.PropertyFactory.iconIgnorePlacement;
import static com.mapbox.mapboxsdk.style.layers.PropertyFactory.iconImage;
import static com.mapbox.mapboxsdk.style.layers.PropertyFactory.iconOffset;

public class SearchActivity extends AppCompatActivity implements OnMapReadyCallback,
        MapboxMap.OnMapClickListener {
    private static final String TAG = "SearchActivity";
    private ArrayList<String> arrayList;
    private ArrayList<String> arrayList2;
    public ArrayList<Double> longitude;
    public ArrayList<Double> latitude;
    public Calendar calendar;
    TextView buildngName;
    private MapView mMapView;
    private MapboxMap mapboxMap;
    private MarkerView markerView;
    private View customView;
    private ImageView notification;
    private MarkerViewManager markerViewManager;
    private AutoCompleteTextView search;
    private static final String geoJsonSourceId = "geoJsonData";
    private static final String geoJsonLayerId = "polygonFillLayer";
    private String mapbox_access_token = "pk.eyJ1IjoiYmVuMjAxOSIsImEiOiJjazI0YmF6MGoxNGhqM2ducjhscGpleXV1In0.czhhj_e8WSpRNqI2IlGd5w";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // locking out landscape screen orientation for mobiles
        if (getResources().getBoolean(R.bool.portrait_only)) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
            // locking out portait screen orientation for tablets
        }
        if (getResources().getBoolean(R.bool.landscape_only)) {
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
        }
        setContentView(R.layout.activity_search);
        calendar = Calendar.getInstance();;
        customView = LayoutInflater.from(this).inflate(
                R.layout.custom_dialog_search, null);
        buildngName = customView.findViewById(R.id.building_name);
        customView.setLayoutParams(new FrameLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT));
        notification = customView.findViewById(R.id.notification);
        arrayList = new ArrayList<>();
        arrayList2 = new ArrayList<>();
        longitude = new ArrayList<>();
        latitude = new ArrayList<>();
        search = findViewById(R.id.search);
        Mapbox.getInstance(this, mapbox_access_token);
        mMapView = findViewById(R.id.mapView);
        mMapView.getMapAsync(this);
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setTitle("");
        Button backBtn = findViewById(R.id.back_btn);
        backBtn.setOnClickListener(v -> {
            onBackPressed();
        });

    }

    @Override
    public void onBackPressed() {
        finish();
        overridePendingTransition(R.anim.fade_in, R.anim.fade_out);
    }

    @Override
    public void onResume() {
        super.onResume();
        mMapView.onResume();
    }

    @Override
    protected void onStart() {
        super.onStart();
        mMapView.onStart();
    }

    @Override
    protected void onStop() {
        super.onStop();
        mMapView.onStop();
    }

    @Override
    public void onPause() {
        super.onPause();
        mMapView.onPause();
    }

    @Override
    public void onLowMemory() {
        super.onLowMemory();
        mMapView.onLowMemory();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (markerViewManager != null) {
            markerViewManager.onDestroy();
        }
        mMapView.onDestroy();
    }

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        mMapView.onSaveInstanceState(outState);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case android.R.id.home:
                onBackPressed();
                break;
        }
        return true;
    }

    @Override
    public boolean onMapClick(@NonNull LatLng point) {
        Utils.hideKeyboard(SearchActivity.this);
        if (markerView != null) {
            markerViewManager.removeMarker(markerView);
        }
// Convert LatLng coordinates to screen pixel and only query the rendered features.

        final PointF pixel = mapboxMap.getProjection().toScreenLocation(point);

        List<Feature> features = mapboxMap.queryRenderedFeatures(pixel, geoJsonLayerId);
// Get the first feature within the list if one exist
        if (features.size() > 0) {
            Feature feature = features.get(0);
            zoomToPoint(point);
// Set the View's TextViews with content
            markerView = new MarkerView(new LatLng(point), customView);
            if (feature.getProperty("name") != null) {
                buildngName.setText(feature.getProperty("name").toString().replace("\"", ""));
                search.setText(feature.getProperty("name").toString().replace("\"", ""));
                markerViewManager.addMarker(markerView);
            }
// Ensure the feature has properties defined
            if (feature.properties() != null) {
                for (Map.Entry<String, JsonElement> entry : feature.properties().entrySet()) {
// Log all the properties
                    Log.d(TAG, String.format("%s = %s", entry.getKey(), entry.getValue()));
                }
            }
        }
        return true;
    }

    private void zoomToPoint(LatLng point) {
        CameraPosition position = new CameraPosition.Builder()
                .target(new LatLng(point)) // Sets the new camera position
                .zoom(16) // Sets the zoom
                .tilt(10) // Set the camera tilt
                .build(); // Creates a CameraPosition from the builder
        mapboxMap.animateCamera(CameraUpdateFactory
                .newCameraPosition(position), 3000);
    }

    @Override
    public void onMapReady(@NonNull final MapboxMap mapboxMap) {
        SearchActivity.this.mapboxMap = mapboxMap;
        mapboxMap.setStyle(Style.MAPBOX_STREETS, style -> {
            markerViewManager = new MarkerViewManager(mMapView, mapboxMap);
            mapboxMap.addOnMapClickListener(SearchActivity.this);
            addGeoJsonSourceToMap(style);

// Use the View to create a MarkerView which will eventually be given to
// the plugin's MarkerViewManager class

            initLayers(style);
            GeoJsonSource source = style.getSourceAs(geoJsonSourceId);
            new Handler().postDelayed(() -> {
                if (source != null) {
                    List<Feature> features = source.querySourceFeatures(Expression.all());
                    FeatureCollection featureCollection = FeatureCollection.fromFeatures(features);
                    List<Point> pointList = TurfMeta.coordAll(featureCollection, true);
                    for (Point singlePoint : pointList) {
                        List<Double> coordinateListForSinglePoint = singlePoint.coordinates();
                        Double lng = coordinateListForSinglePoint.get(0);
                        Double lat = coordinateListForSinglePoint.get(1);
                        longitude.add(lng);
                        latitude.add(lat);

                    }
                    search.setOnItemClickListener((parent, view, position, id) -> {
                        Utils.hideKeyboard(SearchActivity.this);
                        if (markerView != null) {
                            markerViewManager.removeMarker(markerView);
                        }
                        if (latitude.get(position) != null && longitude.get(position) != null) {
                            LatLng point = new LatLng(new LatLng(latitude.get(position), longitude.get(position)));
                            zoomToPoint(new LatLng(point));
                            markerView = new MarkerView(new LatLng(point), customView);
                            buildngName.setText(search.getText().toString());
                            search.setText(search.getText().toString());
                            markerViewManager.addMarker(markerView);

                        } else {
                            Toast.makeText(this, "Coordinates for this building not found. Try again.", Toast.LENGTH_SHORT).show();
                        }
                    });
                    notification.setOnClickListener(v -> {
                        TimePickerDialog timePickerDialog;
                        int currentHour = calendar.get(Calendar.HOUR_OF_DAY);
                        int currentMinute = calendar.get(Calendar.MINUTE);
                        timePickerDialog = new TimePickerDialog(SearchActivity.this, R.style.TimePickerTheme, (timePicker, hourOfDay, minutes) -> {
                            calendar.set(Calendar.HOUR_OF_DAY, hourOfDay);
                            calendar.set(Calendar.MINUTE, minutes);
                            calendar.set(Calendar.SECOND, 0);
                            String amPm;
                            if (hourOfDay >= 12) {
                                amPm = "PM";
                            } else {
                                amPm = "AM";
                            }
                            //show alert dialog
                            AlertDialog.Builder builder = new AlertDialog.Builder(this);
                            builder.setIcon(R.drawable.ic_bell)
                                    .setTitle(buildngName.getText().toString())
                                    .setMessage("You are about to schedule a routing reminder for " + buildngName.getText().toString() +
                                            " destination at " + String.format("%02d:%02d", hourOfDay, minutes) + amPm+".This reminder would be be received with a notification.")
                                    .setPositiveButton("SET", (dialogInterface, i) -> {
                                        setTimer();
                                    })
                                    .setNegativeButton("CANCEL", (dialogInterface, i) -> {
                                        dialogInterface.dismiss();
                                    })
                                    .show();
                        }, currentHour, currentMinute, false);
                        timePickerDialog.setTitle(buildngName.getText().toString());
                        timePickerDialog.show();
                    });
                    for (int i = 0; i < features.size(); i++) {
                        Feature feature = features.get(i);
// Ensure the feature has properties defined
                        if (feature.properties() != null) {
                            for (Map.Entry<String, JsonElement> entry : feature.properties().entrySet()) {
// Log all the properties
                                if (entry.getKey().equals("name")) {
                                    if (!arrayList2.contains(entry.getValue().toString())) {
                                        arrayList2.add(entry.getValue().toString().replace("\"", ""));
                                    }

                                    ArrayAdapter<String> adapter = new ArrayAdapter<String>(this,
                                            android.R.layout.simple_dropdown_item_1line, arrayList2);
                                    search.setAdapter(adapter);
                                    search.setThreshold(1);
                                }
                            }
                        }
                    }
                }
            }, 5000);

        });
    }

    private void setTimer(){
        AlarmManager alarmManager = (AlarmManager) this.getSystemService(Context.ALARM_SERVICE);
        Intent intent = new Intent(this, BroadcastAlarm.class);
        intent.setAction("MY_NOTIFICATION_MESSAGE");
        PendingIntent pendingIntent = PendingIntent.getBroadcast(this, 100, intent, PendingIntent.FLAG_UPDATE_CURRENT);
        alarmManager.set(AlarmManager.RTC_WAKEUP, calendar.getTimeInMillis(), pendingIntent);
    }

    private void addGeoJsonSourceToMap(@NonNull Style loadedMapStyle) {
        try {
// Add GeoJsonSource to map
            loadedMapStyle.addSource(new GeoJsonSource(geoJsonSourceId, new URI("https://gist.githubusercontent.com/benthemobileguy/c5ee9e6e5a5db7e70aeeba4137816073/raw/7df879385a193d1c91cdc63fe341a9ab8a37a7c6/my%2520map")));
        } catch (Throwable throwable) {
            Timber.e("Couldn't add GeoJsonSource to map - %s", throwable);
        }
    }

    private void initLayers(@NonNull Style loadedMapStyle) {
// Add the LineLayer to the map. This layer will display the directions route.
        loadedMapStyle.addLayer(new FillLayer(geoJsonLayerId, geoJsonSourceId).withProperties(
                PropertyFactory.fillColor(ContextCompat.getColor(this, R.color.customRed))));

// Add the SymbolLayer to the map to show the origin and destination pin markers
        loadedMapStyle.addLayer(new SymbolLayer(Constants.ICON_LAYER_ID, Constants.ICON_SOURCE_ID).withProperties(
                iconImage(match(get("originDestination"), literal("origin"),
                        stop("origin", Constants.ORIGIN_ICON_ID),
                        stop("destination", Constants.DESTINATION_ICON_ID))),
                iconIgnorePlacement(true),
                iconAllowOverlap(true),
                iconOffset(new Float[]{0f, -4f})));
    }

}
