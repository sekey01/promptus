import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

// ─── Public entry-point ───────────────────────────────────────────────────────

/// Inserts / removes a floating selection toolbar `OverlayEntry`.
/// Call [show] when selection becomes non-collapsed,
/// call [hide] when selection clears or focus is lost.
class NoteSelectionToolbarController {
  OverlayEntry? _entry;

  void show({
    required BuildContext context,
    required QuillController controller,
    required GlobalKey editorKey,
    required ScrollController scrollController,
    required bool isDark,
  }) {
    hide();
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (_) => _FloatingToolbarOverlay(
        controller: controller,
        editorKey: editorKey,
        scrollController: scrollController,
        isDark: isDark,
        onDismiss: hide,
      ),
    );
    overlay.insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  bool get isVisible => _entry != null;
}

// ─── Overlay widget ───────────────────────────────────────────────────────────

class _FloatingToolbarOverlay extends StatefulWidget {
  const _FloatingToolbarOverlay({
    required this.controller,
    required this.editorKey,
    required this.scrollController,
    required this.isDark,
    required this.onDismiss,
  });

  final QuillController controller;
  final GlobalKey editorKey;
  final ScrollController scrollController;
  final bool isDark;
  final VoidCallback onDismiss;

  @override
  State<_FloatingToolbarOverlay> createState() =>
      _FloatingToolbarOverlayState();
}

enum _ToolbarPage { main, more, textColor, highlight }

