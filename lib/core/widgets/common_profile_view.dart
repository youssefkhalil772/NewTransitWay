import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../networking/supabase_init.dart';
import '../routes/routes_manager.dart';

class CommonProfileView extends StatelessWidget {
  final String name;
  final String email;
  final String? phone; // إضافة اختياري
  final String? license; // إضافة اختياري
  final String imagePath;
  final List<ProfileMenuItem> menuItems;
  final bool isDriver;
  final VoidCallback? onImageTap;

  const CommonProfileView({
    super.key,
    required this.name,
    required this.email,
    this.phone,
    this.license,
    required this.imagePath,
    required this.menuItems,
    this.isDriver = false,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30.h),
        _buildHeader(context),
        SizedBox(height: 40.h),
        Expanded(
          child: ListView.separated(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: menuItems.length,
            separatorBuilder: (context, index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.w),
              child: const Divider(thickness: 2, color: Color(0xFFEEEEEE)),
            ),
            itemBuilder: (context, index) => _buildMenuTile(context, menuItems[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    bool isNetwork = imagePath.startsWith('http');
    bool isAsset = imagePath.contains('assets/');
    bool hasValidImage = imagePath.isNotEmpty && imagePath != 'assets/logo/3.png';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: onImageTap,
            child: Stack(
              children: [
                Container(
                  width: 100.r,
                  height: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.5), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50.r),
                    child: isNetwork
                        ? CachedNetworkImage(
                            imageUrl: imagePath,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (context, url, error) => Icon(Icons.person, size: 50.r, color: Colors.white),
                          )
                        : (hasValidImage
                            ? (isAsset 
                                ? Image.asset(imagePath, fit: BoxFit.cover)
                                : Image.file(File(imagePath), fit: BoxFit.cover))
                            : Icon(Icons.person, size: 50.r, color: Colors.white)),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: const BoxDecoration(color: Color(0xFF1B4D3E), shape: BoxShape.circle),
                    child: Icon(Icons.remove_red_eye, color: Colors.white, size: 16.sp),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isDriver ? "Driver Account" : "Passenger Account",
                  style: TextStyle(fontSize: 13.sp, color: const Color(0xFF39C449), fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                _buildInfoRow(Icons.email_outlined, email),
                if (phone != null && phone!.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  _buildInfoRow(Icons.phone_android_outlined, phone!),
                ],
                if (license != null && license!.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  _buildInfoRow(Icons.badge_outlined, "License: $license"),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: Colors.grey),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(BuildContext context, ProfileMenuItem item) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 8.h),
      leading: Icon(item.icon, color: item.iconColor, size: 26.sp),
      title: Text(
        item.text,
        style: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.w500,
          color: item.isLogout ? Colors.red : Colors.black,
        ),
      ),
      trailing: item.trailing ?? (item.isLogout ? null : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)),
      onTap: () async {
        if (item.isLogout) {
          _showLogoutDialog(context);
        } else if (item.onTap != null) {
          item.onTap!();
        }
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              String? driverImg = prefs.getString('selected_driver_avatar');
              String? userImg = prefs.getString('selected_profile_avatar');
              String? driverPhoto = prefs.getString('driverPhoto');
              
              await prefs.clear();
              
              if (driverImg != null) await prefs.setString('selected_driver_avatar', driverImg);
              if (userImg != null) await prefs.setString('selected_profile_avatar', userImg);
              if (driverPhoto != null) await prefs.setString('driverPhoto', driverPhoto);

              try {
                await GoogleSignIn().signOut();
                await GoogleSignIn().disconnect();
                await SupabaseConfig.client.auth.signOut();
              } catch (e) {
                debugPrint("SignOut Error: $e");
              }

              if (context.mounted) {
                RoutesManager.navigateAndRemoveUntil(context, RoutesManager.role);
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ProfileMenuItem {
  final IconData icon;
  final String text;
  final Color iconColor;
  final bool isLogout;
  final VoidCallback? onTap;
  final Widget? trailing;

  ProfileMenuItem({
    required this.icon,
    required this.text,
    required this.iconColor,
    this.isLogout = false,
    this.onTap,
    this.trailing,
  });
}
