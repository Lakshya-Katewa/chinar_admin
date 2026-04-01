import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../models/banner.dart' as model;

// Provider to get the stream of banners from Firestore
final bannersStreamProvider = StreamProvider<List<model.Banner>>((ref) {
  return FirebaseService.getBanners();
});

// StateNotifier for managing banner create, update, and delete actions
class BannerNotifier extends StateNotifier<AsyncValue<void>> {
  BannerNotifier() : super(const AsyncValue.data(null));

  // Method to add a new banner
  Future<void> addBanner({
    required String title,
    required String subtitle,
    required String actionType,
    required String target,
    required bool isActive,
    required File imageFile,
  }) async {
    state = const AsyncValue.loading();
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
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Method to update an existing banner
  Future<void> updateBanner({
    required String bannerId,
    required String title,
    required String subtitle,
    required String actionType,
    required String target,
    required bool isActive,
    File? imageFile, // Image is optional on update
    required String existingImageUrl,
  }) async {
    state = const AsyncValue.loading();
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
        // The 'createdAt' field is intentionally omitted from the update object
        // to prevent overwriting it in Firestore. We create a temporary object for the
        // update method, which only cares about the fields being changed.
        createdAt: Timestamp.now(), 
      );

      await FirebaseService.updateBanner(updatedBanner);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Method to delete a banner
  Future<void> deleteBanner(String bannerId) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseService.deleteBanner(bannerId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Provider for the BannerNotifier
final bannerNotifierProvider =
    StateNotifierProvider<BannerNotifier, AsyncValue<void>>((ref) {
  return BannerNotifier();
});
