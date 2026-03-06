import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../main.dart';
import '../home/presentation/widgets/custom_points_badge.dart';

class QRScannerPage extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onBackToHome;
  final VoidCallback? onViewTickets;

  const QRScannerPage({
    super.key,
    required this.isActive,
    this.onBackToHome,
    this.onViewTickets,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> with TickerProviderStateMixin, RouteAware {
  late MobileScannerController cameraController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  bool isDialogShowing = false;
  bool showCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _initAnimation();
    if (widget.isActive) _activateCamera();
  }

  void _initializeScanner() {
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      autoStart: false,
    );
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(covariant QRScannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _activateCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _deactivateCamera();
    }
  }

  @override
  void didPopNext() {
    if (widget.isActive) _activateCamera();
  }

  void _activateCamera() {
    if (isDialogShowing) return;
    setState(() {
      isDialogShowing = false;
      showCamera = false;
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && widget.isActive) {
        setState(() => showCamera = true);
        cameraController.start();
        _animationController.repeat(reverse: true);
      }
    });
  }

  void _deactivateCamera() {
    cameraController.stop();
    _animationController.stop();
    if (mounted) setState(() => showCamera = false);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildCustomAppBar(),
      body: Stack(
        alignment: Alignment.center,
        children: [
          _buildCameraPreview(),
          _buildScannerOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(80.h),
      child: Container(
        padding: EdgeInsets.only(top: 35.h, left: 10.w, right: 15.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30.r),
            bottomRight: Radius.circular(30.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: 26.sp),
                  onPressed: () {
                    cameraController.stop();
                    if (widget.onBackToHome != null) widget.onBackToHome!();
                  },
                ),
                Text("TransitWay",
                    style: TextStyle(color: const Color(0xFF054F3A), fontWeight: FontWeight.bold, fontSize: 24.sp)),
                SizedBox(width: 2.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 5.h),
                  child: Icon(Icons.location_on, color: const Color(0xFF054F3A), size: 20.sp),
                ),
              ],
            ),
            const CustomPointsBadge(points: "9833"), // استدعاء الويدجت الخاصة بكِ
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (showCamera && widget.isActive) {
      return MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (!isDialogShowing && capture.barcodes.isNotEmpty) {
            setState(() => isDialogShowing = true);
            cameraController.stop();
            _showSuccessDialog(context);
          }
        },
      );
    }
    return const Center(child: CircularProgressIndicator(color: Color(0xFF054F3A)));
  }

  Widget _buildScannerOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Scan Now",
            style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 25.h),
        Container(
          width: 270.w, height: 270.w,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2.5.w),
            borderRadius: BorderRadius.circular(35.r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32.r),
            child: Stack(
              children: [
                if (showCamera) _buildAnimatedLine(),
              ],
            ),
          ),
        ),
        SizedBox(height: 50.h),
        Text("Align QR code within the frame",
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15.sp)),
      ],
    );
  }

  Widget _buildAnimatedLine() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: (_animation.value * 270.w),
          left: 0, right: 0,
          child: Container(
            height: 4.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, const Color(0xFF054F3A).withOpacity(0.9), Colors.transparent],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFF054F3A).withOpacity(0.6), blurRadius: 20.r, spreadRadius: 2.r)
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SuccessDialogContent(
        onViewTickets: widget.onViewTickets,
        onBackToHome: widget.onBackToHome, // تمرير دالة العودة للهوم
      ),
    );
  }
}

class _SuccessDialogContent extends StatefulWidget {
  final VoidCallback? onViewTickets;
  final VoidCallback? onBackToHome;

  const _SuccessDialogContent({this.onViewTickets, this.onBackToHome});

  @override
  State<_SuccessDialogContent> createState() => _SuccessDialogContentState();
}

class _SuccessDialogContentState extends State<_SuccessDialogContent> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      contentPadding: EdgeInsets.symmetric(vertical: 35.h, horizontal: 25.w),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Ticket Scanned Successfully",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.black87)),
          SizedBox(height: 35.h),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0XFF054F3A),
              elevation: 0, minimumSize: Size(double.infinity, 55.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
            ),
            onPressed: isLoading ? null : () async {
              setState(() => isLoading = true);
              await Future.delayed(const Duration(milliseconds: 1200));
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pop();
                if (widget.onViewTickets != null) widget.onViewTickets!();
              }
            },
            child: isLoading
                ? SizedBox(height: 22.h, width: 22.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text("View Your Tickets", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17.sp)),
          ),
          SizedBox(height: 20.h),
          GestureDetector(
            onTap: () {
              Navigator.of(context, rootNavigator: true).pop(); // إغلاق الدايالوج
              if (widget.onBackToHome != null) {
                widget.onBackToHome!(); // العودة للهوم
              }
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: Text("OK",
                  style: TextStyle(color: const Color(0xFF054F3A), fontWeight: FontWeight.bold, fontSize: 18.sp, decoration: TextDecoration.underline)),
            ),
          ),
        ],
      ),
    );
  }
}