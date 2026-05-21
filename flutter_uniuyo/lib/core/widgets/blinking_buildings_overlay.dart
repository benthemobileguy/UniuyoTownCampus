import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../features/reminders/data/providers/reminder_providers.dart';

/// Widget that adds a blinking/pulsing layer for buildings with active reminders
/// Integrates with Mapbox map to create animated fill layer
/// Uses AnimationController for smooth 0.3 → 1.0 opacity pulse (1500ms)
class BlinkingBuildingsOverlay extends ConsumerStatefulWidget {
  final MapboxMap mapboxMap;

  const BlinkingBuildingsOverlay({
    super.key,
    required this.mapboxMap,
  });

  @override
  ConsumerState<BlinkingBuildingsOverlay> createState() =>
      _BlinkingBuildingsOverlayState();
}

class _BlinkingBuildingsOverlayState
    extends ConsumerState<BlinkingBuildingsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  List<String> _buildingsWithReminders = [];
  bool _layerAdded = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation: 0.3 → 1.0 → 0.3 (smooth breathing effect)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation.addListener(_updateBlinkingLayer);
  }

  @override
  void dispose() {
    _controller.dispose();
    _removeBlinkingLayer();
    super.dispose();
  }

  void _updateBlinkingLayer() async {
    if (!_layerAdded || _buildingsWithReminders.isEmpty) return;

    try {
      // Update layer opacity based on animation value
      await widget.mapboxMap.style.setStyleLayerProperty(
        'buildings-blinking-layer',
        'fill-opacity',
        _opacityAnimation.value,
      );
    } catch (e) {
      // Silently handle - layer might not exist yet
      debugPrint('⚠️ BlinkingOverlay: Failed to update opacity - $e');
    }
  }

  Future<void> _addBlinkingLayer(List<String> buildingIds) async {
    if (_layerAdded || buildingIds.isEmpty) return;

    try {
      debugPrint(
          '✨ BlinkingOverlay: Adding blinking layer for ${buildingIds.length} buildings');

      // Add layer ABOVE the default building layers but BELOW labels
      await widget.mapboxMap.style.addLayerAt(
        FillLayer(
          id: 'buildings-blinking-layer',
          sourceId: 'buildings-source', // Reuse existing source
          fillColor: const Color(0xFFFFD700).value, // Gold color
          fillOpacity: _opacityAnimation.value,
          filter: <Object>[
            'in',
            <String>['get', 'names'],
            ...buildingIds,
          ],
        ),
        LayerPosition(
          above: 'buildings-medical-layer', // Add above all building fill layers
          below: 'buildings-labels-layer', // But below labels
        ),
      );

      _layerAdded = true;
      debugPrint(
          '✅ BlinkingOverlay: Added blinking layer for ${buildingIds.length} buildings');
    } catch (e) {
      debugPrint('❌ BlinkingOverlay: Failed to add blinking layer - $e');
    }
  }

  Future<void> _removeBlinkingLayer() async {
    if (!_layerAdded) return;

    try {
      await widget.mapboxMap.style
          .removeStyleLayer('buildings-blinking-layer');
      _layerAdded = false;
      debugPrint('🗑️ BlinkingOverlay: Removed blinking layer');
    } catch (e) {
      debugPrint('⚠️ BlinkingOverlay: Failed to remove blinking layer - $e');
    }
  }

  Future<void> _updateBlinkingBuildings(List<String> buildingIds) async {
    // If list changed, recreate layer
    if (_buildingsWithReminders.toString() != buildingIds.toString()) {
      await _removeBlinkingLayer();
      _buildingsWithReminders = buildingIds;

      if (buildingIds.isNotEmpty) {
        await _addBlinkingLayer(buildingIds);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch active reminders
    final remindersAsync = ref.watch(activeRemindersProvider);

    remindersAsync.whenData((reminders) {
      final buildingIds = reminders.map((r) => r.buildingId).toSet().toList();
      _updateBlinkingBuildings(buildingIds);
    });

    // This widget doesn't render anything visible - it just manages the map layer
    return const SizedBox.shrink();
  }
}
