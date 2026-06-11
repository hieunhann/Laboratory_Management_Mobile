import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key});
  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Kết quả xét nghiệm'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.of(context).pop()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.science_rounded, size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            const Text('Kết quả xét nghiệm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Xem kết quả từ lịch sử đặt lịch của bạn',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.history_rounded),
              label: const Text('Xem lịch sử'),
            ),
          ],
        ),
      ),
    );
  }
}
