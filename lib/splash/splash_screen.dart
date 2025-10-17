import 'dart:async';

import 'package:bus_booking/admin/admin_home_page.dart';
import 'package:bus_booking/auth/auth_page.dart';
import 'package:bus_booking/home/presentation/pages/main_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() async {
    Timer(
      const Duration(seconds: 2),
      () async {
        final user = FirebaseAuth.instance.currentUser;
        if (mounted) {
          if (user == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AuthPage()),
            );
          } else {
            // Check if user is admin
            try {
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              final isAdmin = userDoc.exists && userDoc.data()!['Role'] == 'Admin';
              
              if (isAdmin) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminHomePage()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainPage()),
                );
              }
            } catch (e) {
              // If there's an error checking admin status, default to regular user
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainPage()),
              );
            }
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Add logo
            Text('BusGo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}