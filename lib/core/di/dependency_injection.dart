import 'package:get_it/get_it.dart';
import 'package:shoto/core/database/app_database.dart';
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
import 'package:shoto/features/onboarding/data/data_sources/onboarding_local_data_source.dart';
import 'package:shoto/features/onboarding/data/repositories_impl/onboarding_repository_impl.dart';
import 'package:shoto/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:shoto/features/onboarding/domain/use_cases/load_onboarding_data_use_case.dart';
import 'package:shoto/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_gallery_data_source.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_metadata_local_data_source.dart';
import 'package:shoto/features/screenshots/data/repositories_impl/screenshot_repository_impl.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/screenshots/domain/use_cases/assign_folder_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/delete_screenshots_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_screenshots_by_folder_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_screenshots_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/import_shared_screenshot_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/request_photo_permission_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_favorite_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/watch_library_changes_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton(() => OnboardingLocalDataSource());
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => LoadOnboardingDataUseCase(sl()));
  sl.registerFactory(() => OnboardingBloc(sl()));

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

  sl.registerLazySingleton(() => ScreenshotGalleryDataSource());
  sl.registerLazySingleton(() => ScreenshotMetadataLocalDataSource(sl()));
  sl.registerLazySingleton<ScreenshotRepository>(
    () => ScreenshotRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton(() => RequestPhotoPermissionUseCase(sl()));
  sl.registerLazySingleton(() => GetScreenshotsUseCase(sl()));
  sl.registerLazySingleton(() => GetScreenshotsByFolderUseCase(sl()));
  sl.registerLazySingleton(() => SetFavoriteUseCase(sl()));
  sl.registerLazySingleton(() => AssignFolderUseCase(sl()));
  sl.registerLazySingleton(() => DeleteScreenshotsUseCase(sl()));
  sl.registerLazySingleton(() => WatchLibraryChangesUseCase(sl()));
  sl.registerLazySingleton(() => ImportSharedScreenshotUseCase(sl()));
  sl.registerFactory(
    () => ScreenshotsBloc(
      requestPhotoPermissionUseCase: sl(),
      getScreenshotsUseCase: sl(),
      getScreenshotsByFolderUseCase: sl(),
      setFavoriteUseCase: sl(),
      assignFolderUseCase: sl(),
      deleteScreenshotsUseCase: sl(),
      watchLibraryChangesUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => FoldersLocalDataSource(sl()));
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
}
