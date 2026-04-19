import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/routes_manager.dart';
import '../home/presentation/widgets/custom_points_badge.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onViewTickets;
  const ProfileScreen({super.key, this.onViewTickets});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Loading...";
  String _userEmail = "...";
  String _selectedAvatar = 'assets/logo/3.png'; // الصورة الافتراضية

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('fullName') ?? "User Name";
      _userEmail = prefs.getString('email') ?? "email@example.com";
      // قراءة مسار الصورة المحفوظ، ولو مش موجود نستخدم الافتراضية
      _selectedAvatar = prefs.getString('selected_profile_avatar') ?? 'assets/logo/3.png';
    });
  }

  Future<void> _updateAvatar(String avatarPath) async {
    final prefs = await SharedPreferences.getInstance();
    // حفظ مسار الصورة الجديد بـ Key واضح
    await prefs.setString('selected_profile_avatar', avatarPath);
    setState(() {
      _selectedAvatar = avatarPath;
    });
  }

  final List<ProfileMenuItemModel> menuItems = [
    ProfileMenuItemModel(
        icon: Icons.star,
        title: 'Charge My Points',
        route: RoutesManager.chargeMyPoints,
        iconColor: Colors.amber),
    ProfileMenuItemModel(
        icon: Icons.confirmation_number_outlined,
        title: 'View My Tickets',
        route: RoutesManager.tickets,
        iconColor: Colors.orangeAccent),
    ProfileMenuItemModel(
        icon: Icons.help,
        title: 'Helps & Feedback',
        route: RoutesManager.home,
        iconColor: Colors.orange),
    ProfileMenuItemModel(
        icon: Icons.logout,
        title: 'Log Out',
        route: RoutesManager.login,
        isLogout: true,
        iconColor: Colors.redAccent),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(color: Colors.black, fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: const Center(child: CustomPointsBadge()),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20.h),
          _buildUserInfo(),
          SizedBox(height: 40.h),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              itemCount: menuItems.length,
              separatorBuilder: (context, index) => Divider(height: 1.h, color: Colors.grey.shade200),
              itemBuilder: (context, index) => _buildMenuTile(menuItems[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showAvatarSelectionDialog,
            child: Stack(
              children: [
                Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFC107), 
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      _selectedAvatar, 
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: const BoxDecoration(color: Color(0xFF1B4D3E), shape: BoxShape.circle),
                    child: Icon(Icons.edit, color: Colors.white, size: 16.sp),
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
                  _userName,
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _userEmail,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Avatar'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAvatarOption('assets/logo/3.png'), 
            _buildAvatarOption('assets/images/Avatar.png'),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(String path) {
    return GestureDetector(
      onTap: () {
        _updateAvatar(path);
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedAvatar == path ? const Color(0xFF1B4D3E) : Colors.transparent,
            width: 2.w,
          ),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 40.r,
          backgroundColor: const Color(0xFFFFC107),
          backgroundImage: AssetImage(path),
        ),
      ),
    );
  }

  Widget _buildMenuTile(ProfileMenuItemModel item) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
      leading: Icon(item.icon, color: item.iconColor, size: 26.sp),
      title: Text(
        item.title,
        style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: item.isLogout ? Colors.red : Colors.black87),
      ),
      onTap: () {
        if (item.isLogout) {
          _showLogoutDialog(context);
        } else if (item.title == 'View My Tickets') {
          if (widget.onViewTickets != null) widget.onViewTickets!();
        } else if (item.title == 'Helps & Feedback') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Coming soon!"),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          RoutesManager.navigateTo(context, item.route);
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
              // عند الخروج نمسح بيانات اليوزر بس ونخلي اختيار الصورة محفوظ
              String savedAvatar = prefs.getString('selected_profile_avatar') ?? 'assets/logo/3.png';
              await prefs.clear();
              await prefs.setString('selected_profile_avatar', savedAvatar);

              if (mounted) RoutesManager.navigateAndRemoveUntil(context, RoutesManager.login);
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ProfileMenuItemModel {
  final IconData icon;
  final String title;
  final String route;
  final Color iconColor;
  final bool isLogout;

  ProfileMenuItemModel({
    required this.icon,
    required this.title,
    required this.route,
    required this.iconColor,
    this.isLogout = false,
  });
}
