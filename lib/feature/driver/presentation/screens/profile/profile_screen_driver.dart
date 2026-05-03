import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/resources/assest_manager.dart';
import 'package:transite_way/core/widgets/common_profile_view.dart';
import 'package:transite_way/feature/driver/data/driver_auth_service.dart';
import 'edit_profile_screen.dart';
import 'ticket_history_screen.dart';

class ProfileScreenDriver extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onAddTicketsTap;

  const ProfileScreenDriver({
    super.key, 
    this.isTab = false,
    this.onAddTicketsTap,
  });

  @override
  State<ProfileScreenDriver> createState() => _ProfileScreenDriverState();
}

class _ProfileScreenDriverState extends State<ProfileScreenDriver> {
  final DriverAuthServices _driverService = DriverAuthServices();
  String _driverName = "";
  String _driverEmail = "";
  String _driverPhone = "";
  String _licenseNumber = "";
  String _profileImagePath = "";

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Initial load from SharedPreferences for speed
    String name = prefs.getString('driverName') ?? "Driver";
    String email = prefs.getString('driverEmail') ?? "";
    String phone = prefs.getString('driverPhone') ?? "";
    String license = prefs.getString('licenseNumber') ?? "";
    String? serverPhoto = prefs.getString('driverPhoto');

    if (mounted) {
      setState(() {
        _driverName = name;
        _driverEmail = email;
        _driverPhone = phone;
        _licenseNumber = license;
        _profileImagePath = (serverPhoto != null && serverPhoto.isNotEmpty) 
            ? serverPhoto 
            : (prefs.getString('selected_driver_avatar') ?? "");
      });
    }

    // 2. Immediate Background Sync from Supabase (Source of Truth)
    final String? driverId = prefs.getString('driverId');
    if (driverId != null && driverId.isNotEmpty) {
      try {
        debugPrint("📡 Syncing Profile for driverId: $driverId");
        final driverData = await _driverService.getDriverData(driverId);
        
        // Correct keys for drivers table
        name = driverData['full_name'] ?? driverData['name'] ?? driverData['fullName'] ?? name;
        phone = driverData['phone_number'] ?? driverData['phone'] ?? driverData['phoneNumber'] ?? phone;
        email = driverData['email'] ?? email;
        license = driverData['license_number'] ?? driverData['licenseNumber'] ?? license;
        serverPhoto = driverData['photo'] ?? serverPhoto;

        // Persist fresh data
        await prefs.setString('driverName', name);
        await prefs.setString('driverPhone', phone);
        await prefs.setString('driverEmail', email);
        await prefs.setString('licenseNumber', license);
        if (serverPhoto != null) await prefs.setString('driverPhoto', serverPhoto);

        if (mounted) {
          setState(() {
            _driverName = name;
            _driverEmail = email;
            _driverPhone = phone;
            _licenseNumber = license;
            if (serverPhoto != null && serverPhoto.isNotEmpty) {
              _profileImagePath = serverPhoto;
            }
          });
          debugPrint("✅ Profile Synced from DB: $name | $phone");
        }
      } catch (e) {
        debugPrint("🛑 Profile DB Sync Error: $e");
      }
    }
  }

  void _viewImage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: _profileImagePath.isEmpty
                  ? Icon(Icons.person, color: Colors.grey, size: 100.sp)
                  : (_profileImagePath.startsWith('http')
                      ? Image.network(_profileImagePath, fit: BoxFit.contain)
                      : Image.file(File(_profileImagePath), fit: BoxFit.contain)),
            ),
            SizedBox(height: 15.h),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.black),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body = CommonProfileView(
      name: _driverName,
      email: _driverEmail,
      phone: _driverPhone,
      license: _licenseNumber,
      imagePath: _profileImagePath,
      isDriver: true,
      onImageTap: _viewImage,
      menuItems: [
        ProfileMenuItem(
          icon: Icons.edit_note_rounded,
          text: 'Edit Profile',
          iconColor: const Color(0xFF1B4D3E),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  currentName: _driverName,
                  currentPhone: _driverPhone,
                  currentEmail: _driverEmail,
                  currentPhoto: _profileImagePath,
                ),
              ),
            );
            if (result == true) {
              _loadDriverData(); // تحديث البيانات لو رجع true
            }
          },
        ),
        ProfileMenuItem(
          icon: Icons.confirmation_number_outlined,
          text: 'Add Tickets',
          iconColor: Colors.green,
          onTap: widget.onAddTicketsTap,
        ),
        ProfileMenuItem(
          icon: Icons.history_outlined,
          text: 'Ticket History',
          iconColor: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TicketHistoryScreen()),
            );
          },
        ),
        ProfileMenuItem(
          icon: Icons.logout,
          text: 'Log Out',
          iconColor: Colors.red,
          isLogout: true,
        ),
      ],
    );

    if (widget.isTab) return body;

    return Scaffold(
      backgroundColor: Colors.white,
      body: body,
    );
  }
}
