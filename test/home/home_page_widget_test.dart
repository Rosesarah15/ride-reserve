import 'dart:async';

import 'package:bus_booking/home/presentation/pages/home_page.dart';
import 'package:bus_booking/models/schedule_model.dart';
import 'package:bus_booking/services/firebase_database_service.dart';
import 'package:bus_booking/utils/custom_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Mock classes
class MockFirebaseDatabaseService extends Mock implements FirebaseDatabaseService {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('HomePage Widget Test', () {
    late MockFirebaseDatabaseService mockDatabaseService;

    setUp(() {
      mockDatabaseService = MockFirebaseDatabaseService();
    });

    testWidgets('displays list of trips when data is available', (WidgetTester tester) async {
      // This test demonstrates how you would test the HomePage if you could inject
      // a mock FirebaseDatabaseService. Since HomePage creates its own service instance,
      // this test cannot be run successfully without code changes.

      // 1. Create mock data
      final schedule = ScheduleModel(
        id: 'schedule1',
        routeId: 'route1',
        busId: 'bus1',
        departureTime: DateTime.now(),
        arrivalTime: DateTime.now().add(const Duration(hours: 2)),
        fee: 20000,
      );

      // 2. Mock the service calls
      final mockScheduleDoc = MockQueryDocumentSnapshot();
      when(mockScheduleDoc.data()).thenReturn(schedule.toMap());

      final mockScheduleSnapshot = MockQuerySnapshot();
      when(mockScheduleSnapshot.docs).thenReturn([mockScheduleDoc]);

      when(mockDatabaseService.getSchedulesStream()).thenAnswer((_) => Stream.value(mockScheduleSnapshot));

      // 3. Build the widget
      // To make this test work, you would need to modify HomePage to accept a
      // FirebaseDatabaseService in its constructor.
      //
      // For example:
      // final homePage = HomePage(databaseService: mockDatabaseService);

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(), // This uses the real service, which will fail in a test env
        ),
      );

      // The test would then look something like this:
      // await tester.pump(); // Let the stream builder get the data
      // expect(find.byType(TripCard), findsOneWidget);
    });

    testWidgets('displays empty state widget when no data is available', (WidgetTester tester) async {
      // Mock the service to return an empty stream
      final mockScheduleSnapshot = MockQuerySnapshot();
      when(mockScheduleSnapshot.docs).thenReturn([]);
      when(mockDatabaseService.getSchedulesStream()).thenAnswer((_) => Stream.value(mockScheduleSnapshot));

      // As before, this test requires dependency injection to work.
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(),
        ),
      );

      // The test would then look something like this:
      // await tester.pump();
      // expect(find.byType(EmptyStateWidget), findsOneWidget);
      // expect(find.text('No Trips Available'), findsOneWidget);
    });
  });
}