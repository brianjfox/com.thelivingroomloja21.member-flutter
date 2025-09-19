import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_router.dart';

class WineLearningScreen extends StatefulWidget {
  final String? initialBarcode;
  
  const WineLearningScreen({super.key, this.initialBarcode});

  @override
  State<WineLearningScreen> createState() => _WineLearningScreenState();
}

class _WineLearningScreenState extends State<WineLearningScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();
  
  File? _frontImage;
  File? _backImage;
  String? _scannedBarcode;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  Map<String, dynamic>? _learningResult;

  @override
  void initState() {
    super.initState();
    // Set initial barcode if provided
    if (widget.initialBarcode != null) {
      _scannedBarcode = widget.initialBarcode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wine Learning'),
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/tabs/dashboard'),
          tooltip: 'Cancel',
        ),
        actions: [
          if (_frontImage != null || _backImage != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearImages,
              tooltip: 'Clear Images',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Theme.of(context).primaryColor,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'AI Wine Learning',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Take photos of wine bottles and let AI analyze them to extract wine information, create items, and generate tasting notes.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Barcode Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Barcode (Optional)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _scannedBarcode,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter or scan barcode',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.barcode_reader),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _scannedBarcode = value.trim().isEmpty ? null : value.trim();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _scanBarcode,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Scan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF388E3C),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Images Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.photo_camera,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Wine Images',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Front Image
                          _buildImageSection(
                            title: 'Front Label (Required)',
                            image: _frontImage,
                            onTap: () => _pickImage('front'),
                            isRequired: true,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Back Image
                          _buildImageSection(
                            title: 'Back Label (Optional)',
                            image: _backImage,
                            onTap: () => _pickImage('back'),
                            isRequired: false,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Error Message
                  if (_errorMessage != null)
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Process Button
                  ElevatedButton.icon(
                    onPressed: _canProcess() ? _processWineLearning : null,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isProcessing ? 'Processing...' : 'Learn Wine'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF388E3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Results Section
                  if (_learningResult != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Learning Complete',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildResultContent(),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required File? image,
    required VoidCallback onTap,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: image != null ? Colors.green : Colors.grey[300]!,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add ${title.toLowerCase()}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultContent() {
    if (_learningResult == null) return const SizedBox.shrink();

    final data = _learningResult!['data'];
    if (data == null) return const SizedBox.shrink();

    final item = data['item'];
    final analysis = data['analysis'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item != null) ...[
          Text(
            'Created Item: ${item['name'] ?? 'Unknown'}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text('Item ID: ${item['id']}'),
          const SizedBox(height: 16),
        ],
        
        if (analysis != null) ...[
          Text(
            'Analysis Results:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildAnalysisField('Name', analysis['name']),
          _buildAnalysisField('Vintage', analysis['vintage']),
          _buildAnalysisField('Country', analysis['country']),
          _buildAnalysisField('Region', analysis['region']),
          _buildAnalysisField('Grapes', analysis['grapes']?.join(', ')),
          _buildAnalysisField('Alcohol Content', analysis['alcohol_content']),
          _buildAnalysisField('Average Price', analysis['average_price']),
          _buildAnalysisField('Winery', analysis['winery']),
          _buildAnalysisField('Average Rating', analysis['average_rating']),
          if (analysis['tasting_notes'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tasting Notes:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              analysis['tasting_notes'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (item != null) {
                    context.go('/item/${item['id']}');
                  }
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Learn Another'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisField(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value.toString()),
          ),
        ],
      ),
    );
  }

  bool _canProcess() {
    return _frontImage != null && !_isProcessing;
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          if (type == 'front') {
            _frontImage = File(image.path);
          } else {
            _backImage = File(image.path);
          }
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _scanBarcode() async {
    // Navigate to barcode scanner
    final result = await context.push('/scan');
    if (result != null && result is String) {
      setState(() {
        _scannedBarcode = result;
        _errorMessage = null;
      });
    }
  }

  Future<void> _processWineLearning() async {
    if (!_canProcess()) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _learningResult = null;
    });

    try {
      // Check if user is admin
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated || authProvider.user?.isAdmin != true) {
        setState(() {
          _errorMessage = 'Admin privileges required for wine learning';
          _isProcessing = false;
        });
        return;
      }

      // Convert images to base64
      final frontImageBytes = await _frontImage!.readAsBytes();
      final frontImageBase64 = base64Encode(frontImageBytes);

      String? backImageBase64;
      if (_backImage != null) {
        final backImageBytes = await _backImage!.readAsBytes();
        backImageBase64 = base64Encode(backImageBytes);
      }

      // Call the API
      final result = await _apiService.learnWineFromImages(
        frontImage: frontImageBase64,
        backImage: backImageBase64,
        scannedBarcode: _scannedBarcode,
      );

      setState(() {
        _learningResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process wine learning: $e';
        _isProcessing = false;
      });
    }
  }

  void _clearImages() {
    setState(() {
      _frontImage = null;
      _backImage = null;
      _errorMessage = null;
    });
  }

  void _clearAll() {
    setState(() {
      _frontImage = null;
      _backImage = null;
      _scannedBarcode = null;
      _errorMessage = null;
      _learningResult = null;
    });
  }
}
