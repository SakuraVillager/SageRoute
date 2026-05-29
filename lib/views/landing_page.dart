import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/color_schemes.dart';

/// Landing style guide page matching the Web version's Landing.tsx.
///
/// Displays a full-screen hero image with gradient overlay, brand badge,
/// title, description, CTA buttons, and social login placeholders.
/// Navigation is handled via callbacks — no built-in routing.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key, this.onStartJourney, this.onLogin});

  /// Callback when the user taps the primary "开启旅程" button.
  final VoidCallback? onStartJourney;

  /// Callback when the user taps any login-related button.
  final VoidCallback? onLogin;

  // Brand colours extracted from the Web landing page.
  static const Color _scaffoldBg = Color(0xFFF5F0EA);
  static const Color _badgeBg = Color(0xFFEBE5DA);
  static const Color _badgeText = Color(0xFF8A8376);
  static const Color _sageText = Color(0xFF2C2624);
  static const Color _mutedText = Color(0xFFA8A195);
  static const Color _borderColor = Color(0xFFDCD6C8);
  static const Color _ctaBg = Color(0xFF1C1A1A);
  static const Color _ctaText = Color(0xFFF3EFE9);
  // Web 版主按钮箭头圆圈使用 sage-accent (#B96144 / 陶土红)，
  // 之前误用了浅褐色 #BDA88A，这里修正为品牌强调色。
  static const Color _accentColor = AppColors.sageAccent;
  static const Color _socialBtnBg = Color(0xFFFAF7F2);
  static const Color _socialBtnBorder = Color(0xFFE8E2D9);
  static const Color _secondaryText = Color(0xFF8A8376);

  static const String _bgImageUrl =
      'https://images.unsplash.com/photo-1574227492706-f65b24c3688a?auto=format&fit=crop&q=80&w=1200';

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: Stack(
        children: [
          // ── Hero image with gradient mask (top 65% of screen) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.65,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  _bgImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                // Gradient mask: image fully visible at top, fades to
                // scaffold background at bottom (matches CSS mask-image:
                // linear-gradient(to bottom, black 40%, transparent 100%)).
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, _scaffoldBg],
                          stops: [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content overlay ──
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            const SizedBox(height: 64),

                            // Brand badge
                            _buildBadge(),

                            // Push remaining content to the bottom
                            // (mt-auto equivalent in CSS flex)
                            const Spacer(),

                            // Title, description, buttons
                            _buildContentSection(),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Badge: "历史足迹 | 跨越时空的旅途" ──
  // Web 版: bg-[#EBE5DA]/50 backdrop-blur-md
  Widget _buildBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: _badgeBg.withAlpha(128),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Text(
            '历史足迹 | 跨越时空的旅途',
            style: TextStyle(
              color: _badgeText,
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom content: title, subtitle, description, buttons, terms ──
  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row: "Sage — Route"
        _TitleRow(),
        const SizedBox(height: 12),

        // Subtitle
        // Web: tracking-[0.3em] uppercase — 0.3em ≈ 4.2px at 14px font size.
        const Text(
          '穿越历史的旅程',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 14,
            letterSpacing: 4.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),

        // Description heading
        const Text(
          '踏上诗人、哲学家\n与帝王走过的足迹。',
          style: TextStyle(
            color: _sageText,
            fontSize: 26,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Description paragraph
        const Text(
          '探索由历史名人生平精心策划的旅行路线——从苏东坡的贬谪之路，到马可·波罗的东方之旅。',
          style: TextStyle(
            color: _secondaryText,
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 32),

        // ── Primary CTA ──
        _buildPrimaryButton(),
        const SizedBox(height: 16),

        // ── Secondary login button ──
        _buildSecondaryButton(),
        const SizedBox(height: 32),

        // ── "或" divider ──
        _buildDividerWithText(),
        const SizedBox(height: 24),

        // ── Social login row ──
        _buildSocialButtons(),
        const SizedBox(height: 32),

        // ── Terms text ──
        _buildTermsText(),
      ],
    );
  }

  // ── "开启旅程" CTA ──
  Widget _buildPrimaryButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Web 版 shadow-lg: 0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -4px rgba(0,0,0,0.1)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onStartJourney,
          style: ElevatedButton.styleFrom(
            backgroundColor: _ctaBg,
            foregroundColor: _ctaText,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '开启旅程',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '探索',
                    style: TextStyle(color: _mutedText, fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── "登录以继续" outlined ──
  Widget _buildSecondaryButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onLogin,
        style: OutlinedButton.styleFrom(
          foregroundColor: _sageText,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: const BorderSide(color: _borderColor),
        ),
        child: const Text(
          '登录以继续',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  // ── "或" divider ──
  Widget _buildDividerWithText() {
    return Row(
      children: [
        const Expanded(child: Divider(color: _borderColor, thickness: 1)),
        Container(
          color: _scaffoldBg,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            '或',
            style: TextStyle(
              color: _mutedText,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _borderColor, thickness: 1)),
      ],
    );
  }

  // ── Social login: Google, Apple, WeChat ──
  // Web 版用 SVG 品牌图标；Flutter 这里用 Material Icons 近似替代。
  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(label: '谷歌', icon: const _GoogleGlyph()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            label: '苹果',
            icon: const Icon(Icons.apple, size: 18, color: Color(0xFF1C1A1A)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            label: '微信',
            icon: const Icon(
              Icons.chat_bubble,
              size: 14,
              color: Color(0xFF09B83E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({required String label, required Widget icon}) {
    return OutlinedButton(
      onPressed: onLogin,
      style: OutlinedButton.styleFrom(
        foregroundColor: _sageText,
        backgroundColor: _socialBtnBg,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: _socialBtnBorder),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // ── Terms & Privacy text ──
  Widget _buildTermsText() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          style: TextStyle(color: _mutedText, fontSize: 11),
          children: [
            TextSpan(text: '继续即表示您同意我们的'),
            TextSpan(
              text: '使用条款',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: _borderColor,
                decorationThickness: 1,
              ),
            ),
            TextSpan(text: '与'),
            TextSpan(
              text: '隐私政策',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: _borderColor,
                decorationThickness: 1,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Private helper: "Sage — Route" title row
// ─────────────────────────────────────────────────────────────

/// Renders the "Sage —— Route" heading with a decorative 1 px line.
class _TitleRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xFF2C2624),
      fontSize: 44,
      height: 1.0,
      fontWeight: FontWeight.w700,
    );

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Sage', style: style),
        SizedBox(width: 12),
        SizedBox(
          width: 32,
          height: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFF2C2624)),
          ),
        ),
        SizedBox(width: 12),
        Text('Route', style: style),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Private helper: Google "G" glyph in brand colors
// ─────────────────────────────────────────────────────────────

/// A simple stylized "G" glyph approximating the Google brand mark,
/// since the project does not depend on flutter_svg.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4), // Google blue
            height: 1,
          ),
        ),
      ),
    );
  }
}
