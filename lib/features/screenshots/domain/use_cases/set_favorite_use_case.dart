import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class SetFavoriteUseCase {
  final ScreenshotRepository repository;
  SetFavoriteUseCase(this.repository);

  Future<void> call(String assetId, bool isFavorite) =>
      repository.setFavorite(assetId, isFavorite);
}
