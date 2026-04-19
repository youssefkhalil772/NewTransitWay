import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/feature/login/login.dart';
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
        // تكبير مساحة الصورة لتقليل مساحة الجزء الأبيض
        Expanded(
          flex: 6, 
          child: SizedBox(
            width: double.infinity,
            child: Image.asset(
              model.image,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),

        // الجزء الخاص بالنصوص والأزرار
        Expanded(
          flex: 4, // جعل الجزء الأبيض يأخذ مساحة أقل (40% من الشاشة)
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(25.w, 30.h, 25.w, 0), // أزلنا الـ padding السفلي هنا
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.r),
                topRight: Radius.circular(40.r),
              ),
            ),
            child: SafeArea(
              top: false, // نهتم فقط بالـ SafeArea من الأسفل
              child: Column(
                children: [
                  Text(
                    model.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.sp, // تصغير الخط قليلاً ليناسب المساحة
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    model.subTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  
                  const Spacer(),

                  // النقاط التوضيحية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      OnboardingModel.onboardingPages.length,
                      (index) => _buildDot(index == currentIndex),
                    ),
                  ),

                  const Spacer(),

                  // زرار البداية
                  if (isLastPage)
                    Padding(
                      padding: EdgeInsets.only(bottom: 20.h), // مسافة أمان إضافية
                      child: SizedBox(
                        width: double.infinity,
                        height: 50.h, // تقليل ارتفاع الزرار قليلاً
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0XFF054F3A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Get Started",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(height: 70.h), // مساحة للحفاظ على التوازن
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(right: 8.w),
      height: 8.h,
      width: 8.w,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF054F3A) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}
