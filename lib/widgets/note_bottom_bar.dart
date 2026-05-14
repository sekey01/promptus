import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Persistent formatting bar that floats just above the keyboard.
/// Mirrors the Apple Notes bottom bar in style and function.
class NoteBottomBar extends StatefulWidget {
  const NoteBottomBar({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onFormatMenu,
    required this.onKeyboardDismiss,
    this.onUndo,
    this.onRedo,
  });

  final QuillController controller;
  final bool isDark;
  final VoidCallback onFormatMenu;
  final VoidCallback onKeyboardDismiss;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  @override
  State<NoteBottomBar> createState() => _NoteBottomBarState();
}

class _NoteBottomBarState extends State<NoteBottomBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  // ── Format helpers ────────────────────────────────────────────────────────

  bool _is(String key, [dynamic val]) {
    final a = widget.controller.getSelectionStyle().attributes;
    if (!a.containsKey(key)) return false;
    if (val == null) return a[key]?.value != null && a[key]?.value != false;
    return a[key]?.value == val;
  }

  void _toggle(Attribute attr) {
    HapticFeedback.selectionClick();
    final attrs = widget.controller.getSelectionStyle().attributes;
    final on = attrs.containsKey(attr.key) &&
        attrs[attr.key]?.value != null &&
        attrs[attr.key]?.value != false;
    widget.controller.formatSelection(on ? Attribute.clone(attr, null) : attr);
  }

  void _applyBlock(Attribute attr) {
    HapticFeedback.selectionClick();
    final attrs = widget.controller.getSelectionStyle().attributes;
    final on = attrs[attr.key]?.value == attr.value;
    widget.controller.formatSelection(on ? Attribute.clone(attr, null) : attr);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.iosDarkToolbarBg : AppColors.iosToolbarBg;
    final border = widget.isDark ? AppColors.iosDarkDivider : AppColors.iosDivider;

    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top border 0.5px
          Container(height: 0.5, color: border),
          SizedBox(
            height: 44,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checklist
                  _BarBtn(
                    icon: Icons.checklist,
                    active: _is('list', 'checked') || _is('list', 'unchecked'),
                    isDark: widget.isDark,
                    onTap: () => _applyBlock(Attribute.unchecked),
                  ),
                  // Bullet
                  _BarBtn(
                    icon: Icons.format_list_bulleted,
                    active: _is('list', 'bullet'),
                    isDark: widget.isDark,
                    onTap: () => _applyBlock(Attribute.ul),
                  ),
                  // Numbered
                  _BarBtn(
                    icon: Icons.format_list_numbered,
                    active: _is('list', 'ordered'),
                    isDark: widget.isDark,
                    onTap: () => _applyBlock(Attribute.ol),
                  ),
                  _BarDivider(isDark: widget.isDark),
                  // Bold
                  _BarBtn(
                    icon: Icons.format_bold,
                    active: _is('bold'),
                    isDark: widget.isDark,
                    onTap: () => _toggle(Attribute.bold),
                  ),
                  // Italic
                  _BarBtn(
                    icon: Icons.format_italic,
                    active: _is('italic'),
                    isDark: widget.isDark,
                    onTap: () => _toggle(Attribute.italic),
                  ),
                  // Underline
                  _BarBtn(
                    icon: Icons.format_underline,
                    active: _is('underline'),
                    isDark: widget.isDark,
                    onTap: () => _toggle(Attribute.underline),
                  ),
                  _BarDivider(isDark: widget.isDark),
                  // Align Left
                  _BarBtn(
                    icon: Icons.format_align_left,
                    active: !_is('align') || _is('align', 'left'),
                    isDark: widget.isDark,
                    onTap: () => _applyBlock(Attribute.leftAlignment),
                  ),
                  // Align Center
                  _BarBtn(
                    icon: Icons.format_align_center,
                    active: _is('align', 'center'),
                    isDark: widget.isDark,
                    onTap: () => _applyBlock(Attribute.centerAlignment),
                  ),
                  // Align Right
                  _BarBtn(
                    icon: Icons.format_align_right,
                    active: _is('align', 'right'),
                    isDark: widget.isDark,
                    onTap: () => _applyBlock(Attribute.rightAlignment),
                  ),
                  _BarDivider(isDark: widget.isDark),
                  // Indent +
                  _BarBtn(
                    icon: Icons.format_indent_increase,
                    active: false,
                    isDark: widget.isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.controller.indentSelection(true);
                    },
                  ),
                  // Indent -
                  _BarBtn(
                    icon: Icons.format_indent_decrease,
                    active: false,
                    isDark: widget.isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.controller.indentSelection(false);
                    },
                  ),
                  _BarDivider(isDark: widget.isDark),
                  // Aa — heading / style menu
                  _AaBtn(isDark: widget.isDark, onTap: widget.onFormatMenu),
                  _BarDivider(isDark: widget.isDark),
                  // Horizontal rule
                  _BarBtn(
                    icon: Icons.horizontal_rule,
                    active: false,
                    isDark: widget.isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final sel = widget.controller.selection;
                      widget.controller.replaceText(
                          sel.baseOffset, sel.extentOffset - sel.baseOffset,
                          '\n─────────────────\n', null);
                    },
                  ),
                  _BarDivider(isDark: widget.isDark),
                  // Undo
                  _BarBtn(
                    icon: Icons.undo,
                    active: false,
                    isDark: widget.isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (widget.onUndo != null) {
                        widget.onUndo!();
                      } else {
                        widget.controller.undo();
                      }
                    },
                  ),
                  // Redo
                  _BarBtn(
                    icon: Icons.redo,
                    active: false,
                    isDark: widget.isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (widget.onRedo != null) {
                        widget.onRedo!();
                      } else {
                        widget.controller.redo();
                      }
                    },
                  ),
                  _BarDivider(isDark: widget.isDark),
                  // Keyboard dismiss
                  _BarBtn(
                    icon: Icons.keyboard_hide,
                    active: false,
                    isDark: widget.isDark,
                    onTap: widget.onKeyboardDismiss,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bar button ───────────────────────────────────────────────────────────────

class _BarBtn extends StatelessWidget {
  const _BarBtn({
    required this.icon,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.noteRed
        : (isDark ? const Color(0xFFEBEBF5) : AppColors.iosDarkSurface);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// ─── Aa button ────────────────────────────────────────────────────────────────

class _AaBtn extends StatelessWidget {
  const _AaBtn({required this.isDark, required this.onTap});
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? const Color(0xFFEBEBF5) : AppColors.iosDarkSurface;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Text(
            'Aa',
            style: AppTypography.roboto(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bar divider ─────────────────────────────────────────────────────────────

class _BarDivider extends StatelessWidget {
  const _BarDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: isDark ? AppColors.iosDarkDivider : AppColors.iosDivider,
    );
  }
}
