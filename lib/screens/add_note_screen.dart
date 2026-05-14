import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../models/note_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/note_bottom_bar.dart';
import '../widgets/note_floating_toolbar.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class AddNoteScreen extends StatefulWidget {
  final Note? note;
  final int? initialFolderId;

  const AddNoteScreen({super.key, this.note, this.initialFolderId});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  // ── Controllers & keys ───────────────────────────────────────────────────
  late final QuillController _quill;
  late final TextEditingController _titleCtrl;
  final ScrollController _scroll = ScrollController();
  final FocusNode _editorFocus = FocusNode();
  final FocusNode _titleFocus = FocusNode();
  final GlobalKey _editorKey = GlobalKey();

  // ── Toolbar ───────────────────────────────────────────────────────────────
  final NoteSelectionToolbarController _toolbar =
      NoteSelectionToolbarController();

  // ── State ─────────────────────────────────────────────────────────────────
  int? _savedNoteId;
  int? _folderId;
  String _saveStatus = 'Saved';
  bool _showFind = false;
  Timer? _saveTimer;

  // ── Find & Replace ────────────────────────────────────────────────────────
  final TextEditingController _findCtrl = TextEditingController();
  final TextEditingController _replaceCtrl = TextEditingController();
  List<int> _matchOffsets = [];
  int _matchIdx = -1;

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _savedNoteId = widget.note?.id;
    _folderId = widget.note?.folderId ?? widget.initialFolderId;
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _initQuill();

    _quill.addListener(_onQuillChange);
    _titleCtrl.addListener(_scheduleAutoSave);
    _editorFocus.addListener(_onFocusChange);
  }

  // ── Quill init ─────────────────────────────────────────────────────────────

  void _initQuill() {
    final raw = widget.note?.content;
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        final delta = Delta.fromJson(list);
        _quill = QuillController(
          document: Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
        return;
      } catch (_) {
        // Old plain-text note — fall through to insert as plain text
      }
    }
    _quill = QuillController.basic();
    if (raw != null && raw.isNotEmpty && !raw.startsWith('[')) {
      // Insert legacy plain text at offset 0
      _quill.document.insert(0, raw);
    }
  }

  // ── Listeners ─────────────────────────────────────────────────────────────

  void _onQuillChange() {
    final sel = _quill.selection;
    final hasSelection = !sel.isCollapsed && sel.start < sel.end;

    if (hasSelection && _editorFocus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        _toolbar.show(
          context: context,
          controller: _quill,
          editorKey: _editorKey,
          scrollController: _scroll,
          isDark: isDark,
        );
      });
    } else {
      _toolbar.hide();
    }

    _scheduleAutoSave();
  }

  void _onFocusChange() {
    if (!_editorFocus.hasFocus) _toolbar.hide();
  }

  // ── Auto-save ──────────────────────────────────────────────────────────────

  void _scheduleAutoSave() {
    _saveTimer?.cancel();
    if (mounted) setState(() => _saveStatus = 'Saving…');
    _saveTimer = Timer(const Duration(seconds: 3), _performSave);
  }

  Future<void> _performSave() async {
    if (!mounted) return;

    final title = _titleCtrl.text.trim();
    final plainText = _quill.document.toPlainText().trim();
    if (title.isEmpty && plainText.isEmpty) return;

    List<dynamic> deltaJson;
    try {
      deltaJson = _quill.document.toDelta().toJson();
    } catch (_) {
      return;
    }

    final now = DateTime.now();
    final db = context.read<DatabaseService>();

    final note = Note(
      id: _savedNoteId,
      folderId: _folderId,
      title: title.isEmpty ? 'Untitled' : title,
      content: jsonEncode(deltaJson),
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      reminderTime: widget.note?.reminderTime,
      isPinned: widget.note?.isPinned ?? false,
    );

    try {
      if (_savedNoteId != null) {
        await db.updateNote(note);
      } else {
        _savedNoteId = await db.addNote(note);
      }
      if (mounted) setState(() => _saveStatus = 'Saved');
    } catch (_) {
      if (mounted) setState(() => _saveStatus = 'Error saving');
    }
  }

  Future<void> _forceSaveAndPop() async {
    _saveTimer?.cancel();
    await _performSave();
    if (mounted) Navigator.pop(context);
  }

  // ── Find & Replace ────────────────────────────────────────────────────────

  void _runFind() {
    final q = _findCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _matchOffsets = [];
        _matchIdx = -1;
      });
      return;
    }
    final text = _quill.document.toPlainText().toLowerCase();
    final query = q.toLowerCase();
    final matches = <int>[];
    int start = 0;
    while (true) {
      final i = text.indexOf(query, start);
      if (i == -1) break;
      matches.add(i);
      start = i + 1;
    }
    setState(() {
      _matchOffsets = matches;
      _matchIdx = matches.isEmpty ? -1 : 0;
    });
    if (matches.isNotEmpty) _highlightMatch(0);
  }

  void _nextMatch() {
    if (_matchOffsets.isEmpty) return;
    final next = (_matchIdx + 1) % _matchOffsets.length;
    setState(() => _matchIdx = next);
    _highlightMatch(next);
  }

  void _prevMatch() {
    if (_matchOffsets.isEmpty) return;
    final prev = (_matchIdx - 1 + _matchOffsets.length) % _matchOffsets.length;
    setState(() => _matchIdx = prev);
    _highlightMatch(prev);
  }

  void _highlightMatch(int index) {
    final offset = _matchOffsets[index];
    final len = _findCtrl.text.length;
    _quill.updateSelection(
        TextSelection(baseOffset: offset, extentOffset: offset + len),
        ChangeSource.local);
  }

  void _replaceOne() {
    if (_matchOffsets.isEmpty || _matchIdx < 0) return;
    final offset = _matchOffsets[_matchIdx];
    final rep = _replaceCtrl.text;
    _quill.replaceText(offset, _findCtrl.text.length, rep, null);
    _runFind();
  }

  void _replaceAll() {
    final q = _findCtrl.text;
    final rep = _replaceCtrl.text;
    if (q.isEmpty) return;
    final text = _quill.document.toPlainText();
    // Iterate backwards to preserve offsets
    final matches = <int>[];
    int start = 0;
    final lower = text.toLowerCase();
    while (true) {
      final i = lower.indexOf(q.toLowerCase(), start);
      if (i == -1) break;
      matches.add(i);
      start = i + 1;
    }
    for (final offset in matches.reversed) {
      _quill.replaceText(offset, q.length, rep, null);
    }
    _runFind();
  }

  // ── Heading sheet ─────────────────────────────────────────────────────────

  void _showHeadingSheet() {
    _toolbar.hide();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _HeadingSheet(
        controller: _quill,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  // ── Ellipsis menu ─────────────────────────────────────────────────────────

  void _showEllipsisMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordCount = _quill.document
        .toPlainText()
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EllipsisSheet(
        isDark: isDark,
        wordCount: wordCount,
        onFindInNote: () {
          Navigator.pop(context);
          setState(() => _showFind = !_showFind);
          if (_showFind) {
            Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) FocusScope.of(context).nextFocus();
              });
          }
        },
        onShareNote: () {
          Navigator.pop(context);
          // Sharing is a future feature
        },
        onSetReminder: () {
          Navigator.pop(context);
          _pickReminder();
        },
        onMoveToFolder: () {
          Navigator.pop(context);
          _pickFolder();
        },
      ),
    );
  }

  // ── Reminder ──────────────────────────────────────────────────────────────

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: now.add(const Duration(hours: 1)),
        firstDate: now,
        lastDate: now.add(const Duration(days: 365 * 5)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))));
    if (time == null || !mounted) return;
    final reminderTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (_savedNoteId != null) {
      await NotificationService.instance.scheduleNotification(
        id: 5000 + _savedNoteId!,
        title: _titleCtrl.text.isEmpty ? 'Note reminder' : _titleCtrl.text,
        body: _quill.document.toPlainText().substring(
            0, _quill.document.toPlainText().length.clamp(0, 80)),
        scheduledTime: reminderTime,
        payload: 'note_$_savedNoteId',
        isAlarmStyle: false,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reminder set'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Folder picker ─────────────────────────────────────────────────────────

  Future<void> _pickFolder() async {
    final db = context.read<DatabaseService>();
    final folders = db.folders;
    final chosen = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _FolderPickerSheet(folders: folders, currentFolderId: _folderId),
    );
    if (!mounted || chosen == null) return;
    setState(() => _folderId = chosen == -1 ? null : chosen);
    _scheduleAutoSave();
  }

  // ── Quill custom styles ────────────────────────────────────────────────────

  DefaultStyles _quillStyles(bool isDark) {
    final bodyColor = isDark ? Colors.white : AppColors.iosDarkSurface;
    final placeholderColor = AppColors.iosPlaceholder;

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        TextStyle(
          fontSize: 17,
          height: 1.6,
          color: bodyColor,
          fontFamily: '.SF Pro Text',
        ),
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      placeHolder: DefaultTextBlockStyle(
        TextStyle(fontSize: 17, height: 1.6, color: placeholderColor),
        HorizontalSpacing.zero,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null,
      ),
      h1: DefaultTextBlockStyle(
        TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: bodyColor,
        ),
        HorizontalSpacing.zero,
        const VerticalSpacing(16, 4),
        VerticalSpacing.zero,
        null,
      ),
      h2: DefaultTextBlockStyle(
        TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: bodyColor,
        ),
        HorizontalSpacing.zero,
        const VerticalSpacing(12, 4),
        VerticalSpacing.zero,
        null,
      ),
      h3: DefaultTextBlockStyle(
        TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: bodyColor,
        ),
        HorizontalSpacing.zero,
        const VerticalSpacing(8, 4),
        VerticalSpacing.zero,
        null,
      ),
      quote: DefaultTextBlockStyle(
        TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: AppColors.iosSecondaryLabel,
          height: 1.5,
        ),
        const HorizontalSpacing(16, 0),
        const VerticalSpacing(8, 8),
        VerticalSpacing.zero,
        BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.noteRed, width: 3),
          ),
        ),
      ),
      code: DefaultTextBlockStyle(
        TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: bodyColor,
          height: 1.5,
        ),
        const HorizontalSpacing(12, 12),
        const VerticalSpacing(8, 8),
        VerticalSpacing.zero,
        BoxDecoration(
          color: isDark
              ? AppColors.iosDarkDivider.withValues(alpha: 0.6)
              : AppColors.iosToolbarBg,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      inlineCode: InlineCodeStyle(
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 15,
          color: AppColors.noteRed,
        ),
        backgroundColor: AppColors.iosToolbarBg,
        radius: const Radius.circular(4),
      ),
    );
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _saveTimer?.cancel();
    _toolbar.hide();
    _quill.removeListener(_onQuillChange);
    _titleCtrl.removeListener(_scheduleAutoSave);
    _editorFocus.removeListener(_onFocusChange);
    _quill.dispose();
    _titleCtrl.dispose();
    _scroll.dispose();
    _editorFocus.dispose();
    _titleFocus.dispose();
    _findCtrl.dispose();
    _replaceCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.iosDarkSurface : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _forceSaveAndPop();
      },
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                isDark: isDark,
                saveStatus: _saveStatus,
                onBack: _forceSaveAndPop,
                onShare: () {},
                onEllipsis: _showEllipsisMenu,
              ),
              if (_showFind) _FindReplaceBar(
                isDark: isDark,
                findCtrl: _findCtrl,
                replaceCtrl: _replaceCtrl,
                matchCount: _matchOffsets.length,
                matchIdx: _matchIdx,
                onFind: _runFind,
                onNext: _nextMatch,
                onPrev: _prevMatch,
                onReplace: _replaceOne,
                onReplaceAll: _replaceAll,
                onClose: () => setState(() {
                  _showFind = false;
                  _matchOffsets = [];
                  _matchIdx = -1;
                }),
              ),
              _TitleField(
                controller: _titleCtrl,
                focusNode: _titleFocus,
                isDark: isDark,
                onSubmit: () => _editorFocus.requestFocus(),
              ),
              _Divider(isDark: isDark),
              Expanded(
                child: QuillEditor(
                  key: _editorKey,
                  controller: _quill,
                  focusNode: _editorFocus,
                  scrollController: _scroll,
                  config: QuillEditorConfig(
                    placeholder: 'Start writing…',
                    expands: false,
                    scrollable: true,
                    autoFocus: widget.note == null,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    customStyles: _quillStyles(isDark),
                    enableSelectionToolbar: false,
                    keyboardAppearance:
                        isDark ? Brightness.dark : Brightness.light,
                    textSelectionThemeData: TextSelectionThemeData(
                      selectionColor:
                          AppColors.noteRed.withValues(alpha: 0.25),
                      cursorColor: AppColors.noteRed,
                    ),
                  ),
                ),
              ),
              NoteBottomBar(
                controller: _quill,
                isDark: isDark,
                onFormatMenu: _showHeadingSheet,
                onKeyboardDismiss: () => FocusScope.of(context).unfocus(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isDark,
    required this.saveStatus,
    required this.onBack,
    required this.onShare,
    required this.onEllipsis,
  });

  final bool isDark;
  final String saveStatus;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onEllipsis;

  @override
  Widget build(BuildContext context) {
    final divColor = isDark ? AppColors.iosDarkDivider : AppColors.iosDivider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              // Back
              _TopBarBtn(
                onTap: onBack,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left,
                        size: 28, color: AppColors.noteRed),
                    Text(
                      'Notes',
                      style: AppTypography.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.noteRed,
                      ),
                    ),
                  ],
                ),
              ),
              // Centered save status
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      saveStatus,
                      key: ValueKey(saveStatus),
                      style: AppTypography.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.iosSecondaryLabel,
                      ),
                    ),
                  ),
                ),
              ),
              // Actions
              _TopBarBtn(
                onTap: onShare,
                child: Icon(Icons.ios_share,
                    size: 22, color: AppColors.noteRed),
              ),
              _TopBarBtn(
                onTap: onEllipsis,
                child: Icon(Icons.more_horiz,
                    size: 22, color: AppColors.noteRed),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        Container(height: 0.5, color: divColor),
      ],
    );
  }
}

