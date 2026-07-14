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
  List<dynamic> _aiReviews = [];
  Map<int, String> _bundleNames = {};
  Map<int, String> _catalogNames = {};
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
      // Tải cache tên gói cho cả List và Detail
      final bundles = await BookingRepository.getAllBundles();
      final catalogs = await BookingRepository.getAllCatalogs();
      final Map<int, String> bNames = {};
      final Map<int, String> cNames = {};
      for (var b in bundles) {
        if (b.bundleId != null && b.bundleName != null) bNames[b.bundleId!] = b.bundleName!;
      }
      for (var c in catalogs) {
        if (c.catalogId != null && c.catalogName != null) cNames[c.catalogId!] = c.catalogName!;
      }

      if (_selectedBookingId != null) {
        final detail = await BookingRepository.getBookingById(_selectedBookingId!);
        
        // Fetch random test results (if available)
        List<dynamic> testCatalogs = [];
        List<dynamic> aiReviews = [];
        if (detail != null && (detail.isCompleted || detail.isConfirmed)) {
          final testResultMap = await BookingRepository.getTestResultByBookingId(_selectedBookingId!);
          if (testResultMap != null && testResultMap['catalogs'] != null) {
            testCatalogs = testResultMap['catalogs'] as List<dynamic>;
          }
          // Tự động gọi phân tích AI khi load chi tiết
          aiReviews = await BookingRepository.getAiReview(_selectedBookingId!);
        }

        if (mounted) {
          setState(() {
            _bundleNames = bNames;
            _catalogNames = cNames;
            _bookingDetail = detail;
            _testResults = testCatalogs;
            _aiReviews = aiReviews;
            _loading = false;
          });
        }
      } else {
        final list = await PatientRepository.getMedicalRecords();
        if (mounted) {
          setState(() {
            _bundleNames = bNames;
            _catalogNames = cNames;
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

    String testName = '';
    if (b.bundleId != null && _bundleNames.containsKey(b.bundleId)) {
      testName = _bundleNames[b.bundleId]!;
    } else if (b.testCatalogs != null && b.testCatalogs!.isNotEmpty) {
      final names = b.testCatalogs!.map((id) => _catalogNames[id]).where((n) => n != null).toList();
      if (names.isNotEmpty) {
        testName = names.join(', ');
      }
    }

    IconData statusIcon = Icons.info_outline_rounded;
    Color statusColor = AppTheme.primary;
    if (b.isCancelled) {
      statusIcon = Icons.cancel_rounded;
      statusColor = AppTheme.error;
    } else if (b.isCompleted) {
      statusIcon = Icons.check_circle_rounded;
      statusColor = AppTheme.success;
    } else {
      statusIcon = Icons.pending_actions_rounded;
      statusColor = AppTheme.warning;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ─── Header Info ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Icon(statusIcon, size: 48, color: statusColor),
                const SizedBox(height: 12),
                if (testName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      testName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
                    ),
                  ),
                Text(
                  'Đơn xét nghiệm #${b.bookingCode ?? b.bookingId}',
                  style: TextStyle(
                    fontSize: testName.isNotEmpty ? 14 : 16, 
                    fontWeight: testName.isNotEmpty ? FontWeight.w500 : FontWeight.w700, 
                    color: testName.isNotEmpty ? AppTheme.textSecondary : AppTheme.textPrimary
                  ),
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
                if (b.patientPhoneNumber != null && b.patientPhoneNumber!.isNotEmpty)
                  _detailRow('Số điện thoại', b.patientPhoneNumber!),
                if (b.patientEmail != null && b.patientEmail!.isNotEmpty)
                  _detailRow('Email', b.patientEmail!),
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
                    final rawIndicators = it['parameters'] ?? it['indicators'] ?? it['results'] ?? it['testResults'] ?? it['metrics'] ?? [];
                    final hasIndicators = rawIndicators is List && rawIndicators.isNotEmpty;
                    
                    // Lọc trùng lặp chỉ số (nếu có)
                    final indicators = [];
                    final seenNames = <String>{};
                    if (hasIndicators) {
                      for (var ind in rawIndicators) {
                        if (ind is Map) {
                          final indName = ind['name'] ?? ind['indicatorName'] ?? ind['parameterName'] ?? ind['testName'] ?? 'Chỉ số';
                          if (!seenNames.contains(indName)) {
                            seenNames.add(indName);
                            indicators.add(ind);
                          }
                        }
                      }
                    }

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
                                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (price.isNotEmpty)
                                Text(
                                  price,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                                ),
                            ],
                          ),
                          if (indicators.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 26, top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: indicators.map<Widget>((ind) {
                                  if (ind is Map) {
                                    final indName = ind['name'] ?? ind['indicatorName'] ?? ind['parameterName'] ?? ind['testName'] ?? 'Chỉ số';
                                    final indValue = ind['value'] ?? ind['resultValue'] ?? ind['result'] ?? ind['measureValue'] ?? 'N/A';
                                    final indUnit = ind['unit'] ?? ind['measureUnit'] ?? '';
                                    final normalRange = ind['normalRange'] ?? ind['referenceRange'] ?? '';
                                    
                                    final aiItem = _aiReviews.cast<Map>().firstWhere(
                                      (ai) => ai['parameter'] == indName, 
                                      orElse: () => {}
                                    );
                                    
                                    final statusStr = aiItem['status']?.toString();
                                    final isNormal = statusStr == 'Normal' || (statusStr == null && ind['isNormal'] == true);
                                    final isAbnormal = statusStr == 'High' || statusStr == 'Low' || statusStr == 'Abnormal' || (statusStr == null && ind['isNormal'] == false);
                                    
                                    Color valColor = AppTheme.textPrimary;
                                    if (isNormal) valColor = Colors.green.shade600;
                                    if (isAbnormal) valColor = Colors.red.shade600;

                                    final comment = aiItem['comment']?.toString() ?? '';

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 5,
                                                child: Text(
                                                  '• $indName:',
                                                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 5,
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: '$indValue $indUnit',
                                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valColor),
                                                    children: [
                                                      if (normalRange.toString().isNotEmpty)
                                                        TextSpan(
                                                          text: '\n(BT: $normalRange)',
                                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (comment.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6, left: 12),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.blue.withOpacity(0.15))
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(Icons.auto_awesome, size: 14, color: Colors.blue),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        comment,
                                                        style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontStyle: FontStyle.italic, height: 1.3),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
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
    String testName = '';
    if (r.bundleId != null && _bundleNames.containsKey(r.bundleId)) {
      testName = _bundleNames[r.bundleId]!;
    } else if (r.testCatalogs != null && r.testCatalogs!.isNotEmpty) {
      final names = r.testCatalogs!.map((id) => _catalogNames[id]).where((n) => n != null).toList();
      if (names.isNotEmpty) {
        testName = names.join(', ');
      }
    }

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
                    if (testName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          testName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.primary),
                        ),
                      ),
                    Text(
                      'Bệnh án #${r.bookingCode ?? r.bookingId}',
                      style: TextStyle(
                        fontWeight: testName.isNotEmpty ? FontWeight.w500 : FontWeight.w700, 
                        fontSize: testName.isNotEmpty ? 12 : 14, 
                        color: testName.isNotEmpty ? AppTheme.textSecondary : AppTheme.textPrimary
                      ),
                    ),
                    Text(
                      r.patientName ?? 'Bệnh nhân',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
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
