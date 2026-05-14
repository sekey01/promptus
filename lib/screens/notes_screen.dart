import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_typography.dart';
import '../models/note_model.dart';
import '../services/database_service.dart';
import 'folder_notes_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final folders = db.folders;
    final generalCount = db.noteCount(null);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Folders',
              style: AppTypography.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.45),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // Folder list
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                // First item = General pseudo-folder
                if (i == 0) {
                  return _FolderRow(
                    name: 'General',
                    color: AppColors.textSecondary,
                    count: generalCount,
                    dark: dark,
                    cs: cs,
                    isFirst: true,
                    isLast: folders.isEmpty,
                    onTap: () => _openFolder(context, null, 'General'),
                  )
                      .animate(delay: (i * 40).ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.06, end: 0);
                }
                final f = folders[i - 1];
                return Dismissible(
                  key: ValueKey(f.id),
                  direction: DismissDirection.endToStart,
                  background: _dismissBg(),
                  confirmDismiss: (_) => _confirmDelete(context, f.name),
                  onDismissed: (_) =>
                      context.read<DatabaseService>().deleteFolder(f.id!),
                  child: _FolderRow(
                    name: f.name,
                    color: Color(f.colorValue),
                    count: db.noteCount(f.id),
                    dark: dark,
                    cs: cs,
                    isFirst: false,
                    isLast: i == folders.length,
                    onTap: () => _openFolder(context, f.id, f.name),
                  )
                      .animate(delay: (i * 40).ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.06, end: 0),
                );
              },
              childCount: folders.length + 1,
            ),
          ),
        ),

        // All-notes count footer
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              '${db.notes.length} note${db.notes.length == 1 ? '' : 's'}',
              style: AppTypography.bodySmall.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _openFolder(BuildContext ctx, int? folderId, String name) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) =>
            FolderNotesScreen(folderId: folderId, folderName: name),
      ),
    );
  }

  Widget _dismissBg() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: AppRadius.lgBR,
        ),
        child: const Icon(Iconsax.trash, color: Colors.white, size: 22),
      );

  Future<bool> _confirmDelete(BuildContext ctx, String name) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: Text('Delete "$name"?', style: AppTypography.titleLarge),
            content: Text(
              'Notes inside will move to General.',
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _FolderRow extends StatelessWidget {
  final String name;
  final Color color;
  final int count;
  final bool dark;
  final ColorScheme cs;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _FolderRow({
    required this.name,
    required this.color,
    required this.count,
    required this.dark,
    required this.cs,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(14) : Radius.zero,
      bottom: isLast ? const Radius.circular(14) : Radius.zero,
    );

    return Column(
      children: [
        Material(
          color: dark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: AppRadius.smBR,
                    ),
                    child: Icon(Iconsax.folder_2, color: color, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(name,
                        style: AppTypography.bodyMedium
                            .copyWith(color: cs.onSurface)),
                  ),
                  Text(
                    '$count',
                    style: AppTypography.bodyMedium.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(width: 8),
                  Icon(Iconsax.arrow_right_3,
                      size: 16,
                      color: cs.onSurface.withValues(alpha: 0.35)),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 64),
            child: Divider(
              height: 1,
              color: dark
                  ? AppColors.darkDivider
                  : AppColors.divider,
            ),
          ),
      ],
    );
  }
}

// ── New Folder Sheet ──────────────────────────────────────────────────────────

class NewFolderSheet extends StatefulWidget {
  const NewFolderSheet({super.key});

  @override
  State<NewFolderSheet> createState() => _NewFolderSheetState();
}

class _NewFolderSheetState extends State<NewFolderSheet> {
  final _ctrl = TextEditingController();
  int _colorValue = 0xFF6366F1;

  static const _palette = [
    0xFF6366F1, // indigo
    0xFF8B5CF6, // violet
    0xFF3B82F6, // blue
    0xFF10B981, // green
    0xFFF59E0B, // amber
    0xFFEF4444, // red
    0xFFEC4899, // pink
    0xFF6B7280, // gray
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    final db = context.read<DatabaseService>();
    await db.addFolder(NoteFolder(name: name, colorValue: _colorValue));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : AppColors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('New Folder',
                style: AppTypography.titleLarge
                    .copyWith(color: cs.onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: AppTypography.bodyLarge.copyWith(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Folder name',
                hintStyle: AppTypography.bodyLarge.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35)),
                filled: true,
                fillColor:
                    dark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: AppRadius.mdBR,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 16),
            // Color palette
            Wrap(
              spacing: 10,
              children: _palette.map((c) {
                final selected = c == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = c),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? cs.onSurface : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _create,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdBR),
                ),
                child: Text('Create Folder',
                    style: AppTypography.labelLarge
                        .copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
