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
import 'add_note_screen.dart';

class FolderNotesScreen extends StatelessWidget {
  final int? folderId;
  final String folderName;

  const FolderNotesScreen(
      {super.key, required this.folderId, required this.folderName});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<DatabaseService>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final notes = db.notesInFolder(folderId);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              folderName,
              style: AppTypography.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '${notes.length} note${notes.length == 1 ? '' : 's'}',
              style: AppTypography.labelSmall.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45)),
            ),
          ],
        ),
      ),
      body: notes.isEmpty
          ? _EmptyNotes(cs: cs)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final note = notes[i];
                return _NoteCard(
                  note: note,
                  dark: dark,
                  cs: cs,
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => AddNoteScreen(note: note),
                    ),
                  ),
                  onDelete: () =>
                      context.read<DatabaseService>().deleteNote(note.id!),
                )
                    .animate(delay: (i * 40).ms)
                    .fadeIn(duration: 280.ms)
                    .slideY(begin: 0.05, end: 0);
              },
            ),
      floatingActionButton: _Fab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddNoteScreen(initialFolderId: folderId),
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final bool dark;
  final ColorScheme cs;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.dark,
    required this.cs,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: AppRadius.lgBR,
        ),
        child: const Icon(Iconsax.trash, color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Delete note?', style: AppTypography.titleLarge),
                content: Text('This cannot be undone.',
                    style: AppTypography.bodyMedium),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: Material(
        color: dark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.lgBR,
        child: InkWell(
          borderRadius: AppRadius.lgBR,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (note.isPinned) ...[
                      Icon(Iconsax.link5,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        note.title,
                        style: AppTypography.titleMedium
                            .copyWith(color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.reminderTime != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Iconsax.notification,
                            size: 14,
                            color: cs.onSurface.withValues(alpha: 0.45)),
                      ),
                  ],
                ),
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    style: AppTypography.bodySmall.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatDate(note.updatedAt),
                  style: AppTypography.labelSmall.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.35)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _EmptyNotes extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyNotes({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.note_text,
              size: 56, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No notes yet',
              style: AppTypography.titleMedium
                  .copyWith(color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 6),
          Text('Tap + to write your first note',
              style: AppTypography.bodySmall
                  .copyWith(color: cs.onSurface.withValues(alpha: 0.3))),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(
            begin: const Offset(0.9, 0.9),
            curve: Curves.easeOutBack,
          ),
    );
  }
}

class _Fab extends StatelessWidget {
  final VoidCallback onPressed;
  const _Fab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      icon: const Icon(Iconsax.add, size: 22),
      label: Text(
        'New Note',
        style: AppTypography.labelLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBR),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}
