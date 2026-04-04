import 'package:flutter/material.dart';
import 'package:transite_way/feature/home/presentation/screens/home_screen.dart';
import 'package:transite_way/feature/login/login.dart';
import '../../payMent/charge_point.dart';
import '../../payMent/pay_details.dart';
import '../model/onboarding_model.dart';

class OnboardingItem extends StatelessWidget {
  final OnboardingModel model;
  final int currentIndex;
  final VoidCallback onGetStarted;

  const OnboardingItem({
    super.key,
    required this.model,
    required this.currentIndex,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {

    bool isLastPage = currentIndex == OnboardingModel.onboardingPages.length - 1;

    return Column(
      children: [

        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(2.0),
            child: Image.asset(
              model.image,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),


        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 40, 30, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Text(
                  model.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  model.subTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    OnboardingModel.onboardingPages.length,
                        (index) => _buildDot(index == currentIndex),
                  ),
                ),

                const Spacer(),

                if (isLastPage)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => ChargeMyPointsScreen() ),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0XFF054F3A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child:  Text(

                        "Get Started",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 55),
                  ]
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 10,
      width: 10,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2E4E45) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}