class _FloatingToolbarOverlayState extends State<_FloatingToolbarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  _ToolbarPage _page = _ToolbarPage.main;

  static const _kToolbarH = 44.0;
  static const _kCaretH = 6.0;
  static const _kGap = 8.0;
  static const _kMaxW = 360.0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _anim.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  // ── Position math ─────────────────────────────────────────────────────────

  _ToolbarPosition _calculatePosition(BuildContext ctx) {
    final screen = MediaQuery.of(ctx).size;
    final kb = MediaQuery.of(ctx).viewInsets.bottom;
    final topSafe = MediaQuery.of(ctx).padding.top;

    final box =
        widget.editorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return _ToolbarPosition(
        top: topSafe + 80,
        left: (screen.width - _kMaxW.clamp(0, screen.width - 32)) / 2,
        width: _kMaxW.clamp(0, screen.width - 32),
        caretBelow: true,
      );
    }

    final editorOrigin = box.localToGlobal(Offset.zero);
    final sel = widget.controller.selection;
    final text = widget.controller.document.toPlainText();
    final before = text.substring(0, sel.baseOffset.clamp(0, text.length));
    final linesBefore = '\n'.allMatches(before).length;
    const lineH = 17.0 * 1.6; // body font-size × line-height
    final scrollOff =
        widget.scrollController.hasClients ? widget.scrollController.offset : 0;

    final rawY = editorOrigin.dy + 12.0 + linesBefore * lineH - scrollOff;

    // Decide: put toolbar ABOVE or BELOW the cursor line
    final availableAbove = rawY - topSafe - 80;
    final caretBelow = availableAbove < (_kToolbarH + _kGap + _kCaretH + 4);

    double toolbarTop;
    if (caretBelow) {
      toolbarTop = rawY + lineH + _kGap;
    } else {
      toolbarTop = rawY - _kToolbarH - _kCaretH - _kGap;
    }

    // Clamp vertically
    final maxTop = screen.height - kb - 44 - _kToolbarH - _kCaretH - 8;
    toolbarTop = toolbarTop.clamp(topSafe + 56.0, maxTop);

    final w = _kMaxW.clamp(0.0, screen.width - 32.0);
    final left = ((screen.width - w) / 2).clamp(16.0, screen.width - w - 16);

    return _ToolbarPosition(
        top: toolbarTop, left: left, width: w, caretBelow: caretBelow);
  }

  // ── Active-format helpers ─────────────────────────────────────────────────

  bool _isActive(String key, [dynamic value]) {
    final attrs = widget.controller.getSelectionStyle().attributes;
    if (!attrs.containsKey(key)) return false;
    if (value == null) return attrs[key]?.value != null && attrs[key]?.value != false;
    return attrs[key]?.value == value;
  }

  void _toggle(Attribute attr) {
    HapticFeedback.selectionClick();
    final attrs = widget.controller.getSelectionStyle().attributes;
    final isOn = attrs.containsKey(attr.key) &&
        attrs[attr.key]?.value != null &&
        attrs[attr.key]?.value != false;
    widget.controller.formatSelection(isOn ? Attribute.clone(attr, null) : attr);
    if (mounted) setState(() {});
  }

  void _applyBlock(Attribute attr) {
    HapticFeedback.selectionClick();
    final attrs = widget.controller.getSelectionStyle().attributes;
    final isOn = attrs[attr.key]?.value == attr.value;
    widget.controller.formatSelection(isOn ? Attribute.clone(attr, null) : attr);
    if (mounted) setState(() {});
  }

  void _applyColor(String hex) {
    HapticFeedback.selectionClick();
    widget.controller.formatSelection(ColorAttribute(hex));
    setState(() => _page = _ToolbarPage.main);
  }

  void _applyHighlight(String? hex) {
    HapticFeedback.selectionClick();
    widget.controller.formatSelection(BackgroundAttribute(hex));
    setState(() => _page = _ToolbarPage.main);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pos = _calculatePosition(context);
    final bg = widget.isDark ? AppColors.iosDarkSurface : Colors.white;
    final divColor = widget.isDark ? AppColors.iosDarkDivider : AppColors.iosDivider;

    return Positioned(
      top: pos.top,
      left: pos.left,
      width: pos.width,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          alignment: pos.caretBelow ? Alignment.topCenter : Alignment.bottomCenter,
          child: _ToolbarCard(
            bg: bg,
            divColor: divColor,
            caretBelow: pos.caretBelow,
            child: _buildPage(bg, divColor),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(Color bg, Color divColor) {
    switch (_page) {
      case _ToolbarPage.main:
        return _buildMainRow(divColor);
      case _ToolbarPage.more:
        return _buildMoreRow(divColor);
      case _ToolbarPage.textColor:
        return _buildColorRow(isHighlight: false, divColor: divColor);
      case _ToolbarPage.highlight:
        return _buildColorRow(isHighlight: true, divColor: divColor);
    }
  }

  // ── Row 1 (main) ──────────────────────────────────────────────────────────

  Widget _buildMainRow(Color divColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(label: 'B', icon: Icons.format_bold, active: _isActive('bold'),
              onTap: () => _toggle(Attribute.bold), isDark: widget.isDark),
          _Btn(label: 'I', icon: Icons.format_italic, active: _isActive('italic'),
              onTap: () => _toggle(Attribute.italic), isDark: widget.isDark),
          _Btn(label: 'U', icon: Icons.format_underline, active: _isActive('underline'),
              onTap: () => _toggle(Attribute.underline), isDark: widget.isDark),
          _Btn(label: 'S', icon: Icons.format_strikethrough, active: _isActive('strike'),
              onTap: () => _toggle(Attribute.strikeThrough), isDark: widget.isDark),
          _VDivider(color: divColor),
          _Btn(icon: Icons.format_color_text, active: false,
              onTap: () => setState(() => _page = _ToolbarPage.textColor),
              isDark: widget.isDark),
          _Btn(icon: Icons.format_color_fill, active: false,
              onTap: () => setState(() => _page = _ToolbarPage.highlight),
              isDark: widget.isDark),
          _VDivider(color: divColor),
          _Btn(icon: Icons.code, active: _isActive('code-block') || _isActive('code'),
              onTap: () => _toggle(Attribute.inlineCode), isDark: widget.isDark),
          _VDivider(color: divColor),
          _Btn(
            icon: Icons.more_horiz,
            active: false,
            isDark: widget.isDark,
            onTap: () => setState(() => _page = _ToolbarPage.more),
          ),
        ],
      ),
    );
  }

  // ── Row 2 (more) ──────────────────────────────────────────────────────────

  Widget _buildMoreRow(Color divColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back
          _Btn(icon: Icons.chevron_left, active: false, isDark: widget.isDark,
              onTap: () => setState(() => _page = _ToolbarPage.main)),
          _VDivider(color: divColor),
          // Headings
          _Btn(label: 'H1', active: _isActive('header', 1), isDark: widget.isDark,
              onTap: () => _applyBlock(Attribute.h1)),
          _Btn(label: 'H2', active: _isActive('header', 2), isDark: widget.isDark,
              onTap: () => _applyBlock(Attribute.h2)),
          _Btn(label: 'H3', active: _isActive('header', 3), isDark: widget.isDark,
              onTap: () => _applyBlock(Attribute.h3)),
          _VDivider(color: divColor),
          // Alignment
          _Btn(icon: Icons.format_align_left,
              active: _isActive('align', 'left') || !_isActive('align'),
              onTap: () => _applyBlock(Attribute.leftAlignment),
              isDark: widget.isDark),
          _Btn(icon: Icons.format_align_center,
              active: _isActive('align', 'center'),
              onTap: () => _applyBlock(Attribute.centerAlignment),
              isDark: widget.isDark),
          _Btn(icon: Icons.format_align_right,
              active: _isActive('align', 'right'),
              onTap: () => _applyBlock(Attribute.rightAlignment),
              isDark: widget.isDark),
          _VDivider(color: divColor),
          // Lists
          _Btn(icon: Icons.format_list_bulleted,
              active: _isActive('list', 'bullet'),
              onTap: () => _applyBlock(Attribute.ul),
              isDark: widget.isDark),
          _Btn(icon: Icons.format_list_numbered,
              active: _isActive('list', 'ordered'),
              onTap: () => _applyBlock(Attribute.ol),
              isDark: widget.isDark),
          _Btn(icon: Icons.checklist,
              active: _isActive('list', 'checked') || _isActive('list', 'unchecked'),
              onTap: () => _applyBlock(Attribute.unchecked),
              isDark: widget.isDark),
          _VDivider(color: divColor),
          // Quote / code block
          _Btn(icon: Icons.format_quote,
              active: _isActive('blockquote'),
              onTap: () => _applyBlock(Attribute.blockQuote),
              isDark: widget.isDark),
          _Btn(icon: Icons.data_object,
              active: _isActive('code-block'),
              onTap: () => _applyBlock(Attribute.codeBlock),
              isDark: widget.isDark),
          _VDivider(color: divColor),
          // Script
          _Btn(icon: Icons.superscript,
              active: _isActive('script', 'super'),
              onTap: () => _applyBlock(Attribute.superscript),
              isDark: widget.isDark),
          _Btn(icon: Icons.subscript,
              active: _isActive('script', 'sub'),
              onTap: () => _applyBlock(Attribute.subscript),
              isDark: widget.isDark),
        ],
      ),
    );
  }

  // ── Color rows ────────────────────────────────────────────────────────────

  static const _textColors = [
    '#1C1C1E', '#9B1D1D', '#007AFF',
    '#34C759', '#FF9500', '#8E8E93', '#FFFFFF',
  ];
  static const _hlColors = [
    '#FFD60A', '#30D158', '#FF375F',
    '#FF9F0A', '#0A84FF',
  ];

  Widget _buildColorRow({required bool isHighlight, required Color divColor}) {
    final colors = isHighlight ? _hlColors : _textColors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.chevron_left, active: false, isDark: widget.isDark,
              onTap: () => setState(() => _page = _ToolbarPage.main)),
          _VDivider(color: divColor),
          ...colors.map((hex) => _ColorSwatch(
                hex: hex,
                isDark: widget.isDark,
                onTap: () => isHighlight ? _applyHighlight(hex) : _applyColor(hex),
              )),
          if (isHighlight) ...[
            _VDivider(color: divColor),
            _Btn(icon: Icons.format_color_reset, active: false,
                isDark: widget.isDark,
                onTap: () => _applyHighlight(null)),
          ],
        ],
      ),
    );
  }
}

