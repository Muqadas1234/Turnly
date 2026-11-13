import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// custom reusable primary filled button
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor = AppColors.primary,
    this.textColor = Colors.white,
    this.height = 52,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// custom reusable text action button (e.g., links, switch screens)
class CustomTextButton extends StatelessWidget {
  final String? leadText;
  final String actionText;
  final VoidCallback onTap;
  final Color actionColor;

  const CustomTextButton({
    super.key,
    this.leadText,
    required this.actionText,
    required this.onTap,
    this.actionColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadText != null) ...[
          Text(
            leadText!,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: TextStyle(
              color: actionColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
