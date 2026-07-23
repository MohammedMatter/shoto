import 'package:shoto/features/onboarding/domain/entities/onboarding_item.dart';

class OnboardingItemModel extends OnboardingItem {
  OnboardingItemModel({
    required super.imageUrl,
    required super.title,
    required super.description,
    required super.iconUrl,
    required super.height,
  });

  factory OnboardingItemModel.fromJson(Map<String, dynamic> json) {
    return OnboardingItemModel(
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      height: (json['height'] ?? 200).toDouble(),
    );
  }
}
