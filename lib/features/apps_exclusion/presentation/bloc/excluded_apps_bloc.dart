import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vkpn/features/apps_exclusion/data/installed_apps_loader.dart';
import 'package:vkpn/features/apps_exclusion/domain/entities/installed_app.dart';

import 'excluded_apps_event.dart';
import 'excluded_apps_state.dart';

class ExcludedAppsBloc extends Bloc<ExcludedAppsEvent, ExcludedAppsState> {
  ExcludedAppsBloc() : super(const ExcludedAppsState()) {
    on<ExcludedAppsStarted>(_onStarted);
    on<ExcludedAppsSearchChanged>(_onSearchChanged);
    on<ExcludedAppsToggled>(_onToggled);
    on<ExcludedAppsManualIdAdded>(_onManualIdAdded);
    on<ExcludedAppsManualEntryRemoved>(_onManualEntryRemoved);
    on<ExcludedAppsManualEntryUpdated>(_onManualEntryUpdated);
  }

  Future<void> _onStarted(
    ExcludedAppsStarted event,
    Emitter<ExcludedAppsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ExcludedAppsStatus.loading,
        selectedIds: Set<String>.from(event.initialIds),
        clearLoadError: true,
      ),
    );
    try {
      if (!event.loadInstalledList) {
        emit(
          state.copyWith(
            status: ExcludedAppsStatus.success,
            apps: const <InstalledApp>[],
            clearLoadError: true,
          ),
        );
        return;
      }
      final apps = await InstalledAppsLoader.load();
      emit(
        state.copyWith(
          status: ExcludedAppsStatus.success,
          apps: apps,
          clearLoadError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExcludedAppsStatus.failure,
          loadErrorMessage: '$e',
          apps: const <InstalledApp>[],
        ),
      );
    }
  }

  void _onSearchChanged(
    ExcludedAppsSearchChanged event,
    Emitter<ExcludedAppsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onToggled(
    ExcludedAppsToggled event,
    Emitter<ExcludedAppsState> emit,
  ) {
    final next = Set<String>.from(state.selectedIds);
    if (event.selected) {
      next.add(event.id);
    } else {
      next.remove(event.id);
    }
    emit(state.copyWith(selectedIds: next));
  }

  void _onManualIdAdded(
    ExcludedAppsManualIdAdded event,
    Emitter<ExcludedAppsState> emit,
  ) {
    final t = event.rawId.trim();
    if (t.isEmpty) return;
    final next = Set<String>.from(state.selectedIds)..add(t);
    emit(state.copyWith(selectedIds: next));
  }

  void _onManualEntryRemoved(
    ExcludedAppsManualEntryRemoved event,
    Emitter<ExcludedAppsState> emit,
  ) {
    final next = Set<String>.from(state.selectedIds)..remove(event.entry);
    emit(state.copyWith(selectedIds: next));
  }

  void _onManualEntryUpdated(
    ExcludedAppsManualEntryUpdated event,
    Emitter<ExcludedAppsState> emit,
  ) {
    final from = event.from.trim();
    final to = event.to.trim();
    if (from.isEmpty || to.isEmpty) {
      return;
    }
    final next = Set<String>.from(state.selectedIds)
      ..remove(from)
      ..add(to);
    emit(state.copyWith(selectedIds: next));
  }
}
