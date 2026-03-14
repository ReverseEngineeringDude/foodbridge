import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:foodbridge/core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Share Food, Share Hope',
      description: 'Your surplus food can be someone\'s survival. Let\'s bridge the gap between waste and hunger.',
      animation: 'https://assets9.lottiefiles.com/packages/lf20_m6cu96ze.json', // Healthy food animation
    ),
    OnboardingData(
      title: 'Connect With NGOs Instantly',
      description: 'We connect you with certified NGOs and volunteers who ensure your food reaches those who need it most.',
      animation: 'https://assets3.lottiefiles.com/packages/lf20_96bovdur.json', // Connection animation
    ),
    OnboardingData(
      title: 'Every Meal Counts',
      description: 'Track your impact and see how many lives you\'ve touched with your kindness.',
      animation: 'https://assets10.lottiefiles.com/packages/lf20_myejio3g.json', // Impact/Success animation
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(data: _pages[index]);
            },
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.primary : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: () => _pageController.jumpToPage(_pages.length - 1),
                        child: const Text('Skip'),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 56),
                      ),
                      onPressed: () async {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('hasSeenOnboarding', true);
                          if (context.mounted) {
                            context.push('/login');
                          }
                        }
                      },
                      child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String animation;

  OnboardingData({
    required this.title,
    required this.description,
    required this.animation,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDesign.padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            data.animation,
            height: 300,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.volunteer_activism, size: 100, color: AppColors.secondary);
            },
          ),
          const SizedBox(height: 40),
          FadeInDown(
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
