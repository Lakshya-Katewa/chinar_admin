import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';

final dashboardDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await FirebaseService.getDashboardData();
});
