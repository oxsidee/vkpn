import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vkpn/core/l10n/l10n_helpers.dart';
import 'package:vkpn/features/profiles/domain/entities/wg_tunnel_profile.dart';

class ProfileSwitcher extends StatelessWidget {
  const ProfileSwitcher({
    super.key,
    required this.profiles,
    required this.activeProfileId,
    required this.onSwitchProfile,
    required this.onAddProfile,
    required this.onRenameProfile,
    required this.onDuplicateProfile,
    required this.onDeleteProfile,
  });

  final List<WgTunnelProfile> profiles;
  final String? activeProfileId;
  final Future<void> Function(String id) onSwitchProfile;
  final VoidCallback onAddProfile;
  final Future<void> Function() onRenameProfile;
  final Future<void> Function() onDuplicateProfile;
  final Future<void> Function() onDeleteProfile;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return const SizedBox.shrink();
    }
    final bool canDelete = profiles.length > 1;
    // Кружки сверху справа: при одном профиле — дубль, редактировать; иначе — удалить, дубль, редактировать.
    const double circleSlot = 32;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _fieldTitle(tr(context, 'profilesSection', (l) => l.profilesSection)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final WgTunnelProfile p in profiles)
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 10),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => unawaited(onSwitchProfile(p.id)),
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: activeProfileId == p.id
                                  ? const Color(0xFF1C3C75)
                                  : const Color(0xFF132B57),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: activeProfileId == p.id
                                    ? Colors.lightBlueAccent
                                    : Colors.white24,
                              ),
                            ),
                            child: Text(
                              p.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        if (canDelete)
                          Positioned(
                            top: -10,
                            right: -10,
                            child: _ProfileActionCircle(
                              icon: Icons.delete_outline,
                              tooltip: tr(
                                context,
                                'deleteProfile',
                                (l) => l.deleteProfile,
                              ),
                              onPressed: () {
                                unawaited(
                                  _runForProfile(p.id, onDeleteProfile),
                                );
                              },
                            ),
                          ),
                        Positioned(
                          top: -10,
                          right: canDelete ? circleSlot - 10 : -10,
                          child: _ProfileActionCircle(
                            icon: Icons.copy_all_outlined,
                            tooltip: tr(
                              context,
                              'duplicateProfile',
                              (l) => l.duplicateProfile,
                            ),
                            onPressed: () {
                              unawaited(
                                _runForProfile(p.id, onDuplicateProfile),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -10,
                          right: canDelete
                              ? circleSlot * 2 - 10
                              : circleSlot - 10,
                          child: _ProfileActionCircle(
                            icon: Icons.edit_outlined,
                            tooltip: tr(
                              context,
                              'renameProfile',
                              (l) => l.renameProfile,
                            ),
                            onPressed: () {
                              unawaited(_runForProfile(p.id, onRenameProfile));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  onPressed: onAddProfile,
                  tooltip: tr(context, 'addProfile', (l) => l.addProfile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runForProfile(
    String profileId,
    Future<void> Function() action,
  ) async {
    if (activeProfileId != profileId) {
      await onSwitchProfile(profileId);
    }
    await action();
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

class _ProfileActionCircle extends StatelessWidget {
  const _ProfileActionCircle({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0E234A),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Icon(icon, size: 16),
          ),
        ),
      ),
    );
  }
}
