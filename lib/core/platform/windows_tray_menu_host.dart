import 'dart:async';
import 'dart:io' show exit, Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vkpn/features/home/presentation/bloc/home_cubit.dart';
import 'package:vkpn/features/home/presentation/bloc/home_state.dart';
import 'package:vkpn/l10n/app_localizations.dart';

/// Синхронизирует контекстное меню трея с [HomeState] и локализацией.
class WindowsTrayMenuHost extends StatefulWidget {
  const WindowsTrayMenuHost({super.key, required this.child});

  final Widget child;

  @override
  State<WindowsTrayMenuHost> createState() => _WindowsTrayMenuHostState();
}

class _WindowsTrayMenuHostState extends State<WindowsTrayMenuHost> {
  Locale? _trackedLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_applyMenu(context));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Locale l = Localizations.localeOf(context);
    if (_trackedLocale != l) {
      _trackedLocale = l;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_applyMenu(context));
        }
      });
    }
  }

  Future<void> _applyMenu(BuildContext context) async {
    if (!Platform.isWindows) {
      return;
    }
    final AppLocalizations? l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return;
    }
    final HomeCubit cubit = context.read<HomeCubit>();
    final HomeState s = cubit.state;
    final bool connected = s.status.toLowerCase() == 'connected';

    final List<MenuItem> items = <MenuItem>[
      MenuItem(
        key: 'tray_status',
        label: connected ? l10n.trayStatusConnected : l10n.trayStatusDisconnected,
        disabled: true,
      ),
      MenuItem.separator(),
      if (!connected) ...<MenuItem>[
        MenuItem(
          key: 'tray_connect_wg',
          label: l10n.trayConnectWg,
          onClick: (_) {
            unawaited(cubit.connectWithTurnMode(false));
          },
        ),
        MenuItem(
          key: 'tray_connect_turn',
          label: l10n.trayConnectWgTurn,
          onClick: (_) {
            unawaited(cubit.connectWithTurnMode(true));
          },
        ),
      ],
      if (connected)
        MenuItem(
          key: 'tray_disconnect',
          label: l10n.disconnect,
          onClick: (_) {
            unawaited(cubit.disconnect());
          },
        ),
      MenuItem.separator(),
      MenuItem(
        key: 'tray_exit',
        label: l10n.trayExit,
        onClick: (_) async {
          await trayManager.destroy();
          exit(0);
        },
      ),
    ];

    await trayManager.setContextMenu(Menu(items: items));
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return widget.child;
    }
    return BlocListener<HomeCubit, HomeState>(
      listenWhen: (HomeState p, HomeState c) =>
          p.status != c.status ||
          p.localeCode != c.localeCode ||
          p.useTurnMode != c.useTurnMode,
      listener: (BuildContext context, HomeState _) {
        unawaited(_applyMenu(context));
      },
      child: widget.child,
    );
  }
}
