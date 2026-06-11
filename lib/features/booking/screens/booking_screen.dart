import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/auth_utils.dart';
import '../../../shared/models/bundle_model.dart';
import '../data/booking_repository.dart';
import 'vnpay_webview_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 0;

  final _stepLabels = ['Bệnh nhân', 'Xét nghiệm', 'Ngày giờ', 'Xác nhận', 'Thanh toán'];

  Map<String, dynamic>? _selectedPatient;
  Map<String, dynamic>? _selectedItems;
  Map<String, dynamic>? _selectedDateTime;
  String? _bookingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Đặt lịch xét nghiệm'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            }
          },
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _PatientSelectionStep(
                    onNext: (p) => setState(() { _selectedPatient = p; _currentStep = 1; })),
                _TestSelectionStep(
                    onNext: (i) => setState(() { _selectedItems = i; _currentStep = 2; }),
                    onBack: () => setState(() => _currentStep = 0)),
                _DateTimeStep(
                    onNext: (dt) => setState(() { _selectedDateTime = dt; _currentStep = 3; }),
                    onBack: () => setState(() => _currentStep = 1)),
                _ConfirmStep(
                    patient: _selectedPatient,
                    items: _selectedItems,
                    dateTime: _selectedDateTime,
                    onNext: (id) => setState(() { _bookingId = id; _currentStep = 4; }),
                    onBack: () => setState(() => _currentStep = 2)),
                _PaymentStep(
                    bookingId: _bookingId,
                    items: _selectedItems,
                    onFinish: () => context.go('/booking/success?bookingId=$_bookingId'),
                    onBack: () => setState(() => _currentStep = 3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(_stepLabels.length * 2 - 1, (i) {
              if (i.isOdd) {
                final isDone = i ~/ 2 < _currentStep;
                return Expanded(child: Container(height: 2,
                    color: isDone ? AppTheme.secondary : AppTheme.stepPending));
              }
              final idx = i ~/ 2;
              final isActive = idx == _currentStep;
              final isDone = idx < _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isActive ? 30 : 26, height: isActive ? 30 : 26,
                decoration: BoxDecoration(
                  color: isDone ? AppTheme.secondary : isActive ? AppTheme.primary : AppTheme.stepPending,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text('${idx + 1}',
                          style: TextStyle(color: isDone || isActive ? Colors.white : AppTheme.textHint,
                              fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.normal)),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: _stepLabels.asMap().entries.map((e) => Expanded(
              child: Text(e.value, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10,
                      color: e.key == _currentStep ? AppTheme.primary : AppTheme.textHint,
                      fontWeight: e.key == _currentStep ? FontWeight.w600 : FontWeight.normal)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Patient ─────────────────────────────────────────────────────────
class _PatientSelectionStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  const _PatientSelectionStep({required this.onNext});
  @override
  State<_PatientSelectionStep> createState() => _PatientSelectionStepState();
}

class _PatientSelectionStepState extends State<_PatientSelectionStep> {
  List<Map<String, dynamic>> _patients = [];
  bool _loading = true;
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ApiClient.get('patient/v1/patients/mine',
          params: {'page': 1, 'pageSize': 50});
      final data = response.data;
      List items = data['items'] ?? data['data'] ?? [];
      if (mounted) setState(() { _patients = items.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn hồ sơ bệnh nhân',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Expanded(
                  child: _patients.isEmpty
                      ? Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_add_alt_1_rounded, size: 56, color: AppTheme.textHint),
                            const SizedBox(height: 12),
                            const Text('Chưa có hồ sơ bệnh nhân',
                                style: TextStyle(color: AppTheme.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.push('/create-profile'),
                              child: const Text('Tạo hồ sơ'),
                            ),
                          ],
                        ))
                      : ListView.separated(
                          itemCount: _patients.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p = _patients[i];
                            final isSelected = _selected == p;
                            return GestureDetector(
                              onTap: () => setState(() => _selected = p),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 2),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: Row(children: [
                                  CircleAvatar(
                                    backgroundColor: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
                                    child: Text((p['fullName']?.toString() ?? 'U')[0].toUpperCase(),
                                        style: TextStyle(color: isSelected ? Colors.white : AppTheme.primary,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(p['fullName']?.toString() ?? 'Bệnh nhân',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text(p['phone']?.toString() ?? '',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ])),
                                  if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
                                ]),
                              ),
                            );
                          }),
                ),
                if (_selected != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity,
                      child: ElevatedButton(
                          onPressed: () => widget.onNext(_selected!),
                          child: const Text('Tiếp tục →'))),
                ],
              ],
            ),
          );
  }
}

