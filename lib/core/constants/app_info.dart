import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Everything shown on the About screen lives here.
///
/// **Fork checklist** — edit the values in [AppInfo] and [socialLinks] with
/// your own name, handles and URLs. Anything left blank is hidden
/// automatically, so the screen never shows a dead link.
abstract final class AppInfo {
  // ── Developer ────────────────────────────────────────────────────────
  static const String developerName = 'Arsalan Kaleem';
  static const String developerRole = 'Flutter And AI Engineer · Motorsport Nerd';
  static const String developerBio =
      'I build fast, data-dense interfaces. F1 Vision is my playground for '
      'real-time telemetry, race strategy analysis and the kind of dashboard '
      'design that usually stays locked inside a paddock.';
  static const String developerLocation = 'Karachi, Pakistan';

  /// Optional headshot in `assets/branding/`. Leave null to show initials.
  static const String avatarAsset = 'assets/branding/me.png';

  // ── App ──────────────────────────────────────────────────────────────
  static const String appName = 'F1 Vision';
  static const String appTagline = 'Formula 1 analytics, telemetry & replay';
  static const String version = '0.6.0';
  static const int copyrightYear = 2026;

  // ── Repository & support ─────────────────────────────────────────────
  static const String repoUrl = 'https://github.com/ArsalanKaleem/F1-Vision';
  static const String issuesUrl = '$repoUrl/issues';
  static const String bugReportUrl = '$repoUrl/issues/new?labels=bug';
  static const String featureRequestUrl =
      '$repoUrl/issues/new?labels=enhancement';

  /// Store listings. Leave blank until published — Rate App then falls back to
  /// starring the repository.
  static const String androidStoreUrl = '';
  static const String iosStoreUrl = '';

  static const String privacyPolicyUrl = '';
  static const String termsUrl = '';

  /// Initials used when no [avatarAsset] is supplied.
  static String get initials {
    final parts = developerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// A social destination rendered as a rounded, brand-tinted button.
class SocialLink {
  const SocialLink({
    required this.label,
    required this.handle,
    required this.url,
    required this.icon,
    required this.color,
  });

  final String label;
  final String handle;
  final String url;
  final IconData icon;
  final Color color;
}

/// The social buttons shown in the hero. Entries with an empty [url] are
/// filtered out, so delete or blank the ones you don't use.
const List<SocialLink> socialLinks = [
  SocialLink(
    label: 'GitHub',
    handle: 'Arsalan Kaleem',
    url: 'https://github.com/ArsalanKaleem',
    icon: FontAwesomeIcons.github,
    color: Color(0xFF8B94A3),
  ),
  SocialLink(
    label: 'LinkedIn',
    handle: '/in/arsalankaleem',
    url: 'www.linkedin.com/in/arsalankaleem',
    icon: FontAwesomeIcons.linkedinIn,
    color: Color(0xFF0A66C2),
  ),
  SocialLink(
    label: 'Email',
    handle: 'arsalanabbasi.here@gmail.com',
    url: 'mailto:arsalanabbasi.here@gmail.com',
    icon: FontAwesomeIcons.envelope,
    color: Color(0xFFE1A100),
  ),
  SocialLink(
    label: 'Website',
    handle: 'https://arsalankaleem.github.io/portfolio/',
    url: 'https://arsalankaleem.github.io/portfolio/',
    icon: FontAwesomeIcons.globe,
    color: Color(0xFF2ECC71),
  ),
];

/// Bundled fallback text so Privacy and Terms never dead-end before the
/// hosted pages exist.
abstract final class LegalText {
  static const String privacy = '''
F1 Vision does not collect, store or transmit personal data to servers operated
by the developer.

• Account data — if you sign in, your email and display name are handled by
  Google Firebase Authentication under Google's privacy policy. You can delete
  your account at any time from Settings.
• On-device storage — your theme preference and a cache of public Formula 1
  data are stored locally on your device. Clearing the cache from Settings
  removes it.
• Third-party APIs — race data is requested from OpenF1 and Jolpica. Those
  requests carry your IP address to those providers, as any web request does.
• Analytics — this app contains no advertising or third-party tracking SDKs.
''';

  static const String terms = '''
By using F1 Vision you agree to the following.

• Unofficial project — F1 Vision is an independent fan project. It is not
  associated with, endorsed by, or affiliated with Formula 1, the FIA, or any
  team. "F1" and "Formula 1" are trademarks of their respective owners.
• Data accuracy — timing, telemetry and results come from third-party public
  APIs and are provided "as is", without warranty. Do not rely on this app for
  betting, commercial or safety-critical decisions.
• Availability — upstream APIs may rate-limit or go offline; features may
  degrade or change without notice.
• Licence — the source code is released under the MIT Licence. You may fork
  and modify it in line with that licence.
''';
}
