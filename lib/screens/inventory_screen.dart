import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/image_service.dart';
import '../models/item.dart';
import 'barcode_scanner_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ApiService _apiService = ApiService();
  final ImageService _imageService = ImageService();
  
  List<Map<String, dynamic>> _scanResults = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Scan Next Item Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _scanNextItem,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_scanner),
              label: Text(_isLoading ? 'Scanning...' : 'Scan Next Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Scan Results
          Expanded(
            child: _scanResults.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No items scanned yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap "Scan Next Item" to start',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      return _buildScanResultCard(result);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResultCard(Map<String, dynamic> result) {
    final item = result['item'] as Item?;
    final isNewItem = result['isNewItem'] as bool;
    final timestamp = result['timestamp'] as DateTime;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Item image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: item != null
                    ? _imageService.buildItemImageWidgetAsync(item.id)
                    : const Icon(
                        Icons.wine_bar,
                        color: Colors.grey,
                        size: 30,
                      ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item?.displayName ?? 'Unknown Item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: isNewItem ? Colors.green : Colors.blue,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          isNewItem ? 'NEW' : 'EXISTING',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (item != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'On Hand: ${item.onHand ?? 0}',
                      style: TextStyle(
                        fontSize: 14,
                        color: (item.onHand ?? 0) > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Price: \$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 4),
                  Text(
                    'Scanned: ${_formatTimestamp(timestamp)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _scanNextItem() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Navigate to barcode scanner
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(
            returnResult: true,
          ),
        ),
      );

      if (result != null && result['barcode'] != null) {
        final barcode = result['barcode'] as String;
        await _processScannedBarcode(barcode);
      }
    } catch (e) {
      debugPrint('InventoryScreen: Error scanning barcode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processScannedBarcode(String barcode) async {
    try {
      debugPrint('InventoryScreen: Processing barcode: $barcode');
      
      // First, try to get existing item
      Item? item;
      bool isNewItem = false;
      
      try {
        item = await _apiService.getItemByBarcode(barcode);
        debugPrint('InventoryScreen: Found existing item: ${item.name}');
      } catch (e) {
        debugPrint('InventoryScreen: Item not found, attempting to learn wine: $e');
        
        // Item doesn't exist, try to learn it
        try {
          final learningResult = await _apiService.learnWineFromBarcode(barcode: barcode);
          
          if (learningResult['success'] == true && learningResult['data'] != null) {
            final itemData = learningResult['data']['item'] as Map<String, dynamic>;
            item = Item.fromJson(itemData);
            isNewItem = true;
            debugPrint('InventoryScreen: Successfully learned new wine: ${item.name}');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully learned new wine: ${item.displayName}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            throw Exception('Failed to learn wine from barcode');
          }
        } catch (learningError) {
          debugPrint('InventoryScreen: Error learning wine: $learningError');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Barcode "$barcode" not found and could not be learned'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      // Add scan result to the list
      if (mounted && item != null) {
        setState(() {
          _scanResults.insert(0, {
            'item': item,
            'isNewItem': isNewItem,
            'timestamp': DateTime.now(),
          });
        });
      }
      
    } catch (e) {
      debugPrint('InventoryScreen: Error processing barcode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

