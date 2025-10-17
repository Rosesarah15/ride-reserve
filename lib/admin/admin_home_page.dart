
import 'package:bus_booking/admin/bookings_tab.dart';
import 'package:bus_booking/admin/buses_tab.dart';
import 'package:bus_booking/admin/routes_tab.dart';
import 'package:bus_booking/admin/schedules_tab.dart';
import 'package:bus_booking/auth/auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bookings', icon: Icon(Icons.book_online)),
            Tab(text: 'Schedules', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Routes', icon: Icon(Icons.directions)),
            Tab(text: 'Buses', icon: Icon(Icons.directions_bus)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BookingsTab(),
          SchedulesTab(),
          RoutesTab(),
          BusesTab(),
        ],
      ),
    );
  }
}
