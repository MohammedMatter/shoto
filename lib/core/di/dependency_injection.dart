import 'package:get_it/get_it.dart';
import 'package:shoto/core/database/app_database.dart';
import 'package:shoto/features/duplicates/data/data_sources/perceptual_hash_data_source.dart';
import 'package:shoto/features/duplicates/data/repositories_impl/duplicates_repository_impl.dart';
import 'package:shoto/features/duplicates/domain/repositories/duplicates_repository.dart';
import 'package:shoto/features/duplicates/domain/use_cases/delete_duplicates_use_case.dart';
import 'package:shoto/features/duplicates/domain/use_cases/find_duplicates_use_case.dart';
import 'package:shoto/features/duplicates/presentation/bloc/duplicates_bloc.dart';
import 'package:shoto/features/stitch/data/repositories_impl/stitch_repository_impl.dart';
import 'package:shoto/features/stitch/data/services/image_stitch_service.dart';
import 'package:shoto/features/stitch/domain/repositories/stitch_repository.dart';
import 'package:shoto/features/stitch/domain/use_cases/save_stitched_image_use_case.dart';
import 'package:shoto/features/stitch/domain/use_cases/stitch_screenshots_use_case.dart';
import 'package:shoto/features/stitch/presentation/bloc/stitch_bloc.dart';
import 'package:shoto/features/smart_actions/data/repositories_impl/smart_actions_repository_impl.dart';
import 'package:shoto/features/smart_actions/domain/repositories/smart_actions_repository.dart';
import 'package:shoto/features/smart_actions/domain/use_cases/get_screenshot_actions_use_case.dart';
import 'package:shoto/core/services/biometric_auth_service.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/features/safe_share/data/services/redaction_service.dart';
import 'package:shoto/core/services/backup_file_service.dart';
import 'package:shoto/core/services/cache_service.dart';
import 'package:shoto/features/backup/data/repositories_impl/backup_repository_impl.dart';
import 'package:shoto/features/backup/domain/repositories/backup_repository.dart';
import 'package:shoto/features/backup/domain/use_cases/create_backup_use_case.dart';
import 'package:shoto/features/backup/domain/use_cases/preview_backup_use_case.dart';
import 'package:shoto/features/backup/domain/use_cases/restore_backup_use_case.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/localization/locale_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:shoto/features/auth/data/repositories_impl/auth_repository_impl.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_in_with_apple_use_case.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_in_with_google_use_case.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shoto/features/folders/data/data_sources/folders_local_data_source.dart';
import 'package:shoto/features/folders/data/repositories_impl/folders_repository_impl.dart';
import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';
import 'package:shoto/features/folders/domain/use_cases/create_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/delete_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/rename_folder_use_case.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/screenshots/data/data_sources/image_labeling_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/library_ownership_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_gallery_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_metadata_local_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/system_photo_picker_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/text_recognition_data_source.dart';
import 'package:shoto/features/screenshots/data/repositories_impl/screenshot_repository_impl.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/screenshots/domain/use_cases/assign_folder_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/check_photo_permission_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/delete_screenshots_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/extract_and_cache_labels_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/extract_and_cache_text_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_cached_ocr_text_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_cached_visual_labels_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_managed_screenshot_count_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_screenshots_by_folder_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_screenshots_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/import_from_system_picker_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/import_shared_screenshot_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/request_photo_permission_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_favorite_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_intent_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_intent_done_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/watch_library_changes_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/subscription/data/data_sources/revenue_cat_data_source.dart';
import 'package:shoto/features/subscription/data/repositories_impl/subscription_repository_impl.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_offerings_use_case.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_subscription_status_use_case.dart';
import 'package:shoto/features/subscription/domain/use_cases/purchase_package_use_case.dart';
import 'package:shoto/features/subscription/domain/use_cases/restore_purchases_use_case.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_bloc.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton(() => AuthRemoteDataSource());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithAppleUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerFactory(
    () => AuthBloc(
      signInWithGoogleUseCase: sl(),
      signInWithAppleUseCase: sl(),
      signOutUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => AppDatabase());
  sl.registerLazySingleton(() => ThemeController());
  sl.registerLazySingleton(() => LocaleController());
  sl.registerLazySingleton(() => GridDensityController());
  sl.registerLazySingleton(() => CacheService());
  sl.registerLazySingleton(() => AppPreferences());
  sl.registerLazySingleton(() => DevAccess());
  sl.registerLazySingleton(() => BiometricAuthService());

  sl.registerLazySingleton(() => ScreenshotGalleryDataSource());
  sl.registerLazySingleton(() => SystemPhotoPickerDataSource());
  sl.registerLazySingleton(() => ScreenshotMetadataLocalDataSource(sl(), sl()));
  sl.registerLazySingleton(() => LibraryOwnershipLocalDataSource(sl(), sl()));
  sl.registerLazySingleton(() => TextRecognitionDataSource());
  sl.registerLazySingleton(() => ImageLabelingDataSource());
  sl.registerLazySingleton<ScreenshotRepository>(
    () => ScreenshotRepositoryImpl(sl(), sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton(() => RequestPhotoPermissionUseCase(sl()));
  sl.registerLazySingleton(() => CheckPhotoPermissionUseCase(sl()));
  sl.registerLazySingleton(() => GetScreenshotsUseCase(sl()));
  sl.registerLazySingleton(() => GetScreenshotsByFolderUseCase(sl()));
  sl.registerLazySingleton(() => SetFavoriteUseCase(sl()));
  sl.registerLazySingleton(() => AssignFolderUseCase(sl()));
  sl.registerLazySingleton(() => SetIntentUseCase(sl()));
  sl.registerLazySingleton(() => SetIntentDoneUseCase(sl()));
  sl.registerLazySingleton(() => DeleteScreenshotsUseCase(sl()));
  sl.registerLazySingleton(() => WatchLibraryChangesUseCase(sl()));
  sl.registerLazySingleton(() => ImportSharedScreenshotUseCase(sl()));
  sl.registerLazySingleton(() => ImportFromSystemPickerUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetCachedOcrTextUseCase(sl()));
  sl.registerLazySingleton(() => ExtractAndCacheTextUseCase(sl()));
  sl.registerLazySingleton(() => GetCachedVisualLabelsUseCase(sl()));
  sl.registerLazySingleton(() => ExtractAndCacheLabelsUseCase(sl()));
  sl.registerLazySingleton(() => GetManagedScreenshotCountUseCase(sl()));
  sl.registerFactory(
    () => ScreenshotsBloc(
      requestPhotoPermissionUseCase: sl(),
      checkPhotoPermissionUseCase: sl(),
      getScreenshotsUseCase: sl(),
      getScreenshotsByFolderUseCase: sl(),
      setFavoriteUseCase: sl(),
      setIntentUseCase: sl(),
      setIntentDoneUseCase: sl(),
      assignFolderUseCase: sl(),
      deleteScreenshotsUseCase: sl(),
      watchLibraryChangesUseCase: sl(),
      getCachedOcrTextUseCase: sl(),
      extractAndCacheTextUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => FoldersLocalDataSource(sl(), sl()));
  sl.registerLazySingleton<FoldersRepository>(
    () => FoldersRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetFoldersUseCase(sl()));
  sl.registerLazySingleton(() => CreateFolderUseCase(sl()));
  sl.registerLazySingleton(() => RenameFolderUseCase(sl()));
  sl.registerLazySingleton(() => DeleteFolderUseCase(sl()));
  sl.registerFactory(
    () => FoldersBloc(
      getFoldersUseCase: sl(),
      createFolderUseCase: sl(),
      renameFolderUseCase: sl(),
      deleteFolderUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => RevenueCatDataSource());
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(sl(), sl(), sl()),
  );
  // After the repository it reads from, and eagerly enough that `main` can
  // prime it before the first frame — a Pro badge that appears a second late
  // reads as the app changing its mind about who you are.
  sl.registerLazySingleton(() => ProStatus(sl(), sl()));
  sl.registerLazySingleton(() => GetOfferingsUseCase(sl()));
  sl.registerLazySingleton(() => GetSubscriptionStatusUseCase(sl()));
  sl.registerLazySingleton(() => PurchasePackageUseCase(sl()));
  sl.registerLazySingleton(() => RestorePurchasesUseCase(sl()));
  sl.registerFactory(
    () => SubscriptionBloc(
      getOfferingsUseCase: sl(),
      getSubscriptionStatusUseCase: sl(),
      purchasePackageUseCase: sl(),
      restorePurchasesUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => PerceptualHashDataSource());
  sl.registerLazySingleton<DuplicatesRepository>(
    () => DuplicatesRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => FindDuplicatesUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDuplicatesUseCase(sl()));
  sl.registerFactory(
    () => DuplicatesBloc(
      findDuplicatesUseCase: sl(),
      deleteDuplicatesUseCase: sl(),
    ),
  );

  sl.registerLazySingleton<SmartActionsRepository>(
    () => SmartActionsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetScreenshotActionsUseCase(sl()));


  sl.registerLazySingleton(() => RedactionService(sl(), sl()));

  // Backup reads through the screenshot repository rather than the gallery
  // directly, so an archive holds exactly the library the app shows — not
  // every picture on the phone.
  sl.registerLazySingleton(() => BackupFileService());
  sl.registerLazySingleton<BackupRepository>(
    () => BackupRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerLazySingleton(() => CreateBackupUseCase(sl()));
  sl.registerLazySingleton(() => RestoreBackupUseCase(sl()));
  sl.registerLazySingleton(() => PreviewBackupUseCase(sl()));

  sl.registerLazySingleton(() => ImageStitchService());
  sl.registerLazySingleton<StitchRepository>(
    () => StitchRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => StitchScreenshotsUseCase(sl()));
  sl.registerLazySingleton(() => SaveStitchedImageUseCase(sl()));
  sl.registerFactory(
    () => StitchBloc(
      stitchScreenshotsUseCase: sl(),
      saveStitchedImageUseCase: sl(),
    ),
  );
}
