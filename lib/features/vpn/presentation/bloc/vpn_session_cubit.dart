import 'package:flutter_bloc/flutter_bloc.dart';

import 'vpn_session_state.dart';

class VpnSessionCubit extends Cubit<VpnSessionState> {
  VpnSessionCubit() : super(const VpnSessionState());

  void hydrate(VpnSessionState state) => emit(state);
}
