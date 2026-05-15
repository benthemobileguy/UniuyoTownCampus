package com.bnotion.uniuyotowncampus

import android.Manifest
import android.content.Context
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.MenuItem
import android.view.inputmethod.InputMethodManager
import android.widget.ArrayAdapter
import android.widget.AutoCompleteTextView
import android.widget.Button
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.mapbox.api.directions.v5.DirectionsCriteria
import com.mapbox.api.directions.v5.models.RouteOptions
import com.mapbox.geojson.Feature
import com.mapbox.geojson.FeatureCollection
import com.mapbox.geojson.Point
import com.mapbox.maps.CameraOptions
import com.mapbox.maps.MapView
import com.mapbox.maps.Style
import com.mapbox.maps.extension.style.layers.addLayer
import com.mapbox.maps.extension.style.layers.generated.fillLayer
import com.mapbox.maps.extension.style.sources.addSource
import com.mapbox.maps.extension.style.sources.generated.geoJsonSource
import com.mapbox.maps.plugin.animation.flyTo
import com.mapbox.maps.plugin.gestures.addOnMapClickListener
import com.mapbox.navigation.base.extensions.applyDefaultNavigationOptions
import com.mapbox.navigation.base.route.NavigationRoute
import com.mapbox.navigation.base.route.NavigationRouterCallback
import com.mapbox.navigation.base.route.RouterFailure
import com.mapbox.navigation.core.lifecycle.MapboxNavigationApp
import com.mapbox.navigation.ui.maps.route.line.api.MapboxRouteLineApi
import com.mapbox.navigation.ui.maps.route.line.api.MapboxRouteLineView
import com.mapbox.navigation.ui.maps.route.line.model.MapboxRouteLineApiOptions
import com.mapbox.navigation.ui.maps.route.line.model.MapboxRouteLineViewOptions
import com.mapbox.turf.TurfMeta
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import timber.log.Timber
import java.net.URL

class DirectionsActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "DirectionsActivity"
        private const val GEO_JSON_SOURCE_ID = "geoJsonData"
        private const val GEO_JSON_LAYER_ID = "polygonFillLayer"
        private const val GEO_JSON_URL = "https://gist.githubusercontent.com/benthemobileguy/9899ee8cd354c7bdb346b17cb79bf966/raw/0772e5e254357c69ab2cce578d1aee5604f85c21/gistfile1.txt"
    }

    private lateinit var mapView: MapView
    private lateinit var toEditText: AutoCompleteTextView
    private lateinit var fromEditText: AutoCompleteTextView

    private var origin: Point = Point.fromLngLat(7.9235053, 5.0409083)
    private var destination: Point = Point.fromLngLat(7.9235090, 5.0409090)
    private var currentRoute: NavigationRoute? = null

    private val buildingNames = ArrayList<String>()
    private val coordinates = ArrayList<Point>()

    private lateinit var routeLineApi: MapboxRouteLineApi
    private lateinit var routeLineView: MapboxRouteLineView

    private var locationPermissionGranted = false

    // Permission request launcher
    private val locationPermissionRequest = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        when {
            permissions.getOrDefault(Manifest.permission.ACCESS_FINE_LOCATION, false) -> {
                locationPermissionGranted = true
                Timber.d("Fine location permission granted")
            }
            permissions.getOrDefault(Manifest.permission.ACCESS_COARSE_LOCATION, false) -> {
                locationPermissionGranted = true
                Timber.d("Coarse location permission granted")
            }
            else -> {
                locationPermissionGranted = false
                Toast.makeText(
                    this,
                    "Location permission is required for navigation",
                    Toast.LENGTH_LONG
                ).show()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Lock screen orientation
        if (resources.getBoolean(R.bool.portrait_only)) {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        }
        if (resources.getBoolean(R.bool.landscape_only)) {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        }

        setContentView(R.layout.activity_directions)

        // Attach to MapboxNavigationApp lifecycle
        MapboxNavigationApp.attach(this)

        // Check and request location permissions
        checkLocationPermission()

        // Initialize views
        mapView = findViewById(R.id.mapView)
        toEditText = findViewById(R.id.to_editText)
        fromEditText = findViewById(R.id.from_EditText)

        val toolbar: Toolbar = findViewById(R.id.toolbar)
        setSupportActionBar(toolbar)
        supportActionBar?.title = ""

        val backBtn: Button = findViewById(R.id.back_btn)
        backBtn.setOnClickListener {
            finish()
            overrideTransitionOnFinish()
        }

        // Handle back press with modern callback
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                finish()
                overrideTransitionOnFinish()
            }
        })

        // Initialize route line components
        routeLineApi = MapboxRouteLineApi(MapboxRouteLineApiOptions.Builder().build())
        routeLineView = MapboxRouteLineView(MapboxRouteLineViewOptions.Builder(this).build())

        // Setup map
        setupMap()

        // Navigation button
        val navigationBtn: Button = findViewById(R.id.button)
        navigationBtn.setOnClickListener {
            if (currentRoute != null) {
                Toast.makeText(this, "Navigation would start here", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this, "Please specify your origin and destination", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun checkLocationPermission() {
        when {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED -> {
                locationPermissionGranted = true
            }
            shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_FINE_LOCATION) -> {
                AlertDialog.Builder(this)
                    .setTitle("Location Permission Required")
                    .setMessage("This app needs location permission to provide navigation directions.")
                    .setPositiveButton("Grant") { _, _ ->
                        requestLocationPermission()
                    }
                    .setNegativeButton("Cancel", null)
                    .show()
            }
            else -> {
                requestLocationPermission()
            }
        }
    }

    private fun requestLocationPermission() {
        locationPermissionRequest.launch(
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            )
        )
    }

    private fun setupMap() {
        mapView.mapboxMap.loadStyle(Style.STANDARD) { style ->
            // Add GeoJSON source
            addGeoJsonSource(style)

            // Add fill layer for buildings
            addBuildingLayer(style)

            // Setup map click listener
            mapView.mapboxMap.addOnMapClickListener { point ->
                handleMapClick(point)
                true
            }

            // Load building data using coroutines
            loadBuildingsFromGeoJson()

            // Center camera on campus
            val cameraOptions = CameraOptions.Builder()
                .center(Point.fromLngLat(7.9235053, 5.0409083))
                .zoom(15.0)
                .build()
            mapView.mapboxMap.setCamera(cameraOptions)
        }
    }

    private fun addGeoJsonSource(style: Style) {
        try {
            style.addSource(
                geoJsonSource(GEO_JSON_SOURCE_ID) {
                    data(GEO_JSON_URL)
                }
            )
        } catch (e: Exception) {
            Timber.e(e, "Error adding GeoJSON source")
        }
    }

    private fun addBuildingLayer(style: Style) {
        try {
            style.addLayer(
                fillLayer(GEO_JSON_LAYER_ID, GEO_JSON_SOURCE_ID) {
                    fillColor(Color.parseColor("#CD5C5C"))
                    fillOpacity(0.7)
                }
            )
        } catch (e: Exception) {
            Timber.e(e, "Error adding building layer")
        }
    }

    private fun loadBuildingsFromGeoJson() {
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val url = URL(GEO_JSON_URL)
                val connection = url.openConnection()
                connection.connectTimeout = 10000
                connection.readTimeout = 10000
                connection.connect()

                val json = connection.getInputStream().bufferedReader().use { it.readText() }
                val featureCollection = FeatureCollection.fromJson(json)

                withContext(Dispatchers.Main) {
                    featureCollection.features()?.let { features ->
                        processFeatures(features)
                    }
                }
            } catch (e: Exception) {
                Timber.e(e, "Error loading GeoJSON")
                withContext(Dispatchers.Main) {
                    Toast.makeText(
                        this@DirectionsActivity,
                        "Failed to load building data",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
        }
    }

    private fun processFeatures(features: List<Feature>) {
        buildingNames.clear()
        coordinates.clear()

        for (feature in features) {
            feature.properties()?.let { props ->
                val name = props.get("name")?.asString?.replace("\"", "")
                if (name != null && !buildingNames.contains(name)) {
                    buildingNames.add(name)

                    // Get coordinates from the feature
                    val points = TurfMeta.coordAll(feature, true)
                    if (points.isNotEmpty()) {
                        coordinates.add(points[0])
                    }
                }
            }
        }

        // Setup autocomplete adapters
        val adapter = ArrayAdapter(this, android.R.layout.simple_dropdown_item_1line, buildingNames)
        toEditText.setAdapter(adapter)
        toEditText.threshold = 1
        fromEditText.setAdapter(adapter)
        fromEditText.threshold = 1

        // Setup item click listeners
        toEditText.setOnItemClickListener { _, _, position, _ ->
            hideKeyboard()
            if (position < coordinates.size) {
                origin = coordinates[position]
                zoomToPoint(origin)
                if (destination != origin) {
                    requestRoute()
                }
            }
        }

        fromEditText.setOnItemClickListener { _, _, position, _ ->
            hideKeyboard()
            if (position < coordinates.size) {
                destination = coordinates[position]
                zoomToPoint(destination)
                if (origin != destination) {
                    requestRoute()
                }
            }
        }

        Timber.d("Loaded ${buildingNames.size} buildings")
    }

    private fun handleMapClick(point: Point): Boolean {
        val screenPoint = mapView.mapboxMap.pixelForCoordinate(point)
        val geometry = com.mapbox.maps.RenderedQueryGeometry(screenPoint)
        val options = com.mapbox.maps.RenderedQueryOptions(listOf(GEO_JSON_LAYER_ID), null)

        mapView.mapboxMap.queryRenderedFeatures(geometry, options) { result ->
            result.value?.let { queriedFeatures ->
                if (queriedFeatures.isNotEmpty()) {
                    val feature = queriedFeatures[0].queriedFeature.feature
                    val name = feature.properties()?.get("name")?.asString?.replace("\"", "") ?: "Unknown"
                    showBuildingDialog(point, name)
                }
            }
        }
        return true
    }

    private fun showBuildingDialog(point: Point, buildingName: String) {
        val dialogView = LayoutInflater.from(this).inflate(R.layout.custom_dialog_directions, null)

        val titleBtn: Button = dialogView.findViewById(R.id.title)
        val directionsFrom: Button = dialogView.findViewById(R.id.directions_from)
        val directionsTo: Button = dialogView.findViewById(R.id.directions_to)
        val closeBtn: Button = dialogView.findViewById(R.id.close_btn)

        titleBtn.text = buildingName

        val dialog = AlertDialog.Builder(this)
            .setView(dialogView)
            .create()

        directionsFrom.setOnClickListener {
            origin = point
            fromEditText.setText(buildingName)
            dialog.dismiss()
            requestRoute()
        }

        directionsTo.setOnClickListener {
            destination = point
            toEditText.setText(buildingName)
            dialog.dismiss()
            requestRoute()
        }

        closeBtn.setOnClickListener {
            dialog.dismiss()
        }

        dialog.show()
        zoomToPoint(point)
    }

    private fun requestRoute() {
        val mapboxNavigation = MapboxNavigationApp.current()
        if (mapboxNavigation == null) {
            Timber.e("MapboxNavigation not available - ensure MapboxNavigationApp is setup")
            Toast.makeText(this, "Navigation not ready, please try again", Toast.LENGTH_SHORT).show()
            return
        }

        Timber.d("Requesting route from $origin to $destination")

        val routeOptions = RouteOptions.builder()
            .applyDefaultNavigationOptions()
            .profile(DirectionsCriteria.PROFILE_WALKING)
            .coordinatesList(listOf(origin, destination))
            .build()

        mapboxNavigation.requestRoutes(
            routeOptions,
            object : NavigationRouterCallback {
                override fun onRoutesReady(routes: List<NavigationRoute>, routerOrigin: String) {
                    if (routes.isNotEmpty()) {
                        currentRoute = routes[0]
                        drawRoute(routes)
                        Timber.d("Route ready with ${routes.size} alternatives")
                        Toast.makeText(
                            this@DirectionsActivity,
                            "Route found!",
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                }

                override fun onFailure(reasons: List<RouterFailure>, routeOptions: RouteOptions) {
                    val errorMessage = reasons.firstOrNull()?.message ?: "Unknown error"
                    Timber.e("Route request failed: $errorMessage")
                    Toast.makeText(
                        this@DirectionsActivity,
                        "Could not find route: $errorMessage",
                        Toast.LENGTH_SHORT
                    ).show()
                }

                override fun onCanceled(routeOptions: RouteOptions, routerOrigin: String) {
                    Timber.d("Route request canceled")
                }
            }
        )
    }

    private fun drawRoute(routes: List<NavigationRoute>) {
        routeLineApi.setNavigationRoutes(routes) { value ->
            mapView.mapboxMap.style?.let { style ->
                routeLineView.renderRouteDrawData(style, value)
            }
        }
    }

    private fun zoomToPoint(point: Point) {
        val cameraOptions = CameraOptions.Builder()
            .center(point)
            .zoom(16.0)
            .build()
        mapView.mapboxMap.flyTo(cameraOptions)
    }

    private fun hideKeyboard() {
        try {
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
            currentFocus?.let {
                imm.hideSoftInputFromWindow(it.windowToken, 0)
            }
        } catch (e: Exception) {
            Timber.e(e, "Error hiding keyboard")
        }
    }

    private fun overrideTransitionOnFinish() {
        @Suppress("DEPRECATION")
        overridePendingTransition(R.anim.fade_in, R.anim.fade_out)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        if (item.itemId == android.R.id.home) {
            finish()
            overrideTransitionOnFinish()
            return true
        }
        return super.onOptionsItemSelected(item)
    }

    override fun onDestroy() {
        super.onDestroy()
        // Detach from MapboxNavigationApp lifecycle
        MapboxNavigationApp.detach(this)
        routeLineApi.cancel()
        routeLineView.cancel()
    }
}
