import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vkpn/features/profiles/domain/entities/wg_tunnel_profile.dart';
import 'package:vkpn/features/profiles/domain/usecases/add_profile_usecase.dart';
import 'package:vkpn/features/profiles/domain/usecases/delete_active_profile_usecase.dart';
import 'package:vkpn/features/profiles/domain/usecases/duplicate_active_profile_usecase.dart';
import 'package:vkpn/features/profiles/domain/usecases/rename_active_profile_usecase.dart';
import 'package:vkpn/features/profiles/domain/usecases/switch_profile_usecase.dart';

import 'profiles_state.dart';

class ProfilesCubit extends Cubit<ProfilesState> {
  ProfilesCubit({
    SwitchProfileUseCase? switchProfileUseCase,
    AddProfileUseCase? addProfileUseCase,
    RenameActiveProfileUseCase? renameActiveProfileUseCase,
    DuplicateActiveProfileUseCase? duplicateActiveProfileUseCase,
    DeleteActiveProfileUseCase? deleteActiveProfileUseCase,
  }) : _switchProfileUsecase = switchProfileUseCase ?? SwitchProfileUseCase(),
       _addProfileUsecase = addProfileUseCase ?? AddProfileUseCase(),
       _renameActiveProfileUsecase =
           renameActiveProfileUseCase ?? RenameActiveProfileUseCase(),
       _duplicateActiveProfileUsecase =
           duplicateActiveProfileUseCase ?? DuplicateActiveProfileUseCase(),
       _deleteActiveProfileUsecase =
           deleteActiveProfileUseCase ?? DeleteActiveProfileUseCase(),
       super(const ProfilesState());

  final SwitchProfileUseCase _switchProfileUsecase;
  final AddProfileUseCase _addProfileUsecase;
  final RenameActiveProfileUseCase _renameActiveProfileUsecase;
  final DuplicateActiveProfileUseCase _duplicateActiveProfileUsecase;
  final DeleteActiveProfileUseCase _deleteActiveProfileUsecase;

  String _newProfileId() => 'p_${DateTime.now().millisecondsSinceEpoch}';

  void hydrate({
    required List<WgTunnelProfile> profiles,
    required String? activeProfileId,
    required String wgConfigText,
    required String? configFileName,
  }) {
    emit(
      state.copyWith(
        profiles: profiles,
        activeProfileId: activeProfileId,
        wgConfigText: wgConfigText,
        configFileName: configFileName,
      ),
    );
  }

  void switchProfile(String id) {
    if (state.activeProfileId == id) return;
    final r = _switchProfileUsecase(
      profiles: state.profiles,
      activeProfileId: state.activeProfileId,
      targetProfileId: id,
      currentWgConfigText: state.wgConfigText,
      currentWgConfigFileName: state.configFileName,
    );
    emit(
      state.copyWith(
        profiles: r.profiles,
        activeProfileId: r.activeProfileId,
        wgConfigText: r.wgConfigText,
        configFileName: r.wgConfigFileName,
        clearConfigFileName: r.wgConfigFileName == null,
      ),
    );
  }

  void addProfile() {
    final r = _addProfileUsecase(
      profiles: state.profiles,
      activeProfileId: state.activeProfileId,
      currentWgConfigText: state.wgConfigText,
      currentWgConfigFileName: state.configFileName,
      newProfileId: _newProfileId(),
    );
    emit(
      state.copyWith(
        profiles: r.profiles,
        activeProfileId: r.activeProfileId,
        wgConfigText: '',
        clearConfigFileName: true,
      ),
    );
  }

  void renameActiveProfile(String trimmedName) {
    final next = _renameActiveProfileUsecase(
      profiles: state.profiles,
      activeProfileId: state.activeProfileId,
      currentWgConfigText: state.wgConfigText,
      currentWgConfigFileName: state.configFileName,
      trimmedName: trimmedName,
    );
    if (next == null) return;
    emit(state.copyWith(profiles: next));
  }

  void duplicateProfile() {
    final r = _duplicateActiveProfileUsecase(
      profiles: state.profiles,
      activeProfileId: state.activeProfileId,
      currentWgConfigText: state.wgConfigText,
      currentWgConfigFileName: state.configFileName,
      newProfileId: _newProfileId(),
    );
    if (r == null) return;
    emit(
      state.copyWith(
        profiles: r.profiles,
        activeProfileId: r.activeProfileId,
      ),
    );
  }

  void deleteProfile() {
    final r = _deleteActiveProfileUsecase(
      profiles: state.profiles,
      activeProfileId: state.activeProfileId,
      currentWgConfigText: state.wgConfigText,
      currentWgConfigFileName: state.configFileName,
    );
    if (r == null) return;
    emit(
      state.copyWith(
        profiles: r.profiles,
        activeProfileId: r.activeProfileId,
        wgConfigText: r.wgConfigText,
        configFileName: r.wgConfigFileName,
        clearConfigFileName: r.wgConfigFileName == null,
      ),
    );
  }
}
