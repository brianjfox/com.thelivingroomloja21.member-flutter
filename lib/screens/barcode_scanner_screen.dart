import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../models/item.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool returnResult;
  
  const BarcodeScannerScreen({super.key, this.returnResult = false});

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
      
      if (widget.returnResult) {
        // Return the barcode result for purchase flow
        if (mounted) {
          Navigator.of(context).pop(barcode.rawValue);
        }
        return;
      }
      
      // Try to find the item by barcode
      final item = await _apiService.getItemByBarcode(barcode.rawValue!);
      
      if (mounted) {
        // Navigate to item detail screen
        context.go('/item/${item.id}');
      }
    } catch (e) {
      debugPrint('BarcodeScannerScreen: Error finding item: $e');
      
      if (mounted) {
        if (widget.returnResult) {
          // For purchase flow, still return the barcode even if item not found
          Navigator.of(context).pop(barcode.rawValue);
        } else {
          // Show item not found dialog
          _showItemNotFoundDialog(barcode.rawValue!);
        }
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
