import 'package:equatable/equatable.dart';
import 'package:vkpn/features/apps_exclusion/domain/entities/installed_app.dart';

enum ExcludedAppsStatus { initial, loading, success, failure }

class ExcludedAppsState extends Equatable {
  const ExcludedAppsState({
    this.status = ExcludedAppsStatus.initial,
    this.apps = const <InstalledApp>[],
    this.loadErrorMessage,
    this.selectedIds = const <String>{},
    this.searchQuery = '',
  });

  final ExcludedAppsStatus status;
  final List<InstalledApp> apps;
  final String? loadErrorMessage;
  final Set<String> selectedIds;
  final String searchQuery;

  List<InstalledApp> get filteredApps {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return apps;
    return apps
        .where(
          (InstalledApp a) =>
              a.label.toLowerCase().contains(q) ||
              a.id.toLowerCase().contains(q),
        )
        .toList();
  }

  ExcludedAppsState copyWith({
    ExcludedAppsStatus? status,
    List<InstalledApp>? apps,
    String? loadErrorMessage,
    bool clearLoadError = false,
    Set<String>? selectedIds,
    String? searchQuery,
  }) {
    return ExcludedAppsState(
      status: status ?? this.status,
      apps: apps ?? this.apps,
      loadErrorMessage: clearLoadError
          ? null
          : (loadErrorMessage ?? this.loadErrorMessage),
      selectedIds: selectedIds ?? this.selectedIds,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    apps,
    loadErrorMessage,
    selectedIds,
    searchQuery,
  ];
}
