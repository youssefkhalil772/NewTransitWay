import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/resources/assest_manager.dart';
import 'package:transite_way/core/widgets/common_profile_view.dart';
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
  String _driverName = "";
  String _driverEmail = "";
  String _driverPhone = "";
  String _licenseNumber = "";
  String _profileImagePath = ImageAssets.boy;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _driverName = prefs.getString('driverName') ?? "Driver";
      _driverEmail = prefs.getString('driverEmail') ?? "";
      _driverPhone = prefs.getString('driverPhone') ?? "";
      _licenseNumber = prefs.getString('licenseNumber') ?? "";
      
      String? serverPhoto = prefs.getString('driverPhoto');
      if (serverPhoto != null && serverPhoto.isNotEmpty) {
        _profileImagePath = serverPhoto;
      } else {
        _profileImagePath = prefs.getString('selected_driver_avatar') ?? ImageAssets.boy;
      }
    });
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
              child: _profileImagePath.startsWith('http')
                  ? Image.network(_profileImagePath, fit: BoxFit.contain)
                  : Image.asset(_profileImagePath, fit: BoxFit.contain),
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
