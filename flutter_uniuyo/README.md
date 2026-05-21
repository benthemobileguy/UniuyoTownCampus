# Uniuyo Town Campus - Flutter

Flutter version of the University of Uyo Town Campus navigation app, migrated from the existing Android (Kotlin) application.

## Project Overview

This Flutter application provides campus navigation features including:
- **Building Search**: Find buildings on campus with autocomplete search and recent searches
- **Directions**: Get walking directions between buildings using Mapbox Directions API
- **Map Visualization**: Interactive 3D map with color-coded buildings and roads
- **Building Reminders**: Schedule notifications for building visits with date/time pickers
- **Building Actions**: Share locations, add comments, and get directions from building info bubble
- **Study Spaces**: Find academic buildings and quiet study locations
- **Campus Information**: View campus details and facilities
- **Feedback**: Submit feedback about the app

## Architecture

### Clean Architecture with Feature-First Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart        # Coral red theme (#FF6B6B)
│   │   ├── app_dimensions.dart    # Layout dimensions
│   │   ├── app_theme.dart         # Material theme configuration
│   │   └── app_spacing.dart       # Spacing constants
│   ├── utils/
│   │   └── coordinate_transformer.dart  # UTM to WGS84 conversion
│   ├── services/
│   │   ├── reminder_service.dart        # SharedPreferences for reminders
│   │   ├── notification_service.dart    # flutter_local_notifications
│   │   └── mapbox_directions_service.dart # Directions API
│   ├── providers/
│   │   └── recent_searches_provider.dart # Recent searches state
│   └── widgets/
│       └── blinking_buildings_overlay.dart # Gold pulsing animation
├── features/
│   ├── splash/                    # Splash screen (8s timeout)
│   ├── home/                      # Main menu with 6 feature cards
│   ├── search/                    # Building search with speech bubble
│   ├── directions/                # Turn-by-turn navigation
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       ├── building.dart  # Building data model
│   │   │       └── road.dart      # Road data model
│   │   ├── data/
│   │   │   └── providers/         # Riverpod providers
│   │   └── presentation/
│   ├── reminders/                 # Building reminder system
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── reminder.dart  # Reminder entity (Freezed)
│   │   ├── data/
│   │   │   └── providers/         # Reminder state management
│   │   └── presentation/
│   │       └── widgets/
│   │           └── reminder_dialog.dart # Date/time picker dialog
│   ├── notifications/             # Announcements page
│   ├── study_space/               # Study spaces page
│   ├── feedback/                  # User feedback page
│   └── campus_info/               # Campus information page
└── main.dart                      # App entry point with notification init
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
- `primary: #FF6B6B` - Coral red (matches university logo) - App bars, buttons, accents
- `primaryLight: #FF8A8A` - Lighter coral shade
- `primaryDark: #E55555` - Darker coral shade
- `secondary: #2E7D32` - Academic green for success/navigation
- `textPrimary: #1A1C1E` - Primary text color
- Building colors: Red (#D32F2F) for academic, Orange (#EF6C00) for admin, Purple (#512DA8) for library

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
  flutter_local_notifications: ^18.0.1  # Local notifications for reminders
  timezone: ^0.9.0                  # Timezone support for notifications
  uuid: ^4.0.0                      # Unique IDs for reminders
  shared_preferences: ^2.3.3        # Local storage for reminders and searches
  url_launcher: ^6.3.1              # Launch URLs and share locations
  http: ^1.2.0                      # Mapbox Directions API calls
  intl: ^0.19.0                     # Date/time formatting
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

### 4. Configure Mapbox Token

Create `android/local.properties` file with your Mapbox access token:

```properties
MAPBOX_ACCESS_TOKEN=your_token_here
```

### 5. Run the App

```bash
flutter run
```

## Building APK

### Development Build

```bash
flutter build apk --debug
```

### Release Build

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Build release APK
flutter build apk --release
```

The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

**Note**: The release build is signed with debug keys. For production, configure proper signing in `android/app/build.gradle.kts`.

## Implementation Status

### ✅ Completed

1. **Core Architecture**
   - Clean Architecture structure
   - Riverpod 2.0+ state management with code generation
   - Coral red theme (#FF6B6B) matching university logo
   - Coordinate transformation utility (UTM to WGS84)

2. **Data Layer**
   - Building and Road entity models (Freezed)
   - Reminder entity model (Freezed) with JSON serialization
   - GeoJSON local data source
   - Repository pattern implementation
   - ReminderService (SharedPreferences persistence)
   - NotificationService (flutter_local_notifications)
   - RecentSearchesService (SharedPreferences)
   - Riverpod providers for buildings, roads, and reminders

3. **UI Pages**
   - ✅ Splash Page (8 second timeout with fade animation)
   - ✅ Home Page (2:8 flex ratio, 6 feature cards)
   - ✅ Search Page (building search with map visualization and speech bubble)
   - ✅ Directions Page (from/to autocomplete, turn-by-turn directions, route visualization)
   - ✅ Notifications Page (campus announcements with settings)
   - ✅ Study Space Page (academic buildings list)
   - ✅ Feedback Page (user feedback form)
   - ✅ Campus Info Page (campus information and facilities)

4. **Mapbox Integration**
   - Map initialization with Mapbox v11 API
   - GeoJSON source loading from local assets
   - Multiple fill layers for buildings (color-coded by function)
   - Line layer for roads
   - Building selection with tap detection
   - Speech bubble with building info (coordinates, display names)
   - Camera animations (flyTo with easing)
   - 3D building toggle
   - Zoom controls

5. **Reminder System**
   - ReminderDialog with date/time pickers
   - Building reminder scheduling with exact alarms
   - Local notification system with channel configuration
   - Blinking/pulsing buildings with active reminders (gold animation)
   - Reminder CRUD operations (Create, Read, Update, Delete)
   - Auto-cleanup of old reminders (30 days)
   - Notification tap handling (deep linking to building)
   - UNDO functionality for reminder creation

6. **Building Actions (Speech Bubble)**
   - Directions: Navigate to DirectionsPage with building as destination
   - Share: Copy location to clipboard with Google Maps link
   - Reminder: Open reminder dialog to schedule notification
   - Comment: Add comments about building (ready for backend integration)

7. **Navigation Features**
   - Route calculation using Mapbox Directions API
   - Turn-by-turn navigation display
   - Route line rendering on map with polyline
   - Route summary cards (distance, duration)
   - Alternative routes support
   - Accessible routes toggle

8. **Permissions**
   - Notification permissions (Android 13+)
   - Exact alarm scheduling permissions
   - Post notifications permission

### 🚧 Pending

1. **Testing**
   - Unit tests for repositories
   - Widget tests for pages
   - Integration tests

2. **Backend Integration**
   - Comment system API
   - User authentication (optional)
   - Cloud storage for reminders (optional)

3. **Enhancements**
   - Location-based reminder triggers (geofencing)
   - Recurring reminders
   - Offline mode improvements

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

## Version Information

- **App Version**: 2.0.0 (Build 2)
- **Package**: com.bnotion.uniuyotowncampus.uniuyo_town_campus
- **Min SDK**: Android 5.0 (API 21)
- **Target SDK**: Android 14 (API 34)
- **Flutter Version**: 3.35.7+
- **Mapbox SDK**: v2.3.0

## Key Features

### Speech Bubble with Building Actions
When you tap a building on the map, a coral-red speech bubble appears with:
- Building display name (e.g., "B11 - Library")
- UTM and WGS84 coordinates
- 4 action icons:
  - **Directions**: Open directions to the building
  - **Share**: Copy location with Google Maps link
  - **Reminder**: Schedule a notification
  - **Comment**: Add comments about the building

### Building Reminder System
- Date and time picker for scheduling
- Optional message field (100 characters)
- Past date validation
- Local notification with vibration and LED
- Buildings with active reminders blink gold on map (1.5s pulse animation)
- Notification tap opens app and navigates to building
- UNDO functionality after creating reminder
- Auto-cleanup of reminders older than 30 days

### Directions System
- Autocomplete search for origin and destination
- Real-time route calculation with Mapbox Directions API
- Turn-by-turn navigation display
- Route summary with distance and duration
- Alternative routes support
- Accessible routes toggle
- Route visualization on map

## Sources

This implementation was built using official documentation:

- [Work with layers | Maps SDK for Flutter | Mapbox Docs](https://docs.mapbox.com/flutter/maps/guides/styles/work-with-layers/)
- [mapbox_maps_flutter | Flutter package](https://pub.dev/packages/mapbox_maps_flutter)
- [Add a line with a GeoJSON source | Maps SDK for Flutter | Mapbox Docs](https://docs.mapbox.com/flutter/maps/examples/geojson_line/)
- [GitHub - mapbox/mapbox-maps-flutter](https://github.com/mapbox/mapbox-maps-flutter)
