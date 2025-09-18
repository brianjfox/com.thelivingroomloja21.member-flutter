import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/image_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final ApiService _apiService = ApiService();
  final ImageService _imageService = ImageService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  Map<int, List<Map<String, dynamic>>> _itemProperties = {};
  
  bool _isLoading = true;
  bool _isSearching = false;
  bool _showFilters = false;
  
  // Filter state with persistence
  RangeValues _priceRange = const RangeValues(0, 50);
  RangeValues _alcoholRange = const RangeValues(0, 20);
  String _selectedRegion = '';
  List<String> _availableRegions = [];
  
  // Scroll position tracking
  final ScrollController _scrollController = ScrollController();
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _loadFilterState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try cache first
      final cachedItems = await CacheService.getCachedItems();
      final cachedProperties = await CacheService.getCachedItemProperties();
      final cachedImages = await CacheService.getCachedItemImages();
      
      if (cachedItems != null && cachedItems.isNotEmpty) {
        debugPrint('ItemsScreen: Loading from cache - ${cachedItems.length} items');
        setState(() {
          _items = cachedItems;
          _itemProperties = cachedProperties ?? {};
          _isLoading = false;
        });
        
        // Preload images in background
        if (cachedItems.isNotEmpty) {
          _imageService.preloadImages(cachedItems.map((item) => item.id).toList());
        }
        
        // Apply filters and update regions
        _updateFilteredItems();
        _loadAvailableRegions();
        
        // Fetch fresh data in background
        _fetchAndCacheItems();
      } else {
        // No cache, fetch from API
        await _fetchAndCacheItems();
      }
    } catch (e) {
      debugPrint('ItemsScreen: Error loading items: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load items. Please try again.');
    }
  }

  Future<void> _fetchAndCacheItems() async {
    try {
      // Check if user is authenticated before making API calls
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        debugPrint('ItemsScreen: User not authenticated, skipping API calls');
        return;
      }
      
      debugPrint('ItemsScreen: Fetching fresh data from API');
      
      // Try prefetch first
      final lastModified = await CacheService.getLastModified();
      final headers = <String, String>{};
      if (lastModified != null) {
        headers['If-Modified-Since'] = lastModified;
      }
      
      try {
        final prefetchData = await _apiService.getPrefetchData(headers: headers);
        final prefetchItems = (prefetchData['data']['items'] as List<dynamic>)
            .map((json) => Item.fromJson(json))
            .toList();
        
        debugPrint('ItemsScreen: Prefetch successful - ${prefetchItems.length} items');
        
        // Update properties from prefetch
        final prefetchProperties = <int, List<Map<String, dynamic>>>{};
        final propertiesList = prefetchData['data']['properties'] as List<dynamic>? ?? [];
        for (final prop in propertiesList) {
          final itemId = prop['item_id'] as int;
          if (!prefetchProperties.containsKey(itemId)) {
            prefetchProperties[itemId] = [];
          }
          prefetchProperties[itemId]!.add(prop);
        }
        
        // Update images from prefetch
        final prefetchImages = <int, String>{};
        final labelsList = prefetchData['data']['labels'] as List<dynamic>? ?? [];
        for (final label in labelsList) {
          final itemId = label['item_id'] as int;
          final imageData = label['image_data'] as String?;
          if (imageData != null) {
            prefetchImages[itemId] = imageData;
          }
        }
        
        // Images will be loaded in background by ImageService
        
        // Cache the data
        await CacheService.setCachedItems(prefetchItems, 
          lastModified: prefetchData['lastModified'], 
          etag: prefetchData['etag']);
        await CacheService.setCachedItemProperties(prefetchProperties,
          lastModified: prefetchData['lastModified'], 
          etag: prefetchData['etag']);
        await CacheService.setCachedItemImages(prefetchImages,
          lastModified: prefetchData['lastModified'], 
          etag: prefetchData['etag']);
        
        if (prefetchData['lastModified'] != null) {
          await CacheService.setLastModified(prefetchData['lastModified']);
        }
        
        setState(() {
          _items = prefetchItems;
          _itemProperties = prefetchProperties;
          _isLoading = false;
        });
        
        // Preload images in background
        if (prefetchItems.isNotEmpty) {
          _imageService.preloadImages(prefetchItems.map((item) => item.id).toList());
        }
        
        _updateFilteredItems();
        _loadAvailableRegions();
        return;
        
      } catch (prefetchError) {
        debugPrint('ItemsScreen: Prefetch failed, falling back to individual calls: $prefetchError');
      }
      
      // Fallback to individual API calls
      final items = await _apiService.getAllItems();
      final properties = await _apiService.getAllItemProperties();
      
      // Cache the data
      await CacheService.setCachedItems(items);
      await CacheService.setCachedItemProperties(properties);
      
      setState(() {
        _items = items;
        _itemProperties = properties;
        _isLoading = false;
      });
      
      _updateFilteredItems();
      _loadAvailableRegions();
      
    } catch (e) {
      debugPrint('ItemsScreen: Error fetching items: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to fetch items. Please try again.');
    }
  }

  void _updateAvailableRegions() {
    final regionCounts = <String, int>{};
    
    for (final item in _items) {
      final properties = _itemProperties[item.id] ?? [];
      final regionProperty = properties.firstWhere(
        (prop) => prop['name'] == 'region' && (prop['value'] as String).trim().isNotEmpty,
        orElse: () => <String, dynamic>{},
      );
      
      if (regionProperty.isNotEmpty) {
        final region = (regionProperty['value'] as String).trim();
        regionCounts[region] = (regionCounts[region] ?? 0) + 1;
      }
    }
    
    setState(() {
      _availableRegions = regionCounts.keys.toList()..sort();
    });
  }


  Future<void> _handleRefresh() async {
    await CacheService.clearItemsCache();
    await _fetchAndCacheItems();
  }

  Future<void> _handleBarcodeScan() async {
    // Navigate to barcode scanner screen
    context.go('/scan');
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '€', decimalDigits: 2).format(amount);
  }

  String _getAlcoholTypeIcon(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('wine') || name.contains('vinho')) return '🍷';
    if (name.contains('beer') || name.contains('cerveja')) return '🍺';
    if (name.contains('whisky') || name.contains('whiskey')) return '🥃';
    if (name.contains('vodka')) return '🍸';
    if (name.contains('gin')) return '🍸';
    if (name.contains('rum')) return '🥃';
    if (name.contains('tequila')) return '🍸';
    if (name.contains('liqueur') || name.contains('licor')) return '🍷';
    return '🍷';
  }

  bool get _areFiltersActive {
    return _priceRange.start != 0 || 
           _priceRange.end != 50 ||
           _alcoholRange.start != 0 || 
           _alcoholRange.end != 20 ||
           _selectedRegion.isNotEmpty;
  }

  // Load filter state from SharedPreferences
  Future<void> _loadFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load price range
      final priceStart = prefs.getDouble('items_price_range_start') ?? 0.0;
      final priceEnd = prefs.getDouble('items_price_range_end') ?? 50.0;
      _priceRange = RangeValues(priceStart, priceEnd);
      
      // Load alcohol range
      final alcoholStart = prefs.getDouble('items_alcohol_range_start') ?? 0.0;
      final alcoholEnd = prefs.getDouble('items_alcohol_range_end') ?? 20.0;
      _alcoholRange = RangeValues(alcoholStart, alcoholEnd);
      
      // Load selected region
      _selectedRegion = prefs.getString('items_selected_region') ?? '';
    } catch (e) {
      debugPrint('ItemsScreen: Error loading filter state: $e');
    }
  }

  // Save filter state to SharedPreferences
  Future<void> _saveFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setDouble('items_price_range_start', _priceRange.start);
      await prefs.setDouble('items_price_range_end', _priceRange.end);
      await prefs.setDouble('items_alcohol_range_start', _alcoholRange.start);
      await prefs.setDouble('items_alcohol_range_end', _alcoholRange.end);
      await prefs.setString('items_selected_region', _selectedRegion);
    } catch (e) {
      debugPrint('ItemsScreen: Error saving filter state: $e');
    }
  }

  // Comprehensive filtering logic matching Ionic app
  List<Item> _filterItems() {
    final searchTerm = _searchController.text.trim().toLowerCase();
    
    return _items.where((item) {
      // Search term filter
      if (searchTerm.isNotEmpty) {
        final name = item.name.toLowerCase();
        final desc = item.description?.toLowerCase() ?? '';
        final code = item.code?.toLowerCase() ?? '';
        final tags = item.tags?.toLowerCase() ?? '';
        
        final matchesSearch = name.contains(searchTerm) ||
            desc.contains(searchTerm) ||
            code.contains(searchTerm) ||
            tags.split(',').any((tag) => tag.trim().contains(searchTerm));
        
        if (!matchesSearch) return false;
      }
      
      // Price filter
      if (item.price < _priceRange.start) return false;
      // If upper limit is 50, treat it as "no upper limit" (effectively €5000)
      if (_priceRange.end < 50 && item.price > _priceRange.end) return false;
      
      // Region filter using item properties
      if (_selectedRegion.isNotEmpty) {
        final properties = _itemProperties[item.id] ?? [];
        final regionProperty = properties.any((prop) => 
            prop['name'] == 'region' && 
            (prop['value'] as String).toLowerCase().contains(_selectedRegion.toLowerCase())
        );
        if (!regionProperty) return false;
      }
      
      // Alcohol content filter using item properties
      final properties = _itemProperties[item.id] ?? [];
      final alcoholProperty = properties.firstWhere(
        (prop) => prop['name'] == 'alcohol_content' && (prop['value'] as String).trim().isNotEmpty,
        orElse: () => <String, dynamic>{},
      );
      
      if (alcoholProperty.isNotEmpty) {
        final alcoholValue = alcoholProperty['value'] as String;
        // Extract numeric value from alcohol content (e.g., "14%" -> 14, "14.5%" -> 14.5)
        final alcoholMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(alcoholValue);
        if (alcoholMatch != null) {
          final alcoholContent = double.parse(alcoholMatch.group(1)!);
          if (alcoholContent < _alcoholRange.start || alcoholContent > _alcoholRange.end) {
            return false;
          }
        }
      }
      
      return true;
    }).toList();
  }

  // Update filtered items when filters change
  void _updateFilteredItems() {
    setState(() {
      _isSearching = true;
    });
    
    // Debounce the filtering to avoid excessive updates
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _filteredItems = _filterItems();
          _isSearching = false;
        });
        _saveFilterState();
      }
    });
  }

  // Reset all filters to default values
  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 50);
      _alcoholRange = const RangeValues(0, 20);
      _selectedRegion = '';
    });
    _updateFilteredItems();
  }

  // Load available regions from item properties
  void _loadAvailableRegions() {
    final regions = <String, int>{};
    
    for (final properties in _itemProperties.values) {
      for (final prop in properties) {
        if (prop['name'] == 'region') {
          final region = prop['value'] as String;
          regions[region] = (regions[region] ?? 0) + 1;
        }
      }
    }
    
    setState(() {
      _availableRegions = regions.keys.toList()..sort();
    });
  }

  // Image handling is now done by ImageService

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _updateFilteredItems(),
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _updateFilteredItems();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      icon: Icon(
                        Icons.filter_list,
                        color: _showFilters 
                            ? Theme.of(context).primaryColor 
                            : (_areFiltersActive ? Colors.orange : Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                
                // Filter Controls
                if (_showFilters) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price Range
                        Text(
                          'Price Range (€)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          onChanged: (values) {
                            setState(() {
                              _priceRange = values;
                            });
                            _updateFilteredItems();
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('€${_priceRange.start.round()}'),
                            Text(_priceRange.end == 50 ? '€50+' : '€${_priceRange.end.round()}'),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Alcohol Content Range
                        Text(
                          'Alcohol Content (%)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        RangeSlider(
                          values: _alcoholRange,
                          min: 0,
                          max: 20,
                          divisions: 40,
                          onChanged: (values) {
                            setState(() {
                              _alcoholRange = values;
                            });
                            _updateFilteredItems();
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_alcoholRange.start}%'),
                            Text('${_alcoholRange.end}%'),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Region Filter
                        Text(
                          'Region',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedRegion.isEmpty ? null : _selectedRegion,
                          decoration: const InputDecoration(
                            hintText: 'Select region...',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All Regions'),
                            ),
                            ..._availableRegions.map((region) {
                              final count = _items.where((item) {
                                final properties = _itemProperties[item.id] ?? [];
                                return properties.any((prop) => 
                                  prop['name'] == 'region' && 
                                  (prop['value'] as String).trim() == region);
                              }).length;
                              
                              return DropdownMenuItem(
                                value: region,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(child: Text(region)),
                                    const SizedBox(width: 8),
                                    Text('($count)', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRegion = value ?? '';
                            });
                            _updateFilteredItems();
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Reset Filters Button
                        if (_areFiltersActive)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _resetFilters,
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Reset Filters'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                
                // Results Count
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isSearching 
                        ? 'Searching...'
                        : '${_filteredItems.length} item${_filteredItems.length != 1 ? 's' : ''} found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Items List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wine_bar,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No beverages found',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search terms or filters',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _handleRefresh,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final properties = _itemProperties[item.id] ?? [];
                            // Image will be handled by ImageService
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: () {
                                  context.go('/item/${item.id}');
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header with icon and name
                                      Row(
                                        children: [
                                          Text(
                                            _getAlcoholTypeIcon(item.name),
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              item.displayName ?? item.name,
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Description
                                      if (item.description?.isNotEmpty == true) ...[
                                        Text(
                                          item.description!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      
                                      // Stock info
                                      Text(
                                        '${item.onHand ?? 0} in stock',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Price and tags
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Chip(
                                                  label: Text(_formatCurrency(item.price)),
                                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                                  labelStyle: TextStyle(
                                                    color: Theme.of(context).primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (item.isAlcohol)
                                                  const Chip(
                                                    label: Text('Contains Alcohol'),
                                                    backgroundColor: Colors.orange,
                                                    labelStyle: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Item image placeholder
                                          Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(4),
                                              color: Colors.grey[50],
                                            ),
                                          child: _imageService.buildItemImageWidget(
                                            item.id,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.contain,
                                          ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      
      // Barcode Scanner Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleBarcodeScan,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Barcode'),
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
      ),
    );
  }
}