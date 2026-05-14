import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class LoadingShimmer extends StatelessWidget {
  final int itemCount;

  const LoadingShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? AppColors.darkSurfaceVariant : const Color(0xFFE5E7EB);
    final highlight = dark ? AppColors.darkSurfaceElevated : Colors.white;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => _ShimmerCard(),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.xlBR,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.mdBR,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.smBR,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadius.smBR,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 20,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.smBR,
            ),
          ),
        ],
      ),
    );
  }
}
