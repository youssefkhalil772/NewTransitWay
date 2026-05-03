import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transite_way/core/networking/api_constants.dart';
import 'package:transite_way/core/networking/supabase_init.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ReportComplaintScreen extends StatefulWidget {
  const ReportComplaintScreen({super.key});

  @override
  State<ReportComplaintScreen> createState() => _ReportComplaintScreenState();
}

class _ReportComplaintScreenState extends State<ReportComplaintScreen> {
  static const _green      = Color(0xFF054F3A);
  static const _lightGreen = Color(0xFFE8F7EA);

  final _descController = TextEditingController();
  final _picker         = ImagePicker();

  File?   _imageFile;
  bool    _isSubmitting = false;
  bool    _submitted    = false;
  String? _errorMsg;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // ── image helpers ─────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final xf = await _picker.pickImage(
        source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 75,
      );
      if (xf != null && mounted) setState(() => _imageFile = File(xf.path));
    } catch (_) {}
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _sourceBtn(Icons.camera_alt_rounded,    'Camera',  ImageSource.camera),
              _sourceBtn(Icons.photo_library_rounded, 'Gallery', ImageSource.gallery),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceBtn(IconData icon, String label, ImageSource src) {
    return GestureDetector(
      onTap: () { Navigator.pop(context); _pickImage(src); },
      child: Column(children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(color: _lightGreen,
              borderRadius: BorderRadius.circular(16.r)),
          child: Icon(icon, color: _green, size: 30.sp),
        ),
        SizedBox(height: 8.h),
        Text(label, style: TextStyle(fontSize: 13.sp)),
      ]),
    );
  }

  // ── submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _errorMsg = null);

    if (_descController.text.trim().length < 10) {
      setState(() => _errorMsg = 'Please describe the problem (at least 10 characters).');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get saved user info from SharedPreferences
      final prefs       = await SharedPreferences.getInstance();
      final userId      = int.tryParse(prefs.getString('userId') ?? '');
      final reporterName = prefs.getString('fullName') ?? '';

      // Upload image if selected (to existing 'avatars' bucket)
      String? imageUrl;
      if (_imageFile != null) {
        try {
          final ext   = _imageFile!.path.split('.').last;
          final ts    = DateTime.now().millisecondsSinceEpoch;
          final path  = 'reports/${userId ?? 'anon'}/$ts.$ext';
          final bytes = await _imageFile!.readAsBytes();

          await SupabaseConfig.client.storage
              .from(ApiConstants.avatarsBucket)
              .uploadBinary(path, bytes,
                  fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));

          imageUrl = SupabaseConfig.client.storage
              .from(ApiConstants.avatarsBucket)
              .getPublicUrl(path);
        } catch (imgErr) {
          debugPrint('⚠️ Image upload skipped: $imgErr');
          // Continue without image
        }
      }

      // Insert into 'complaints' table without category/priority
      await SupabaseConfig.client.from('complaints').insert({
        'user_id':          userId,
        'problem_detected': true,
        'text_complaint':   _descController.text.trim(),
        'reporter_name':    reporterName.isNotEmpty ? reporterName : null,
        'reporter_role':    'Passenger',
        'status':           'Pending',
        'original_image':   imageUrl,
      });

      if (mounted) setState(() { _isSubmitting = false; _submitted = true; });

    } catch (e) {
      debugPrint('Report submit error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMsg = _isNetworkErr(e)
              ? 'Connection failed. Please check your internet.'
              : 'Failed to submit. Please try again.';
        });
      }
    }
  }

  bool _isNetworkErr(Object e) {
    final m = e.toString().toLowerCase();
    return m.contains('clientexception') || m.contains('socketexception') ||
        m.contains('connection reset')   || m.contains('network') ||
        m.contains('failed host');
  }

  // ── build ─────────────────────────────────────────────────────────────────
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
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Transit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20.sp)),
          Text('Way',     style: TextStyle(color: _green,       fontWeight: FontWeight.bold, fontSize: 20.sp)),
        ]),
        centerTitle: true,
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  // ── success ───────────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: const BoxDecoration(color: _lightGreen, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_rounded, color: _green, size: 64.sp),
          ),
          SizedBox(height: 24.h),
          Text('Report Submitted!',
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
          SizedBox(height: 10.h),
          Text(
            'Your complaint has been sent to our admin team.\nWe\'ll review it and take action as soon as possible.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600, height: 1.6),
          ),
          SizedBox(height: 36.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                elevation: 0,
              ),
              child: Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => setState(() {
              _submitted        = false;
              _imageFile        = null;
              _descController.clear();
            }),
            child: Text('Submit another report', style: TextStyle(color: _green, fontSize: 13.sp)),
          ),
        ]),
      ),
    );
  }

  // ── form ──────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(),
        SizedBox(height: 32.h),

        _sectionLabel('DESCRIBE THE PROBLEM'),
        SizedBox(height: 8.h),
        _buildDescField(),
        SizedBox(height: 24.h),

        _sectionLabel('ATTACH A PHOTO (OPTIONAL)'),
        SizedBox(height: 8.h),
        _buildImageSection(),
        SizedBox(height: 32.h),

        if (_errorMsg != null) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(child: Text(_errorMsg!, style: TextStyle(color: Colors.red.shade700, fontSize: 13.sp))),
            ]),
          ),
          SizedBox(height: 16.h),
        ],

        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? SizedBox(width: 18.w, height: 18.w,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white),
            label: Text(
              _isSubmitting ? 'Submitting…' : 'Submit Report',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: _green.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── sub-widgets ───────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(children: [
      Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(12.r)),
        child: const Icon(Icons.report_problem_outlined, color: _green, size: 26),
      ),
      SizedBox(width: 12.w),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Report a Problem',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text('Your report goes directly to our admin team.',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500)),
        ]),
      ),
    ]);
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold,
        color: Colors.grey.shade500, letterSpacing: 0.8),
  );

  Widget _buildDescField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: TextField(
        controller: _descController,
        maxLines: 6,
        minLines: 5,
        maxLength: 500,
        textInputAction: TextInputAction.newline,
        style: TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.5),
        decoration: InputDecoration(
          hintText: 'e.g. The bus on route 55 was 30 minutes late and the driver was rude…',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14.w),
          counterStyle: TextStyle(fontSize: 10.sp, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(children: [
      if (_imageFile != null) ...[
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.file(_imageFile!,
                height: 160.h, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8.h, right: 8.w,
            child: GestureDetector(
              onTap: () => setState(() => _imageFile = null),
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Icon(Icons.close, color: Colors.white, size: 16.sp),
              ),
            ),
          ),
        ]),
        SizedBox(height: 8.h),
      ],
      GestureDetector(
        onTap: _showImagePicker,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.camera_alt_outlined, color: _green, size: 20.sp),
            SizedBox(width: 8.w),
            Text(_imageFile != null ? 'Change Photo' : 'Take or Choose a Photo',
                style: TextStyle(color: _green, fontWeight: FontWeight.w600, fontSize: 14.sp)),
          ]),
        ),
      ),
    ]);
  }
}
