import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'items_screen.dart';
import 'events_screen.dart';
import 'purchases_screen.dart';
import 'inventory_screen.dart';
import '../providers/auth_provider.dart';

class MainTabsScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainTabsScreen({super.key, this.initialIndex = 0});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const EventsScreen(),
    const ItemsScreen(),
    const PurchasesScreen(),
  ];

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const NavigationDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event),
      label: 'Events',
    ),
    const NavigationDestination(
      icon: Icon(Icons.wine_bar_outlined),
      selectedIcon: Icon(Icons.wine_bar),
      label: 'Drinks',
    ),
    const NavigationDestination(
      icon: Icon(Icons.shopping_cart_outlined),
      selectedIcon: Icon(Icons.shopping_cart),
      label: 'Purchases',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Navigate to the appropriate route
          switch (index) {
            case 0:
              context.go('/tabs/dashboard');
              break;
            case 1:
              context.go('/tabs/events');
              break;
            case 2:
              context.go('/tabs/items');
              break;
            case 3:
              context.go('/tabs/purchases');
              break;
          }
        },
        destinations: _destinations,
      ),
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          // Admin hamburger menu
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.user?.isAdmin == true) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Admin Menu',
                  onSelected: (value) => _handleAdminMenuSelection(value, context),
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'inventory',
                      child: ListTile(
                        leading: Icon(Icons.inventory_2_outlined),
                        title: Text('Inventory Management'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'wine_research',
                      child: ListTile(
                        leading: Icon(Icons.auto_awesome),
                        title: Text('Wine Research'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'test_user',
                      child: ListTile(
                        leading: Icon(Icons.switch_account),
                        title: Text('Login as Test User'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/tabs/settings'),
          ),
        ],
      ),
    );
  }

  void _handleAdminMenuSelection(String value, BuildContext context) {
    switch (value) {
      case 'inventory':
        _showInventoryManagement(context);
        break;
      case 'wine_research':
        context.go('/wine-learning');
        break;
      case 'test_user':
        _showTestUserLogin(context);
        break;
    }
  }

  void _showInventoryManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InventoryScreen(),
      ),
    );
  }

  void _showTestUserLogin(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login as Test User'),
        content: const Text('This feature will allow you to switch to a test user account for testing purposes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement test user login functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test user login feature coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Login as Test User'),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Events';
      case 2:
        return 'Drinks';
      case 3:
        return 'Purchases';
      default:
        return 'The Living Room';
    }
  }
}
