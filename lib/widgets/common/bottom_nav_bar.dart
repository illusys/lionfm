import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/navigation/nav_destinations.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(top: BorderSide(color: AppColors.border1, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppDimensions.bottomNavHeight,
          child: Row(
            children: List.generate(navDestinations.length, (i) {
              final dest = navDestinations[i];
              final isSelected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(dest.route),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? dest.activeIcon : dest.icon,
                        size: AppDimensions.iconMd,
                        color: isSelected
                            ? AppColors.amberGold
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dest.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: isSelected
                              ? AppColors.amberGold
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