class _TopBarBtn extends StatelessWidget {
  const _TopBarBtn({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: child,
      ),
    );
  }
}

// ─── Title field ──────────────────────────────────────────────────────────────

class _TitleField extends StatelessWidget {
  const _TitleField({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: AppTypography.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.iosDarkSurface,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        decoration: InputDecoration(
          hintText: 'Title',
          hintStyle: AppTypography.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.iosPlaceholder,
            letterSpacing: -0.5,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        maxLines: null,
        minLines: 1,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => onSubmit(),
        cursorColor: AppColors.noteRed,
        cursorWidth: 2,
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: isDark ? AppColors.iosDarkDivider : AppColors.iosDivider,
    );
  }
}

// ─── Find & Replace bar ───────────────────────────────────────────────────────

class _FindReplaceBar extends StatelessWidget {
  const _FindReplaceBar({
    required this.isDark,
    required this.findCtrl,
    required this.replaceCtrl,
    required this.matchCount,
    required this.matchIdx,
    required this.onFind,
    required this.onNext,
    required this.onPrev,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onClose,
  });

  final bool isDark;
  final TextEditingController findCtrl;
  final TextEditingController replaceCtrl;
  final int matchCount;
  final int matchIdx;
  final VoidCallback onFind;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onReplace;
  final VoidCallback onReplaceAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final bg =
        isDark ? AppColors.iosDarkToolbarBg : AppColors.iosToolbarBg;
    final fieldBg =
        isDark ? AppColors.iosDarkSurface : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.iosDarkSurface;

