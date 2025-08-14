import 'package:bus_booking/home/presentation/widgets/home_tab.dart';
import 'package:bus_booking/home/presentation/widgets/mytrips.dart';
import 'package:bus_booking/home/presentation/widgets/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayinza_page_scaffold/page_scaffold.dart';
import '../bloc/bus_booking_bloc.dart';
import '../bloc/bus_booking_event.dart';
import '../bloc/bus_booking_state.dart';

class RideReservePage extends StatelessWidget {
  const RideReservePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(),
      child: const _RideReservePageView(),
    );
  }
}

class _RideReservePageView extends StatelessWidget {
  const _RideReservePageView();

  static final List<Widget> pages = [
    const HomeTab(),
    const MyTripsTab(),
    const ProfileTab(),
  ];

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return "Home";
      case 1:
        return "My Trips";
      case 2:
        return "Profile";
      default:
        return "";
    }
  }

  List<Widget> _getAppBarWidgets(int index) {
    if (index == 0) {
      return [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Handle notifications
            },
          ),
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return PageScaffold(
          pageTitle: _getPageTitle(state.currentPageIndex),
          appBarWidgets: _getAppBarWidgets(state.currentPageIndex),
          footerContent: _buildNavigationBar(context, state.currentPageIndex),
          bodyContent: pages[state.currentPageIndex],
        );
      },
    );
  }

  Widget _buildNavigationBar(BuildContext context, int currentIndex) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton(
              context,
              icon: Icons.home,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => context.read<HomeBloc>().add(
                    NavigationEvent(0),
                  ),
            ),
            _buildNavButton(
              context,
              icon: Icons.directions_bus,
              label: 'My Trips',
              isSelected: currentIndex == 1,
              onTap: () => context.read<HomeBloc>().add(
                    NavigationEvent(1),
                  ),
            ),
            _buildNavButton(
              context,
              icon: Icons.person,
              label: 'Profile',
              isSelected: currentIndex == 2,
              onTap: () => context.read<HomeBloc>().add(
                    NavigationEvent(2),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.lightBlue : Colors.grey[600],
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.lightBlue : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}




