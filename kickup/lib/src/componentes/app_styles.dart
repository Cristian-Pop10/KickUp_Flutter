import 'package:flutter/material.dart';

class AppColors {
  static Color primary(BuildContext context) => const Color(0xFF5A9A7A);

  static Color background(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color cardBackground(BuildContext context) =>
      Theme.of(context).cardColor;

  static Color fieldBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : const Color.fromARGB(255, 225, 225, 202); // beige claro
  }


  static Color textPrimary(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

  static Color textSecondary(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.grey[400]! // Claro en modo oscuro
        : Colors.grey[600]!; // Oscuro en modo claro
  }

  static Color iconColor(BuildContext context) =>
      Theme.of(context).iconTheme.color ?? Colors.green;

  static Color adaptiveBeige(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark
        ? const Color.fromARGB(255, 183, 176, 151)
        : const Color.fromARGB(255, 218, 203, 134);
  }
}

class AppTextStyles {
  static TextStyle title(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.bold,
          );

  static TextStyle cardTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          );

  static TextStyle cardSubtitle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: AppColors.textSecondary(context),
          );

  static TextStyle buttonText(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          );
}
