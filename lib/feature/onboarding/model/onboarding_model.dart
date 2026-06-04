import '../../../core/resources/assest_manager.dart';

class OnboardingModel {
  final String image;
  final String title;
  final String subTitle;

  const OnboardingModel({
    required this.image,
    required this.title,
    required this.subTitle,
  });

  static const List<OnboardingModel> onboardingPages = [
    OnboardingModel(
      image: ImageAssets.phone,
      title: "Track Your Ride in Real Time",
      subTitle:
          "Know exactly where your bus is and \n when it will arrive, no more guessing \nor long waits.",
    ),

    OnboardingModel(
      image: ImageAssets.phonee,
      title: "Pay Smart, Travel Easy",
      subTitle:
          "Buy tickets and subscriptions \n securely using multiple digital \npayment options â€” fast and cash-\nfree",
    ),

    OnboardingModel(
      image: ImageAssets.buss,
      title: "Arrive On Time, Every Time",
      subTitle:
          "Get accurate ETAs, instant alerts, and\n a smoother journey from start to\n finish.",
    ),
  ];
}
