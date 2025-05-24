import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/area.dart';
import '../services/firebase_service.dart';

final areasProvider = StreamProvider<List<Area>>((ref) {
  return FirebaseService.getAreas();
});

final areaNotifierProvider = Provider<AreaNotifier>((ref) {
  return AreaNotifier();
});

class AreaNotifier {
  Future<void> addArea(Area area) async {
    await FirebaseService.addArea(area);
  }

  Future<void> deleteArea(String areaId) async {
    await FirebaseService.deleteArea(areaId);
  }
}
