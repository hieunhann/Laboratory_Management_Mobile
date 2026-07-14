import '../../../core/network/api_client.dart';

class RolePermissionRepository {
  // ─── Default Fallback Data (Dùng khi mất kết nối mạng hoặc lỗi API) ──────────────────
  static final List<Map<String, dynamic>> _fallbackPermissions = [
    {
      'code': 'view_appointments',
      'name': 'Xem lịch xét nghiệm',
      'desc': 'Cho phép xem danh sách và chi tiết lịch đặt hẹn xét nghiệm.',
      'group': 'Lịch hẹn'
    },
    {
      'code': 'update_appointment_status',
      'name': 'Cập nhật trạng thái',
      'desc': 'Cho phép thay đổi trạng thái lịch hẹn (Chờ khám, Hoàn thành, Hủy).',
      'group': 'Lịch hẹn'
    },
    {
      'code': 'input_test_results',
      'name': 'Nhập kết quả',
      'desc': 'Cho phép nhập thông số và chỉ số kết quả xét nghiệm máu.',
      'group': 'Xét nghiệm'
    },
    {
      'code': 'approve_results',
      'name': 'Duyệt kết quả',
      'desc': 'Cho phép phê duyệt kết quả xét nghiệm cuối cùng gửi tới bệnh nhân.',
      'group': 'Xét nghiệm'
    },
    {
      'code': 'run_instrument',
      'name': 'Vận hành thiết bị',
      'desc': 'Cho phép khởi chạy và đồng bộ dữ liệu từ thiết bị xét nghiệm.',
      'group': 'Thiết bị'
    },
    {
      'code': 'maintain_instrument',
      'name': 'Bảo trì thiết bị',
      'desc': 'Xem và quản lý thông tin bảo trì máy móc phòng lab.',
      'group': 'Thiết bị'
    },
    {
      'code': 'create_blog',
      'name': 'Tạo bài viết',
      'desc': 'Cho phép soạn thảo bài viết, tin tức y khoa.',
      'group': 'Bài viết'
    },
    {
      'code': 'publish_blog',
      'name': 'Duyệt bài viết',
      'desc': 'Phê duyệt và công bố bài viết lên cổng thông tin công cộng.',
      'group': 'Bài viết'
    },
    {
      'code': 'manage_roles',
      'name': 'Quản lý vai trò & quyền',
      'desc': 'Toàn quyền cấu hình vai trò mới và phân chia quyền hạn hệ thống.',
      'group': 'Hệ thống'
    },
    {
      'code': 'manage_users',
      'name': 'Quản lý tài khoản nhân viên',
      'desc': 'Thêm mới, kích hoạt hoặc khóa tài khoản nhân viên phòng lab.',
      'group': 'Hệ thống'
    }
  ];

  static final List<Map<String, dynamic>> _fallbackRoles = [
    {
      'id': 1,
      'code': 'Admin',
      'name': 'Quản trị viên (Admin)',
      'desc': 'Toàn quyền quản trị hệ thống, thiết lập vai trò và phân quyền.',
      'color': '0xFF1565C0',
      'permissions': [
        'view_appointments',
        'update_appointment_status',
        'input_test_results',
        'approve_results',
        'run_instrument',
        'maintain_instrument',
        'create_blog',
        'publish_blog',
        'manage_roles',
        'manage_users'
      ]
    },
    {
      'id': 2,
      'code': 'Manager',
      'name': 'Quản lý phòng lab',
      'desc': 'Quản lý nhân sự, phê duyệt và điều phối lịch hẹn phòng lab.',
      'color': '0xFF00897B',
      'permissions': [
        'view_appointments',
        'update_appointment_status',
        'approve_results',
        'maintain_instrument',
        'publish_blog',
        'manage_users'
      ]
    }
  ];

  // ─── Get Permissions (Fetch từ API thực tế) ───────────────────────────────
  static Future<List<Map<String, dynamic>>> getPermissions() async {
    try {
      final response = await ApiClient.get('iam/api/rbac/permission-groups');
      final resData = response.data;
      // Trích xuất list từ envelope { "data": [...] } hoặc từ List gốc
      final List? groups = resData is Map ? resData['data'] : (resData is List ? resData : null);

      if (groups != null) {
        final List<Map<String, dynamic>> flatList = [];
        for (var g in groups) {
          final groupLabel = g['label']?.toString() ?? g['module']?.toString() ?? 'Chung';
          final List perms = g['permissions'] ?? [];
          for (var p in perms) {
            flatList.add({
              'code': p['key']?.toString() ?? '',
              'name': p['label']?.toString() ?? p['key']?.toString() ?? '',
              'desc': p['description']?.toString() ?? 'Không có mô tả.',
              'group': groupLabel,
            });
          }
        }
        if (flatList.isNotEmpty) {
          return flatList;
        }
      }
    } catch (e) {
      print('====== [RolePermissionRepository] getPermissions Error: $e ======');
    }
    return List.from(_fallbackPermissions);
  }

  // ─── Get Roles (Fetch từ API thực tế kèm chi tiết quyền) ────────────────
  static Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response = await ApiClient.get('iam/api/rbac/roles');
      final resData = response.data;
      final List? rolesData = resData is Map ? resData['data'] : (resData is List ? resData : null);

