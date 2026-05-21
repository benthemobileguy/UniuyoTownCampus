import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../directions/data/providers/campus_data_providers.dart';
import '../../../directions/domain/entities/building.dart';
import '../../../search/presentation/pages/search_page.dart';

/// Campus Info page displaying catalog of all buildings
/// Tapping a building navigates to SearchPage at that location
class CampusInfoPage extends ConsumerStatefulWidget {
  const CampusInfoPage({super.key});

  @override
  ConsumerState<CampusInfoPage> createState() => _CampusInfoPageState();
}

class _CampusInfoPageState extends ConsumerState<CampusInfoPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildingsAsync = ref.watch(buildingsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.colorPrimary,
        foregroundColor: AppColors.white,
        title: const Text('Campus Buildings'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search buildings by name or function...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Buildings List/Table
          Expanded(
            child: buildingsAsync.when(
              data: (buildings) {
                // Filter buildings based on search query
                final filteredBuildings = _searchQuery.isEmpty
                    ? buildings
                    : buildings.where((building) {
                        return building.name.toLowerCase().contains(_searchQuery) ||
                            building.buildingFunction.toLowerCase().contains(_searchQuery);
                      }).toList();

                if (filteredBuildings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No buildings found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Results count header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: AppColors.colorPrimary.withOpacity(0.05),
                      child: Row(
                        children: [
                          Icon(
                            Icons.apartment,
                            size: 20,
                            color: AppColors.colorPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${filteredBuildings.length} Buildings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.colorPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Showing all'
                                : 'Filtered results',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Buildings data table
                    Expanded(
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 24,
                            headingRowColor: WidgetStateProperty.all(
                              AppColors.colorPrimary.withOpacity(0.1),
                            ),
                            headingRowHeight: 56,
                            dataRowMinHeight: 60,
                            dataRowMaxHeight: 80,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Building Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Function',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                            rows: filteredBuildings.map((building) {
                              return DataRow(
                                onSelectChanged: (_) => _navigateToBuilding(building),
                                cells: [
                                  DataCell(
                                    Text(
                                      building.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      building.buildingFunction,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading buildings...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading buildings',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBuilding(Building building) {
    // Navigate to SearchPage and pass the display name (e.g., "B11 - Library")
    // The SearchPage will handle showing this building on the map
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchPage(initialBuildingName: building.displayName),
      ),
    );
  }
}
