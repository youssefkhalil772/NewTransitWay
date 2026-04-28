import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop/crop.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/networking/api_constants.dart';
import 'package:transite_way/core/networking/api_service.dart';
import 'package:transite_way/core/resources/color_manager.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String currentEmail;
  final String currentPhoto;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentPhone,
    required this.currentEmail,
    required this.currentPhoto,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _cropImage(image.path);
    }
  }

  Future<void> _cropImage(String filePath) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CropScreen(imagePath: filePath),
      ),
    );
    if (result != null && result is String) {
      setState(() => _selectedImage = File(result));
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Phone cannot be empty")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      int? driverId = prefs.getInt('driverId');
      if (driverId == null) return;

      Map<String, String> fields = {
        "FullName": _nameController.text.trim(),
        "PhoneNumber": _phoneController.text.trim(),
        "Email": widget.currentEmail,
      };

      final response = await ApiService().putMultipart(
        ApiConstants.getDriver(driverId),
        fields: fields,
        file: _selectedImage,
      );

      if (response != null) {
        await prefs.setString('driverName', response['name'] ?? _nameController.text);
        await prefs.setString('driverPhone', response['phone'] ?? _phoneController.text);
        if (response['photo'] != null) {
          await prefs.setString('driverPhoto', response['photo']);
        }
        
        if (mounted) {
          _showSuccessDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ColorManager.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
        contentPadding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 25.w),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: ColorManager.lightGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: ColorManager.lightGreen, size: 50),
            ),
            SizedBox(height: 24.h),
            Text(
              "Profile Updated",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp, color: ColorManager.black),
            ),
            SizedBox(height: 12.h),
            Text(
              "Your profile details have been successfully updated.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: ColorManager.grey),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.lightGreen,
                minimumSize: Size(double.infinity, 52.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: Text(
                "OK",
                style: TextStyle(color: ColorManager.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.lightGreen,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10.h,
              left: 20.w,
              right: 20.w,
              bottom: 10.h,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: ColorManager.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: ColorManager.white, size: 20),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Edit profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ColorManager.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 40.w), 
              ],
            ),
          ),

          SizedBox(height: 5.h),
          Stack(
            children: [
              Container(
                width: 85.w,
                height: 85.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorManager.white.withValues(alpha: 0.4), width: 3),
                  color: ColorManager.white.withValues(alpha: 0.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : (widget.currentPhoto.startsWith('http')
                        ? Image.network(widget.currentPhoto, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.person, color: ColorManager.white, size: 40.sp))
                        : Image.asset(widget.currentPhoto, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.person, color: ColorManager.white, size: 40.sp))),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: ColorManager.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: ColorManager.lightGreen, width: 2),
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: ColorManager.lightGreen, size: 14.sp),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'tap to change photo',
            style: TextStyle(color: ColorManager.white.withValues(alpha: 0.7), fontSize: 11.sp),
          ),
          SizedBox(height: 15.h),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: ColorManager.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 25.h),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: ColorManager.grey2,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: ColorManager.grey2),
                      ),
                      child: Column(
                        children: [
                          _buildField(
                            label: 'Full name',
                            controller: _nameController,
                            icon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.name,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: Divider(color: ColorManager.grey.withValues(alpha: 0.1), thickness: 1),
                          ),
                          _buildField(
                            label: 'Phone number',
                            controller: _phoneController,
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: Divider(color: ColorManager.grey.withValues(alpha: 0.1), thickness: 1),
                          ),
                          _buildReadOnlyField(),
                        ],
                      ),
                    ),

                    SizedBox(height: 30.h),

                    SizedBox(
                      width: double.infinity,
                      height: 55.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.lightGreen,
                          disabledBackgroundColor: ColorManager.lightGreen.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: ColorManager.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'Save changes',
                                style: TextStyle(
                                  color: ColorManager.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            color: ColorManager.grey,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14.sp, color: ColorManager.black, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: ColorManager.lightGreen, size: 20),
            filled: true,
            fillColor: ColorManager.white,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ColorManager.grey.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ColorManager.grey.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: ColorManager.lightGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EMAIL ADDRESS',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            color: ColorManager.grey,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: ColorManager.grey2,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: ColorManager.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.email_outlined, color: ColorManager.grey4, size: 20),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  widget.currentEmail,
                  style: TextStyle(fontSize: 14.sp, color: ColorManager.grey, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorManager.lightGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'locked',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: ColorManager.lightGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CropScreen extends StatefulWidget {
  final String imagePath;
  const _CropScreen({required this.imagePath});

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final _controller = CropController(aspectRatio: 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.black,
      appBar: AppBar(
        backgroundColor: ColorManager.lightGreen,
        title: const Text('Crop Photo', style: TextStyle(color: ColorManager.white, fontSize: 18)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: ColorManager.white),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final bitmap = await _controller.crop();
                
                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
                final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
                
                if (data != null) {
                  await file.writeAsBytes(data.buffer.asUint8List());
                  if (context.mounted) {
                    Navigator.pop(context, file.path);
                  }
                }
              } catch (e) {
                debugPrint("Crop Error: $e");
              }
            },
            child: const Text('DONE', style: TextStyle(color: ColorManager.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Crop(
        controller: _controller,
        shape: BoxShape.circle,
        child: Image.file(File(widget.imagePath)),
      ),
    );
  }
}