    final fieldDecoration = InputDecoration(
      hintStyle: AppTypography.roboto(
          fontSize: 14, color: AppColors.iosPlaceholder),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: fieldBg,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );

    final fieldStyle = AppTypography.roboto(fontSize: 14, color: textColor);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          // Row 1: Find
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: findCtrl,
                  style: fieldStyle,
                  decoration:
                      fieldDecoration.copyWith(hintText: 'Find'),
                  onChanged: (_) => onFind(),
                  onSubmitted: (_) => onFind(),
                  cursorColor: AppColors.noteRed,
                ),
              ),
              const SizedBox(width: 8),
              // Match counter
              if (matchCount > 0)
                Text(
                  '${matchIdx + 1} of $matchCount',
                  style: AppTypography.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.iosSecondaryLabel,
                  ),
                ),
              if (matchCount > 0) ...[
                const SizedBox(width: 4),
                _FRBtn(
                    icon: Icons.keyboard_arrow_up, onTap: onPrev, isDark: isDark),
                _FRBtn(
                    icon: Icons.keyboard_arrow_down, onTap: onNext, isDark: isDark),
              ],
              const SizedBox(width: 4),
              _FRBtn(icon: Icons.close, onTap: onClose, isDark: isDark),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: Replace
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: replaceCtrl,
                  style: fieldStyle,
                  decoration:
                      fieldDecoration.copyWith(hintText: 'Replace'),
                  cursorColor: AppColors.noteRed,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onReplace,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.noteRed,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Replace',
                    style: AppTypography.roboto(
                        fontSize: 13,
                        color: AppColors.noteRed,
                        fontWeight: FontWeight.w500)),
              ),
              TextButton(
                onPressed: onReplaceAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.noteRed,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('All',
                    style: AppTypography.roboto(
                        fontSize: 13,
                        color: AppColors.noteRed,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FRBtn extends StatelessWidget {
  const _FRBtn({required this.icon, required this.onTap, required this.isDark});
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon,
            size: 18,
            color:
                isDark ? const Color(0xFFEBEBF5) : AppColors.iosDarkSurface),
      ),
    );
  }
}

