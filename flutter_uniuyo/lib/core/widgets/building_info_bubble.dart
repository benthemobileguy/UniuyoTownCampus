import 'package:flutter/material.dart';
import '../../features/directions/domain/entities/building.dart';
import '../theme/app_colors.dart';
import '../utils/coordinate_transformer.dart';

/// Speech bubble widget that appears on map when building is tapped
/// Matches Android's custom_dialog_search.xml with bubble_bg.xml
class BuildingInfoBubble extends StatelessWidget {
  final Building building;
  final VoidCallback? onDirections;
  final VoidCallback? onShare;
  final VoidCallback? onReminder;
  final VoidCallback? onComment;
  final VoidCallback onClose;

  const BuildingInfoBubble({
    super.key,
    required this.building,
    this.onDirections,
    this.onShare,
    this.onReminder,
    this.onComment,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Get coordinates
    final centroid = building.centroid;
    final wgs84 = CoordinateTransformer.utmToWgs84(
      easting: centroid.x,
      northing: centroid.y,
    );

    return GestureDetector(
      onTap: () {}, // Prevent taps from passing through to map
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: CustomPaint(
          painter: _BubblePainter(),
          child: Container(
            margin: const EdgeInsets.only(left: 20, top: 10, right: 10, bottom: 10),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  ),
                ),

                // Building name (red bold text like Android)
                Text(
                  building.name,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Coordinate details
                _buildCoordinateInfo(centroid, wgs84),
                const SizedBox(height: 16),

                // Action icons (matching Android layout)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionIcon(
                      Icons.directions,
                      'Directions',
                      onDirections,
                    ),
                    _buildActionIcon(
                      Icons.share,
                      'Share',
                      onShare,
                    ),
                    _buildActionIcon(
                      Icons.notifications_outlined,
                      'Reminder',
                      onReminder,
                    ),
                    _buildActionIcon(
                      Icons.comment_outlined,
                      'Comment',
                      onComment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinateInfo(
    ({double x, double y}) centroid,
    ({double latitude, double longitude}) wgs84,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Units, Edge, Point',
          style: TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'easting = ${centroid.x.toStringAsFixed(2)}, '
          'northing = ${centroid.y.toStringAsFixed(2)}, '
          'altitude = 0.0',
          style: const TextStyle(
            fontSize: 9,
            color: Colors.black87,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'latitude = ${wgs84.latitude.toStringAsFixed(7)}, '
          'longitude = ${wgs84.longitude.toStringAsFixed(7)}',
          style: const TextStyle(
            fontSize: 9,
            color: Colors.black87,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.colorPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.colorPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for speech bubble background with pointer
/// Replicates Android's bubble_bg.xml (white rounded rectangle with tail)
class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();

    // Draw pointer/tail (bottom-left triangle)
    const tailWidth = 16.0;
    const tailHeight = 16.0;
    path.moveTo(tailWidth, size.height);
    path.lineTo(tailWidth / 2, size.height + tailHeight);
    path.lineTo(0, size.height);

    // Draw main rounded rectangle
    const radius = 8.0;
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tailWidth, 0, size.width - tailWidth, size.height),
        const Radius.circular(radius),
      ),
    );

    // Draw shadow
    canvas.drawPath(path, shadowPaint);

    // Draw bubble
    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
