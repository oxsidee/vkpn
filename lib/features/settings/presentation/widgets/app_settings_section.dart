import 'package:flutter/material.dart';
import 'package:vkpn/core/l10n/l10n_helpers.dart';

class AppSettingsSection extends StatelessWidget {
  const AppSettingsSection({
    super.key,
    required this.localeCode,
    required this.customArbContent,
    required this.proxyPortCtrl,
    required this.threadsCtrl,
    required this.useUdp,
    required this.excludedAppsSummary,
    required this.onSetLocaleCode,
    required this.onPickCustomArb,
    required this.onExportCustomArb,
    required this.onClearCustomArb,
    required this.onUseUdpChanged,
    required this.onOpenExcludedAppsPicker,
  });

  final String? localeCode;
  final String? customArbContent;
  final TextEditingController proxyPortCtrl;
  final TextEditingController threadsCtrl;
  final bool useUdp;
  final String excludedAppsSummary;
  final ValueChanged<String?> onSetLocaleCode;
  final VoidCallback onPickCustomArb;
  final VoidCallback onExportCustomArb;
  final VoidCallback onClearCustomArb;
  final ValueChanged<bool> onUseUdpChanged;
  final VoidCallback onOpenExcludedAppsPicker;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            tr(context, 'appSettingsSection', (l) => l.appSettingsSection),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr(context, 'language', (l) => l.language),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButton<String?>(
              value: localeCode,
              isExpanded: true,
              items: <DropdownMenuItem<String?>>[
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(tr(context, 'langSystem', (l) => l.langSystem)),
                ),
                DropdownMenuItem<String?>(
                  value: 'en',
                  child: Text(tr(context, 'langEnglish', (l) => l.langEnglish)),
                ),
                DropdownMenuItem<String?>(
                  value: 'ru',
                  child: Text(tr(context, 'langRussian', (l) => l.langRussian)),
                ),
                if ((customArbContent ?? '').trim().isNotEmpty)
                  DropdownMenuItem<String?>(
                    value: 'custom',
                    child: Text(
                      tr(context, 'langCustomArb', (l) => l.langCustomArb),
                    ),
                  ),
              ],
              onChanged: onSetLocaleCode,
              underline: const SizedBox.shrink(),
            ),
            const SizedBox(height: 6),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: const Color(0xFF132B57),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onPickCustomArb,
              child: Text(tr(context, 'loadCustomArb', (l) => l.loadCustomArb)),
            ),
            TextButton(
              onPressed: onExportCustomArb,
              child: Text(tr(context, 'exportCustomArb', (l) => l.exportCustomArb)),
            ),
            TextButton(
              onPressed: customArbContent == null ? null : onClearCustomArb,
              child: Text(tr(context, 'clearCustomArb', (l) => l.clearCustomArb)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          initiallyExpanded: false,
          title: Text(
            tr(context, 'advancedSection', (l) => l.advancedSection),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _fieldTitle(tr(context, 'proxyPort', (l) => l.proxyPort)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: proxyPortCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '56000'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _fieldTitle(tr(context, 'threads', (l) => l.threads)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: threadsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '8'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(context, 'useUdp', (l) => l.useUdp)),
              value: useUdp,
              onChanged: onUseUdpChanged,
            ),
            const SizedBox(height: 8),
            _fieldTitle(tr(context, 'excludedAppsTitle', (l) => l.excludedAppsTitle)),
            const SizedBox(height: 4),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF132B57),
                side: BorderSide.none,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onOpenExcludedAppsPicker,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.apps_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tr(context, 'selectInstalledApps', (l) => l.selectInstalledApps),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                excludedAppsSummary,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }

  Widget _fieldTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
