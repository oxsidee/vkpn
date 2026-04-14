import 'package:equatable/equatable.dart';

sealed class ExcludedAppsEvent extends Equatable {
  const ExcludedAppsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class ExcludedAppsStarted extends ExcludedAppsEvent {
  const ExcludedAppsStarted(this.initialIds, {this.loadInstalledList = true});

  final Set<String> initialIds;

  /// Windows: no useful installed-app list for WG bypass; use manual hostnames/IPs only.
  final bool loadInstalledList;

  @override
  List<Object?> get props => <Object?>[initialIds, loadInstalledList];
}

final class ExcludedAppsSearchChanged extends ExcludedAppsEvent {
  const ExcludedAppsSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

final class ExcludedAppsToggled extends ExcludedAppsEvent {
  const ExcludedAppsToggled({required this.id, required this.selected});

  final String id;
  final bool selected;

  @override
  List<Object?> get props => <Object?>[id, selected];
}

final class ExcludedAppsManualIdAdded extends ExcludedAppsEvent {
  const ExcludedAppsManualIdAdded(this.rawId);

  final String rawId;

  @override
  List<Object?> get props => <Object?>[rawId];
}

final class ExcludedAppsManualEntryRemoved extends ExcludedAppsEvent {
  const ExcludedAppsManualEntryRemoved(this.entry);

  final String entry;

  @override
  List<Object?> get props => <Object?>[entry];
}

final class ExcludedAppsManualEntryUpdated extends ExcludedAppsEvent {
  const ExcludedAppsManualEntryUpdated({required this.from, required this.to});

  final String from;
  final String to;

  @override
  List<Object?> get props => <Object?>[from, to];
}
