import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dashboard_screen.dart';
import 'items_screen.dart';
import 'events_screen.dart';
import 'purchases_screen.dart';

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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/tabs/settings'),
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
