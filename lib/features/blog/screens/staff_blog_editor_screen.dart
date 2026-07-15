import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import '../../../config/app_theme.dart';
import '../data/blog_repository.dart';
import '../../../shared/models/blog_model.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class StaffBlogEditorScreen extends StatefulWidget {
  final BlogModel? existingBlog;

  const StaffBlogEditorScreen({super.key, this.existingBlog});

  @override
  State<StaffBlogEditorScreen> createState() => _StaffBlogEditorScreenState();
}

class _StaffBlogEditorScreenState extends State<StaffBlogEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _summaryController;
  late TextEditingController _authorController;

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingBlog?.title ?? '');
    _contentController =
        TextEditingController(text: widget.existingBlog?.content ?? '');
    _summaryController =
        TextEditingController(text: widget.existingBlog?.summary ?? '');
    _authorController =
        TextEditingController(text: widget.existingBlog?.authorName ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _summaryController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCropImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cắt ảnh',
            toolbarColor: AppTheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Cắt ảnh',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
      }
    }
  }

  Future<void> _saveBlog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      final authorName = _authorController.text.trim().isNotEmpty 
          ? _authorController.text.trim() 
          : (authProvider.currentUser?.fullName ?? 'Staff');

      final Map<String, dynamic> dataMap = {
        'Title': _titleController.text.trim(),
        'Content': _contentController.text.trim(),
        'CategoryId': widget.existingBlog?.categoryId ?? 1, // Mandatory in backend
        'AuthorId': authProvider.currentUser?.userId ?? '', // Mandatory in backend
      };

      if (_selectedImage != null) {
        dataMap['Image'] = await MultipartFile.fromFile(
          _selectedImage!.path,
          filename: _selectedImage!.path.split('/').last,
        );
      }

      final payload = FormData.fromMap(dataMap);

      bool success;
      if (widget.existingBlog == null) {
        success = await BlogRepository.createBlog(payload);
      } else {
        success = await BlogRepository.updateBlog(
            widget.existingBlog!.postId, payload);
      }

      if (success) {
        Fluttertoast.showToast(msg: 'Lưu bài viết thành công');
        if (mounted) context.pop(true);
      } else {
        Fluttertoast.showToast(msg: 'Lỗi khi lưu bài viết');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Đã xảy ra lỗi');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingBlog != null;
    if (!isEditing && _authorController.text.isEmpty) {
      _authorController.text = context.read<AuthProvider>().currentUser?.fullName ?? 'Staff';
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa bài viết' : 'Thêm bài viết mới'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickAndCropImage,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                  )
                                : (widget.existingBlog?.thumbnailUrl != null || widget.existingBlog?.imagePath != null)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: widget.existingBlog?.thumbnailUrl ?? 
                                                    (widget.existingBlog!.imagePath!.startsWith('http') 
                                                        ? widget.existingBlog!.imagePath! 
                                                        : 'https://hemalink-gateway-5ils.onrender.com/blog/${widget.existingBlog!.imagePath!}'),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate,
                                              size: 48, color: Colors.grey),
                                          SizedBox(height: 8),
                                          Text(
                                            'Nhấn để chọn và cắt ảnh',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                        if (_selectedImage != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 16,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề bài viết',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _summaryController,
                      decoration: const InputDecoration(
                        labelText: 'Tóm tắt (tuỳ chọn)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Tên tác giả',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên tác giả' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung chi tiết',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 15,
                      validator: (v) => v!.isEmpty ? 'Vui lòng nhập nội dung' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveBlog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Lưu bài viết',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
