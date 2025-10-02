import 'firebase_database_service.dart';

class DataInitializationService {
  final FirebaseDatabaseService _databaseService = FirebaseDatabaseService();

  Future<void> initializeAppData() async {
    try {
      print('Starting data initialization...');
      await _databaseService.initializeSampleData();
      print('Sample data initialized successfully');
    } catch (e) {
      print('Error initializing sample data: $e');
      // Don't throw the error, just log it so the app can continue
    }
  }
}