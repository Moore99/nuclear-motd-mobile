import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Service for sharing content to other apps
class ShareService {
  /// Share a message
  static Future<void> shareMessage({
    required String title,
    required String content,
    String? url,
    Rect? sharePositionOrigin,
  }) async {
    debugPrint('📤 Sharing - Title: $title');
    debugPrint('📤 Sharing - Content length: ${content.length}');
    
    // Strip HTML tags from content for plain text sharing
    final plainContent = _stripHtml(content);
    debugPrint('📤 Sharing - Plain content length: ${plainContent.length}');
    
    // Build share text
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln();
    if (plainContent.isNotEmpty) {
      buffer.writeln(plainContent);
      buffer.writeln();
    }
    
    if (url != null && url.isNotEmpty) {
      buffer.writeln('Read more: $url');
      buffer.writeln();
    }
    
    buffer.writeln('— Shared from Nuclear MOTD');
    
    final shareText = buffer.toString();
    debugPrint('📤 Final share text: $shareText');
    
    await Share.share(
      shareText,
      subject: title,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share just a link
  static Future<void> shareLink({
    required String url,
    String? title,
    Rect? sharePositionOrigin,
  }) async {
    final text = title != null ? '$title\n\n$url' : url;
    
    await Share.share(
      text,
      subject: title,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Strip HTML tags from content
  static String _stripHtml(String html) {
    // Remove HTML tags
    final withoutTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    // Normalize whitespace
    final normalized = withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Decode common HTML entities
    return normalized
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  /// Get share position for iPad (required for proper display)
  static Rect? getSharePosition(BuildContext context, GlobalKey? key) {
    if (key?.currentContext != null) {
      final box = key!.currentContext!.findRenderObject() as RenderBox?;
      if (box != null) {
        final position = box.localToGlobal(Offset.zero);
        return Rect.fromLTWH(
          position.dx,
          position.dy,
          box.size.width,
          box.size.height,
        );
      }
    }
    return null;
  }
}
