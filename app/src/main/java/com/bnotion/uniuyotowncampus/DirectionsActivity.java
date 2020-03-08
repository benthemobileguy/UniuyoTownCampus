package com.bnotion.uniuyotowncampus;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.content.ContextCompat;

import android.content.Context;
import android.content.pm.ActivityInfo;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.PointF;
import android.graphics.RectF;

import static com.mapbox.mapboxsdk.style.expressions.Expression.get;
import static com.mapbox.mapboxsdk.style.expressions.Expression.match;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.google.gson.JsonElement;
import com.mapbox.android.core.permissions.PermissionsListener;
import com.mapbox.android.core.permissions.PermissionsManager;
import com.mapbox.api.directions.v5.DirectionsCriteria;
import com.mapbox.api.directions.v5.models.DirectionsResponse;
import com.mapbox.api.directions.v5.models.DirectionsRoute;
import com.mapbox.geojson.Feature;
import com.mapbox.geojson.FeatureCollection;
import com.mapbox.geojson.Point;
import com.mapbox.mapboxsdk.Mapbox;
import com.mapbox.mapboxsdk.annotations.MarkerOptions;
import com.mapbox.mapboxsdk.camera.CameraPosition;
import com.mapbox.mapboxsdk.camera.CameraUpdateFactory;
import com.mapbox.mapboxsdk.geometry.LatLng;
import com.mapbox.mapboxsdk.location.LocationComponent;
import com.mapbox.mapboxsdk.location.LocationComponentActivationOptions;
import com.mapbox.mapboxsdk.location.modes.CameraMode;
import com.mapbox.mapboxsdk.location.modes.RenderMode;
import com.mapbox.mapboxsdk.maps.MapView;
import com.mapbox.mapboxsdk.maps.MapboxMap;
import com.mapbox.mapboxsdk.maps.OnMapReadyCallback;
import com.mapbox.mapboxsdk.maps.Style;
import com.mapbox.mapboxsdk.plugins.markerview.MarkerView;
import com.mapbox.mapboxsdk.plugins.markerview.MarkerViewManager;
import com.mapbox.mapboxsdk.style.expressions.Expression;
import com.mapbox.mapboxsdk.style.layers.FillLayer;
import com.mapbox.mapboxsdk.style.layers.LineLayer;
import com.mapbox.mapboxsdk.style.layers.Property;
import com.mapbox.mapboxsdk.style.layers.PropertyFactory;
import com.mapbox.mapboxsdk.style.layers.SymbolLayer;
import com.mapbox.mapboxsdk.style.sources.GeoJsonSource;
import com.mapbox.services.android.navigation.ui.v5.NavigationLauncher;
import com.mapbox.services.android.navigation.ui.v5.NavigationLauncherOptions;
import com.mapbox.services.android.navigation.ui.v5.route.NavigationMapRoute;
import com.mapbox.services.android.navigation.v5.navigation.NavigationRoute;
import com.mapbox.turf.TurfMeta;

import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import timber.log.Timber;

import static android.graphics.Color.parseColor;
import static android.view.ViewGroup.LayoutParams.WRAP_CONTENT;
import static com.mapbox.mapboxsdk.style.expressions.Expression.color;
import static com.mapbox.mapboxsdk.style.expressions.Expression.interpolate;
import static com.mapbox.mapboxsdk.style.expressions.Expression.lineProgress;
import static com.mapbox.mapboxsdk.style.expressions.Expression.linear;
import static com.mapbox.mapboxsdk.style.expressions.Expression.literal;
import static com.mapbox.mapboxsdk.style.expressions.Expression.stop;
import static com.mapbox.mapboxsdk.style.layers.PropertyFactory.fillOpacity;
import static com.mapbox.mapboxsdk.style.layers.PropertyFactory.iconAllowOverlap;
import static com.mapbox.mapboxsdk.style.layers.PropertyFactory.iconIgnorePlacement;
import static com.mapbox.mapboxsdk.style.layers.PropertyFactory.iconImage;
import static com.mapbox.mapboxsdk.style.layers.PropertyFactory.iconOffset;

