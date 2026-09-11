import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/app_section_card.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: const Text('Học tập')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppSectionCard(
            title: 'Lộ trình JLPT',
            subtitle: 'N5 → N4 → N3',
            child: Column(
              children: [
                _RoadmapTile(
                  level: JlptLevel.n3,
                  progress: 0.68,
                  status: 'Đang học',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _RoadmapTile(
                  level: JlptLevel.n4,
                  progress: 1,
                  status: 'Hoàn thành',
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _RoadmapTile(
                  level: JlptLevel.n5,
                  progress: 1,
                  status: 'Hoàn thành',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppSectionCard(
            title: 'Thư viện kiến thức',
            child: Column(
              children: [
                _LibraryTile(
                  icon: Icons.translate,
                  title: 'Từ vựng',
                  subtitle: 'Tìm kiếm, ví dụ, audio và lưu vào notebook',
                  onTap: () {},
                ),
                _LibraryTile(
                  icon: Icons.gesture,
                  title: 'Kanji',
                  subtitle: 'Onyomi, Kunyomi, stroke order, từ ghép',
                  onTap: () {},
                ),
                _LibraryTile(
                  icon: Icons.schema_outlined,
                  title: 'Ngữ pháp',
                  subtitle: 'Cấu trúc, cách dùng và ví dụ',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapTile extends StatelessWidget {
  const _RoadmapTile({
    required this.level,
    required this.progress,
    required this.status,
    required this.onTap,
  });

  final JlptLevel level;
  final double progress;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            JlptBadge(level),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: progress),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
