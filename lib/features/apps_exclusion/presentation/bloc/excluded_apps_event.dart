import 'package:equatable/equatable.dart';

sealed class ExcludedAppsEvent extends Equatable {
  const ExcludedAppsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class ExcludedAppsStarted extends ExcludedAppsEvent {
  const ExcludedAppsStarted(this.initialIds);

  final Set<String> initialIds;

  @override
  List<Object?> get props => <Object?>[initialIds];
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
