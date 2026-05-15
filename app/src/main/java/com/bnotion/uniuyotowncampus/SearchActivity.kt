package com.bnotion.uniuyotowncampus

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.TimePickerDialog
import android.content.Context
import android.content.Intent
import android.content.pm.ActivityInfo
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.MenuItem
import android.widget.ArrayAdapter
import android.widget.AutoCompleteTextView
import android.widget.Button
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar
import androidx.lifecycle.lifecycleScope
import com.bnotion.uniuyotowncampus.application.BroadcastAlarm
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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import timber.log.Timber
import java.net.URL
import java.util.Calendar

class SearchActivity : AppCompatActivity() {

    companion object {
        private const val GEO_JSON_SOURCE_ID = "geoJsonData"
        private const val GEO_JSON_LAYER_ID = "polygonFillLayer"
        private const val GEO_JSON_URL = "https://gist.githubusercontent.com/benthemobileguy/9899ee8cd354c7bdb346b17cb79bf966/raw/0772e5e254357c69ab2cce578d1aee5604f85c21/gistfile1.txt"
    }

    private lateinit var mapView: MapView
    private lateinit var searchEditText: AutoCompleteTextView

    private val buildingNames = ArrayList<String>()
    private val buildingCoordinates = ArrayList<String>()

    private var currentBuildingName: String = ""
    private val calendar: Calendar = Calendar.getInstance()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Lock screen orientation
        if (resources.getBoolean(R.bool.portrait_only)) {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        }
        if (resources.getBoolean(R.bool.landscape_only)) {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        }

        setContentView(R.layout.activity_search)

        // Initialize views
        mapView = findViewById(R.id.mapView)
        searchEditText = findViewById(R.id.search)

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

