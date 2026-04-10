import 'package:flutter/material.dart';
import 'package:vkpn/core/l10n/l10n_helpers.dart';
import 'package:vkpn/l10n/app_localizations.dart';

class VpnPanel extends StatelessWidget {
  const VpnPanel({
    super.key,
    required this.useTurnMode,
    required this.status,
    required this.statusColor,
    required this.configLoaded,
    required this.lastError,
    required this.rxBytesText,
    required this.txBytesText,
    required this.logsText,
    required this.logScrollController,
    required this.onModeChanged,
    required this.onConnect,
    required this.onDisconnect,
    required this.onCopyLogs,
    required this.onClearLogs,
    this.beforeConnect = const <Widget>[],
  });

  final bool useTurnMode;
  final String status;
  final Color statusColor;
  final bool configLoaded;
  final String? lastError;
  final String rxBytesText;
  final String txBytesText;
  final String logsText;
  final ScrollController logScrollController;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onCopyLogs;
  final VoidCallback onClearLogs;
  final List<Widget> beforeConnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xAA163063),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/vkpn_logo.png',
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.appTitle ?? 'VkPN',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  ToggleButtons(
                    isSelected: <bool>[!useTurnMode, useTurnMode],
                    borderRadius: BorderRadius.circular(10),
                    constraints: const BoxConstraints(minHeight: 30, minWidth: 68),
                    onPressed: (int index) => onModeChanged(index == 1),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          tr(context, 'modeWg', (l) => l.modeWg),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          tr(context, 'modeWgTurn', (l) => l.modeWgTurn),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!configLoaded)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              tr(context, 'wgConfigNotLoaded', (l) => l.wgConfigNotLoaded),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        if (lastError != null) ...<Widget>[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(lastError!, style: const TextStyle(color: Colors.red)),
          ),
        ],
        ...beforeConnect,
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                style: _buttonStyle(),
                onPressed: onConnect,
                child: Text(tr(context, 'connect', (l) => l.connect)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: _buttonStyle(),
                onPressed: onDisconnect,
                child: Text(tr(context, 'disconnect', (l) => l.disconnect)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x40132B57),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${tr(context, 'received', (l) => l.received)}: $rxBytesText',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${tr(context, 'sent', (l) => l.sent)}: $txBytesText',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.27 + 46,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: onCopyLogs,
                    child: Text(tr(context, 'copy', (l) => l.copy)),
                  ),
                  TextButton(
                    onPressed: onClearLogs,
                    child: Text(tr(context, 'clear', (l) => l.clear)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF020814),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      controller: logScrollController,
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        logsText,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF132B57),
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