      if (rolesData != null) {
        final List<Map<String, dynamic>> results = [];
        for (var r in rolesData) {
          final roleId = r['roleId'];
          final name = r['name']?.toString() ?? '';
          
          // Lấy danh sách quyền hạn đã gán cho vai trò này
          List<String> perms = [];
          try {
            final permRes = await ApiClient.get('iam/api/rbac/roles/$roleId/permissions');
            final permData = permRes.data;
            final List? activePerms = permData is Map ? permData['data'] : (permData is List ? permData : null);
            if (activePerms != null) {
              perms = List<String>.from(activePerms);
            }
          } catch (e) {
            print('====== [RolePermissionRepository] getRolePermissions Error for $roleId ($name): $e ======');
          }
          
          results.add({
            'id': roleId,
            'code': name,
            'name': name,
            'desc': 'Vai trò $name trên hệ thống.',
            'color': _getColorForRole(name),
            'permissions': perms,
          });
        }
        return results;
      }
    } catch (e) {
      print('====== [RolePermissionRepository] getRoles Error: $e ======');
    }
    return List.from(_fallbackRoles);
  }

  // ─── Add Role (Tạo vai trò trên backend) ──────────────────────────────────
  static Future<bool> addRole({
    required String code,
    required String name,
    required String desc,
    required String color,
    List<String> permissions = const [],
  }) async {
    try {
      final response = await ApiClient.post(
        'iam/api/roles',
        data: {
          'name': code, // Sử dụng mã vai trò (e.g. Supervisor) làm tên chính thức trong JWT/DB
          'description': '$name: $desc', // Lưu tên hiển thị tiếng Việt kèm mô tả vào description
          'isDefault': false,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      // Ghi nhận lỗi chi tiết
      print('====== [RolePermissionRepository] addRole Error: $e ======');
    }
    return false;
  }

  // ─── Add Permission (Backend quản lý cứng) ──────────────────────────────
  static Future<bool> addPermission({
    required String code,
    required String name,
    required String desc,
    required String group,
  }) async {
    // Quyền hạn được định nghĩa tĩnh ở code/DB migrations phía Backend.
    // Client không có API tự tạo thêm Permission định danh mới.
    return false;
  }

  // ─── Update Role Permissions (Cập nhật quyền cho Role) ─────────────────────
  static Future<void> updateRolePermissions(
    dynamic roleIdOrCode,
    List<String> selectedPermissions,
  ) async {
    try {
      dynamic roleId = roleIdOrCode;
      // Nếu là code (String), tìm roleId tương ứng
      if (roleIdOrCode is String) {
        final roles = await getRoles();
        final role = roles.firstWhere((r) => r['code'] == roleIdOrCode, orElse: () => {});
        if (role.containsKey('id')) {
          roleId = role['id'];
        }
      }
      
      await ApiClient.put(
        'iam/api/rbac/roles/$roleId/permissions',
        data: {
          'permissionKeys': selectedPermissions,
        },
      );
    } catch (_) {
      // Swallow or handle
    }
  }

  // ─── Get Users (Tải danh sách người dùng) ──────────────────────────────────
  static Future<List<Map<String, dynamic>>> getUsers({
    String? search,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      final response = await ApiClient.get('iam/api/Users', params: params);
      final resData = response.data;
      final List? usersList = resData is Map ? resData['data'] : (resData is List ? resData : null);
      if (usersList != null) {
        return usersList.map((u) => Map<String, dynamic>.from(u)).toList();
      }
    } catch (e) {
      print('====== [RolePermissionRepository] getUsers Error: $e ======');
    }
    return [];
  }

  // ─── Assign User Roles (Gán vai trò cho người dùng) ─────────────────────────
  static Future<bool> assignUserRoles(String userId, List<int> roleIds) async {
    try {
      final response = await ApiClient.post(
        'iam/api/Users/$userId/roles',
        data: {
          'roleIds': roleIds,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201 || response.data?['success'] == true) {
        return true;
      }
    } catch (e) {
      print('====== [RolePermissionRepository] assignUserRoles Error: $e ======');
    }
    return false;
  }

  // ─── Helper: Ánh xạ màu sắc cho vai trò ─────────────────────────────────────
  static String _getColorForRole(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('admin')) return '0xFF1565C0'; // Xanh đậm
    if (lower.contains('manager') || lower.contains('quản lý')) return '0xFF00897B'; // Teal
    if (lower.contains('labuser') || lower.contains('lab staff')) return '0xFFF57C00'; // Cam
    if (lower.contains('receptionist') || lower.contains('lễ tân')) return '0xFF0288D1'; // Xanh sáng
    if (lower.contains('technician') || lower.contains('kỹ thuật')) return '0xFF673AB7'; // Tím
    if (lower.contains('blogger') || lower.contains('biên tập')) return '0xFFE91E63'; // Hồng
    if (lower.contains('staff') || lower.contains('nhân viên')) return '0xFF9E9E9E'; // Xám
    return '0xFF3F51B5'; // Indigo mặc định
  }
}
