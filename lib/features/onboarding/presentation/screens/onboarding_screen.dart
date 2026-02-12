import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';

/// Key for storing onboarding completion status
const String _onboardingCompleteKey = 'onboarding_complete';

/// Provider to check if onboarding is complete
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingCompleteKey) ?? false;
});

/// Mark onboarding as complete
Future<void> completeOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingCompleteKey, true);
}

/// Reset onboarding (for testing)
Future<void> resetOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_onboardingCompleteKey);
}

/// Onboarding page data
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Onboarding pages content
const List<OnboardingPage> _onboardingPages = [
  OnboardingPage(
    title: 'Welcome to Nuclear MOTD',
    description: 'Stay informed with daily messages curated for the nuclear industry. '
        'Get the latest updates, safety tips, and industry insights.',
    icon: Icons.wb_sunny_outlined,
    color: Color(0xFF1565C0),
  ),
  OnboardingPage(
    title: 'Personalized Topics',
    description: 'Subscribe to topics that matter to you. From safety protocols to '
        'industry news, customize your feed to match your interests.',
    icon: Icons.category_outlined,
    color: Color(0xFF00897B),
  ),
  OnboardingPage(
    title: 'Never Miss a Message',
    description: 'Set your preferred schedule and receive notifications when new '
        'messages are available. Stay up-to-date on your terms.',
    icon: Icons.notifications_outlined,
    color: Color(0xFFF57C00),
  ),
  OnboardingPage(
    title: 'Save & Share',
    description: 'Bookmark important messages for later and share valuable insights '
        'with your colleagues. Knowledge is meant to be shared.',
    icon: Icons.bookmark_border,
    color: Color(0xFF7B1FA2),
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  /// Optional callback when onboarding completes (used when viewing from About page)
  final VoidCallback? onComplete;
  
  const OnboardingScreen({super.key, this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await completeOnboarding();
    if (mounted) {
      // If we have a custom callback (viewing from About), use it
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        // Otherwise navigate to login (first-time user flow)
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    widget.onComplete != null ? 'Close' : 'Skip',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageView(page: _onboardingPages[index]);
                },
              ),
            ),
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingPages.length,
                  (index) => _PageIndicator(
                    isActive: index == _currentPage,
                    color: _onboardingPages[_currentPage].color,
                  ),
                ),
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _onboardingPages[_currentPage].color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    _currentPage == _onboardingPages.length - 1
                        ? (widget.onComplete != null ? 'Done' : 'Get Started')
                        : 'Next',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with background
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha:isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _PageIndicator({
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
