import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
            const Text('Help'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Getting Started Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Getting Started',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHelpCard(
                    icon: Icons.category_outlined,
                    title: 'Choose Your Topics',
                    content: 'Go to Topics and select the nuclear industry areas you\'re interested in. You\'ll only receive messages related to your selected topics.',
                    isDark: isDark,
                  ),
                  _buildHelpCard(
                    icon: Icons.schedule_outlined,
                    title: 'Set Your Schedule',
                    content: 'Visit Profile > Edit Schedule to choose when you receive messages: daily, weekly, or specific days. Set your preferred time and timezone.',
                    isDark: isDark,
                  ),
                  _buildHelpCard(
                    icon: Icons.bookmark_outline,
                    title: 'Save Messages',
                    content: 'Tap the bookmark icon on any message to save it for later. Access saved messages from the menu > Bookmarks.',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // FAQ Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFAQ(
                    question: 'How do I stop receiving emails?',
                    answer: 'Go to Profile > Edit Schedule and select "Disabled", or use the unsubscribe link in any email. Your account stays active for app access.',
                    isDark: isDark,
                  ),
                  _buildFAQ(
                    question: 'Can I change my email address?',
                    answer: 'Contact support to change your email address. Your message history and preferences will be transferred.',
                    isDark: isDark,
                  ),
                  _buildFAQ(
                    question: 'How do I submit my own content?',
                    answer: 'Use Submit Content from the main menu. Your submission will be reviewed before being shared with the community.',
                    isDark: isDark,
                  ),
                  _buildFAQ(
                    question: 'Why am I not receiving messages?',
                    answer: 'Check that: 1) Email delivery is enabled in your schedule, 2) You have at least one topic selected, 3) Check your spam folder.',
                    isDark: isDark,
                  ),
                  _buildFAQ(
                    question: 'How do I delete my account?',
                    answer: 'Visit nuclear-motd.com, log in, and go to Profile > Privacy & Data > Request Data Deletion. Your request will be processed within 30 days per GDPR requirements.',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // Contact Support Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need More Help?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.email_outlined, color: AppColors.primary),
                      title: const Text('Email Support'),
                      subtitle: const Text('support@nuclear-motd.com'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl('mailto:support@nuclear-motd.com'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.language_outlined, color: AppColors.primary),
                      title: const Text('Visit Website'),
                      subtitle: const Text('nuclear-motd.com'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl('https://nuclear-motd.com'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.4,
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

  Widget _buildFAQ({
    required String question,
    required String answer,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
