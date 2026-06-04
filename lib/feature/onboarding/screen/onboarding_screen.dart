import 'package:flutter/material.dart';
import '../model/onboarding_model.dart';
import '../widged/onboarding_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: OnboardingModel.onboardingPages.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return OnboardingItem(
                model: OnboardingModel.onboardingPages[index],
                currentIndex: _currentIndex,
                onGetStarted: () {},
              );
            },
          ),

          if (_currentIndex != OnboardingModel.onboardingPages.length - 1)
            Positioned(
              bottom: 30,
              right: 30,
              child: GestureDetector(
                onTap: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.black87),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
