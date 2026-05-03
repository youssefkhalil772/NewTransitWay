import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/routes/routes_manager.dart';
import '../../main.dart';
import '../home/presentation/widgets/custom_points_badge.dart';
import '../../core/utils/sound_manager.dart';

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
  MobileScannerController? cameraController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  bool isProcessing = false;
  bool showCamera = false;
  bool isDialogShowing = false; 
  int _scannerResetKey = 0; 

  @override
  void initState() {
    super.initState();
    _initAnimation();
    if (widget.isActive) _activateCamera();
  }

  void _initializeScanner() {
    if (cameraController != null) {
      cameraController!.dispose();
    }
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      autoStart: false,
    );
  }

  void _initAnimation() {
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
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

  void _activateCamera() {
    if (mounted) {
      setState(() {
        isProcessing = false;
        isDialogShowing = false;
        showCamera = false;
        _scannerResetKey++; 
        _initializeScanner(); 
      });
    }
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && widget.isActive && cameraController != null) {
        setState(() => showCamera = true);
        cameraController!.start();
        _animationController.repeat(reverse: true);
      }
    });
  }

  void _deactivateCamera() {
    _animationController.stop();
    cameraController?.stop();
    if (mounted) setState(() => showCamera = false);
  }

  String _translateError(String? error) {
    if (error == null) return 'An unexpected error occurred';
    const Map<String, String> errorMessages = {
      'Invalid QR code': 'Invalid or expired QR code',
      'No active trip found for this bus': 'No active trip found for this bus',
      'Insufficient balance': 'Insufficient balance',
      'User not found': 'User not found',
      'Route not found for this QR': 'Route not found for this QR code',
    };
    for (final entry in errorMessages.entries) {
      if (error.contains(entry.key)) return entry.value;
    }
    return error;
  }

  Future<void> _handlePayment(String qrCode) async {
    if (isProcessing || isDialogShowing) return;
    setState(() {
      isProcessing = true;
      isDialogShowing = true;
    });
    _animationController.stop();
    cameraController?.stop();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not found — please log in');
      }

      final response = await Supabase.instance.client.functions.invoke(
        'scan-pay',
        body: {
          'userId': userId,
          'qrToken': qrCode,
        },
      );

      final data = response.data;

      if (data is Map && data['error'] != null) {
        final errorMsg = _translateError(data['error'].toString());
        if (mounted) {
          setState(() {
            isProcessing = false;
            isDialogShowing = false;
          });
          if (errorMsg.toLowerCase().contains('insufficient') || errorMsg.toLowerCase().contains('balance')) {
            _showInsufficientBalanceDialog(context);
          } else {
            _showErrorDialog(context, customMessage: errorMsg);
          }
        }
        return;
      }

      // Update local balance
      if (data is Map && data['remainingBalance'] != null) {
        final int balance = (data['remainingBalance'] as num).toInt();
        CustomPointsBadge.updateGlobalBalance(balance);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userPoints', balance);
      }

      if (mounted) {
        SoundManager.playSuccess();
        _showSuccessDialog(
          context,
          routeName: data['routeName']?.toString(),
          fare: (data['fare'] as num?)?.toDouble(),
          remainingBalance: (data['remainingBalance'] as num?)?.toInt(),
        );
      }
    } catch (e) {
      debugPrint('🛑 scan-pay Edge Function Error: $e');
      if (mounted) {
        setState(() {
          isProcessing = false;
          isDialogShowing = false;
        });
        final errStr = e.toString();
        if (errStr.toLowerCase().contains('insufficient') || errStr.toLowerCase().contains('balance')) {
          _showInsufficientBalanceDialog(context);
        } else {
          _showErrorDialog(context, customMessage: _translateError(errStr));
        }
      }
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _animationController.dispose();
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey('scanner_scaffold_$_scannerResetKey'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          IconButton(icon: Icon(Icons.arrow_back, color: Colors.black, size: 26.sp), onPressed: () => widget.onBackToHome?.call()),
          Text("Transit", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24.sp)),
          Text("Way", style: TextStyle(color: const Color(0xFF054F3A), fontWeight: FontWeight.bold, fontSize: 24.sp)),
        ]),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: const Center(child: CustomPointsBadge()),
          )
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          _buildCameraPreview(),
          _buildScannerOverlay(),
          if (isProcessing) 
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white))
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (showCamera && widget.isActive && cameraController != null) {
      return MobileScanner(
        key: ValueKey('camera_widget_$_scannerResetKey'),
        controller: cameraController!,
        onDetect: (capture) {
          if (!isProcessing && isDialogShowing == false && capture.barcodes.isNotEmpty) {
            final String code = capture.barcodes.first.rawValue ?? "";
            _handlePayment(code);
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
        Text("Scan Now", style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 25.h),
        Container(
          width: 270.w, height: 270.w,
          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2.5.w), borderRadius: BorderRadius.circular(35.r)),
          child: ClipRRect(borderRadius: BorderRadius.circular(32.r), child: Stack(children: [if (showCamera) _buildAnimatedLine()])),
        ),
        SizedBox(height: 50.h),
        Text("Align QR code within the frame", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15.sp)),
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
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, const Color(0xFF054F3A).withOpacity(0.9), Colors.transparent])),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context, {String? routeName, double? fare, int? remainingBalance}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ScannerDialogContent(
        title: "Payment Successful! ✅",
        subtitle: [
          if (routeName != null) 'Route: $routeName',
          if (fare != null) 'Fare Paid: ${fare.toStringAsFixed(0)} EGP',
          if (remainingBalance != null) 'Remaining Balance: $remainingBalance EGP',
        ].join('\n'),
        buttonText: "View Your Tickets",
        onPrimaryPressed: () {
          Navigator.pop(context);
          widget.onViewTickets?.call();
        },
        onSecondaryPressed: () {
          Navigator.pop(context);
          widget.onBackToHome?.call();
        },
        showSecondaryButton: true,
        isError: false,
      ),
    );
  }

  void _showErrorDialog(BuildContext context, {String? customMessage}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ScannerDialogContent(
        title: "Scan Failed",
        subtitle: customMessage ?? "Invalid or expired QR code",
        buttonText: "Try Again",
        isError: true,
        onPrimaryPressed: () {
          Navigator.pop(context);
          _activateCamera();
        },
        onSecondaryPressed: () {
          Navigator.pop(context);
          _activateCamera();
        },
        showSecondaryButton: false,
      ),
    );
  }

  void _showInsufficientBalanceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ScannerDialogContent(
        title: "Insufficient Balance",
        subtitle: "Please charge your points to continue",
        buttonText: "Charge Now",
        isError: true,
        onPrimaryPressed: () {
          Navigator.pop(context);
          RoutesManager.navigateTo(context, RoutesManager.chargeMyPoints);
        },
        onSecondaryPressed: () {
          Navigator.pop(context);
          _activateCamera();
        },
        showSecondaryButton: false,
      ),
    );
  }
}

