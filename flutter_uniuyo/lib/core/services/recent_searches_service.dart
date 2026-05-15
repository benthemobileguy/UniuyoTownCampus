import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage recent building searches
/// Stores up to 10 most recent searches for quick access
class RecentSearchesService {
  static const String _recentSearchesKey = 'recent_building_searches';
  static const int _maxRecentSearches = 10;

  /// Save a building search to recent history
  Future<void> saveSearch(String buildingName) async {
    if (buildingName.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];

      // Remove if already exists (to move to top)
      recentSearches.remove(buildingName);

      // Add to beginning
      recentSearches.insert(0, buildingName);

      // Limit to max
      if (recentSearches.length > _maxRecentSearches) {
        recentSearches = recentSearches.sublist(0, _maxRecentSearches);
      }

      await prefs.setStringList(_recentSearchesKey, recentSearches);
    } catch (e) {
      // Silently fail if SharedPreferences unavailable
      // This prevents crashes on iOS platform channel issues
    }
  }

  /// Get recent searches
  Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_recentSearchesKey) ?? [];
    } catch (e) {
      // Fallback if SharedPreferences fails (e.g., iOS platform channel issues)
      return [];
    }
  }

  /// Clear all recent searches
  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }

  /// Remove a specific search from history
  Future<void> removeSearch(String buildingName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    recentSearches.remove(buildingName);
    await prefs.setStringList(_recentSearchesKey, recentSearches);
  }
}
