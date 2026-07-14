import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../config/app_theme.dart';
import '../data/role_permission_repository.dart';

class RolePermissionManagementScreen extends StatefulWidget {
  const RolePermissionManagementScreen({super.key});

  @override
  State<RolePermissionManagementScreen> createState() =>
      _RolePermissionManagementScreenState();
}

class _RolePermissionManagementScreenState
    extends State<RolePermissionManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _permissions = [];
  bool _isLoading = true;

  // Search queries
  String _roleSearchQuery = '';
  String _permissionSearchQuery = '';

  // Horizontal Color Picker options for new roles
  final List<String> _colorOptions = [
    '0xFF1565C0', // Deep Blue
    '0xFF00897B', // Teal
    '0xFFF57C00', // Orange
    '0xFFE53935', // Red
    '0xFF673AB7', // Purple
    '0xFFE91E63', // Pink
    '0xFF9E9E9E', // Grey
    '0xFF3F51B5', // Indigo
    '0xFF4CAF50', // Green
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final roles = await RolePermissionRepository.getRoles();
      final permissions = await RolePermissionRepository.getPermissions();
      setState(() {
        _roles = roles;
        _permissions = permissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast('Có lỗi xảy ra khi tải dữ liệu');
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? AppTheme.error : AppTheme.secondary,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  // ─── Actions: Add Role ─────────────────────────────────────
  void _openAddRoleDialog() {
    final formKey = GlobalKey<FormState>();
    String code = '';
    String name = '';
    String desc = '';
    String selectedColor = _colorOptions[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        'Thêm vai trò mới',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Mã vai trò (Ví dụ: Supervisor)',
                          hintText: 'Chữ cái liền nhau, không dấu',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mã vai trò';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                            return 'Mã vai trò chỉ gồm chữ cái và số';
                          }
                          return null;
                        },
                        onSaved: (val) => code = val!.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Tên vai trò',
                          hintText: 'Nhập tên hiển thị (Ví dụ: Giám sát viên)',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên vai trò';
                          }
                          return null;
                        },
                        onSaved: (val) => name = val!.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Mô tả vai trò',
                          hintText: 'Nhập chi tiết nhiệm vụ vai trò',
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mô tả';
                          }
                          return null;
                        },
                        onSaved: (val) => desc = val!.trim(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Màu sắc đại diện',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _colorOptions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final colorHex = _colorOptions[index];
                            final color = Color(int.parse(colorHex));
                            final isSelected = selectedColor == colorHex;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() => selectedColor = colorHex);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: AppTheme.textPrimary,
                                          width: 3,
                                        )
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              final success =
                                  await RolePermissionRepository.addRole(
                                code: code,
                                name: name,
                                desc: desc,
                                color: selectedColor,
                              );
                              if (context.mounted) {
                                if (success) {
                                  _showToast('Thêm vai trò thành công!');
                                  context.pop();
                                  _loadData();
                                } else {
                                  _showToast('Mã vai trò đã tồn tại!',
                                      isError: true);
                                }
                              }
                            }
                          },
                          child: const Text('Tạo vai trò'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Actions: Add Permission ───────────────────────────────
  void _openAddPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Định nghĩa Quyền hạn'),
        content: const Text(
          'Quyền hạn hệ thống được định nghĩa tĩnh trong mã nguồn Backend (nhằm kiểm soát bảo mật API). Bạn chỉ có thể gán các quyền hạn này vào các vai trò khác nhau chứ không thể tự tạo thêm quyền hạn mới từ ứng dụng di động.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  // ─── Actions: Edit Role Permissions ────────────────────────
  void _openEditRolePermissions(Map<String, dynamic> role) {
    final List<String> currentRolePerms =
        List<String>.from(role['permissions'] ?? []);
    final roleColor = Color(int.parse(role['color'] ?? '0xFF1565C0'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Group permissions
            final Map<String, List<Map<String, dynamic>>> groupedPerms = {};
            for (var p in _permissions) {
              final g = p['group']?.toString() ?? 'Chung';
              groupedPerms.putIfAbsent(g, () => []).add(p);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Sheet bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: roleColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Phân quyền: ${role['name']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(
                      role['desc']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  // Select All / Deselect All
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đã chọn ${currentRolePerms.length}/${_permissions.length} quyền',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  currentRolePerms.clear();
                                  currentRolePerms.addAll(
                                    _permissions.map((p) => p['code'].toString()),
                                  );
                                });
                              },
                              child: const Text('Chọn hết',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            const Text('|',
                                style: TextStyle(color: Colors.grey)),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  currentRolePerms.clear();
                                });
                              },
                              child: const Text('Bỏ chọn hết',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 12),
                  // Permissions list (scrollable)
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: groupedPerms.keys.map((groupName) {
                        final list = groupedPerms[groupName]!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.08),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppTheme.radiusMd),
                                  ),
                                ),
                                child: Text(
                                  groupName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: roleColor,
                                  ),
                                ),
                              ),
                              // Checklist
                              ...list.map((perm) {
                                final code = perm['code'].toString();
                                final isChecked = currentRolePerms.contains(code);
                                return CheckboxListTile(
                                  activeColor: roleColor,
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                  title: Text(
                                    perm['name']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    perm['desc']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  value: isChecked,
                                  onChanged: (bool? val) {
                                    setModalState(() {
                                      if (val == true) {
                                        if (!currentRolePerms.contains(code)) {
                                          currentRolePerms.add(code);
                                        }
                                      } else {
                                        currentRolePerms.remove(code);
                                      }
                                    });
                                  },
                                );
                              }),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  // Save button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.pop(),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: roleColor,
                            ),
                            onPressed: () async {
                              await RolePermissionRepository
                                  .updateRolePermissions(
                                role['code'].toString(),
                                currentRolePerms,
                              );
                              if (context.mounted) {
                                _showToast(
                                    'Đã cập nhật quyền cho vai trò ${role['name']}!');
                                context.pop();
                                _loadData();
                              }
                            },
                            child: const Text('Lưu thay đổi'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Quản lý Vai trò & Quyền'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Vai trò (Roles)'),
            Tab(text: 'Quyền hạn (Permissions)'),
            Tab(text: 'Thành viên (Users)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRolesTab(),
                _buildPermissionsTab(),
                _buildUsersTab(),
              ],
            ),
    );
  }

  // ─── TAB 1: ROLES ─────────────────────────────────────────
  Widget _buildRolesTab() {
    final filteredRoles = _roles.where((r) {
      final name = r['name']?.toString().toLowerCase() ?? '';
      final code = r['code']?.toString().toLowerCase() ?? '';
      final query = _roleSearchQuery.toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();

    return Column(
      children: [
        // Search bar & Add button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm vai trò...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _roleSearchQuery = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _openAddRoleDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Roles List
        Expanded(
          child: filteredRoles.isEmpty
              ? const Center(
                  child: Text(
                    'Không tìm thấy vai trò nào',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredRoles.length,
                  itemBuilder: (context, index) {
                    final role = filteredRoles[index];
                    final colorHex = role['color'] ?? '0xFF1565C0';
                    final color = Color(int.parse(colorHex));
                    final perms = List<String>.from(role['permissions'] ?? []);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            leading: Container(
                              width: 6,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    role['name']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    role['code']?.toString() ?? '',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Đã gán ${perms.length} quyền',
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  bottom: 16,
                                  top: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role['desc']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Permissions tags preview
                                    if (perms.isEmpty)
                                      const Text(
                                        'Chưa gán quyền hạn nào.',
                                        style: TextStyle(
                                          color: AppTheme.error,
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    else
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: perms.map((pCode) {
                                          final pName = _permissions.firstWhere(
                                            (element) =>
                                                element['code'] == pCode,
                                            orElse: () => {'name': pCode},
                                          )['name'];
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.background,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              pName.toString(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: color,
                                          side: BorderSide(color: color),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                        ),
                                        onPressed: () =>
                                            _openEditRolePermissions(role),
                                        icon: const Icon(Icons.security_rounded,
                                            size: 16),
                                        label: const Text('Thay đổi phân quyền'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── TAB 2: PERMISSIONS ───────────────────────────────────
  Widget _buildPermissionsTab() {
    // Filter permissions
    final filteredPerms = _permissions.where((p) {
      final name = p['name']?.toString().toLowerCase() ?? '';
      final code = p['code']?.toString().toLowerCase() ?? '';
      final group = p['group']?.toString().toLowerCase() ?? '';
      final query = _permissionSearchQuery.toLowerCase();
      return name.contains(query) || code.contains(query) || group.contains(query);
    }).toList();

    // Group filtered permissions by group name
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var p in filteredPerms) {
      final groupName = p['group']?.toString() ?? 'Chung';
      grouped.putIfAbsent(groupName, () => []).add(p);
    }

    return Column(
      children: [
        // Search bar & Add button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm quyền hạn...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _permissionSearchQuery = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _openAddPermissionDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Grouped Permissions List
        Expanded(
          child: grouped.isEmpty
              ? const Center(
                  child: Text(
                    'Không tìm thấy quyền hạn nào',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, index) {
                    final groupName = grouped.keys.elementAt(index);
                    final list = grouped[groupName]!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            child: Text(
                              groupName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          // List of permissions in group
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 16),
                            itemBuilder: (context, idx) {
                              final p = list[idx];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p['name']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: Text(
                                        p['code']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontFamily: 'monospace',
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  p['desc']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── TAB 3: USERS & ROLES ASSIGNMENT ─────────────────────
  List<Map<String, dynamic>> _users = [];
  bool _isUsersLoading = true;
  String _userSearchQuery = '';

  Future<void> _loadUsers() async {
    setState(() => _isUsersLoading = true);
    try {
      final users = await RolePermissionRepository.getUsers(search: _userSearchQuery);
      setState(() {
        _users = users;
        _isUsersLoading = false;
      });
    } catch (_) {
      setState(() => _isUsersLoading = false);
    }
  }

  void _openEditUserRoles(Map<String, dynamic> user) {
    // Lấy ID của các vai trò hiện tại của user
    final List<int> selectedRoleIds = [];
    final List userRoleNames = List.from(user['roles'] ?? []);
    for (var rName in userRoleNames) {
      final matchedRole = _roles.firstWhere(
        (r) => r['name']?.toString().toLowerCase() == rName.toString().toLowerCase(),
        orElse: () => {},
      );
      if (matchedRole.containsKey('id')) {
        selectedRoleIds.add(matchedRole['id'] as int);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Phân vai trò: ${user['fullName'] ?? user['username']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(
                      '@${user['username']} - ${user['email']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _roles.length,
                      itemBuilder: (context, index) {
                        final role = _roles[index];
                        final roleId = role['id'] as int;
                        final isChecked = selectedRoleIds.contains(roleId);
                        final color = Color(int.parse(role['color'] ?? '0xFF1565C0'));

                        return CheckboxListTile(
                          activeColor: color,
                          controlAffinity: ListTileControlAffinity.trailing,
                          title: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                role['name']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            role['desc']?.toString() ?? '',
                            style: const TextStyle(fontSize: 11),
                          ),
                          value: isChecked,
                          onChanged: (bool? val) {
                            setModalState(() {
                              if (val == true) {
                                if (!selectedRoleIds.contains(roleId)) {
                                  selectedRoleIds.add(roleId);
                                }
                              } else {
                                selectedRoleIds.remove(roleId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.pop(),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final success = await RolePermissionRepository.assignUserRoles(
                                user['userId']?.toString() ?? '',
                                selectedRoleIds,
                              );
                              if (context.mounted) {
                                if (success) {
                                  _showToast('Đã cập nhật vai trò của thành viên!');
                                  context.pop();
                                  _loadUsers();
                                } else {
                                  _showToast('Cập nhật vai trò thất bại!', isError: true);
                                }
                              }
                            },
                            child: const Text('Lưu thay đổi'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm thành viên...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() {
                _userSearchQuery = val;
              });
              _loadUsers();
            },
          ),
        ),
        // Users list
        Expanded(
          child: _isUsersLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : _users.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy thành viên nào',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final name = user['fullName']?.toString() ?? user['username']?.toString() ?? 'Thành viên';
                        final username = user['username']?.toString() ?? '';
                        final email = user['email']?.toString() ?? '';
                        final rolesList = List<String>.from(user['roles'] ?? []);

                        // Lấy chữ cái đầu làm avatar
                        final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                foregroundColor: AppTheme.primary,
                                radius: 22,
                                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '@$username • $email',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (rolesList.isEmpty)
                                      const Text(
                                        'Chưa gán vai trò (Mặc định: Customer)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    else
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: rolesList.map((rName) {
                                          // Chọn màu tương ứng cho vai trò
                                          final colorHex = _roles.firstWhere(
                                            (r) => r['name']?.toString().toLowerCase() == rName.toLowerCase(),
                                            orElse: () => {'color': '0xFF9E9E9E'},
                                          )['color'];
                                          final color = Color(int.parse(colorHex));
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: color.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              rName,
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 9,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.manage_accounts_rounded, color: AppTheme.primary),
                                onPressed: () => _openEditUserRoles(user),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
