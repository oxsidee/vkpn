import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_form_state.dart';

class SettingsFormCubit extends Cubit<SettingsFormState> {
  SettingsFormCubit() : super(const SettingsFormState());

  void hydrate(SettingsFormState state) => emit(state);

  void applySnapshot({
    required String vkCallLink,
    required String proxyPortText,
    required String threadsText,
    required String excludedAppPackages,
  }) {
    emit(
      state.copyWith(
        vkCallLink: vkCallLink,
        proxyPortText: proxyPortText,
        threadsText: threadsText,
        excludedAppPackages: excludedAppPackages,
      ),
    );
  }

  void setLocaleCode(String? code) => emit(state.copyWith(localeCode: code));
  void setUseUdp(bool v) => emit(state.copyWith(useUdp: v));
  void setUseTurnMode(bool v) => emit(state.copyWith(useTurnMode: v));
  void setCustomArbContent(String? content) => emit(
    state.copyWith(customArbContent: content, clearCustomArb: content == null),
  );
}
