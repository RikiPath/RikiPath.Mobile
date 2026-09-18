import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/app_section_card.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: const Text('Luyện tập')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AppSectionCard(
            title: 'Thi thử JLPT',
            subtitle: 'Mô phỏng cấu trúc từ vựng/ngữ pháp, đọc và nghe',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const JlptBadge(JlptLevel.n3),
                  title: const Text(
                    'Mock Test N3 #04',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('110 phút • Chưa làm'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: const Text('Kết quả gần nhất'),
                  subtitle: const Text('112 / 180 • Đọc hiểu: 48%'),
                  trailing: TextButton(
                    onPressed: () {},
                    child: const Text('Xem'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppSectionCard(
            title: 'Chấm bài AI',
            subtitle: 'Writing & Kanji practice',
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Writing'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.draw_outlined),
                    label: const Text('Kanji'),
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