// ─── Position data ────────────────────────────────────────────────────────────

class _ToolbarPosition {
  final double top, left, width;
  final bool caretBelow;
  const _ToolbarPosition(
      {required this.top,
      required this.left,
      required this.width,
      required this.caretBelow});
}

// ─── Card with caret ─────────────────────────────────────────────────────────

class _ToolbarCard extends StatelessWidget {
  const _ToolbarCard({
    required this.bg,
    required this.divColor,
    required this.caretBelow,
    required this.child,
  });

  final Color bg, divColor;
  final bool caretBelow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: bg,
      elevation: 0,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: divColor.withValues(alpha: 0.5), width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: child,
        ),
      ),
    );

    // Caret triangle pointing toward the selection
    final caret = CustomPaint(
      size: const Size(16, 6),
      painter: _CaretPainter(color: bg, pointDown: !caretBelow),
    );

    if (caretBelow) {
      // Toolbar is below selection — caret points UP (at top center)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [Center(child: caret), card],
      );
    } else {
      // Toolbar is above selection — caret points DOWN (at bottom center)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [card, Center(child: caret)],
      );
    }
  }
}

// ─── Caret painter ────────────────────────────────────────────────────────────

class _CaretPainter extends CustomPainter {
  const _CaretPainter({required this.color, required this.pointDown});
  final Color color;
  final bool pointDown;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    } else {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CaretPainter old) => old.color != color;
}

// ─── Toolbar button ───────────────────────────────────────────────────────────

class _Btn extends StatefulWidget {
  const _Btn({
    required this.active,
    required this.onTap,
    required this.isDark,
    this.icon,
    this.label,
  }) : assert(icon != null || label != null);

  final IconData? icon;
  final String? label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scaleA;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _scaleA = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.active
        ? AppColors.noteRed
        : (widget.isDark ? const Color(0xFFEBEBF5) : AppColors.iosDarkSurface);

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapCancel: () => _press.reverse(),
      onTap: () {
        _press.reverse();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleA,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.label != null && widget.label!.length > 1 ? 44 : 36,
          height: 44,
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.noteRed.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: widget.icon != null
                ? Icon(widget.icon, size: 17, color: iconColor)
                : Text(
                    widget.label!,
                    style: AppTypography.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Vertical divider ─────────────────────────────────────────────────────────

class _VDivider extends StatelessWidget {
  const _VDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: color,
    );
  }
}

// ─── Color swatch ─────────────────────────────────────────────────────────────

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(
      {required this.hex, required this.isDark, required this.onTap});
  final String hex;
  final bool isDark;
  final VoidCallback onTap;

  Color _parse(String h) {
    final s = h.replaceAll('#', '');
    return Color(int.parse('FF$s', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final c = _parse(hex);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 36,
        height: 44,
        alignment: Alignment.center,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black12,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
