import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/models/booking_model.dart';
import '../../booking/data/booking_repository.dart';
import '../../profile/data/patient_repository.dart';
import '../../../core/utils/format_utils.dart';

class MedicalRecordScreen extends StatefulWidget {
  final String? bookingId;
  const MedicalRecordScreen({super.key, this.bookingId});

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  String? _selectedBookingId;
  BookingModel? _bookingDetail;
  List<dynamic> _testResults = [];
  List<BookingModel> _records = [];
  bool _loading = true;
  bool _downloading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedBookingId = widget.bookingId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      if (_selectedBookingId != null) {
        final detail = await BookingRepository.getBookingById(_selectedBookingId!);
        
        // Fetch random test results (if available)
        List<dynamic> testCatalogs = [];
        if (detail != null && (detail.isCompleted || detail.isConfirmed)) {
          final testResultMap = await BookingRepository.getTestResultByBookingId(_selectedBookingId!);
          if (testResultMap != null && testResultMap['catalogs'] != null) {
            testCatalogs = testResultMap['catalogs'] as List<dynamic>;
          }
        }

        if (mounted) {
          setState(() {
            _bookingDetail = detail;
            _testResults = testCatalogs;
            _loading = false;
          });
        }
      } else {
        final list = await PatientRepository.getMedicalRecords();
        if (mounted) {
          setState(() {
            _records = list;
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleDownload(String bookingId) async {
    setState(() => _downloading = true);
    try {
      // Vì API download trả về File binary, ta dùng url_launcher để mở trình duyệt tải file về máy
      final url = Uri.parse('${AppConfig.baseUrl}testorder/api/TestReport/DownloadReport/$bookingId');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang tiến hành mở và tải file PDF...'),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw 'Không thể mở trình duyệt để tải file.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _selectedBookingId != null ? 'Chi tiết kết quả' : 'Kết quả xét nghiệm';
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (_selectedBookingId != null && widget.bookingId == null) {
              setState(() {
                _selectedBookingId = null;
                _bookingDetail = null;
              });
              _loadData();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _selectedBookingId != null
              ? _buildDetailView()
              : _buildListView(),
    );
  }

  Widget _buildDetailView() {
    if (_bookingDetail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            const Text('Không tìm thấy thông tin đơn hàng này.',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (widget.bookingId != null) {
                  context.pop();
                } else {
                  setState(() {
                    _selectedBookingId = null;
                  });
                  _loadData();
                }
              },
              child: const Text('Quay lại'),
            ),
          ],
        ),
      );
    }

    final b = _bookingDetail!;
    final formattedPrice = FormatUtils.formatCurrency(b.totalAmount);
    final date = b.appointmentDate ?? '';
    final time = FormatUtils.formatTime(b.appointmentTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ─── Header Card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_rounded, size: 48, color: AppTheme.success),
                const SizedBox(height: 12),
                Text(
                  'Đơn xét nghiệm #${b.bookingCode ?? b.bookingId}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày khám: $date  $time',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _detailRow('Bệnh nhân', b.patientName ?? ''),
                _detailRow('Trạng thái', FormatUtils.formatBookingStatus(b.status)),
                _detailRow('Thanh toán', (b.isPaid || b.isCompleted) ? 'Đã thanh toán' : 'Chưa thanh toán'),
                _detailRow('Tổng tiền', formattedPrice, isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Test items Card ──────────────────────────────
          if (_testResults.isNotEmpty || (b.items != null && b.items!.isNotEmpty)) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Các xét nghiệm đã thực hiện',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ...(_testResults.isNotEmpty ? _testResults : b.items!).map((it) {
                    final name = it['catalogName']?.toString() ?? it['testName']?.toString() ?? it['displayName']?.toString() ?? 'Chỉ số xét nghiệm';
                    final price = it['price'] != null ? FormatUtils.formatCurrency(it['price'] as num) : '';
                    
                    // Lấy ra danh sách indicators/results
                    final indicators = it['parameters'] ?? it['indicators'] ?? it['results'] ?? it['testResults'] ?? it['metrics'] ?? [];
                    final hasIndicators = indicators is List && indicators.isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.biotech_rounded, size: 18, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (price.isNotEmpty)
                                Text(
                                  price,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                                ),
                            ],
                          ),
                          if (hasIndicators)
                            Padding(
                              padding: const EdgeInsets.only(left: 26, top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: indicators.map<Widget>((ind) {
                                  if (ind is Map) {
                                    final indName = ind['name'] ?? ind['indicatorName'] ?? ind['parameterName'] ?? ind['testName'] ?? 'Chỉ số';
                                    final indValue = ind['value'] ?? ind['resultValue'] ?? ind['result'] ?? ind['measureValue'] ?? 'N/A';
                                    final indUnit = ind['unit'] ?? ind['measureUnit'] ?? '';
                                    final normalRange = ind['normalRange'] ?? ind['referenceRange'] ?? '';
                                    
                                    String displayText = '•  $indName: $indValue $indUnit';
                                    if (normalRange.toString().isNotEmpty) {
                                      displayText += ' (BT: $normalRange)';
                                    }
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        displayText,
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ─── Actions ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloading ? null : () => _handleDownload(b.bookingId.toString()),
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.file_download_outlined),
              label: Text(_downloading ? 'Đang tải PDF...' : 'Tải kết quả PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final filtered = _records.where((r) {
      final name = (r.patientName ?? '').toLowerCase();
      final id = (r.bookingId ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();

    return Column(
      children: [
        // ─── Search Bar ──────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: const InputDecoration(
              hintText: 'Tìm theo tên hoặc mã đơn...',
              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),

        // ─── List of Records ─────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final r = filtered[i];
                      return _buildRecordCard(r);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(BookingModel r) {
    final date = r.appointmentDate ?? '';
    final time = FormatUtils.formatTime(r.appointmentTime);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.science_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bệnh án #${r.bookingId}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    Text(
                      r.patientName ?? 'Bệnh nhân',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.file_download_outlined, color: AppTheme.primary),
                onPressed: () => _handleDownload(r.bookingId.toString()),
              )
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                '$date  $time',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedBookingId = r.bookingId.toString();
                  });
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Xem chi tiết', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? AppTheme.primary : AppTheme.textPrimary,
              fontSize: isTotal ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 56, color: AppTheme.textHint),
          const SizedBox(height: 16),
          const Text(
            'Chưa có hồ sơ bệnh án nào hoàn thành',
            style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kết quả sẽ hiển thị sau khi quá trình xét nghiệm hoàn tất',
            style: TextStyle(color: AppTheme.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
