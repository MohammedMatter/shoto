import 'dart:convert';
import 'dart:developer';
import 'package:shoto/features/onboarding/data/models/onboarding_item_model.dart';
import 'package:flutter/services.dart';

class OnboardingLocalDataSource {
  Future<List<OnboardingItemModel>> loadOnboardingData() async {
    List<OnboardingItemModel> items = [];
    final String jsonString = await rootBundle.loadString(
      'assets/cfg/onboarding_data.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);

    for (var element in jsonList) {
      final item = OnboardingItemModel.fromJson(element);
      items.add(item);
    }

    return items;
  }
}
