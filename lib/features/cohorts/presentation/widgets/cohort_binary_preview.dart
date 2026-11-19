import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

/// Shared preview dialog for binary homework scans, transfer evidence, and
/// retake verification files fetched via authenticated API endpoints.
Future<void> showCohortBinaryAttachmentPreview(
  BuildContext context, {
  required String title,
  required Future<({Uint8List bytes, String contentType})> Function() loader,
}) async {
  try {
    final file = await loader();
    if (!context.mounted) return;
    final isPdf = file.contentType.toLowerCase().contains('pdf');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: isPdf
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 48,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tệp PDF (${(file.bytes.length / 1024).toStringAsFixed(0)} KB).',
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 420,
                  maxWidth: 360,
                ),
                child: Image.memory(
                  file.bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Text(
                    'Không hiển thị được định dạng tệp đính kèm này.',
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(appErrorMessage(error, context.l10n))),
    );
  }
}
