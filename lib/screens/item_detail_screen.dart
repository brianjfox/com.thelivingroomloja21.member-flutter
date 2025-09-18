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
  Map<int, List<Map<String, dynamic>>> _itemProperties = {};
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  
  // Tasting notes state
  List<Map<String, dynamic>> _tastingNotes = [];
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

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
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

      // First, try to get cached image
      String? labelImage;
      try {
        final cachedImages = await CacheService.getCachedItemImages();
        labelImage = cachedImages?[widget.itemId];
        debugPrint('ItemDetailScreen: Cached image for item ${widget.itemId}: ${labelImage != null ? "found" : "not found"}');
      } catch (e) {
        debugPrint('ItemDetailScreen: Error getting cached image: $e');
      }

      // Load item details, properties, and tasting notes in parallel
      final results = await Future.wait([
        _apiService.getItem(widget.itemId),
        _apiService.getItemProperties(widget.itemId),
        _apiService.getTastingNotes(widget.itemId).catchError((e) {
          debugPrint('ItemDetailScreen: Error loading tasting notes: $e');
          return <Map<String, dynamic>>[];
        }),
      ]);

      final item = results[0] as Item;
      final properties = results[1] as List<Map<String, dynamic>>;
      final tastingNotes = results[2] as List<Map<String, dynamic>>;

      setState(() {
        _item = item;
        _itemProperties[widget.itemId] = properties;
        _tastingNotes = tastingNotes;
        _isLoading = false;
      });

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
      await _apiService.createTastingNote(widget.itemId, _tastingNoteText.trim());
      _showSnackBar('Tasting note saved successfully!', Colors.green);
      
      // Reload tasting notes to show the new one
      final notes = await _apiService.getTastingNotes(widget.itemId);
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
      final notes = await _apiService.getTastingNotes(widget.itemId);
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
      final notes = await _apiService.getTastingNotes(widget.itemId);
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
      final properties = _itemProperties[widget.itemId] ?? [];
      
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

      final result = await _apiService.fetchTastingNotes(widget.itemId);
      
      if (result['success'] == true) {
        // Refresh tasting notes to see if any were added
        final notes = await _apiService.getTastingNotes(widget.itemId);
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
        _showSnackBar(result['message'] ?? 'Failed to fetch tasting notes', Colors.red);
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
    // Always use ImageService for image display

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
        child: _imageService.buildItemImageWidget(
          widget.itemId,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // Image handling is now done by ImageService

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
    final properties = _itemProperties[widget.itemId];
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            property['property_name'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            property['property_value'] ?? 'N/A',
                            style: Theme.of(context).textTheme.bodyMedium,
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
    if (_tastingNotes.isEmpty) {
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
                children: _tastingNotes.map((note) => _buildTastingNoteCard(note)).toList(),
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
        child: _isLoading
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
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Label image
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildLabelImage(),
                        ),
                        
                        // Item information
                        _buildItemInfo(),
                        
                        // Properties
                        _buildProperties(),
                        
                        // Tasting notes
                        _buildTastingNotes(),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
      ),
    );
  }
}
