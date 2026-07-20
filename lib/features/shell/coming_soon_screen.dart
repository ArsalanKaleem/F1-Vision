import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glass_card.dart';

/// A polished placeholder for features that are scaffolded but not yet built
/// out. It documents *what each screen will contain* per the brief, so the app
/// runs end-to-end and the roadmap is visible in-product.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    this.planned = const [],
  });

  final String title;
  final IconData icon;
  final String description;
  final List<String> planned;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            glow: true,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 20),
                Text(title, style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Text(description, style: AppTextStyles.body),
                if (planned.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('PLANNED', style: AppTextStyles.overline),
                  const SizedBox(height: 12),
                  ...planned.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(p, style: AppTextStyles.titleSmall),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
        ),
      ),
    );
  }
}
