import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/app_section_card.dart';

class NotebookScreen extends StatelessWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: const Text('Sổ từ vựng'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Row(
              children: [
                Icon(Icons.offline_pin_outlined),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Notebook và hàng đợi ôn tập có thể dùng offline.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppSectionCard(
            title: 'Ôn tập hôm nay',
            subtitle: '28 từ đến hạn',
            child: FilledButton(
              onPressed: () {},
              child: const Text('Bắt đầu ôn'),
            ),
          ),
          const SizedBox(height: 14),
          AppSectionCard(
            title: 'Từ đã lưu',
            subtitle: '128 từ • 4 danh sách',
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm từ...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                ...const [
                  ('経験', 'けいけん', 'kinh nghiệm'),
                  ('改善', 'かいぜん', 'cải tiến'),
                  ('目標', 'もくひょう', 'mục tiêu'),
                ].map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.$1,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${item.$2} • ${item.$3}'),
                    trailing: const Icon(Icons.chevron_right),
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
