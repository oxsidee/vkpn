import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vkpn/core/l10n/l10n_helpers.dart';
import 'package:vkpn/features/apps_exclusion/domain/entities/installed_app.dart';
import 'package:vkpn/features/apps_exclusion/presentation/bloc/excluded_apps_bloc.dart';
import 'package:vkpn/features/apps_exclusion/presentation/bloc/excluded_apps_event.dart';
import 'package:vkpn/features/apps_exclusion/presentation/bloc/excluded_apps_state.dart';
import 'package:vkpn/l10n/app_localizations.dart';

class ExcludedAppsSheet extends StatelessWidget {
  const ExcludedAppsSheet({super.key, required this.initialIds, required this.isIos});

  final Set<String> initialIds;
  final bool isIos;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExcludedAppsBloc()..add(ExcludedAppsStarted(initialIds)),
      child: _ExcludedAppsSheetView(isIos: isIos),
    );
  }
}

class _ExcludedAppsSheetView extends StatefulWidget {
  const _ExcludedAppsSheetView({required this.isIos});

  final bool isIos;

  @override
  State<_ExcludedAppsSheetView> createState() => _ExcludedAppsSheetViewState();
}

class _ExcludedAppsSheetViewState extends State<_ExcludedAppsSheetView> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _manualCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (!mounted) return;
      context.read<ExcludedAppsBloc>().add(
        ExcludedAppsSearchChanged(_searchCtrl.text),
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _submitManual() {
    context.read<ExcludedAppsBloc>().add(
      ExcludedAppsManualIdAdded(_manualCtrl.text),
    );
    _manualCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height * 0.82;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      tr(context, 'excludeFromVpn', (l) => l.excludeFromVpn),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (widget.isIos)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  tr(context, 'iosAppsListDisabled', (l) => l.iosAppsListDisabled),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: tr(context, 'search', (l) => l.search),
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _manualCtrl,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: tr(
                          context,
                          'addIdManual',
                          (l) => l.addIdManual,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _submitManual(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submitManual,
                    child: Text(tr(context, 'add', (l) => l.add)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<ExcludedAppsBloc, ExcludedAppsState>(
                builder: (BuildContext context, ExcludedAppsState state) {
                  switch (state.status) {
                    case ExcludedAppsStatus.initial:
                    case ExcludedAppsStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case ExcludedAppsStatus.failure:
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            AppLocalizations.of(context)!.couldNotLoadList(
                              state.loadErrorMessage ?? '',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      );
                    case ExcludedAppsStatus.success:
                      final List<InstalledApp> shown = state.filteredApps;
                      if (shown.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              tr(
                                context,
                                'noMatchingApps',
                                (l) => l.noMatchingApps,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: shown.length,
                        itemBuilder: (BuildContext context, int i) {
                          final InstalledApp app = shown[i];
                          final bool checked = state.selectedIds.contains(
                            app.id,
                          );
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (bool? v) {
                              context.read<ExcludedAppsBloc>().add(
                                ExcludedAppsToggled(
                                  id: app.id,
                                  selected: v == true,
                                ),
                              );
                            },
                            title: Text(
                              app.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              app.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(tr(context, 'cancel', (l) => l.cancel)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BlocBuilder<ExcludedAppsBloc, ExcludedAppsState>(
                      buildWhen: (ExcludedAppsState p, ExcludedAppsState c) =>
                          p.selectedIds != c.selectedIds,
                      builder: (BuildContext context, ExcludedAppsState state) {
                        return FilledButton(
                          onPressed: () =>
                              Navigator.of(context).pop(state.selectedIds),
                          child: Text(tr(context, 'apply', (l) => l.apply)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
