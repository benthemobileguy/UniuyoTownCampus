# Uniuyo Town Campus - Flutter

Flutter version of the University of Uyo Town Campus navigation app, migrated from the existing Android (Kotlin) application.

## Project Overview

This Flutter application provides campus navigation features including:
- **Building Search**: Find buildings on campus with autocomplete search
- **Directions**: Get walking directions between buildings
- **Map Visualization**: Interactive map showing buildings and roads
- **Reminders**: Set location-based reminders (coming soon)

## Architecture

### Clean Architecture with Feature-First Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart        # Exact colors from Android colors.xml
│   │   ├── app_dimensions.dart    # Exact dimensions from Android layouts
│   │   └── app_theme.dart         # Material theme configuration
│   └── utils/
│       └── coordinate_transformer.dart  # UTM to WGS84 conversion
├── features/
│   ├── splash/                    # Splash screen (8 second timeout)
│   ├── home/                      # Main menu with 6 feature cards
│   ├── search/                    # Building search with map
│   └── directions/                # Turn-by-turn navigation
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── building.dart  # Building data model
│       │   │   └── road.dart      # Road data model
│       │   └── repositories/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── geojson_local_datasource.dart
│       │   ├── repositories/
│       │   └── providers/         # Riverpod providers
│       └── presentation/
└── main.dart
```

## Data Sources

### GeoJSON Files

The app uses local GeoJSON files instead of remote URLs:

- **Buildings111.geojson** (224 KB)
  - Properties: `gid`, `names`, `area_m2`, `building_function`
  - Geometry: MultiPolygon
  - Coordinates: UTM EPSG:32632 (transformed to WGS84 at runtime)

- **Roads111.geojson** (86 KB)
  - Properties: `Names`, `source`, `target`
  - Geometry: MultiLineString
  - Coordinates: UTM EPSG:32632 (transformed to WGS84 at runtime)

### Coordinate System

The GeoJSON files use **UTM Zone 32N (EPSG:32632)** projection. The app includes a `CoordinateTransformer` utility that converts these coordinates to **WGS84 (latitude/longitude)** for Mapbox compatibility.

## Extracted Android Resources

All values were extracted from the original Android project (no assumptions):

### Colors (`app_colors.dart`)
- `customRed: #CD5C5C` - Primary accent color
- `colorPrimary: #404040` - App bar and primary UI
- `colorPrimaryDark: #1C1C1C` - Status bar
- `customTextColor: #1C1C1C` - Text color
- `customGreen: #008000` - Success/navigation color

### Dimensions (`app_dimensions.dart`)
- Grid padding: 14dp
- Card margin: 16dp
- Card elevation: 8dp
- Card corner radius: 8dp
- Feature icon size: 30dp
- Map zoom (default): 15.0
- Map zoom (building): 16.0
- Building fill opacity: 0.7

### Animations
- Fade in/out: 500ms
- Splash fade: 3000ms
- Splash timeout: 8 seconds

### Font
- **Muli** font family from Google Fonts (Bold, SemiBold, ExtraBold)

## Dependencies

Key packages used:

```yaml
dependencies:
  flutter_riverpod: ^2.6.1          # State management
  riverpod_annotation: ^2.6.1       # Code generation for providers
  auto_route: ^9.2.2                # Type-safe navigation
  mapbox_maps_flutter: ^2.3.0       # Mapbox Maps SDK
  freezed_annotation: ^2.4.1        # Immutable data classes
  json_annotation: ^4.9.0           # JSON serialization
  google_fonts: ^6.2.1              # Muli font
  flutter_local_notifications: ^18.0.1  # Reminders/notifications
```

## Setup Instructions

### 1. Install Dependencies

```bash
cd /Users/apple/AndroidProjects/UniuyoTownCampus/flutter_uniuyo
flutter pub get
```

### 2. Copy Assets (if not already done)

The GeoJSON files are already in `assets/geojson/`. To copy image assets from the Android project:

```bash
# Create assets directory
mkdir -p assets/images

# Copy images from Android drawable folder
cp ../app/src/main/res/drawable/*.{png,jpeg} assets/images/
```

Required images:
- `directions.png`
- `search.png`
- `notifications.png`
- `study.png`
- `feedback.png`
- `info.png`
- `header.jpeg`
- `logo_image.jpeg`

### 3. Generate Code

