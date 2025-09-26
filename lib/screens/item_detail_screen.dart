import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/image_service.dart';
import '../models/item.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final int itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final ApiService _apiService = ApiService();
  final ImageService _imageService = ImageService();
  
  Item? _item;
  Map<int, List<Map<String, dynamic>>>? _itemProperties;
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  
  // Tasting notes state
  List<Map<String, dynamic>>? _tastingNotes;
  Map<String, User> _tastingNoteUsers = {};
  bool _tastingNotesExpanded = false;
  bool _showTastingNotePrompt = false;
  bool _showTastingNoteInput = false;
  String _tastingNoteText = '';
  int? _editingNoteId;
  String _editingNoteText = '';
  bool _fetchingTastingNotes = false;
  
  // Properties state
  bool _propertiesExpanded = false;
  
  // Purchase state
  bool _isPurchasing = false;
  
  // Label generation state
  bool _isGeneratingLabel = false;

  @override
  void initState() {
    super.initState();
    debugPrint('ItemDetailScreen: initState called with itemId: ${widget.itemId}');
    _loadItemDetails();
  }

  Future<void> _loadItemDetails([int? itemId]) async {
    final targetItemId = itemId ?? widget.itemId;
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      // Check if user is authenticated before making API calls
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        setState(() {
          _isError = true;
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      debugPrint('ItemDetailScreen: Loading details for item $targetItemId');
      debugPrint('ItemDetailScreen: Widget itemId: ${widget.itemId}');

      // Check cache first for item and properties
      final cachedItems = await CacheService.getCachedItems();
      final cachedProperties = await CacheService.getCachedItemProperties();
      
      debugPrint('ItemDetailScreen: Cache check - cachedItems count: ${cachedItems?.length ?? 0}');
      if (cachedItems != null) {
        final cachedItem = cachedItems.where((item) => item.id == targetItemId).firstOrNull;
        debugPrint('ItemDetailScreen: Found cached item: ${cachedItem?.name} (ID: ${cachedItem?.id})');
      }
      
      Item? item;
      List<Map<String, dynamic>> properties = [];
      
      // Try to get item from cache first
      if (cachedItems != null) {
        item = cachedItems.firstWhere(
          (cachedItem) => cachedItem.id == targetItemId,
          orElse: () => Item(
            id: -1, 
            code: '', 
            name: '', 
            description: '', 
            cost: 0, 
            price: 0, 
            isAlcohol: false, 
            createdAt: DateTime.now().toIso8601String(), 
            updatedAt: DateTime.now().toIso8601String(),
            onHand: 0
          ),
        );
        if (item.id != -1) {
          debugPrint('ItemDetailScreen: Found item $targetItemId in cache');
        }
      }
      
      // Try to get properties from cache
      if (cachedProperties != null && cachedProperties.containsKey(targetItemId)) {
        properties = cachedProperties[targetItemId]!;
        debugPrint('ItemDetailScreen: Found properties for item $targetItemId in cache');
      }

      // If we don't have cached data, fetch from API
      if (item == null || item.id == -1) {
        debugPrint('ItemDetailScreen: Item $targetItemId not in cache, fetching from API');
        item = await _apiService.getItem(targetItemId);
      }
      
      if (properties.isEmpty) {
        debugPrint('ItemDetailScreen: Properties for item $targetItemId not in cache, fetching from API');
        properties = await _apiService.getItemProperties(targetItemId);
      }

      // Always fetch tasting notes (they change frequently)
      final tastingNotes = await _apiService.getTastingNotes(targetItemId).catchError((e) {
        debugPrint('ItemDetailScreen: Error loading tasting notes: $e');
        return <Map<String, dynamic>>[];
      });

        setState(() {
          _item = item!;
          _itemProperties = {targetItemId: properties};
          _tastingNotes = tastingNotes;
          _isLoading = false;
        });
        
        debugPrint('ItemDetailScreen: State updated with item: ${_item?.name} (ID: ${_item?.id})');

      // Fetch user information for tasting notes that don't have complete user data
      for (final note in tastingNotes) {
        if (note['user'] != null && !_tastingNoteUsers.containsKey(note['user'])) {
          _fetchUserForTastingNote(note['user']);
        }
      }
    } catch (e) {
      debugPrint('ItemDetailScreen: Error loading item details: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to load item details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '€', decimalDigits: 2).format(amount);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatPropertyName(String propertyName) {
    // Convert snake_case to Title Case
    return propertyName
        .split('_')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }

  // Tasting notes methods
  Future<void> _fetchUserForTastingNote(String userEmail) async {
    if (_tastingNoteUsers.containsKey(userEmail)) return; // Already have this user
    
    try {
      final userData = await _apiService.getCurrentUser(); // This might need to be adjusted based on API
      if (userData.email == userEmail) {
        setState(() {
          _tastingNoteUsers[userEmail] = userData;
        });
      }
    } catch (e) {
      debugPrint('ItemDetailScreen: Error fetching user for tasting note: $e');
    }
  }

  Future<void> _handleSaveTastingNote() async {
    if (_tastingNoteText.trim().isEmpty) {
      _showSnackBar('Please enter a tasting note', Colors.red);
      return;
    }

    try {
      await _apiService.createTastingNote(_item!.id, _tastingNoteText.trim());
      _showSnackBar('Tasting note saved successfully!', Colors.green);
      
      // Reload tasting notes to show the new one
      final notes = await _apiService.getTastingNotes(_item!.id);
      setState(() {
        _tastingNotes = notes;
        _showTastingNoteInput = false;
        _tastingNoteText = '';
      });

      // Fetch user information for new notes
      for (final note in notes) {
        if (note['user'] != null && !_tastingNoteUsers.containsKey(note['user'])) {
          _fetchUserForTastingNote(note['user']);
        }
      }
    } catch (e) {
      _showSnackBar('Failed to save tasting note', Colors.red);
    }
  }

  Future<void> _handleUpdateTastingNote() async {
    if (_editingNoteText.trim().isEmpty) {
      _showSnackBar('Please enter a tasting note', Colors.red);
      return;
    }

    try {
      await _apiService.updateTastingNote(_editingNoteId!, _editingNoteText.trim());
      _showSnackBar('Tasting note updated successfully!', Colors.green);
      
      // Reload tasting notes to show the updated one
      final notes = await _apiService.getTastingNotes(_item!.id);
      setState(() {
        _tastingNotes = notes;
        _editingNoteId = null;
        _editingNoteText = '';
      });

      // Fetch user information for updated notes
      for (final note in notes) {
        if (note['user'] != null && !_tastingNoteUsers.containsKey(note['user'])) {
          _fetchUserForTastingNote(note['user']);
        }
      }
    } catch (e) {
      _showSnackBar('Failed to update tasting note', Colors.red);
    }
  }

  Future<void> _handleDeleteTastingNote(int noteId) async {
    try {
      await _apiService.deleteTastingNote(noteId);
      _showSnackBar('Tasting note deleted successfully!', Colors.green);
      
      // Reload tasting notes to show the updated list
      final notes = await _apiService.getTastingNotes(_item!.id);
      setState(() {
        _tastingNotes = notes;
      });

      // Fetch user information for remaining notes
      for (final note in notes) {
        if (note['user'] != null && !_tastingNoteUsers.containsKey(note['user'])) {
          _fetchUserForTastingNote(note['user']);
        }
      }
    } catch (e) {
      _showSnackBar('Failed to delete tasting note', Colors.red);
    }
  }

  Future<void> _handleFetchTastingNotes() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || !authProvider.user!.isAdmin) {
      _showSnackBar('Only admins can fetch tasting notes', Colors.red);
      return;
    }

    setState(() {
      _fetchingTastingNotes = true;
    });

    try {
      // Get wine details from item properties for better search
      final wineDetails = <String, dynamic>{};
      final properties = _itemProperties?[_item!.id] ?? [];
      
      for (final prop in properties) {
        final name = prop['property_name']?.toString().toLowerCase() ?? '';
        final value = prop['property_value']?.toString() ?? '';
        
        if (name.contains('vintage') && value.isNotEmpty) {
          wineDetails['vintage'] = value;
        } else if (name.contains('region') && value.isNotEmpty) {
          wineDetails['region'] = value;
        } else if (name.contains('country') && value.isNotEmpty) {
          wineDetails['country'] = value;
        }
      }
      
      if (_item != null) {
        wineDetails['wine_name'] = _item!.name;
      }

      final result = await _apiService.fetchTastingNotes(_item!.id, wineDetails: wineDetails);
      
      if (result['success'] == true) {
        // Refresh tasting notes to see if any were added
        final notes = await _apiService.getTastingNotes(_item!.id);
        setState(() {
          _tastingNotes = notes;
        });

        // Fetch user information for new notes
        for (final note in notes) {
          if (note['user'] != null && !_tastingNoteUsers.containsKey(note['user'])) {
            _fetchUserForTastingNote(note['user']);
          }
        }

        // Check if any tasting notes were actually added
        if (notes.isEmpty) {
          _showSnackBar('We cannot find any tasting notes for this wine.', Colors.orange);
        } else {
          _showSnackBar('Tasting notes fetched successfully!', Colors.green);
        }
      } else {
        final message = result['message'] ?? 'Failed to fetch tasting notes';
        debugPrint('ItemDetailScreen: Fetch tasting notes failed: $message');
        _showSnackBar(message, Colors.red);
      }
    } catch (e) {
      _showSnackBar('Failed to fetch tasting notes', Colors.red);
    } finally {
      setState(() {
        _fetchingTastingNotes = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildLabelImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildLabelImageWithGenerateButton(),
      ),
    );
  }

  Widget _buildLabelImageWithGenerateButton() {
    return FutureBuilder<String?>(
      future: _imageService.getImageForItem(_item!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey[100],
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                ),
              ),
            ),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          // Image exists, show it with long-press for admin users
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final user = authProvider.user;
          
          if (user?.isAdmin == true) {
            // Admin user - wrap with GestureDetector for long-press
            return GestureDetector(
              onLongPress: _showRegenerateLabelDialog,
              child: _imageService.buildImageWidget(
                snapshot.data!,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            );
          } else {
            // Regular user - show image without long-press
            return _imageService.buildImageWidget(
              snapshot.data!,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            );
          }
        } else {
          // No image - check if user is admin to show generate button
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final user = authProvider.user;
          
          if (user?.isAdmin == true) {
            // Admin user - show generate label button
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[100],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No Label Image',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isGeneratingLabel ? null : _generateLabelImage,
                      icon: _isGeneratingLabel
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGeneratingLabel ? 'Generating...' : 'Generate Label'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF388E3C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Regular user - show placeholder
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[100],
              child: Center(
                child: Icon(
                  Icons.wine_bar,
                  color: Colors.grey[400],
                  size: 48,
                ),
              ),
            );
          }
        }
      },
    );
  }

  // Image handling is now done by ImageService

  Future<void> _generateLabelImage() async {
    if (_item == null) return;
    
    setState(() {
      _isGeneratingLabel = true;
    });

    try {
      debugPrint('ItemDetailScreen: Generating label image for item ${_item!.id}');
      
      // Call the API to generate the label image
      final imageData = await _apiService.generateLabelImage(_item!.id);
      
      if (imageData != null) {
        debugPrint('ItemDetailScreen: Label image generated successfully');
        
        // Update the cache with the new image
        await CacheService.setCachedImage(_item!.id, imageData);
        
        // Clear the ImageService memory cache for this item to force refresh
        _imageService.clearImageCache(_item!.id);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Label image generated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Force a rebuild to show the new image
        setState(() {});
      } else {
        debugPrint('ItemDetailScreen: Failed to generate label image');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate label image. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('ItemDetailScreen: Error generating label image: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating label image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingLabel = false;
        });
      }
    }
  }

  void _showRegenerateLabelDialog() {
    if (_item == null) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Regenerate Label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to regenerate the label image for this item?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_item != null) ...[
                Text(
                  _item!.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Item Code: ${_item!.code}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _generateLabelImage();
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Regenerate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemInfo() {
    if (_item == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _item!.displayNameOrName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF388E3C),
              ),
            ),
            if (_item!.displayName != null && _item!.displayName != _item!.name) ...[
              const SizedBox(height: 4),
              Text(
                _item!.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Price and stock info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatCurrency(_item!.price),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_item!.onHand != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'In Stock',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${_item!.onHand}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _item!.onHand! > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Description
            if (_item!.description.isNotEmpty) ...[
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _item!.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            
            // Item details
            _buildDetailRow('Code', _item!.code),
            _buildDetailRow('Type', _item!.isAlcohol ? 'Alcoholic Beverage' : 'Non-Alcoholic'),
            if (_item!.barcode != null) _buildDetailRow('Barcode', _item!.barcode!),
            if (_item!.tags != null && _item!.tags!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Tags',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _item!.tags!.split(',').map((tag) {
                  return Chip(
                    label: Text(tag.trim()),
                    backgroundColor: const Color(0xFF388E3C).withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: Color(0xFF388E3C),
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Dates
            _buildDetailRow('Added', _formatDate(_item!.createdAt)),
            _buildDetailRow('Updated', _formatDate(_item!.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProperties() {
    final properties = _itemProperties?[_item?.id];
    
    if (properties == null || properties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Properties header
          InkWell(
            onTap: () {
              setState(() {
                _propertiesExpanded = !_propertiesExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Properties',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _propertiesExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          
          // Properties content
          if (_propertiesExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: properties.map((property) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Information icon
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 12),
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        // Property name and value
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatPropertyName(property['name'] ?? 'Unknown'),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                property['value'] ?? 'N/A',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTastingNotes() {
    if (_tastingNotes?.isEmpty ?? true) {
      // Show admin fetch button if no tasting notes and user is admin
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.user!.isAdmin) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'No tasting notes available for this wine.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchingTastingNotes ? null : _handleFetchTastingNotes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF388E3C),
                    foregroundColor: Colors.white,
                  ),
                  child: _fetchingTastingNotes
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Finding Tasting Notes...'),
                          ],
                        )
                      : const Text('Find Tasting Notes'),
                ),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Tasting notes header
          InkWell(
            onTap: () {
              setState(() {
                _tastingNotesExpanded = !_tastingNotesExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasting Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _tastingNotesExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          
          // Tasting notes content
          if (_tastingNotesExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  children: (_tastingNotes ?? []).map((note) => _buildTastingNoteCard(note)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTastingNoteCard(Map<String, dynamic> note) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isEditing = _editingNoteId == note['id'];
    final canEdit = authProvider.isAuthenticated && 
        (authProvider.user!.isAdmin || note['email'] == authProvider.user!.email);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isEditing
            ? _buildTastingNoteEditMode(note)
            : _buildTastingNoteViewMode(note, canEdit),
      ),
    );
  }

  Widget _buildTastingNoteViewMode(Map<String, dynamic> note, bool canEdit) {
    String? contributorName;
    if (note['fname'] != null && note['lname'] != null) {
      contributorName = '${note['fname']} ${note['lname']}';
    } else if (note['user'] != null && _tastingNoteUsers.containsKey(note['user'])) {
      final user = _tastingNoteUsers[note['user']]!;
      contributorName = '${user.fname} ${user.lname}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Note text
        Text(
          '"${note['notes'] ?? ''}"',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        
        // Source and contributor info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note['source'] != null && note['source'].toString().trim().isNotEmpty)
                    Text(
                      '— ${note['source']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  if (contributorName != null)
                    Text(
                      '— Contributed by: $contributorName',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            
            // Edit/Delete buttons
            if (canEdit)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editingNoteId = note['id'];
                        _editingNoteText = note['notes'] ?? '';
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Edit'),
                  ),
                  TextButton(
                    onPressed: () => _handleDeleteTastingNote(note['id']),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTastingNoteEditMode(Map<String, dynamic> note) {
    return Column(
      children: [
        TextField(
          controller: TextEditingController(text: _editingNoteText),
          onChanged: (value) {
            setState(() {
              _editingNoteText = value;
            });
          },
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your tasting note...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _editingNoteId = null;
                  _editingNoteText = '';
                });
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _handleUpdateTastingNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_item?.displayNameOrName ?? 'Item Details'),
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/tabs/items');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            debugPrint('ItemDetailScreen: Building UI - _isLoading: $_isLoading, _isError: $_isError, _item: ${_item?.name}');
            
            return _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF388E3C)),
                    ),
                  )
                : _isError
                    ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Item',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Unknown error occurred',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadItemDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF388E3C),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _item == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF388E3C)),
                        ),
                      )
                    : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Label image
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildLabelImage(),
                        ),
                        
                        // Purchase button
                        _buildPurchaseButton(),
                        
                        const SizedBox(height: 16),
                        
                        // Item information
                        _buildItemInfo(),
                        
                        // Properties
                        _buildProperties(),
                        
                        const SizedBox(height: 16),

                        // Tasting notes
                        _buildTastingNotes(),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isPurchasing ? null : _showPurchaseDialog,
          icon: _isPurchasing 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.shopping_cart),
          label: Text(_isPurchasing ? 'Processing...' : 'Purchase Item'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF388E3C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Purchase Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_item != null) ...[
                Text(
                  _item!.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Price: €${_item!.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF388E3C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan the barcode to purchase this item. If you scan a different item, it will load that item instead.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Item Code: ${_item!.code}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: _scanBarcodeForPurchase,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Barcode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scanBarcodeForPurchase() async {
    debugPrint('ItemDetailScreen: Starting barcode scan for purchase');
    Navigator.of(context).pop(); // Close the dialog first
    
    // Navigate to scanner with current item context - let scanner handle everything
    final currentItemId = _item!.id;
    final currentItemName = _item!.name;
    
    debugPrint('ItemDetailScreen: Navigating to scanner for item $currentItemId ($currentItemName)');
    
    // Use simple navigation - scanner will handle all logic internally
    context.push('/scan?purchase=true&itemId=$currentItemId');
  }

  Future<void> _loadNewItem(int newItemId) async {
    debugPrint('ItemDetailScreen: Loading new item with ID: $newItemId');
    debugPrint('ItemDetailScreen: Current state - mounted: $mounted, _isLoading: $_isLoading, _isError: $_isError');
    
    if (!mounted) {
      debugPrint('ItemDetailScreen: Widget not mounted, skipping load');
      return;
    }
    
    debugPrint('ItemDetailScreen: Setting loading state to true');
    // Set loading state immediately
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
      // Don't clear _item immediately to avoid black screen
    });
    debugPrint('ItemDetailScreen: Loading state set, _isLoading is now: $_isLoading');

    // Add timeout to prevent infinite loading
    try {
      await Future.any([
        _loadNewItemData(newItemId),
        Future.delayed(const Duration(seconds: 30), () {
          throw TimeoutException('Loading timeout after 30 seconds', const Duration(seconds: 30));
        }),
      ]);
    } catch (e) {
      debugPrint('ItemDetailScreen: Error loading new item: $e');
      
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to load item: ${e.toString()}';
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load item: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadNewItemData(int newItemId) async {
    debugPrint('ItemDetailScreen: _loadNewItemData called for item $newItemId');
    debugPrint('ItemDetailScreen: Widget mounted in _loadNewItemData: $mounted');
    
    // Check if user is authenticated before making API calls
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('ItemDetailScreen: User authenticated: ${authProvider.isAuthenticated}');
    
    if (!authProvider.isAuthenticated) {
      debugPrint('ItemDetailScreen: User not authenticated');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        debugPrint('ItemDetailScreen: Set error state for unauthenticated user');
      }
      return;
    }

    debugPrint('ItemDetailScreen: Loading details for new item $newItemId');

    // Check cache first for item and properties
    final cachedItems = await CacheService.getCachedItems();
    final cachedProperties = await CacheService.getCachedItemProperties();
    
    Item? item;
    List<Map<String, dynamic>> properties = [];
    
    // Try to get item from cache first
    if (cachedItems != null) {
      try {
        item = cachedItems.firstWhere(
          (cachedItem) => cachedItem.id == newItemId,
          orElse: () => Item(
            id: -1, 
            code: '', 
            name: '', 
            description: '', 
            cost: 0, 
            price: 0, 
            isAlcohol: false, 
            createdAt: DateTime.now().toIso8601String(), 
            updatedAt: DateTime.now().toIso8601String(),
            onHand: 0
          ),
        );
        if (item.id != -1) {
          debugPrint('ItemDetailScreen: Found new item $newItemId in cache');
        }
      } catch (e) {
        debugPrint('ItemDetailScreen: Error finding item in cache: $e');
        item = null;
      }
    }
    
    // Try to get properties from cache
    if (cachedProperties != null && cachedProperties.containsKey(newItemId)) {
      properties = cachedProperties[newItemId]!;
      debugPrint('ItemDetailScreen: Found properties for new item $newItemId in cache');
    }

    // If we don't have cached data, fetch from API
    if (item == null || item.id == -1) {
      debugPrint('ItemDetailScreen: New item $newItemId not in cache, fetching from API');
      try {
        item = await _apiService.getItem(newItemId);
        debugPrint('ItemDetailScreen: Successfully fetched item $newItemId from API: ${item.name}');
      } catch (e) {
        debugPrint('ItemDetailScreen: Error fetching item from API: $e');
        throw Exception('Failed to fetch item: $e');
      }
    }
    
    if (properties.isEmpty) {
      debugPrint('ItemDetailScreen: Properties for new item $newItemId not in cache, fetching from API');
      try {
        properties = await _apiService.getItemProperties(newItemId);
        debugPrint('ItemDetailScreen: Successfully fetched properties for item $newItemId');
      } catch (e) {
        debugPrint('ItemDetailScreen: Error fetching properties from API: $e');
        // Don't throw here, just use empty properties
        properties = [];
      }
    }

    // Always fetch tasting notes (they change frequently)
    final tastingNotes = await _apiService.getTastingNotes(newItemId).catchError((e) {
      debugPrint('ItemDetailScreen: Error loading tasting notes: $e');
      return <Map<String, dynamic>>[];
    });

    if (!mounted) {
      debugPrint('ItemDetailScreen: Widget not mounted during setState, skipping');
      return;
    }

    debugPrint('ItemDetailScreen: About to update state with new item data');
    debugPrint('ItemDetailScreen: New item: ${item?.name} (ID: ${item?.id})');
    debugPrint('ItemDetailScreen: Properties count: ${properties.length}');
    debugPrint('ItemDetailScreen: Tasting notes count: ${tastingNotes.length}');
    
    // Update state with new item data
    setState(() {
      _item = item!;
      _itemProperties = {newItemId: properties};
      _tastingNotes = tastingNotes;
      _isLoading = false;
    });
    
    debugPrint('ItemDetailScreen: State updated successfully, _isLoading: $_isLoading, _item: ${_item?.name}');

    // Fetch user information for tasting notes that don't have complete user data
    for (final note in tastingNotes) {
      if (note['user'] != null && !_tastingNoteUsers.containsKey(note['user'])) {
        _fetchUserForTastingNote(note['user']);
      }
    }
    
    debugPrint('ItemDetailScreen: Successfully loaded new item: ${_item?.name}');
  }

}
