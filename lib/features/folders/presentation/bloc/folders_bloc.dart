import 'package:shoto/core/localization/app_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/features/folders/domain/use_cases/create_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/delete_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/rename_folder_use_case.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';

class FoldersBloc extends Bloc<FoldersEvent, FoldersState> {
  final GetFoldersUseCase getFoldersUseCase;
  final CreateFolderUseCase createFolderUseCase;
  final RenameFolderUseCase renameFolderUseCase;
  final DeleteFolderUseCase deleteFolderUseCase;

  FoldersBloc({
    required this.getFoldersUseCase,
    required this.createFolderUseCase,
    required this.renameFolderUseCase,
    required this.deleteFolderUseCase,
  }) : super(FoldersInitialState()) {
    on<LoadFoldersEvent>(_onLoad);
    on<CreateFolderEvent>(_onCreate);
    on<RenameFolderEvent>(_onRename);
    on<DeleteFolderEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadFoldersEvent event,
    Emitter<FoldersState> emit,
  ) async {
    emit(FoldersLoadingState());
    try {
      final folders = await getFoldersUseCase();
      emit(FoldersLoadedState(folders));
    } catch (error) {
      emit(FoldersErrorState(AppMessage.loadFolders));
    }
  }

  Future<void> _onCreate(
    CreateFolderEvent event,
    Emitter<FoldersState> emit,
  ) async {
    await createFolderUseCase(
      event.name,
      event.color,
      isPrivate: event.isPrivate,
    );
    await _onLoad(LoadFoldersEvent(), emit);
  }

  Future<void> _onRename(
    RenameFolderEvent event,
    Emitter<FoldersState> emit,
  ) async {
    await renameFolderUseCase(event.folderId, event.name);
    await _onLoad(LoadFoldersEvent(), emit);
  }

  Future<void> _onDelete(
    DeleteFolderEvent event,
    Emitter<FoldersState> emit,
  ) async {
    await deleteFolderUseCase(event.folderId);
    await _onLoad(LoadFoldersEvent(), emit);
  }
}
