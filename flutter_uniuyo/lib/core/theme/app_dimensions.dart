/// App dimensions extracted from Android layout XMLs
class AppDimensions {
  // From activity_main.xml GridLayout android:padding="14dp"
  static const double gridPadding = 14.0;

  // From activity_main.xml CardView android:layout_marginBottom="16dp"
  static const double cardMarginBottom = 16.0;

  // From activity_main.xml CardView app:cardElevation="8dp"
  static const double cardElevation = 8.0;

  // From activity_main.xml CardView app:cardCornerRadius="8dp"
  static const double cardCornerRadius = 8.0;

  // From activity_main.xml ImageView layout_width="30dp"
  static const double featureIconSize = 30.0;

  // From toolbar layouts
  static const double backButtonSize = 40.0;

  // From various layouts android:padding="16dp"
  static const double buttonPadding = 16.0;

  // Text sizes from layouts
  static const double textSizeSmall = 14.0; // textSize="14sp"
  static const double textSizeMedium = 16.0; // textSize="16sp"
  static const double textSizeLarge = 18.0; // textSize="18sp"

  // Map specific dimensions
  static const double mapZoomDefault = 15.0;
  static const double mapZoomBuilding = 16.0;

  // From DirectionsActivity.kt fillOpacity(0.7)
  static const double buildingFillOpacity = 0.7;
}