// ─── Step 2: Test Selection ───────────────────────────────────────────────────
class _TestSelectionStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;
  const _TestSelectionStep({required this.onNext, required this.onBack});

  @override
  State<_TestSelectionStep> createState() => _TestSelectionStepState();
}

class _TestSelectionStepState extends State<_TestSelectionStep> {
  bool _isPackageMode = true;
  bool _loading = true;
  List<BundleModel> _bundles = [];
  List<CatalogModel> _catalogs = [];
  
  dynamic _selectedBundleId;
  final Set<dynamic> _selectedCatalogIds = {};
  final Map<dynamic, bool> _expandedBundles = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final bundles = await BookingRepository.getAllBundles();
      final catalogs = await BookingRepository.getAllCatalogs();
      if (mounted) {
        setState(() {
          _bundles = bundles;
          _catalogs = catalogs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu xét nghiệm: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _handleContinue() {
    if (_isPackageMode) {
      final selectedBundle = _bundles.firstWhere((b) => b.bundleId == _selectedBundleId);
      final price = selectedBundle.price ?? 0;
      final includes = selectedBundle.catalogs?.map((c) => {
        'catalogId': c.catalogId,
        'testName': c.displayName,
        'price': c.price,
        'description': c.description,
      }).toList() ?? [];
      
      widget.onNext({
        'source': 'package',
        'package': {
          'bundleId': selectedBundle.bundleId,
          'title': selectedBundle.displayName,
          'includes': includes,
          'price': selectedBundle.price,
          'description': selectedBundle.description,
          'total': price,
        },
        'total': price,
        'name': selectedBundle.displayName,
        'price': price,
      });
    } else {
      final selectedItems = _catalogs.where((c) => _selectedCatalogIds.contains(c.catalogId)).toList();
      final total = selectedItems.fold<num>(0, (sum, item) => sum + (item.price ?? 0));
      final itemsList = selectedItems.map((c) => {
        'catalogId': c.catalogId,
        'testName': c.displayName,
        'price': c.price,
        'description': c.description,
      }).toList();

      widget.onNext({
        'source': 'catalog',
        'items': itemsList,
        'total': total,
        'name': itemsList.map((e) => e['testName']).join(', '),
        'price': total,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    String summaryTitle = 'Chưa chọn xét nghiệm';
    num summaryPrice = 0;
    bool canContinue = false;

    if (_isPackageMode) {
      if (_selectedBundleId != null) {
        final selectedBundle = _bundles.firstWhere((b) => b.bundleId == _selectedBundleId, orElse: () => _bundles.first);
        summaryTitle = selectedBundle.displayName;
        summaryPrice = selectedBundle.price ?? 0;
        canContinue = true;
      }
    } else {
      if (_selectedCatalogIds.isNotEmpty) {
        summaryTitle = '${_selectedCatalogIds.length} xét nghiệm tùy chọn';
        summaryPrice = _catalogs
            .where((c) => _selectedCatalogIds.contains(c.catalogId))
            .fold<num>(0, (sum, item) => sum + (item.price ?? 0));
        canContinue = true;
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton('Chọn gói có sẵn', _isPackageMode, () {
                setState(() => _isPackageMode = true);
              }),
              const SizedBox(width: 12),
              _buildTabButton('Tùy chỉnh xét nghiệm', !_isPackageMode, () {
                setState(() => _isPackageMode = false);
              }),
            ],
          ),
        ),
        Expanded(
          child: _isPackageMode ? _buildPackageList() : _buildCatalogList(),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isPackageMode ? 'Gói đã chọn' : 'Đã chọn',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      Text(
                        summaryTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_formatPrice(summaryPrice)} đ',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: widget.onBack,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Quay lại'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: canContinue ? _handleContinue : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Tiếp tục'),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String text, bool isActive, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? AppTheme.primary : const Color(0xFFE2E8F0),
        foregroundColor: isActive ? Colors.white : AppTheme.textSecondary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPackageList() {
    if (_bundles.isEmpty) {
      return const Center(child: Text('Không có gói xét nghiệm nào', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _bundles.length,
      itemBuilder: (context, index) {
        final pkg = _bundles[index];
        final isSelected = _selectedBundleId == pkg.bundleId;
        final catalogs = pkg.catalogs ?? [];
        final isExpanded = _expandedBundles[pkg.bundleId] ?? false;
        final displayedCatalogs = isExpanded || catalogs.length <= 5 
            ? catalogs 
            : catalogs.sublist(0, 5);
        final hasMore = catalogs.length > 5;

        return GestureDetector(
          onTap: () => setState(() => _selectedBundleId = pkg.bundleId),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pkg.displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                    ),
                    Text(
                      pkg.displayPrice,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primary),
                    ),
                  ],
                ),
                if (pkg.description != null && pkg.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    pkg.description!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
                const Divider(height: 24),
                const Text(
                  'Bao gồm:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedCatalogs.length,
                  itemBuilder: (context, idx) {
                    final cat = displayedCatalogs[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppTheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.description ?? cat.displayName,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (hasMore) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _expandedBundles[pkg.bundleId] = !isExpanded;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isExpanded ? 'Thu gọn' : 'Xem thêm (${catalogs.length - 5})',
                      style: const TextStyle(fontSize: 12, color: AppTheme.primary),
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCatalogList() {
    if (_catalogs.isEmpty) {
      return const Center(child: Text('Không có xét nghiệm nào', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _catalogs.length,
      itemBuilder: (context, index) {
        final cat = _catalogs[index];
        final isSelected = _selectedCatalogIds.contains(cat.catalogId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            side: BorderSide(
              color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            activeColor: AppTheme.primary,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedCatalogIds.add(cat.catalogId);
                } else {
                  _selectedCatalogIds.remove(cat.catalogId);
                }
              });
            },
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    cat.displayName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                ),
                Text(
                  cat.displayPrice,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary),
                ),
              ],
            ),
            subtitle: cat.description != null && cat.description!.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      cat.description!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  )
                : null,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      },
    );
  }

  String _formatPrice(num p) {
    return p.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

// ─── Step 3: DateTime ─────────────────────────────────────────────────────────
class _DateTimeStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;
  const _DateTimeStep({required this.onNext, required this.onBack});

  @override
  State<_DateTimeStep> createState() => _DateTimeStepState();
}

class _DateTimeStepState extends State<_DateTimeStep> {
  DateTime? _selectedDate;
  String? _selectedTime;
  List<dynamic> _slotCounts = [];
  bool _loadingSlots = false;

  final List<DateTime> _days = List.generate(30, (i) {
    final today = DateTime.now();
    final d = today.add(Duration(days: i + 1));
    return DateTime(d.year, d.month, d.day, 12, 0, 0, 0);
  });

  final _morningSlots = ['07:00', '08:00', '09:00', '10:00', '11:00'];
  final _afternoonSlots = ['13:00', '14:00', '15:00', '16:00'];

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    try {
      final res = await BookingRepository.getAppointmentSlotCounts();
      List data = [];
      if (res is List) {
        data = res;
      } else if (res is Map) {
        data = res['items'] ?? res['data'] ?? [];
      }
      if (mounted) {
        setState(() {
          _slotCounts = data;
          _loadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSlots = false);
      }
    }
  }

  bool _isSlotFullyBooked(DateTime? date, String time) {
    if (date == null) return false;
    final dateStr = date.toIso8601String().split('T')[0];
    final timeBlock = '$time:00';

    final slot = _slotCounts.firstWhere(
      (s) => s['appointmentDate'] == dateStr && s['timeBlock'] == timeBlock,
      orElse: () => null,
    );
    return slot != null ? slot['isFullyBooked'] == true : false;
  }

  int _getRemainingSlots(DateTime? date, String time) {
    if (date == null) return 10;
    final dateStr = date.toIso8601String().split('T')[0];
    final timeBlock = '$time:00';

    final slot = _slotCounts.firstWhere(
      (s) => s['appointmentDate'] == dateStr && s['timeBlock'] == timeBlock,
      orElse: () => null,
    );
    final count = slot != null ? (slot['totalBookings'] ?? 0) as int : 0;
    return 10 - count;
  }

  String _formatDayLabel(DateTime d) {
    final Map<int, String> weekdays = {
      1: 'T2', 2: 'T3', 3: 'T4', 4: 'T5', 5: 'T6', 6: 'T7', 7: 'CN'
    };
    return '${weekdays[d.weekday]}, ${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Row(
              children: [
                Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trung Tâm Xét nghiệm FPT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      SizedBox(height: 2),
                      Text('Tòa nhà F-Town 1, Khu Công nghệ Cao Sài Gòn, Thủ Đức, TP.HCM',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 18),
              SizedBox(width: 8),
              Text('Chọn ngày (trong 30 ngày tới)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              itemBuilder: (context, idx) {
                final d = _days[idx];
                final isSelected = _selectedDate == d;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedDate = d;
                    _selectedTime = null;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      _formatDayLabel(d),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.access_time_filled_rounded, color: AppTheme.primary, size: 18),
              SizedBox(width: 8),
              Text('Chọn khung giờ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loadingSlots
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeSection('Ca sáng (07:00 - 11:00)', _morningSlots),
                        const SizedBox(height: 16),
                        _buildTimeSection('Ca chiều (13:00 - 17:00)', _afternoonSlots),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: const Text('← Quay lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedDate != null && _selectedTime != null
                      ? () => widget.onNext({
                            'date': _selectedDate!.toIso8601String(),
                            'time': _selectedTime!,
                          })
                      : null,
                  child: const Text('Tiếp tục →'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(String title, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 2.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: slots.map((t) {
            final isSelected = t == _selectedTime;
            final isFullyBooked = _isSlotFullyBooked(_selectedDate, t);
            final remaining = _getRemainingSlots(_selectedDate, t);

            return GestureDetector(
              onTap: _selectedDate == null || isFullyBooked ? null : () => setState(() => _selectedTime = t),
              child: Opacity(
                opacity: _selectedDate == null ? 0.5 : 1.0,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primary 
                        : isFullyBooked 
                            ? const Color(0xFFFEE2E2) 
                            : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.primary 
                          : isFullyBooked 
                              ? const Color(0xFFFCA5A5) 
                              : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t,
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white 
                              : isFullyBooked 
                                  ? const Color(0xFFEF4444) 
                                  : AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: isSelected || isFullyBooked ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          isFullyBooked ? 'Hết chỗ' : 'Còn $remaining chỗ',
                          style: TextStyle(
                            color: isSelected 
                                ? Colors.white70 
                                : isFullyBooked 
                                    ? const Color(0xFFEF4444) 
                                    : AppTheme.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Step 4: Confirm ──────────────────────────────────────────────────────────
class _ConfirmStep extends StatefulWidget {
  final Map<String, dynamic>? patient;
  final Map<String, dynamic>? items;
  final Map<String, dynamic>? dateTime;
  final Function(String) onNext;
  final VoidCallback onBack;
  const _ConfirmStep({this.patient, this.items, this.dateTime,
      required this.onNext, required this.onBack});
  @override
  State<_ConfirmStep> createState() => _ConfirmStepState();
}

class _ConfirmStepState extends State<_ConfirmStep> {
  bool _loading = false;

  Future<void> _handleConfirm() async {
    final patient = widget.patient;
    final items = widget.items;
    final dateTime = widget.dateTime;

    if (patient == null || items == null || dateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu thông tin đặt lịch!'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final patientId = patient['patientId'];
      final fullName = patient['fullName'];
      final phone = patient['phone'];
      final email = patient['email'];

      if (patientId == null || fullName == null || phone == null || email == null) {
        throw 'Thông tin hồ sơ bệnh nhân không đầy đủ. Vui lòng kiểm tra lại!';
      }

      final createdBy = await AuthUtils.getUserId() ?? '';
      
      final source = items['source'];
      final bundleId = source == 'package' ? items['package']['bundleId'] ?? 0 : 0;
      
      List<dynamic> catalogs = [];
      if (source == 'catalog') {
        catalogs = (items['items'] as List).map((it) => it['catalogId']).toList();
      }

      final rawDate = dateTime['date'] as String;
      final dateStr = rawDate.split('T')[0];
      
      final rawTime = dateTime['time'] as String;
      final timeBlock = rawTime.contains(':00') ? rawTime : '$rawTime:00';

      final payload = {
        'patientId': patientId,
        'patientPhoneNumber': phone,
        'patientName': fullName,
        'patientEmail': email,
        'createdBy': createdBy,
        'bundleId': bundleId,
        'catalogs': catalogs,
        'slotDTO': {
          'appointmentDate': dateStr,
          'timeBlock': timeBlock,
        }
      };

      final response = await BookingRepository.createBooking(payload);
      
      final newBookingId = response['bookingId']?.toString() ?? response['id']?.toString() ?? response['data']?.toString();
      
      if (newBookingId != null && newBookingId.isNotEmpty) {
        widget.onNext(newBookingId);
      } else {
        throw 'Không lấy được mã đơn hàng từ server!';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final items = widget.items;
    final dateTime = widget.dateTime;

    String testName = 'Không rõ';
    num total = 0;
    if (items != null) {
      if (items['source'] == 'package') {
        testName = items['package']?['title'] ?? 'Gói xét nghiệm';
      } else if (items['source'] == 'catalog') {
        testName = (items['items'] as List).map((e) => e['testName']).join(', ');
      }
      total = items['total'] ?? 0;
    }

    final appointmentDate = dateTime != null ? (dateTime['date'] as String).split('T')[0] : '';
    final timeBlock = dateTime != null ? dateTime['time'] as String : '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Xác nhận thông tin',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.cardShadow,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Bệnh nhân', patient?['fullName'] ?? ''),
                    _infoRow('Số điện thoại', patient?['phone'] ?? ''),
                    const Divider(height: 24),
                    _infoRow('Xét nghiệm', testName),
                    const Divider(height: 24),
                    _infoRow('Ngày khám', appointmentDate),
                    _infoRow('Giờ khám', timeBlock),
                    const Divider(height: 24),
                    _infoRow('Tổng tiền', '${_formatPrice(total)} đ', isTotal: true),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: widget.onBack, child: const Text('← Quay lại'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _loading ? null : _handleConfirm,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Xác nhận'),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: isTotal ? AppTheme.primary : AppTheme.textPrimary,
                fontSize: isTotal ? 16 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(num p) {
    return p.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

// ─── Step 5: Payment ──────────────────────────────────────────────────────────
class _PaymentStep extends StatefulWidget {
  final String? bookingId;
  final Map<String, dynamic>? items;
  final VoidCallback onFinish;
  final VoidCallback onBack;
  const _PaymentStep({this.bookingId, this.items, required this.onFinish, required this.onBack});

  @override
  State<_PaymentStep> createState() => _PaymentStepState();
}

class _PaymentStepState extends State<_PaymentStep> {
  bool _loadingUrl = false;

  Future<void> _handlePayment() async {
    final bookingId = widget.bookingId;
    final total = widget.items?['total'] ?? 0;

    if (bookingId == null || total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Thiếu mã đơn hàng hoặc tổng tiền!'), backgroundColor: AppTheme.error),
      );
      return;
    }

    // Hiển thị Warning Modal hoàn tiền trước (như web)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Chính sách hoàn tiền', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lưu ý quan trọng:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            SizedBox(height: 8),
            Text('• Thanh toán sẽ không được hoàn nếu hủy trong vòng 24 giờ trước lịch hẹn.', style: TextStyle(fontSize: 12)),
            SizedBox(height: 4),
            Text('• Nếu lịch hẹn vào thứ 7 hoặc chủ nhật, sẽ không được hoàn tiền khi hủy.', style: TextStyle(fontSize: 12)),
            SizedBox(height: 12),
            Text('Bạn có chắc chắn muốn tiếp tục thanh toán?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loadingUrl = true);
    try {
      final vnpayUrl = await BookingRepository.getVnPayUrl(bookingId, total);
      if (vnpayUrl == null || vnpayUrl.isEmpty) {
        throw 'Không tạo được link thanh toán VNPay. Vui lòng kiểm tra lại!';
      }

      if (!mounted) return;
      
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => VnPayWebViewScreen(url: vnpayUrl),
        ),
      );

      if (success == true) {
        widget.onFinish();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thanh toán không hoàn thành hoặc bị huỷ!'), backgroundColor: AppTheme.warning),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingUrl = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items?['total'] ?? 0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(children: [
              const Icon(Icons.payment_rounded, size: 56, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text('Booking #${widget.bookingId}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Text('${_formatPrice(total)} đ',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              const SizedBox(height: 8),
              const Text('Thanh toán qua VNPay',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚡ VNPay sẽ mở trong ứng dụng để xử lý thanh toán an toàn',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
            ]),
          ),
          const Spacer(),
          SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadingUrl ? null : _handlePayment,
                icon: _loadingUrl 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.payment_rounded),
                label: const Text('Thanh toán qua VNPay'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00509D)),
              )),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
              child: OutlinedButton(onPressed: widget.onBack, child: const Text('← Quay lại'))),
        ],
      ),
    );
  }

  String _formatPrice(num p) {
    return p.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
