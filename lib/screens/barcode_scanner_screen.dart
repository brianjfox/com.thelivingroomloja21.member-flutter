import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/item.dart';
import '../providers/auth_provider.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool returnResult;
  final bool isPurchase;
  final int? purchaseItemId;
  
  const BarcodeScannerScreen({
    super.key, 
    this.returnResult = false,
    this.isPurchase = false,
    this.purchaseItemId,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  final ApiService _apiService = ApiService();
  
  bool _isScanning = true;
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;
    
    // Avoid processing the same barcode multiple times
    if (_lastScannedCode == barcode.rawValue) return;
    _lastScannedCode = barcode.rawValue;

    setState(() {
      _isProcessing = true;
      _isScanning = false;
    });

    try {
      debugPrint('BarcodeScannerScreen: Scanning barcode: ${barcode.rawValue}');
      
      // Handle purchase flow - NEW CLEAN ARCHITECTURE
      if (widget.isPurchase) {
        await _handlePurchaseFlow(barcode.rawValue!);
        return;
      }
      
      // Handle return result flow (legacy)
      if (widget.returnResult) {
        await _handleReturnResultFlow(barcode.rawValue!);
        return;
      }
      
      // Regular barcode scanning flow
      await _handleRegularFlow(barcode.rawValue!);
      
    } catch (e) {
      debugPrint('BarcodeScannerScreen: Error in _onDetect: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning barcode: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isScanning = true;
          _lastScannedCode = null;
        });
      }
    }
  }

  /// Handle purchase flow - scan barcode and either purchase or change item
  Future<void> _handlePurchaseFlow(String barcode) async {
    debugPrint('BarcodeScannerScreen: Handling purchase flow for barcode: $barcode');
    debugPrint('BarcodeScannerScreen: Purchase item ID: ${widget.purchaseItemId}');
    
    try {
      // Get the scanned item
      final scannedItem = await _apiService.getItemByBarcode(barcode);
      debugPrint('BarcodeScannerScreen: Found scanned item: ${scannedItem.id} - ${scannedItem.name}');
      
      // Check if it's the same item or different
      if (scannedItem.id == widget.purchaseItemId) {
        // Same item - complete the purchase
        debugPrint('BarcodeScannerScreen: Same item scanned, completing purchase');
        await _completePurchase(scannedItem, barcode);
      } else {
        // Different item - navigate to new item detail
        debugPrint('BarcodeScannerScreen: Different item scanned, navigating to new item');
        await _navigateToNewItem(scannedItem);
      }
      
    } catch (e) {
      debugPrint('BarcodeScannerScreen: Error in purchase flow: $e');
      await _handleUnknownBarcode(barcode);
    }
  }

  /// Complete purchase for the same item
  Future<void> _completePurchase(Item item, String barcode) async {
    try {
      if (!mounted) return;
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('BarcodeScannerScreen: Creating purchase for item ${item.id}');
      debugPrint('BarcodeScannerScreen: Item details - name: ${item.name}, price: ${item.price}, onHand: ${item.onHand}');
      debugPrint('BarcodeScannerScreen: User email: ${user.email}');
      debugPrint('BarcodeScannerScreen: Barcode: $barcode');
      
      final purchase = await _apiService.createPurchase(
        userEmail: user.email,
        itemId: item.id,
        priceAsked: item.price,
        pricePaid: item.price,
        barcode: barcode,
      );

      debugPrint('BarcodeScannerScreen: Purchase created successfully: ${purchase.id}');

      if (mounted) {
        // Close the scanner first
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Use post-frame callback to ensure navigation happens after the scanner is disposed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Show success message and navigate to purchases
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Enjoy your ${item.displayName}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Navigate to purchases list
          context.go('/tabs/purchases');
        });
      }
    } catch (e) {
      debugPrint('BarcodeScannerScreen: Error completing purchase: $e');
      
      if (mounted) {
        String errorMessage = 'Purchase failed';
        
        // Handle specific error cases
        if (e is DioException && e.response?.data != null) {
          final responseData = e.response!.data;
          if (responseData is Map<String, dynamic>) {
            final message = responseData['message'] as String?;
            if (message != null) {
              if (message.contains('out of stock')) {
                errorMessage = 'This item is out of stock and cannot be purchased';
              } else {
                errorMessage = message;
              }
            }
          }
        }
        
        // Close the scanner first
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Show error toast and stay on item page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  /// Navigate to new item detail page
  Future<void> _navigateToNewItem(Item item) async {
    if (mounted) {
      // Close the scanner first
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Use post-frame callback to ensure navigation happens after the scanner is disposed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Navigate to new item detail
        context.go('/item/${item.id}');
      });
    }
  }

  /// Handle unknown barcode in purchase flow
  Future<void> _handleUnknownBarcode(String barcode) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user?.isAdmin == true) {
      // Admin user - navigate to wine learning
      debugPrint('BarcodeScannerScreen: Unknown barcode for admin, navigating to wine learning');
      if (mounted) {
        // Close the scanner first
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Use post-frame callback to ensure navigation happens after the scanner is disposed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/wine-learning?barcode=$barcode');
        });
      }
    } else {
      // Regular user - show message and close scanner
      debugPrint('BarcodeScannerScreen: Unknown barcode for regular user');
      if (mounted) {
        // Close the scanner first
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Use post-frame callback to ensure UI updates happen after the scanner is disposed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Show long-lasting error toast
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Barcode "$barcode" is not in our database'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 8), // Longer duration for error messages
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        });
      }
    }
  }

  /// Legacy: Handle return result flow
  Future<void> _handleReturnResultFlow(String barcode) async {
    try {
      final item = await _apiService.getItemByBarcode(barcode);
      
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop({
          'barcode': barcode,
          'item': item,
        });
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop({
          'barcode': barcode,
          'item': null,
        });
      }
    }
  }

  /// Regular barcode scanning flow
  Future<void> _handleRegularFlow(String barcode) async {
    try {
      final item = await _apiService.getItemByBarcode(barcode);
      
      if (mounted) {
        context.go('/item/${item.id}');
      }
    } catch (e) {
      if (mounted) {
        _showItemNotFoundDialog(barcode);
      }
    }
  }

  void _showItemNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Item Not Found'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                'No item found with barcode:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                barcode,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Would you like to learn about this wine using AI?',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resumeScanning();
              },
              child: const Text('Scan Again'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToWineLearning(barcode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Learn Wine'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToWineLearning(String barcode) {
    // Navigate to wine learning screen with the scanned barcode
    context.go('/wine-learning?barcode=$barcode');
  }

  void _resumeScanning() {
    setState(() {
      _isScanning = true;
      _lastScannedCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_off, color: Colors.grey),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.camera_rear),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Camera view
            MobileScanner(
              controller: cameraController,
              onDetect: _onDetect,
            ),
            
            // Scanning overlay
            if (_isScanning) _buildScanningOverlay(),
            
            // Processing overlay
            if (_isProcessing) _buildProcessingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      child: Column(
        children: [
          // Top section
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          
          // Middle section with scanning area
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Left side
                Expanded(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                
                // Scanning area
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF388E3C),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Corner indicators
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF388E3C),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF388E3C),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF388E3C),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF388E3C),
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right side
                Expanded(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom section
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.black.withOpacity(0.5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Position the barcode within the frame',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The item will be found automatically',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF388E3C)),
            ),
            const SizedBox(height: 16),
            Text(
              'Processing barcode...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looking up item information',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
