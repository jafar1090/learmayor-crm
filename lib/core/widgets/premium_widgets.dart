import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A premium Bento-style card with hover effects for desktop
class BentoCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.onTap,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -4.0 : 0.0),
          padding: widget.padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: widget.color ?? Colors.white,
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 24),
            border: Border.all(
              color: _isHovered ? AppTheme.accent.withOpacity(0.5) : AppTheme.border,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered ? AppTheme.premiumShadow : AppTheme.softShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A standard detail tile for profile information
class DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const DetailTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor ?? AppTheme.textMid, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A semantic badge for status display
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
      ),
    );
  }
}

/// A wrapper to ensure layout stays tight on large screens
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A premium skeleton loader using Shimmer
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A robust image widget with caching and shimmer placeholder
class PremiumImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool isCircle;
  final double borderRadius;
  final BoxFit fit;

  const PremiumImage({
    super.key,
    this.imageUrl,
    this.size = 50,
    this.isCircle = true,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty || imageUrl!.startsWith('blob:')) {
      return _buildPlaceholder();
    }

    // Handle Local Assets
    if (imageUrl!.startsWith('assets/')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCircle ? size : borderRadius),
          child: Image.asset(imageUrl!, fit: fit),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
          image: DecorationImage(image: imageProvider, fit: fit),
        ),
      ),
      placeholder: (context, url) => ShimmerLoading(
        width: size,
        height: size,
        borderRadius: isCircle ? size / 2 : borderRadius,
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.background,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Center(
        child: Icon(Icons.person_rounded, color: AppTheme.textLight.withOpacity(0.5), size: size * 0.45),
      ),
    );
  }
}

/// A premium stylized confirmation dialog
class PremiumConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final IconData? icon;

  const PremiumConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor = AppTheme.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      title: Column(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: confirmColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: confirmColor, size: 32),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textDark),
          ),
        ],
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textMid, fontSize: 15, height: 1.5),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(cancelLabel, style: const TextStyle(color: AppTheme.textMid, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