        // Setup map
        setupMap()
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
                        this@SearchActivity,
                        "Failed to load building data",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
        }
    }

    private fun processFeatures(features: List<Feature>) {
        buildingNames.clear()
        buildingCoordinates.clear()

        for (feature in features) {
            feature.properties()?.let { props ->
                val name = props.get("name")?.asString?.replace("\"", "")
                val latLng = props.get("latlong")?.asString?.replace("\"", "")

                if (name != null && latLng != null) {
                    buildingNames.add(name)
                    buildingCoordinates.add(latLng)
                }
            }
        }

        // Setup autocomplete adapter
        val adapter = ArrayAdapter(this, android.R.layout.simple_dropdown_item_1line, buildingNames)
        searchEditText.setAdapter(adapter)
        searchEditText.threshold = 1

        // Setup item click listener
        searchEditText.setOnItemClickListener { parent, _, position, _ ->
            Utils.hideKeyboard(this)
            val selected = parent.getItemAtPosition(position) as String
            val pos = buildingNames.indexOf(selected)

            if (pos >= 0 && pos < buildingCoordinates.size) {
                val latLng = stringToPoint(buildingCoordinates[pos])
                if (latLng != null) {
                    zoomToPoint(latLng)
                    showBuildingDialog(latLng, selected)
                }
            }
        }

        Timber.d("Loaded ${buildingNames.size} buildings")
    }

    private fun stringToPoint(latLngString: String): Point? {
        return try {
            val parts = latLngString.split(",")
            val lat = parts[0].toDouble()
            val lng = parts[1].toDouble()
            Point.fromLngLat(lng, lat)
        } catch (e: Exception) {
            Timber.e(e, "Error parsing coordinates")
            null
        }
    }

    private fun handleMapClick(point: Point): Boolean {
        Utils.hideKeyboard(this)

        val screenPoint = mapView.mapboxMap.pixelForCoordinate(point)
        val geometry = com.mapbox.maps.RenderedQueryGeometry(screenPoint)
        val options = com.mapbox.maps.RenderedQueryOptions(listOf(GEO_JSON_LAYER_ID), null)

        mapView.mapboxMap.queryRenderedFeatures(geometry, options) { result ->
            result.value?.let { queriedFeatures ->
                if (queriedFeatures.isNotEmpty()) {
                    val feature = queriedFeatures[0].queriedFeature.feature
                    val name = feature.properties()?.get("name")?.asString?.replace("\"", "") ?: "Unknown"
                    showBuildingDialog(point, name)
                    searchEditText.setText(name)
                }
            }
        }
        return true
    }

    private fun showBuildingDialog(point: Point, buildingName: String) {
        currentBuildingName = buildingName

        AlertDialog.Builder(this)
            .setTitle(buildingName)
            .setMessage("Coordinates: ${point.latitude()}, ${point.longitude()}")
            .setPositiveButton("Get Directions") { dialog, _ ->
                dialog.dismiss()
                val intent = Intent(this, DirectionsActivity::class.java)
                intent.putExtra("destination_name", buildingName)
                intent.putExtra("destination_lat", point.latitude())
                intent.putExtra("destination_lng", point.longitude())
                startActivity(intent)
                @Suppress("DEPRECATION")
                overridePendingTransition(R.anim.fade_in, R.anim.fade_out)
            }
            .setNeutralButton("Set Reminder") { dialog, _ ->
                dialog.dismiss()
                checkAlarmPermissionAndShowPicker()
            }
            .setNegativeButton("Cancel") { dialog, _ ->
                dialog.dismiss()
            }
            .show()

        zoomToPoint(point)
    }

    private fun checkAlarmPermissionAndShowPicker() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (!alarmManager.canScheduleExactAlarms()) {
                AlertDialog.Builder(this)
                    .setTitle("Permission Required")
                    .setMessage("This app needs permission to schedule exact alarms for reminders.")
                    .setPositiveButton("Grant") { _, _ ->
                        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                        startActivity(intent)
                    }
                    .setNegativeButton("Cancel", null)
                    .show()
                return
            }
        }
        showTimePicker()
    }

    private fun showTimePicker() {
        val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
        val currentMinute = calendar.get(Calendar.MINUTE)

        val timePickerDialog = TimePickerDialog(
            this,
            R.style.TimePickerTheme,
            { _, hourOfDay, minutes ->
                calendar.set(Calendar.HOUR_OF_DAY, hourOfDay)
                calendar.set(Calendar.MINUTE, minutes)
                calendar.set(Calendar.SECOND, 0)

                val amPm = if (hourOfDay >= 12) "PM" else "AM"

                AlertDialog.Builder(this)
                    .setIcon(R.drawable.ic_bell)
                    .setTitle(currentBuildingName)
                    .setMessage(
                        "You are about to schedule a routing reminder for $currentBuildingName " +
                        "destination at ${String.format("%02d:%02d", hourOfDay, minutes)} $amPm. " +
                        "This reminder would be received with a notification."
                    )
                    .setPositiveButton("SET") { _, _ ->
                        setTimer()
                    }
                    .setNegativeButton("CANCEL") { dialog, _ ->
                        dialog.dismiss()
                    }
                    .show()
            },
            currentHour,
            currentMinute,
            false
        )
        timePickerDialog.setTitle(currentBuildingName)
        timePickerDialog.show()
    }

    private fun setTimer() {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, BroadcastAlarm::class.java).apply {
                action = "MY_NOTIFICATION_MESSAGE"
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                100,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        calendar.timeInMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    pendingIntent
                )
            }

            Toast.makeText(this, "Reminder set!", Toast.LENGTH_SHORT).show()
            Timber.d("Alarm set for ${calendar.time}")
        } catch (e: Exception) {
            Timber.e(e, "Error setting alarm")
            Toast.makeText(this, "Failed to set reminder", Toast.LENGTH_SHORT).show()
        }
    }

    private fun zoomToPoint(point: Point) {
        val cameraOptions = CameraOptions.Builder()
            .center(point)
            .zoom(16.0)
            .build()
        mapView.mapboxMap.flyTo(cameraOptions)
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
}
