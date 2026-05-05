import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop/crop.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/networking/api_service.dart';
import 'package:transite_way/core/networking/api_constants.dart';
import 'package:transite_way/core/resources/color_manager.dart';

class UserEditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String currentEmail;
  final String currentPhoto;

  const UserEditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentPhone,
    required this.currentEmail,
    required this.currentPhoto,
  });

  @override
  State<UserEditProfileScreen> createState() => _UserEditProfileScreenState();
}

class _UserEditProfileScreenState extends State<UserEditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) _cropImage(image.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) _cropImage(image.path);
                },
              ),
            ],
          ),
        );
      },
    );
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

  void _viewImage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(10.w),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.contain)
                  : (widget.currentPhoto.startsWith('http')
                      ? Image.network(widget.currentPhoto, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.person, color: Colors.white, size: 100.sp))
                      : Icon(Icons.person, color: Colors.white, size: 100.sp)),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty || 
        _phoneController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      userId ??= prefs.getString('id');
      
      if (userId == null || userId.isEmpty) {
         throw Exception("User ID not found. Please log in again.");
      }

      Map<String, dynamic> fields = {
        "full_name": _nameController.text.trim(),
        "phone_number": _phoneController.text.trim(),
        "email": _emailController.text.trim(),
      };

      final response = await ApiService().updateProfile(
        table: ApiConstants.usersTable,
        fields: fields,
        filters: {"id": userId},
        file: _selectedImage,
        fileKey: 'photo',
      );

      final userData = response['data'] ?? response;

        // Save with multiple keys to ensure consistency across the app
        String finalName = userData['fullName'] ?? userData['FullName'] ?? _nameController.text.trim();
        String finalEmail = userData['email'] ?? userData['Email'] ?? _emailController.text.trim();
        String finalPhone = userData['phone'] ?? userData['Phone'] ?? _phoneController.text.trim();

        await prefs.setString('fullName', finalName);
        await prefs.setString('email', finalEmail);
        await prefs.setString('phone', finalPhone);
        await prefs.setString('phoneNumber', finalPhone);
        
        String? newPhoto = userData['photo'] ?? userData['Photo'] ?? userData['photoUrl'] ?? userData['image'];
        if (newPhoto != null) {
          await prefs.setString('userPhoto', newPhoto);
        }
        
        if (mounted) {
          _showSuccessDialog();
        }
    } catch (e) {
      debugPrint("Update Profile Error: $e");
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
                color: ColorManager.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: ColorManager.green, size: 50),
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
                backgroundColor: ColorManager.green,
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
      backgroundColor: ColorManager.green,
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
                      color: ColorManager.white.withOpacity(0.15),
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
              GestureDetector(
                onTap: _viewImage,
                child: Container(
                  width: 85.w,
                  height: 85.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ColorManager.white.withOpacity(0.4), width: 3),
                    color: ColorManager.white.withOpacity(0.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : (widget.currentPhoto.startsWith('http')
                          ? Image.network(widget.currentPhoto, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.person, color: ColorManager.white, size: 40.sp))
                          : Icon(Icons.person, color: ColorManager.white, size: 40.sp)),
                ),
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
                      border: Border.all(color: ColorManager.green, width: 2),
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: ColorManager.green, size: 14.sp),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'tap photo to view, icon to change',
            style: TextStyle(color: ColorManager.white.withOpacity(0.7), fontSize: 11.sp),
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
                physics: const ClampingScrollPhysics(),
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
                            child: Divider(color: ColorManager.grey.withOpacity(0.1), thickness: 1),
                          ),
                          _buildField(
                            label: 'Phone number',
                            controller: _phoneController,
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: Divider(color: ColorManager.grey.withOpacity(0.1), thickness: 1),
                          ),
                          _buildField(
                            label: 'Email address',
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            readOnly: true,
                          ),
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
                          backgroundColor: ColorManager.green,
                          disabledBackgroundColor: ColorManager.green.withOpacity(0.6),
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
    bool readOnly = false,
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
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 14.sp, 
            color: readOnly ? ColorManager.grey : ColorManager.black, 
            fontWeight: FontWeight.w600
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: readOnly ? ColorManager.grey : ColorManager.green, size: 20),
            filled: true,
            fillColor: readOnly ? ColorManager.grey.withOpacity(0.05) : ColorManager.white,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ColorManager.grey.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ColorManager.grey.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: readOnly ? ColorManager.grey.withOpacity(0.1) : ColorManager.green, width: 1.5),
            ),
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
        backgroundColor: ColorManager.green,
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
