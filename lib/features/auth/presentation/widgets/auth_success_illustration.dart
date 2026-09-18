import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class AuthSuccessIllustration extends StatelessWidget {
  const AuthSuccessIllustration({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Thành công',
      child: SizedBox.square(
        dimension: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 144,
              height: 144,
              decoration: const BoxDecoration(
                color: AppColors.successBackground,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 108,
              height: 108,
              decoration: const BoxDecoration(
                color: AppColors.successBackgroundSoft,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.successBorderSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AppColors.success),
            ),
            Positioned(
              right: 20,
              bottom: 24,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.successAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
