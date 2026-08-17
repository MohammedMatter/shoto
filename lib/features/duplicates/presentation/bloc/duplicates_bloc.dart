import 'package:shoto/core/localization/app_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/features/duplicates/domain/entities/duplicate_group.dart';
import 'package:shoto/features/duplicates/domain/use_cases/delete_duplicates_use_case.dart';
import 'package:shoto/features/duplicates/domain/use_cases/find_duplicates_use_case.dart';
import 'package:shoto/features/duplicates/presentation/bloc/duplicates_event.dart';
import 'package:shoto/features/duplicates/presentation/bloc/duplicates_state.dart';

class DuplicatesBloc extends Bloc<DuplicatesEvent, DuplicatesState> {
  final FindDuplicatesUseCase findDuplicatesUseCase;
  final DeleteDuplicatesUseCase deleteDuplicatesUseCase;

  DuplicatesBloc({
    required this.findDuplicatesUseCase,
    required this.deleteDuplicatesUseCase,
  }) : super(DuplicatesInitialState()) {
    on<ScanForDuplicatesEvent>(_onScan);
    on<ScanProgressEvent>(_onProgress);
    on<ToggleCandidateEvent>(_onToggleCandidate);
    on<ResetGroupSelectionEvent>(_onResetGroup);
    on<KeepEntireGroupEvent>(_onKeepGroup);
    on<DeleteSelectedDuplicatesEvent>(_onDelete);
  }

  Future<void> _onScan(
    ScanForDuplicatesEvent event,
    Emitter<DuplicatesState> emit,
  ) async {
    emit(DuplicatesScanningState());
    try {
      final List<DuplicateGroup> groups = await findDuplicatesUseCase(
        // Routed back through the event queue rather than emitted directly:
        // the callback fires from inside the repository's async loop, where
        // this handler's `emit` may already have completed.
        onProgress: (processed, total) =>
            add(ScanProgressEvent(processed, total)),
      );
      emit(
        DuplicatesLoadedState(
          groups: groups,
          selectedIds: _defaultSelection(groups),
        ),
      );
    } catch (error) {
      emit(DuplicatesErrorState(AppMessage.scanDuplicates));
    }
  }

  void _onProgress(ScanProgressEvent event, Emitter<DuplicatesState> emit) {
    // Ignore late progress events that arrive after the scan resolved.
    if (state is! DuplicatesScanningState) return;
    emit(
      DuplicatesScanningState(processed: event.processed, total: event.total),
    );
  }

  void _onToggleCandidate(
    ToggleCandidateEvent event,
    Emitter<DuplicatesState> emit,
  ) {
    final DuplicatesState current = state;
    if (current is! DuplicatesLoadedState) return;

    final Set<String> selected = Set<String>.from(current.selectedIds);
    if (!selected.remove(event.assetId)) selected.add(event.assetId);
    emit(current.copyWith(selectedIds: selected));
  }

  void _onResetGroup(
    ResetGroupSelectionEvent event,
    Emitter<DuplicatesState> emit,
  ) {
    final DuplicatesState current = state;
    if (current is! DuplicatesLoadedState) return;

    final DuplicateGroup? group = _groupById(current, event.groupId);
    if (group == null) return;

    final Set<String> selected = Set<String>.from(current.selectedIds);
    for (final DuplicateCandidate candidate in group.candidates) {
      if (candidate.id == group.suggestedKeeperId) {
        selected.remove(candidate.id);
      } else {
        selected.add(candidate.id);
      }
    }
    emit(current.copyWith(selectedIds: selected));
  }

  void _onKeepGroup(KeepEntireGroupEvent event, Emitter<DuplicatesState> emit) {
    final DuplicatesState current = state;
    if (current is! DuplicatesLoadedState) return;

    final DuplicateGroup? group = _groupById(current, event.groupId);
    if (group == null) return;

    final Set<String> selected = Set<String>.from(current.selectedIds)
      ..removeAll(group.candidates.map((candidate) => candidate.id));
    emit(current.copyWith(selectedIds: selected));
  }

  Future<void> _onDelete(
    DeleteSelectedDuplicatesEvent event,
    Emitter<DuplicatesState> emit,
  ) async {
    final DuplicatesState current = state;
    if (current is! DuplicatesLoadedState || current.selectedIds.isEmpty) {
      return;
    }

    emit(current.copyWith(isDeleting: true));

    try {
      // Counted from what went, not from what was selected. The confirmation
      // used to read "Deleted 5 · freed 12 MB" after the user pressed Deny on
      // the system prompt and nothing at all had been removed — a number the
      // app had no basis for, about storage the user did not get back.
      final Set<String> deleted = (await deleteDuplicatesUseCase(
        current.selectedIds.toList(),
      )).toSet();

      if (deleted.isEmpty) {
        emit(current.copyWith(isDeleting: false));
        return;
      }

      emit(
        DuplicatesDeletedState(
          deletedCount: deleted.length,
          freedBytes: current.bytesOf(deleted),
        ),
      );
    } catch (error) {
      emit(DuplicatesErrorState(AppMessage.deleteSelected));
    }
  }

  /// Everything except each group's suggested keeper starts pre-selected —
  /// the common case is "yes, remove the extra copies", but the user can
  /// still change any of it before confirming.
  Set<String> _defaultSelection(List<DuplicateGroup> groups) {
    final Set<String> selected = {};
    for (final DuplicateGroup group in groups) {
      for (final DuplicateCandidate candidate in group.candidates) {
        if (candidate.id != group.suggestedKeeperId) selected.add(candidate.id);
      }
    }
    return selected;
  }

  DuplicateGroup? _groupById(DuplicatesLoadedState state, String groupId) {
    for (final DuplicateGroup group in state.groups) {
      if (group.id == groupId) return group;
    }
    return null;
  }
}
