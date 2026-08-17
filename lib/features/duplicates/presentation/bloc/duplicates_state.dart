import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/features/duplicates/domain/entities/duplicate_group.dart';

/// Sealed — see `docs/decisions/screen-states.md`.
sealed class DuplicatesState {}

class DuplicatesInitialState extends DuplicatesState {}

class DuplicatesScanningState extends DuplicatesState {
  final int processed;
  final int total;
  DuplicatesScanningState({this.processed = 0, this.total = 0});

  double get fraction => total == 0 ? 0 : processed / total;
}

class DuplicatesLoadedState extends DuplicatesState {
  final List<DuplicateGroup> groups;

  /// Asset ids currently marked for deletion, across all groups.
  final Set<String> selectedIds;

  final bool isDeleting;

  DuplicatesLoadedState({
    required this.groups,
    required this.selectedIds,
    this.isDeleting = false,
  });

  bool get hasDuplicates => groups.isNotEmpty;

  int get selectedCount => selectedIds.length;

  /// Space reclaimed by deleting exactly what's currently selected.
  int get selectedBytes => bytesOf(selectedIds);

  /// Space taken by [ids], whichever ids those are.
  ///
  /// Split out from [selectedBytes] because what the user *selected* and what
  /// was *deleted* are not the same set once the system delete prompt is
  /// allowed to be refused, and the confirmation has to report the second.
  int bytesOf(Set<String> ids) {
    int total = 0;
    for (final DuplicateGroup group in groups) {
      for (final DuplicateCandidate candidate in group.candidates) {
        if (ids.contains(candidate.id)) total += candidate.fileSizeBytes;
      }
    }
    return total;
  }

  DuplicatesLoadedState copyWith({
    List<DuplicateGroup>? groups,
    Set<String>? selectedIds,
    bool? isDeleting,
  }) {
    return DuplicatesLoadedState(
      groups: groups ?? this.groups,
      selectedIds: selectedIds ?? this.selectedIds,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}

class DuplicatesErrorState extends DuplicatesState {
  final AppMessage message;
  DuplicatesErrorState(this.message);
}

/// One-shot state after a successful cleanup, so the page can show a
/// confirmation before returning to the (now re-scanned) list.
class DuplicatesDeletedState extends DuplicatesState {
  final int deletedCount;
  final int freedBytes;
  DuplicatesDeletedState({
    required this.deletedCount,
    required this.freedBytes,
  });
}
