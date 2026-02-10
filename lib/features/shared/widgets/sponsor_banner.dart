import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';

/// Provider for fetching active sponsors from your API
final activeSponsorsProvider = FutureProvider.autoDispose((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get(AppConfig.sponsors);
    if (response.data is List) {
      return response.data as List;
    }
    return [];
  } catch (e) {
    debugPrint('Failed to load sponsors: $e');
    return [];
  }
});

/// Sponsor banner widget - displays your own sponsors from the API
/// This is separate from AdMob ads and shows your direct sponsors
class SponsorBanner extends ConsumerWidget {
  const SponsorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sponsorsAsync = ref.watch(activeSponsorsProvider);

    return sponsorsAsync.when(
      data: (sponsors) {
        if (sponsors.isEmpty) return const SizedBox.shrink();
        final sponsor = sponsors.first;
        return _SponsorCard(sponsor: sponsor);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SponsorCard extends StatelessWidget {
  final Map<String, dynamic> sponsor;

  const _SponsorCard({required this.sponsor});

  Future<void> _handleTap(BuildContext context) async {
    final url = sponsor['website_url'];
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return const Color(0xFF607D8B);
      case 'gold':
        return const Color(0xFFFFB300);
      case 'silver':
        return const Color(0xFF9E9E9E);
      case 'bronze':
      default:
        return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tier = sponsor['tier'] ?? 'bronze';
    final tierColor = _getTierColor(tier);

    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? AppColors.sponsorBackgroundDark : AppColors.sponsorBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tierColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Sponsor logo
              if (sponsor['logo_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: sponsor['logo_url'],
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade200,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.business, color: Colors.grey.shade400),
                    ),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.business, color: tierColor),
                ),
              const SizedBox(width: 12),

              // Sponsor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Sponsored',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tierColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tier.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              color: tierColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sponsor['name'] ?? 'Sponsor',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (sponsor['tagline'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sponsor['tagline'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
