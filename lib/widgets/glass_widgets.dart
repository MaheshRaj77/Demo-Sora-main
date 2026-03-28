import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'dart:io';
import '../theme/app_theme.dart';

/// ─── PUnova · Minimal Neutral Widget System ────────────────────────

/// A clean card container — the core building block.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final double opacity;
  final double blur;
  final bool hasBorder;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.color,
    this.opacity = 1.0,
    this.blur = 0,
    this.hasBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? tc.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(color: tc.border, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: tc.isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: blur > 0
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              )
            : Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// A tappable icon tile for quick-access grids.
class GlassIconTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Gradient? gradient;
  final Color? iconBgColor;
  final VoidCallback? onTap;

  const GlassIconTile({
    super.key,
    required this.icon,
    required this.label,
    this.gradient,
    this.iconBgColor,
    this.onTap,
  });

  @override
  State<GlassIconTile> createState() => _GlassIconTileState();
}

class _GlassIconTileState extends State<GlassIconTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    final bgColor = widget.iconBgColor ?? tc.bgSurface;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: widget.gradient,
                color: widget.gradient == null ? bgColor : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                widget.icon,
                color: widget.gradient != null
                    ? Colors.white
                    : tc.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(
                color: tc.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header with optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  letterSpacing: -0.3,
                ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText!,
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A clean button with optional icon.
class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? backgroundColor;
  final IconData? icon;
  final double height;
  final bool isLoading;
  final bool isOutlined;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.backgroundColor,
    this.icon,
    this.height = 52,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    final isDisabled = widget.onPressed == null;
    final bgColor = widget.backgroundColor ?? AppColors.primary;

    // iOS: Use Cupertino button
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: widget.onPressed,
        minimumSize: Size.fromHeight(widget.height),
        padding: EdgeInsets.zero,
        child: _buildContent(tc, bgColor, isDisabled),
      );
    }

    // Android & Web
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _scale = 0.96),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _scale = 1.0);
              widget.onPressed?.call();
            },
      onTapCancel: isDisabled ? null : () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: _buildContent(tc, bgColor, isDisabled),
      ),
    );
  }

  Widget _buildContent(Tc tc, Color bgColor, bool isDisabled) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: !widget.isOutlined && !isDisabled ? widget.gradient : null,
        color: widget.isOutlined
            ? Colors.transparent
            : (isDisabled
                ? tc.textMuted.withValues(alpha: 0.2)
                : (widget.gradient != null ? null : bgColor)),
        borderRadius: BorderRadius.circular(12),
        border: widget.isOutlined
            ? Border.all(color: tc.border, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: Platform.isIOS
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
            )
          else ...[
            if (widget.icon != null) ...[
              Icon(widget.icon,
                  color: widget.isOutlined ? tc.textPrimary : Colors.white,
                  size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              widget.text,
              style: TextStyle(
                color: widget.isOutlined ? tc.textPrimary : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Clean list tile for settings/profile.
class GlassListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const GlassListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    final color = iconColor ?? tc.textPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: tc.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(color: tc.textMuted, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: tc.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}

/// A clean text field for forms.
class GlassTextField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final IconData? icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final int maxLines;
  final bool hasError;

  const GlassTextField({
    super.key,
    required this.hint,
    this.controller,
    this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.hasError = false,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    final shouldObscure = widget.isPassword && _obscureText;

    // iOS: Use Cupertino TextField
    if (Platform.isIOS) {
      return Container(
        decoration: BoxDecoration(
          color: widget.hasError
              ? AppColors.error.withValues(alpha: 0.06)
              : tc.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.hasError
                ? AppColors.error.withValues(alpha: 0.5)
                : tc.border,
            width: 1,
          ),
        ),
        child: CupertinoTextField(
          controller: widget.controller,
          obscureText: shouldObscure,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          style: TextStyle(color: tc.textPrimary, fontSize: 16),
          placeholder: widget.hint,
          placeholderStyle: TextStyle(color: tc.textMuted, fontSize: 15),
          prefix: widget.icon != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(widget.icon, color: tc.textMuted, size: 20),
                )
              : null,
          suffix: widget.isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _obscureText = !_obscureText),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      _obscureText
                          ? CupertinoIcons.eye_fill
                          : CupertinoIcons.eye_slash_fill,
                      color: tc.textMuted,
                      size: 20,
                    ),
                  ),
                )
              : null,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.transparent),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        ),
      );
    }

    // Android & Web
    return Container(
      decoration: BoxDecoration(
        color: widget.hasError
            ? AppColors.error.withValues(alpha: 0.06)
            : tc.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.hasError
              ? AppColors.error.withValues(alpha: 0.5)
              : tc.border,
          width: 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: shouldObscure,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        style: TextStyle(color: tc.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: widget.icon != null
              ? Icon(widget.icon, color: tc.textMuted, size: 20)
              : null,
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _obscureText = !_obscureText),
                  child: Icon(
                    _obscureText
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: tc.textMuted,
                    size: 20,
                  ),
                )
              : null,
          hintText: widget.hint,
          hintStyle: TextStyle(color: tc.textMuted, fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

/// A clean scaffold with background.
class GlassScaffold extends StatelessWidget {
  final Widget body;
  final bool hasSafeArea;

  const GlassScaffold({
    super.key,
    required this.body,
    this.hasSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return Scaffold(
      backgroundColor: tc.bg,
      body: Container(
        color: tc.bg,
        child: hasSafeArea ? SafeArea(child: body) : body,
      ),
    );
  }
}

/// Clean app bar for sub-screens.
class GlassAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tc.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tc.border, width: 1),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: tc.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// A subtle divider.
class GlassDivider extends StatelessWidget {
  const GlassDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: tc.border,
    );
  }
}
