import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AtomIcon(size: 28),
            const SizedBox(width: 10),
            const Text('Privacy Policy'),
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
              'Introduction',
              'Nuclear Message of the Day ("Nuclear MOTD", "we", "us", or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and web service.',
            ),

            _buildSection(
              'Information We Collect',
              '''We collect information you provide directly to us, including:

• Account Information: Name, email address, company/organization (optional), and country.

• Profile Preferences: Your selected topics of interest, email delivery preferences, and timezone settings.

• Content Submissions: Any safety insights, best practices, or content you submit for publication.

• Usage Data: Information about how you interact with our service, including messages viewed and features used.''',
            ),

            _buildSection(
              'How We Use Your Information',
              '''We use the information we collect to:

• Deliver personalized daily messages based on your topic preferences
• Send scheduled email notifications at your preferred time
• Improve and optimize our service
• Respond to your comments and questions
• Send administrative information and updates
• Comply with legal obligations''',
            ),

            _buildSection(
              'Data Sharing',
              '''We do not sell your personal information. We may share your information only in the following circumstances:

• With your consent
• To comply with legal obligations
• To protect our rights and safety
• With service providers who assist in operating our service (under strict confidentiality agreements)''',
            ),

            _buildSection(
              'Data Retention',
              'We retain your personal information for as long as your account is active or as needed to provide you services. You may request deletion of your account and associated data at any time by contacting us.',
            ),

            _buildSection(
              'Data Security',
              'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. This includes encryption of data in transit and at rest.',
            ),

            _buildSection(
              'Your Rights',
              '''Depending on your location, you may have the following rights:

• Access: Request a copy of your personal data
• Correction: Request correction of inaccurate data
• Deletion: Request deletion of your data
• Portability: Request transfer of your data
• Objection: Object to certain processing of your data

To exercise these rights, contact us at privacy@nuclear-motd.com''',
            ),

            _buildSection(
              'GDPR Compliance',
              'For users in the European Economic Area (EEA), we process personal data in accordance with the General Data Protection Regulation (GDPR). Our lawful bases for processing include consent, legitimate interests, and contractual necessity.',
            ),

            _buildSection(
              'PIPEDA Compliance',
              'For users in Canada, we comply with the Personal Information Protection and Electronic Documents Act (PIPEDA). We obtain meaningful consent for the collection, use, and disclosure of personal information.',
            ),

            _buildSection(
              'Children\'s Privacy',
              'Our service is not intended for individuals under the age of 18. We do not knowingly collect personal information from children.',
            ),

            _buildSection(
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
            ),

            _buildSection(
              'Contact Us',
              '''If you have questions about this Privacy Policy, please contact us:

Email: privacy@nuclear-motd.com
Website: https://nuclear-motd.com/contact''',
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha:0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kernkraft Consulting Inc. is committed to protecting your privacy and handling your data responsibly.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
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