class _ScannerDialogContent extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String buttonText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;
  final bool isError;
  final bool showSecondaryButton;

  const _ScannerDialogContent({
    required this.title,
    this.subtitle,
    required this.buttonText,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    this.isError = false,
    this.showSecondaryButton = true,
  });

  @override
  State<_ScannerDialogContent> createState() => _ScannerDialogContentState();
}

class _ScannerDialogContentState extends State<_ScannerDialogContent> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      contentPadding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 25.w),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isError)
            Icon(
              widget.title.contains("Insufficient") ? Icons.warning_amber_rounded : Icons.error_outline,
              color: widget.title.contains("Insufficient") ? Colors.orange : Colors.red,
              size: 60.sp,
            ),
          if (widget.isError) SizedBox(height: 20.h),
          Text(widget.title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.black87)),
          if (widget.subtitle != null) ...[
            SizedBox(height: 10.h),
            Text(widget.subtitle!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
          ],
          SizedBox(height: 35.h),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0XFF054F3A), minimumSize: Size(double.infinity, 55.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r))),
            onPressed: isLoading ? null : () async {
              if (widget.isError) {
                widget.onPrimaryPressed();
              } else {
                setState(() => isLoading = true);
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) widget.onPrimaryPressed();
              }
            },
            child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.buttonText, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17.sp)),
          ),
          if (widget.showSecondaryButton) ...[
            SizedBox(height: 15.h),
            GestureDetector(
              onTap: widget.onSecondaryPressed,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text("OK", style: TextStyle(color: const Color(0xFF054F3A), fontWeight: FontWeight.bold, fontSize: 18.sp, decoration: TextDecoration.underline)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
