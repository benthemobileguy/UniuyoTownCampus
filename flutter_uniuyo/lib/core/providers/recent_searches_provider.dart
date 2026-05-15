import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recent_searches_service.dart';

/// Provider for the recent searches service
final recentSearchesServiceProvider = Provider<RecentSearchesService>((ref) {
  return RecentSearchesService();
});

/// Provider for recent building searches
final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(recentSearchesServiceProvider);
  return await service.getRecentSearches();
});

/// Provider to save a search (StateProvider for triggering saves)
final saveSearchProvider = StateProvider<String?>((ref) => null);