// ─── Heading style bottom sheet ───────────────────────────────────────────────

class _HeadingSheet extends StatelessWidget {
  const _HeadingSheet({required this.controller, required this.isDark});

  final QuillController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.iosDarkSurface : Colors.white;
    final border = isDark ? AppColors.iosDarkDivider : AppColors.iosDivider;
    final bodyColor = isDark ? Colors.white : AppColors.iosDarkSurface;
    final attrs = controller.getSelectionStyle().attributes;
    final currentHeader = attrs['header']?.value;

    final styles = [
      _HeadingRow(
        label: 'Title',
        style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: bodyColor,
            fontFamily: '.SF Pro Text'),
        isActive: false, // Title uses the title TextField
        onTap: () {},
      ),
      _HeadingRow(
        label: 'Heading 1',
        style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w700, color: bodyColor),
        isActive: currentHeader == 1,
        onTap: () {
          Navigator.pop(context);
          final on = currentHeader == 1;
          controller.formatSelection(
              on ? Attribute.clone(Attribute.h1, null) : Attribute.h1);
        },
      ),
      _HeadingRow(
        label: 'Heading 2',
        style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: bodyColor),
        isActive: currentHeader == 2,
        onTap: () {
          Navigator.pop(context);
          final on = currentHeader == 2;
          controller.formatSelection(
              on ? Attribute.clone(Attribute.h2, null) : Attribute.h2);
        },
      ),
      _HeadingRow(
        label: 'Heading 3',
        style: TextStyle(
            fontSize: 19, fontWeight: FontWeight.w600, color: bodyColor),
        isActive: currentHeader == 3,
        onTap: () {
          Navigator.pop(context);
          final on = currentHeader == 3;
          controller.formatSelection(
              on ? Attribute.clone(Attribute.h3, null) : Attribute.h3);
        },
      ),
      _HeadingRow(
        label: 'Body',
        style:
            TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: bodyColor),
        isActive: currentHeader == null,
        onTap: () {
          Navigator.pop(context);
          controller.formatSelection(Attribute.clone(Attribute.header, null));
        },
      ),
      _HeadingRow(
        label: 'Monospaced',
        style: TextStyle(
            fontSize: 17,
            fontFamily: 'monospace',
            color: bodyColor),
        isActive: false,
        onTap: () {
          Navigator.pop(context);
          controller.formatSelection(
              Attribute.clone(Attribute.font, null));
          controller.formatSelection(const FontAttribute('monospace'));
        },
      ),
      _HeadingRow(
        label: 'Caption',
        style: TextStyle(
            fontSize: 13,
            color: AppColors.iosSecondaryLabel),
        isActive: false,
        onTap: () {
          Navigator.pop(context);
          controller.formatSelection(Attribute.clone(Attribute.header, null));
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'FORMAT',
            style: AppTypography.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.iosSecondaryLabel,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          ...styles.map((row) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 0.5, color: border),
                row,
              ],
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _HeadingRow extends StatelessWidget {
  const _HeadingRow({
    required this.label,
    required this.style,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: false,
      minVerticalPadding: 4,
      title: Text(label, style: style),
      trailing: isActive
          ? Icon(Icons.check, color: AppColors.noteRed, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

// ─── Ellipsis menu sheet ──────────────────────────────────────────────────────

class _EllipsisSheet extends StatelessWidget {
  const _EllipsisSheet({
    required this.isDark,
    required this.wordCount,
    required this.onFindInNote,
    required this.onShareNote,
    required this.onSetReminder,
    required this.onMoveToFolder,
  });

  final bool isDark;
  final int wordCount;
  final VoidCallback onFindInNote;
  final VoidCallback onShareNote;
  final VoidCallback onSetReminder;
  final VoidCallback onMoveToFolder;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.iosDarkSurface : Colors.white;
    final border = isDark ? AppColors.iosDarkDivider : AppColors.iosDivider;

    final items = [
      _MenuItem(
          icon: Icons.search,
          label: 'Find in Note',
          onTap: onFindInNote),
      _MenuItem(
          icon: Icons.ios_share, label: 'Share', onTap: onShareNote),
      _MenuItem(
          icon: Icons.alarm,
          label: 'Set Reminder',
          onTap: onSetReminder),
      _MenuItem(
          icon: Icons.drive_file_move_outline,
          label: 'Move to Folder',
          onTap: onMoveToFolder),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              '$wordCount word${wordCount == 1 ? '' : 's'}',
              style: AppTypography.roboto(
                  fontSize: 13, color: AppColors.iosSecondaryLabel),
            ),
          ),
          ...items.map((item) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 0.5, color: border),
                  ListTile(
                    leading: Icon(item.icon, color: AppColors.noteRed),
                    title: Text(item.label,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? Colors.white
                              : AppColors.iosDarkSurface,
                        )),
                    onTap: item.onTap,
                  ),
                ],
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon, required this.label, required this.onTap});
}

// ─── Folder picker sheet ──────────────────────────────────────────────────────

class _FolderPickerSheet extends StatelessWidget {
  const _FolderPickerSheet(
      {required this.folders, required this.currentFolderId});
  final List<NoteFolder> folders;
  final int? currentFolderId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.iosDarkSurface : Colors.white;
    final border = isDark ? AppColors.iosDarkDivider : AppColors.iosDivider;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Move to Folder',
              style: AppTypography.titleLarge
                  .copyWith(color: isDark ? Colors.white : AppColors.iosDarkSurface),
            ),
          ),
          const SizedBox(height: 8),
          _FolderRow(
              name: 'General',
              color: AppColors.iosSecondaryLabel,
              isSelected: currentFolderId == null,
              onTap: () => Navigator.pop(context, -1),
              isDark: isDark),
          ...folders.map((f) => _FolderRow(
                name: f.name,
                color: Color(f.colorValue),
                isSelected: f.id == currentFolderId,
                onTap: () => Navigator.pop(context, f.id),
                isDark: isDark,
              )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.folder_outlined, color: color),
      title: Text(name,
          style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.iosDarkSurface)),
      trailing: isSelected
          ? Icon(Icons.check, color: AppColors.noteRed, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
