import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
            const Text('Terms of Service'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    'Kernkraft Consulting Inc.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: January 2026',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Acceptance of Terms',
              'By accessing or using Nuclear Message of the Day ("Nuclear MOTD", "Service"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the Service.',
            ),

            _buildSection(
              'Description of Service',
              'Nuclear MOTD is a professional communication platform that delivers daily safety messages, industry insights, and best practices to nuclear industry professionals. The Service includes a mobile application, web interface, and email delivery system.',
            ),

            _buildSection(
              'User Accounts',
              '''To use the Service, you must:

• Provide accurate and complete registration information
• Maintain the security of your account credentials
• Promptly update your information if it changes
• Be at least 18 years of age
• Not share your account with others

You are responsible for all activities that occur under your account.''',
            ),

            _buildSection(
              'Acceptable Use',
              '''You agree not to:

• Use the Service for any unlawful purpose
• Submit false, misleading, or inappropriate content
• Attempt to gain unauthorized access to the Service
• Interfere with or disrupt the Service
• Violate any applicable laws or regulations
• Impersonate any person or entity
• Harvest or collect user information without consent''',
            ),

            _buildSection(
              'Content Submissions',
              '''By submitting content to Nuclear MOTD, you:

• Grant us a non-exclusive, royalty-free license to use, modify, and distribute your content
• Represent that you have the right to submit the content
• Understand that submissions are subject to review before publication
• Agree that we may edit or decline submissions at our discretion

You retain ownership of your original content.''',
            ),

            _buildSection(
              'Intellectual Property',
              'The Service and its original content (excluding user submissions) are owned by Kernkraft Consulting Inc. and are protected by copyright, trademark, and other intellectual property laws. You may not reproduce, distribute, or create derivative works without our express permission.',
            ),

            _buildSection(
              'Email Communications',
              '''By creating an account, you consent to receive:

• Scheduled message deliveries based on your preferences
• Service announcements and updates
• Administrative communications

You may opt out of email deliveries at any time through your account settings or by using the unsubscribe link in our emails.''',
            ),

            _buildSection(
              'Disclaimer of Warranties',
              'THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND. WE DO NOT WARRANT THAT THE SERVICE WILL BE UNINTERRUPTED, ERROR-FREE, OR SECURE. CONTENT PROVIDED THROUGH THE SERVICE IS FOR INFORMATIONAL PURPOSES ONLY AND SHOULD NOT BE CONSIDERED PROFESSIONAL ADVICE.',
            ),

            _buildSection(
              'Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, KERNKRAFT CONSULTING INC. SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF THE SERVICE.',
            ),

            _buildSection(
              'Indemnification',
              'You agree to indemnify and hold harmless Kernkraft Consulting Inc. and its officers, directors, employees, and agents from any claims, damages, or expenses arising from your use of the Service or violation of these Terms.',
            ),

            _buildSection(
              'Termination',
              'We may suspend or terminate your account at any time for any reason, including violation of these Terms. You may also delete your account at any time. Upon termination, your right to use the Service will immediately cease.',
            ),

            _buildSection(
              'Changes to Terms',
              'We reserve the right to modify these Terms at any time. We will notify users of significant changes via email or through the Service. Continued use of the Service after changes constitutes acceptance of the new Terms.',
            ),

            _buildSection(
              'Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of Canada, without regard to conflict of law principles.',
            ),

            _buildSection(
              'Contact Information',
              '''For questions about these Terms, please contact us:

Email: legal@nuclear-motd.com
Website: https://nuclear-motd.com/contact''',
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agreement',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By using Nuclear MOTD, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '© ${DateTime.now().year} Kernkraft Consulting Inc.',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
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
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
