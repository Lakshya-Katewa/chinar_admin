import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../models/banner.dart' as model;

final bannersStreamProvider = StreamProvider<List<model.Banner>>((ref) {
  return FirebaseService.getBanners();
});

class BannerNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addBanner({
    required String title,
    required String subtitle,
    required String actionType,
    required String target,
    required bool isActive,
    required File imageFile,
  }) async {
    state = const AsyncLoading();
    try {
      final bannerId = const Uuid().v4();
      final imageUrl = await FirebaseService.uploadBannerImage(
        file: imageFile,
        bannerId: bannerId,
      );

      final newBanner = model.Banner(
        id: bannerId,
        title: title,
        subtitle: subtitle,
        actionType: actionType,
        target: target,
        isActive: isActive,
        imageUrl: imageUrl,
        createdAt: Timestamp.now(),
      );

      await FirebaseService.addBanner(newBanner);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; // <-- THIS TELLS THE UI THAT IT FAILED
    }
  }

  Future<void> updateBanner({
    required String bannerId,
    required String title,
    required String subtitle,
    required String actionType,
    required String target,
    required bool isActive,
    File? imageFile,
    required String existingImageUrl,
  }) async {
    state = const AsyncLoading();
    try {
      String imageUrl = existingImageUrl;
      if (imageFile != null) {
        imageUrl = await FirebaseService.uploadBannerImage(
          file: imageFile,
          bannerId: bannerId,
        );
      }

      final updatedBanner = model.Banner(
        id: bannerId,
        title: title,
        subtitle: subtitle,
        actionType: actionType,
        target: target,
        isActive: isActive,
        imageUrl: imageUrl,
        createdAt: Timestamp.now(),
      );

      await FirebaseService.updateBanner(updatedBanner);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; // <-- THIS TELLS THE UI THAT IT FAILED
    }
  }

  Future<void> deleteBanner(String bannerId) async {
    state = const AsyncLoading();
    try {
      await FirebaseService.deleteBanner(bannerId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final bannerNotifierProvider = AsyncNotifierProvider<BannerNotifier, void>(() {
  return BannerNotifier();
});
