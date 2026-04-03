import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_manager.dart';
import '../home/presentation/widgets/custom_points_badge.dart';

class ProfileScreen extends StatefulWidget {
  // Callback لتغيير التبويب من الـ MainWrapper
  final VoidCallback? onViewTickets;

  const ProfileScreen({super.key, this.onViewTickets});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<ProfileMenuItemModel> menuItems = [
    ProfileMenuItemModel(
        icon: Icons.star_border,
        title: 'Charge My Points',
        route: RoutesManager.home,
        iconColor: Colors.amber),
    ProfileMenuItemModel(
        icon: Icons.confirmation_number_outlined,
        title: 'View My Tickets',
        route: RoutesManager.tickets,
        iconColor: Colors.orangeAccent),
    ProfileMenuItemModel(
        icon: Icons.help_outline,
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
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          SizedBox(height: 20.h),
          _buildUserInfo(),
          SizedBox(height: 30.h),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              itemCount: menuItems.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1.h, color: Colors.grey.shade200),
              itemBuilder: (context, index) => _buildMenuTile(menuItems[index]),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
        onPressed: () {
          if (Navigator.canPop(context)) {
            RoutesManager.goBack(context);
          } else {
            RoutesManager.navigateAndReplace(context, RoutesManager.mainWrapper);
          }
        },
      ),
      title: Text(
        'My Profile',
        style: TextStyle(
            color: Colors.black, fontSize: 20.sp, fontWeight: FontWeight.bold),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: const Center(
            child: CustomPointsBadge(points: "9833"),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          CircleAvatar(
            radius: 45.r,
            backgroundColor: const Color(0xFF054F3A),
            child: CircleAvatar(
              radius: 42.r,
              backgroundImage: const AssetImage('assets/logo/3.png'),
            ),
          ),
          SizedBox(width: 20.w),
          Text(
            'Jumana Shahien',
            style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(ProfileMenuItemModel item) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
      leading: Icon(item.icon, color: item.iconColor, size: 28.sp),
      title: Text(
        item.title,
        style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w500,
            color: item.isLogout ? Colors.red : Colors.black87),
      ),
      trailing: Icon(item.isLogout ? Icons.logout : Icons.arrow_forward_ios,
          size: 16.sp, color: Colors.grey),
      onTap: () {
        if (item.isLogout) {
          _showLogoutDialog(context);
        } else if (item.title == 'View My Tickets') {
          // اللوجيك الجديد للانتقال للتبويب الصحيح
          if (widget.onViewTickets != null) {
            widget.onViewTickets!();
          }
        } else if (item.title == 'Charge My Points') {
          // التنقل لشاشة الـ Points
          RoutesManager.navigateTo(context, RoutesManager.points);
        }
        else if (item.route == RoutesManager.home && item.title != 'Home' && item.title != 'Charge My Points') {
          // رسائل التنبيه للخيارات التانية
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${item.title} is coming soon!"),
              backgroundColor: const Color(0xFF054F3A),
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => RoutesManager.navigateAndRemoveUntil(
                context, RoutesManager.login),
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

  ProfileMenuItemModel(
      {required this.icon,
        required this.title,
        required this.route,
        required this.iconColor,
        this.isLogout = false});
}