public class DirectionsActivity extends AppCompatActivity implements OnMapReadyCallback,
        MapboxMap.OnMapClickListener, PermissionsListener { ;
    private static final String TAG = "DirectionsActivity";
    private static final String RED_PIN_ICON_ID = "red_icon_id";
    private static final float LINE_WIDTH = 6f;
    private static final String ORIGIN_COLOR = "#2096F3";
    private static final String DESTINATION_COLOR = "#F84D4D";
    public ArrayList<Double> longitude;
    public ArrayList<Double> latitude;
    private MapView mMapView;
    private ArrayList<String> arrayList2;
    private String buildingName;
    private MarkerView markerView;
    private MarkerViewManager markerViewManager;
    private Point origin = Point.fromLngLat(7.9235053, 5.0409083);
    private Point destination  = Point.fromLngLat(7.9235090, 5.0409090);
    private Point initOrigin = Point.fromLngLat(7.9235053, 5.0409083);
    private Point initDestination  = Point.fromLngLat(7.9235090, 5.0409090);
    private AutoCompleteTextView toEditText, fromEditText;
    private NavigationMapRoute navigationMapRoute;
    private LocationComponent locationComponent;
    private MapboxMap mapboxMap;
    private DirectionsRoute currentRoute;
    private static final String geoJsonSourceId = "geoJsonData";
    private static final String geoJsonLayerId = "polygonFillLayer";
    private String mapbox_access_token = "pk.eyJ1IjoiYmVuMjAxOSIsImEiOiJjazI0YmF6MGoxNGhqM2ducjhscGpleXV1In0.czhhj_e8WSpRNqI2IlGd5w";
    private PermissionsManager permissionsManager;

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
        setContentView(R.layout.activity_directions);
        // Mapbox access token is configured here. This needs to be called either in your application
// object or in the same activity which contains the mapview.
        arrayList2 = new ArrayList<>();
        longitude = new ArrayList<>();
        latitude = new ArrayList<>();
        Mapbox.getInstance(this, mapbox_access_token);
        mMapView = findViewById(R.id.mapView);
        toEditText = findViewById(R.id.to_editText);
        fromEditText = findViewById(R.id.from_EditText);
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setTitle("");
        Button backBtn = findViewById(R.id.back_btn);
        backBtn.setOnClickListener(v -> {
            onBackPressed();
        });
        mMapView.getMapAsync(this);
        Button navigationBtn = findViewById(R.id.button);
        navigationBtn.setOnClickListener(v -> {
            boolean simulateRoute = true;
            if (origin !=null && destination != null && currentRoute!=null) {
                NavigationLauncherOptions options = NavigationLauncherOptions.builder()
                        .directionsRoute(currentRoute)
                        .shouldSimulateRoute(simulateRoute)
                        .build();
// Call this method with Context from within an Activity
                NavigationLauncher.startNavigation(this, options);
            } else {
                Toast.makeText(this, "Please specify your origin and destination", Toast.LENGTH_LONG).show();
            }
        });
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
    public void onBackPressed() {
        finish();
        overridePendingTransition(R.anim.fade_in, R.anim.fade_out);
    }

    @Override
    public void onMapReady(@NonNull final MapboxMap mapboxMap) {
        markerViewManager = new MarkerViewManager(mMapView, mapboxMap);
        DirectionsActivity.this.mapboxMap = mapboxMap;
        mapboxMap.setStyle(Style.MAPBOX_STREETS, style -> {
            //enableLocationComponent(style);
            addDestinationIconLayer(style);
            addGeoJsonSourceToMap(style);
            addOriginIconLayer(style);
            addDestinationIconLayer(style);
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
                    toEditText.setOnItemClickListener((parent, view, position, id) -> {
                        hideKeyboard();
                        if (markerView != null) {
                            markerViewManager.removeMarker(markerView);
                        }
                        if (latitude.get(position) != null && longitude.get(position) != null) {
                            zoomToPoint(new LatLng(latitude.get(position), longitude.get(position)));
                            origin =  Point.fromLngLat(longitude.get(position), latitude.get(position));
                           getRoute(mapboxMap,  origin, destination);

                        } else {
                            Toast.makeText(this, "Coordinates for this building not found. Try again.", Toast.LENGTH_SHORT).show();
                        }
                    });
                    fromEditText.setOnItemClickListener((parent, view, position, id) -> {
                        hideKeyboard();
                        if (markerView != null) {
                            markerViewManager.removeMarker(markerView);
                        }
                        if (latitude.get(position) != null && longitude.get(position) != null) {
                            zoomToPoint(new LatLng(latitude.get(position), longitude.get(position)));
                            destination =  Point.fromLngLat(longitude.get(position), latitude.get(position));
                            getRoute(mapboxMap,  origin, destination);

                        } else {
                            Toast.makeText(this, "Coordinates for this building not found. Try again.", Toast.LENGTH_SHORT).show();
                        }
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
                                    toEditText.setAdapter(adapter);
                                    toEditText.setThreshold(1);
                                    fromEditText.setAdapter(adapter);
                                    fromEditText.setThreshold(1);
                                }
                            }
                        }
                    }
                }
            }, 5000);

            mapboxMap.addOnMapClickListener(DirectionsActivity.this);

        });
    }

    private void addDestinationIconLayer(Style style) {
        style.addImage("icon-destination-image", BitmapFactory.decodeResource(this.getResources(), R.drawable.mapbox_marker_icon_default));
    }
    private void addOriginIconLayer(Style style) {
        style.addImage("icon-origin-image", BitmapFactory.decodeResource(this.getResources(), R.drawable.mapbox_marker_icon_default));
    }

    private void enableLocationComponent(@NonNull Style loadedMapStyle) {
// Check if permissions are enabled and if not request
        if (PermissionsManager.areLocationPermissionsGranted(this)) {

// Get an instance of the component
            LocationComponent locationComponent = mapboxMap.getLocationComponent();

// Activate with options
            locationComponent.activateLocationComponent(
                    LocationComponentActivationOptions.builder(this, loadedMapStyle).build());

// Enable to make component visible
            locationComponent.setLocationComponentEnabled(false);

// Set the component's camera mode
            locationComponent.setCameraMode(CameraMode.TRACKING);

// Set the component's render mode
            locationComponent.setRenderMode(RenderMode.COMPASS);
        } else {
            permissionsManager = new PermissionsManager(this);
            permissionsManager.requestLocationPermissions(this);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        permissionsManager.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    @Override
    public void onExplanationNeeded(List<String> permissionsToExplain) {

    }

    @Override
    public void onPermissionResult(boolean granted) {
        if (granted) {
            mapboxMap.getStyle(this::enableLocationComponent);
        } else {
            Toast.makeText(this, "Permission not granted", Toast.LENGTH_LONG).show();
            finish();
        }
    }

    @Override
    public boolean onMapClick(@NonNull LatLng point) {
       removeMarker();
       final PointF pixel = mapboxMap.getProjection().toScreenLocation(point);

        List<Feature> features = mapboxMap.queryRenderedFeatures(pixel, geoJsonLayerId);
// Get the first feature within the list if one exist
        if (features.size() > 0) {
            Feature feature = features.get(0);
            CameraPosition position = new CameraPosition.Builder()
                    .target(new LatLng(point)) // Sets the new camera position
                    .zoom(16) // Sets the zoom
                    .tilt(10) // Set the camera tilt
                    .build(); // Creates a CameraPosition from the builder

            mapboxMap.animateCamera(CameraUpdateFactory
                    .newCameraPosition(position), 3000);
            View customView = LayoutInflater.from(this).inflate(
                    R.layout.custom_dialog_directions, null);
            customView.setLayoutParams(new FrameLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT));
            if(feature.getProperty("name")!=null){
               buildingName = feature.getProperty("name").toString().replace("\"", "");
            }
            Button buildngName = customView.findViewById(R.id.title);
            Button directionsFrom = customView.findViewById(R.id.directions_from);
            Button directionsTo = customView.findViewById(R.id.directions_to);
            Button closeMarker= customView.findViewById(R.id.close_btn);
            directionsFrom.setOnClickListener(v -> {
                origin =  Point.fromLngLat(point.getLongitude(), point.getLatitude());
                if (!buildingName.equals(toEditText.getText().toString())) {
                    fromEditText.setText(buildingName);
                    removeMarker();
                    if(origin!=null && destination!=null && origin !=initOrigin &&destination  !=initDestination){
                        getRoute(mapboxMap, origin, destination);
                    }
                }

            });
            directionsTo.setOnClickListener(v -> {
                destination = Point.fromLngLat(point.getLongitude(), point.getLatitude());
                if (!buildingName.equals(fromEditText.getText().toString())) {
                    toEditText.setText(buildingName);
                    removeMarker();
                    if(origin!=null && destination!=null){
                        getRoute(mapboxMap, origin, destination);
                    }
                } else {
                    Toast.makeText(this, "Origin and destination can not be the same", Toast.LENGTH_SHORT).show();
                }
            });
            closeMarker.setOnClickListener(v -> {
                removeMarker();
            });
            markerView = new MarkerView(new LatLng(point), customView);
            if(feature.getProperty("name")!=null){
                buildngName.setText(buildingName);
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
        locationComponent = mapboxMap.getLocationComponent();

//        if (locationComponent.getLastKnownLocation() != null) {
//            Point originPoint = Point.fromLngLat(locationComponent.getLastKnownLocation().getLongitude(), locationComponent.getLastKnownLocation().getLatitude());
//            GeoJsonSource geoJsonSource = mapboxMap.getStyle().getSourceAs(geoJsonSourceId);
//            if(geoJsonSource!=null){
//                geoJsonSource.setGeoJson(originPoint);
//            }
//


        return false;
    }

    private void removeMarker() {
        if(markerView!=null){
            markerViewManager.removeMarker(markerView);
        }
    }

    private void getRoute(MapboxMap mapboxMap, Point originPoint, Point destinationPoint) {
        NavigationRoute.builder(this)
                .accessToken(Mapbox.getAccessToken())
                .origin(originPoint)
                .destination(destinationPoint)
                .profile(DirectionsCriteria.PROFILE_DRIVING)
                .build()
                .getRoute(new Callback<DirectionsResponse>() {
                    @Override
                    public void onResponse(Call<DirectionsResponse> call, Response<DirectionsResponse> response) {
// You can get the generic HTTP info about the response
                        Log.d(TAG, "Response code: " + response.code());
                        if (response.body() == null) {
                            Log.e(TAG, "No routes found, make sure you set the right user and access token.");
                            return;
                        } else if (response.body().routes().size() < 1) {
                            Log.e(TAG, "No routes found");
                            return;
                        }

                        currentRoute = response.body().routes().get(0);
// Draw the route on the map
                        if (navigationMapRoute != null) {
                            navigationMapRoute.removeRoute();
                        } else {
                            navigationMapRoute = new NavigationMapRoute(null, mMapView, mapboxMap, R.style.NavigationMapRoute);
                        }
                        navigationMapRoute.addRoute(currentRoute);
                    }

                    @Override
                    public void onFailure(Call<DirectionsResponse> call, Throwable throwable) {
                        Log.e(TAG, "Error: " + throwable.getMessage());
                    }
                });
    }

    private void addGeoJsonSourceToMap(@NonNull Style loadedMapStyle) {

        try {
// Add GeoJsonSource to map
            loadedMapStyle.addSource(new GeoJsonSource(geoJsonSourceId, new URI("https://gist.githubusercontent.com/benthemobileguy/9899ee8cd354c7bdb346b17cb79bf966/raw/0772e5e254357c69ab2cce578d1aee5604f85c21/gistfile1.txt"))
            );
            loadedMapStyle.addSource(new GeoJsonSource(Constants.ICON_SOURCE_ID, getOriginAndDestinationFeatureCollection()));
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
                iconOffset(new Float[] {0f, -4f})));
    }

    private FeatureCollection getOriginAndDestinationFeatureCollection() {
        Feature originFeature = Feature.fromGeometry(origin);
        originFeature.addStringProperty("originDestination", "origin");
        Feature destinationFeature = Feature.fromGeometry(destination);
        destinationFeature.addStringProperty("originDestination", "destination");
        return FeatureCollection.fromFeatures(new Feature[] {originFeature, destinationFeature});
    }
    public void hideKeyboard() {
        try {
            InputMethodManager inputmanager = (InputMethodManager) this.getSystemService(Context.INPUT_METHOD_SERVICE);
            if (inputmanager != null) {
                inputmanager.hideSoftInputFromWindow(this.getCurrentFocus().getWindowToken(), 0);
            }
        } catch (Exception var2) {
        }

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
}
