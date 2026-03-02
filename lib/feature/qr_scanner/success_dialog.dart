import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  // بنعرف الكنترولر عشان نتحكم في الكاميرا (نشغلها ونطفيها)
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // الخلفية سوداء زي صورتك
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "TransitWay",
          style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. الكاميرا في الخلفية
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                // أول ما يلقط الكود، بنوقف الكاميرا مؤقتاً ونظهر الدايالوج
                cameraController.stop();
                _showSuccessDialog(context);
              }
            },
          ),

          // 2. تصميم الـ Overlay (المربع الأبيض اللي في نص الشاشة)
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Scan Now",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Icon(Icons.qr_code_scanner, size: 120, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- دالة الـ Dialog (رسالة النجاح) ---
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // لازم يضغط على الأزرار عشان يقفل
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ticket Scanned Successfully",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // الزرار الأخضر
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // ممكن توديه هنا لصفحة التذاكر
                },
                child: const Text("View Your Tickets", style: TextStyle(color: Colors.white)),
              ),

              // زرار الـ OK
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  cameraController.start(); // نرجع نشغل الكاميرا تاني
                },
                child: const Text("OK", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }
}