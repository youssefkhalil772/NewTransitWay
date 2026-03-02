import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../tickets/tickets.dart';

class QRScannerPage extends StatefulWidget {
  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [

        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              controller.stop(); // نوقف الكاميرا عشان نفتح الدايالوج
              _showSuccessDialog(context);
            }
          },
        ),


        Center(
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Scan Now", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Icon(Icons.qr_code_scanner, size: 120, color: Colors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Ticket Scanned Successfully",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {

                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyTicketsScreen()),
                );
              },
              child: Text("View Your Tickets", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.start();
              },
              child: Text("OK", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}