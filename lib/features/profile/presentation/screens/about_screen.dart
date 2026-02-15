import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
            const Text('About'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Atom logo matching web version
                  const AtomLogo(
                    size: 80,
                    borderRadius: 20,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nuclear Message of the Day',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version ${AppConfig.appVersion}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Nuclear MOTD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nuclear Message of the Day (MOTD) is a professional communication platform designed specifically for the nuclear industry. Our mission is to deliver timely, relevant safety messages and industry insights directly to nuclear professionals worldwide.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Whether you\'re working in operations, maintenance, safety, engineering, or management, Nuclear MOTD helps you stay informed about best practices, safety culture, regulatory updates, and emerging technologies in the nuclear sector.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // Features List
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha:0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platform Features',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(Icons.category_outlined, '48+ Industry Topics', 'Comprehensive coverage of nuclear industry areas'),
                  _buildFeatureItem(Icons.schedule_outlined, 'Flexible Scheduling', 'Daily, weekly, or custom delivery options'),
                  _buildFeatureItem(Icons.public_outlined, 'Global Timezone Support', 'Receive messages at your preferred time'),
                  _buildFeatureItem(Icons.edit_note_outlined, 'Content Contributions', 'Share your expertise with the community'),
                  _buildFeatureItem(Icons.security_outlined, 'Privacy Compliant', 'GDPR and PIPEDA compliant platform'),
                ],
              ),
            ),

            // Support Us Section
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite_outline, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Support Nuclear MOTD',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Help us keep Nuclear MOTD free and continue improving the platform for the nuclear community.',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl('https://ko-fi.com/kernkraft'),
                          icon: const Icon(Icons.coffee_outlined),
                          label: const Text('Ko-fi'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber.shade800,
                            side: BorderSide(color: Colors.amber.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl('https://buymeacoffee.com/kernkraft'),
                          icon: const Icon(Icons.local_cafe_outlined),
                          label: const Text('Buy Me a Coffee'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber.shade800,
                            side: BorderSide(color: Colors.amber.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contact Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(Icons.language_outlined, color: AppColors.primary),
                    title: const Text('Visit Website'),
                    subtitle: const Text('nuclear-motd.com'),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _launchUrl('https://nuclear-motd.com'),
                  ),
                  ListTile(
                    leading: Icon(Icons.email_outlined, color: AppColors.primary),
                    title: const Text('Contact Support'),
                    subtitle: const Text('support@nuclear-motd.com'),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _launchUrl('mailto:support@nuclear-motd.com'),
                  ),
                  ListTile(
                    leading: Icon(Icons.policy_outlined, color: AppColors.primary),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.description_outlined, color: AppColors.primary),
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.play_circle_outline, color: AppColors.primary),
                    title: const Text('View App Tour'),
                    subtitle: const Text('See the onboarding guide again'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OnboardingScreen(
                            onComplete: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Copyright
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  Text(
                    '© ${DateTime.now().year} Kernkraft Consulting Inc.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All rights reserved.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
