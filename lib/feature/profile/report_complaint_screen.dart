import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transite_way/core/networking/supabase_init.dart';

class ReportComplaintScreen extends StatefulWidget {
  const ReportComplaintScreen({super.key});

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isAnalyzing = false;
  String? _result;
  String? _resultCategory;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  static const Color _green = Color(0xFF054F3A);
  static const Color _lightGreen = Color(0xFFE8F7EA);

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Opens camera to capture a photo.
  Future<void> _captureFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (image != null && mounted) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access camera. Please check permissions.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Opens gallery to pick an image.
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (image != null && mounted) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access gallery. Please check permissions.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Shows bottom sheet to choose between camera and gallery.
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Attach Evidence Photo',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _captureFromCamera();
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                ],
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: _green, size: 30.sp),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.black87)),
        ],
      ),
    );
  }

  /// Calls the Supabase Edge Function 'report-complaint' with text and optional image.
  Future<void> _analyzeComplaint() async {
    final String inputText = _textController.text.trim();

    if (inputText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your complaint before analyzing.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
      _resultCategory = null;
    });

    try {
      // Build request body
      final Map<String, dynamic> body = {'text': inputText};

      // Encode image as base64 if selected
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        body['image'] = base64Encode(bytes);
        body['imageName'] = _selectedImage!.path.split('/').last;
      }

      final response = await SupabaseConfig.client.functions.invoke(
        'report-complaint',
        body: body,
      );

      // Decode response data
      final data = response.data;
      String analysisResult = '';
      String? category;

      if (data is Map) {
        analysisResult = data['result']?.toString() ??
            data['analysis']?.toString() ??
            data['message']?.toString() ??
            data['response']?.toString() ??
            data.toString();
        category = data['category']?.toString() ?? data['type']?.toString();
      } else if (data is String) {
        analysisResult = data;
      } else {
        analysisResult = data.toString();
      }

      if (mounted) {
        setState(() {
          _result = analysisResult;
          _resultCategory = category;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('report-complaint Edge Function Error: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: ${_friendlyError(e)}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Extracts a user-friendly message from the exception.
  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Network error. Check your connection.';
    }
    if (msg.contains('401') || msg.contains('403')) {
      return 'Authorization error. Please log in again.';
    }
    if (msg.contains('timeout')) return 'Request timed out. Try again.';
    if (msg.contains('404') || msg.contains('not found')) {
      return 'Service not available. Please try again later.';
    }
    return 'Server error. Please try again later.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Transit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20.sp)),
            Text('Way', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 20.sp)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(),
              SizedBox(height: 24.h),
              _buildInputSection(),
              SizedBox(height: 16.h),
              _buildImageSection(),
              SizedBox(height: 20.h),
              _buildAnalyzeButton(),
              SizedBox(height: 24.h),
              if (_isAnalyzing) _buildLoadingState(),
              if (_result != null && !_isAnalyzing) _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(Icons.psychology_outlined, color: _green, size: 26),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Complaint Analysis',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    'Powered by AI — fast & accurate',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          'Describe your complaint or issue below and our AI will analyze it and suggest the best resolution.',
          style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESCRIBE YOUR ISSUE',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: TextField(
            controller: _textController,
            maxLines: 6,
            minLines: 4,
            textInputAction: TextInputAction.newline,
            style: TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.5),
            decoration: InputDecoration(
              hintText: 'e.g. The driver was speeding and the bus was overcrowded on route 55...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATTACH EVIDENCE (OPTIONAL)',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 8.h),
        if (_selectedImage != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.file(
                  _selectedImage!,
                  height: 160.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8.h,
                right: 8.w,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImage = null),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 16.sp),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
        GestureDetector(
          onTap: _showImageSourcePicker,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, color: _green, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  _selectedImage != null ? 'Change Photo' : 'Take or Choose a Photo',
                  style: TextStyle(color: _green, fontWeight: FontWeight.w600, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed: _isAnalyzing ? null : _analyzeComplaint,
        icon: const Icon(Icons.psychology, color: Colors.white, size: 20),
        label: Text(
          'Analyze Complaint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor: _green.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFB8E7BE)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: _green, strokeWidth: 2.5),
          SizedBox(height: 16.h),
          Text(
            'Analyzing your complaint…',
            style: TextStyle(color: _green, fontWeight: FontWeight.w500, fontSize: 14.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            'This may take a few seconds',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI ANALYSIS RESULT',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFB8E7BE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: const BoxDecoration(
                      color: _lightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, color: _green, size: 20),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis Complete',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87),
                        ),
                        if (_resultCategory != null)
                          Text(
                            'Category: $_resultCategory',
                            style: TextStyle(color: _green, fontSize: 11.sp, fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              const Divider(height: 1),
              SizedBox(height: 14.h),
              Text(
                _result!,
                style: TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.6),
              ),
              SizedBox(height: 16.h),
              // Clear button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _result = null;
                    _resultCategory = null;
                    _selectedImage = null;
                    _textController.clear();
                  });
                },
                child: Text(
                  'Submit another complaint →',
                  style: TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 30.h),
      ],
    );
  }
}
