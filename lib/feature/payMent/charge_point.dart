import 'package:flutter/material.dart';
import 'package:transite_way/core/resources/assest_manager.dart';
import 'package:transite_way/feature/payMent/pay_details.dart';
// تأكدي من عمل import لملف الشاشة الثانية هنا

class ChargeMyPointsScreen extends StatefulWidget {
  const ChargeMyPointsScreen({super.key});

  @override
  State<ChargeMyPointsScreen> createState() => _ChargeMyPointsScreenState();
}

class _ChargeMyPointsScreenState extends State<ChargeMyPointsScreen> {
  TextEditingController amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Charge My Points",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// --------- STEPS BAR ---------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  stepCircle("1", active: true),
                  line(active: true),
                  stepCircle("2"),
                  line(active: false),
                  stepCircle("3"),
                ],
              ),

              const SizedBox(height: 20),

              /// -------- IMAGE --------
              Image.asset(
                ImageAssets.points,
                height: MediaQuery.of(context).size.height * 0.40,
                fit: BoxFit.fitWidth,
              ),

              const SizedBox(height: 30),

              /// -------- INPUT --------
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "Enter the amount you want to pay with",
                  hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// -------- RATE TEXT --------
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w500),
                  children: [
                    TextSpan(text: "Amount "),
                    TextSpan(
                        text: "100 EGP", style: TextStyle(color: Colors.green)),
                    TextSpan(text: " = "),
                    TextSpan(
                        text: "100 Points", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              /// -------- BUTTON (Navigation Added Here) --------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF1B4332),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // الانتقال للشاشة الثانية
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  ChargePointsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Continue To Payment",
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget stepCircle(String num, {bool active = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2D6A4F) : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          num,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget line({bool active = false}) {
    return Container(
      width: 40,
      height: 1.5,
      color: active ? const Color(0xFF2D6A4F) : Colors.grey.shade300,
    );
  }
}