Run code generation for Riverpod providers and Freezed models:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the App

```bash
flutter run
```

## Implementation Status

### ✅ Completed

1. **Core Architecture**
   - Clean Architecture structure
   - Riverpod state management setup
   - Theme configuration with exact Android values
   - Coordinate transformation utility (UTM to WGS84)

2. **Data Layer**
   - Building and Road entity models (Freezed)
   - GeoJSON local data source
   - Repository pattern implementation
   - Riverpod providers for buildings and roads

3. **UI Pages**
   - ✅ Splash Page (8 second timeout with fade animation)
   - ✅ Home Page (2:8 flex ratio, 6 feature cards)
   - ✅ Search Page (building search with map visualization)
   - ✅ Directions Page (from/to autocomplete, map visualization)

4. **Mapbox Integration**
   - Map initialization with correct API
   - GeoJSON source loading from assets
   - Fill layer for buildings (red with 0.7 opacity)
   - Line layer for roads
   - Building selection on tap
   - Camera animations (flyTo)

### 🚧 Pending

1. **Navigation Features**
   - Route calculation using Mapbox Directions API
   - Turn-by-turn navigation display
   - Route line rendering on map

2. **Notifications**
   - Location-based reminders
   - Time-based reminders
   - Notification scheduling with flutter_local_notifications

3. **Additional Pages**
   - Notifications Page
   - Study Space Page
   - Feedback Page
   - Campus Info Page

4. **Testing**
   - Unit tests for repositories
   - Widget tests for pages
   - Integration tests

5. **Permissions**
   - Location permission handling
   - Notification permission handling

## Key Differences from Android

### Architecture
- **Android**: Activities + ViewBinding + Coroutines
- **Flutter**: Riverpod + AutoRoute + async/await

### Map SDK
- **Android**: Mapbox Maps SDK v11 + Navigation SDK v3
- **Flutter**: Mapbox Maps Flutter SDK v2.3

### Data Loading
- **Android**: Loads GeoJSON from remote URL
- **Flutter**: Loads GeoJSON from local assets (faster, offline support)

### State Management
- **Android**: LiveData/StateFlow
- **Flutter**: Riverpod providers with code generation

## Mapbox API References

Based on the official Mapbox Flutter SDK documentation:

- [Work with layers | Mapbox Docs](https://docs.mapbox.com/flutter/maps/guides/styles/work-with-layers/)
- [Add a line with GeoJSON | Mapbox Docs](https://docs.mapbox.com/flutter/maps/examples/geojson_line/)
- [mapbox_maps_flutter package](https://pub.dev/packages/mapbox_maps_flutter)

### Adding GeoJSON Sources and Layers

```dart
// Load GeoJSON
var data = await rootBundle.loadString('assets/geojson/Buildings111.geojson');

// Add source
await mapboxMap.style.addSource(
  GeoJsonSource(id: "buildings-source", data: data)
);

// Add fill layer for buildings
await mapboxMap.style.addLayer(
  FillLayer(
    id: "buildings-fill-layer",
    sourceId: "buildings-source",
    fillColor: AppColors.buildingFillColor.value,
    fillOpacity: 0.7,
  )
);

// Add line layer for roads
await mapboxMap.style.addLayer(
  LineLayer(
    id: "roads-line-layer",
    sourceId: "roads-source",
    lineColor: Colors.grey.value,
    lineWidth: 2.0,
  )
);
```

## Next Steps

1. **Install dependencies and generate code**:
   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Copy image assets** from Android project

3. **Test the app** on a device or emulator

4. **Implement navigation** using Mapbox Directions API

5. **Add notification support** for reminders

6. **Complete remaining pages** (Notifications, Study Space, Feedback, Campus Info)

## Sources

This implementation was built using official documentation:

- [Work with layers | Maps SDK for Flutter | Mapbox Docs](https://docs.mapbox.com/flutter/maps/guides/styles/work-with-layers/)
- [mapbox_maps_flutter | Flutter package](https://pub.dev/packages/mapbox_maps_flutter)
- [Add a line with a GeoJSON source | Maps SDK for Flutter | Mapbox Docs](https://docs.mapbox.com/flutter/maps/examples/geojson_line/)
- [GitHub - mapbox/mapbox-maps-flutter](https://github.com/mapbox/mapbox-maps-flutter)
