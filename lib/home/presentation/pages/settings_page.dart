import 'package:bus_booking/auth/auth_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final idTokenResult = await user.getIdTokenResult(true);
      setState(() {
        _isAdmin = idTokenResult.claims?['admin'] == true;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.exit_to_app),
            onTap: _logout,
          ),
          if (_isAdmin)
            const AdminToolsSection(),
        ],
      ),
    );
  }
}

class AdminToolsSection extends StatefulWidget {
  const AdminToolsSection({super.key});

  @override
  State<AdminToolsSection> createState() => _AdminToolsSectionState();
}

class _AdminToolsSectionState extends State<AdminToolsSection> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _makeAdmin() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('addAdminRole');
      final result = await callable.call(<String, dynamic>{'email': _emailController.text});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.data['message'] ?? 'Success!')),
      );
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unknown error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 20),
          Text('Admin Tools', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'User Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _makeAdmin,
              child: const Text('Make Admin'),
            ),
        ],
      ),
    );
  }
}