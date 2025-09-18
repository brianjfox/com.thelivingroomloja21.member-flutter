import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/purchase.dart';
import '../services/api_service.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final ApiService _apiService = ApiService();
  
  List<Purchase> _purchases = [];
  double _outstandingBalance = 0.0;
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  String _selectedFilter = 'all'; // all, settled, outstanding
  String _selectedSort = 'recent'; // recent, oldest, amount_high, amount_low

  @override
  void initState() {
    super.initState();
    _loadPurchasesData();
  }

  Future<void> _loadPurchasesData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final results = await Future.wait([
        _apiService.getUserPurchases(),
        _apiService.getUserBalance(),
      ]);

      setState(() {
        _purchases = results[0] as List<Purchase>;
        _outstandingBalance = results[1] as double;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('PurchasesScreen: Error loading purchases data: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to load purchases: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Purchase> get _filteredAndSortedPurchases {
    List<Purchase> filtered = _purchases;
    
    // Apply filter
    switch (_selectedFilter) {
      case 'settled':
        filtered = _purchases.where((p) => p.settled).toList();
        break;
      case 'outstanding':
        filtered = _purchases.where((p) => !p.settled).toList();
        break;
      default:
        filtered = _purchases;
    }
    
    // Apply sorting
    switch (_selectedSort) {
      case 'recent':
        filtered.sort((a, b) => b.purchasedOn.compareTo(a.purchasedOn));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.purchasedOn.compareTo(b.purchasedOn));
        break;
      case 'amount_high':
        filtered.sort((a, b) => b.pricePaid.compareTo(a.pricePaid));
        break;
      case 'amount_low':
        filtered.sort((a, b) => a.pricePaid.compareTo(b.pricePaid));
        break;
    }
    
    return filtered;
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

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Balance card
          if (!_isLoading && !_isError) _buildBalanceCard(),
          
          // Filter and sort controls
          if (!_isLoading && !_isError) _buildFilterControls(),
          
          // Purchases list
          Expanded(
            child: _buildPurchasesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _outstandingBalance > 0 
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFF388E3C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: _outstandingBalance > 0 ? Colors.red : const Color(0xFF388E3C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outstanding Balance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(_outstandingBalance),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _outstandingBalance > 0 ? Colors.red : const Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceStat(
                    'Total Purchases',
                    _purchases.length.toString(),
                    Icons.shopping_bag,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceStat(
                    'Outstanding',
                    _purchases.where((p) => !p.settled).length.toString(),
                    Icons.pending,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceStat(
                    'Settled',
                    _purchases.where((p) => p.settled).length.toString(),
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF388E3C),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Filter chips
          Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Outstanding', 'outstanding'),
              const SizedBox(width: 8),
              _buildFilterChip('Settled', 'settled'),
            ],
          ),
          const SizedBox(height: 8),
          
          // Sort dropdown
          Row(
            children: [
              const Icon(
                Icons.sort,
                size: 16,
                color: Color(0xFF388E3C),
              ),
              const SizedBox(width: 8),
              Text(
                'Sort by:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedSort,
                underline: Container(),
                items: const [
                  DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
                  DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                  DropdownMenuItem(value: 'amount_high', child: Text('Amount (High to Low)')),
                  DropdownMenuItem(value: 'amount_low', child: Text('Amount (Low to High)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSort = value!;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: const Color(0xFF388E3C).withOpacity(0.2),
      checkmarkColor: const Color(0xFF388E3C),
    );
  }

  Widget _buildPurchasesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF388E3C)),
        ),
      );
    }

    if (_isError) {
      return Center(
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
              'Error Loading Purchases',
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
              onPressed: _loadPurchasesData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredPurchases = _filteredAndSortedPurchases;
    
    if (filteredPurchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFilter == 'outstanding' ? Icons.pending_actions :
              _selectedFilter == 'settled' ? Icons.check_circle : Icons.shopping_bag,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'outstanding' ? 'No Outstanding Purchases' :
              _selectedFilter == 'settled' ? 'No Settled Purchases' : 'No Purchases Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'outstanding' ? 'All your purchases have been settled' :
              _selectedFilter == 'settled' ? 'No settled purchases to display' : 'No purchase history available',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPurchasesData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPurchases.length,
        itemBuilder: (context, index) {
          final purchase = filteredPurchases[index];
          return _buildPurchaseCard(purchase);
        },
      ),
    );
  }

  Widget _buildPurchaseCard(Purchase purchase) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/item/${purchase.itemId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and amount
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: purchase.settled 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: purchase.settled 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      purchase.settled ? 'SETTLED' : 'OUTSTANDING',
                      style: TextStyle(
                        color: purchase.settled ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatCurrency(purchase.pricePaid),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF388E3C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Item name
              Text(
                purchase.itemName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Purchase details
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: Color(0xFF388E3C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Purchased: ${_formatDateTime(purchase.purchasedOn)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Settlement details (if settled)
              if (purchase.settled && purchase.settledOn != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Settled: ${_formatDateTime(purchase.settledOn!)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              // Price comparison (if different)
              if (purchase.priceAsked != purchase.pricePaid) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.euro,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Asked: ${_formatCurrency(purchase.priceAsked)} • Paid: ${_formatCurrency(purchase.pricePaid)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              // Item code (if available)
              if (purchase.code != null && purchase.code!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.qr_code,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Code: ${purchase.code}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}