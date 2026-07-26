import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import '../i18n/strings.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';
import '../widgets/language_sheet.dart';
import 'account_screen.dart' show LegalPage, LegalSection, privacySections, termsSections;
import 'dashboard_screen.dart';
import 'farmer_dashboard_screen.dart';

enum _Panel { login, otp }

/// Login → OTP → Dashboard — pure OTP login, no password anywhere. Mirrors
/// the #s1-sheet flow in vanix_screens.html panel-for-panel.
///
/// The HTML version plays a looping, muted, auto-playing hero video behind the
/// sheet (assets/images/hero.mp4) with a dark scrim over it. `_HeroBackground`
/// wires that up via video_player, fading the video in over the fallback
/// gradient (mirrors the CSS `opacity 2.2s ease`).
class LoginScreen extends StatefulWidget {
  final AppState appState;
  const LoginScreen({super.key, required this.appState});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _Panel _panel = _Panel.login;
  // Landing: video + logo at top + a Login CTA at bottom. Tapping Login
  // slides the sheet up (mirrors the HTML splash → landing → sheet flow).
  bool _landing = true;

  final _emailCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 30;
  bool _showResend = false;

  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  VanixStrings get t => VanixStrings.of(widget.appState.languageCode);

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.asset('assets/images/hero.mp4');
    _videoCtrl = ctrl;
    try {
      await ctrl.initialize();
      await ctrl.setVolume(0);
      await ctrl.setLooping(true);
      await ctrl.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (_) {
      // Fall back to the gradient/first-frame background silently.
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _timer?.cancel();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    _emailCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 30;
      _showResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          timer.cancel();
          _showResend = true;
        }
      });
    });
  }

  void _goToOtp() {
    setState(() {
      _panel = _Panel.otp;
      for (final c in _otpCtrls) {
        c.clear();
      }
    });
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _otpFocus.first.requestFocus());
  }

  bool get _otpFilled => _otpCtrls.every((c) => c.text.isNotEmpty);

  void _confirmOtp() {
    if (!_otpFilled) return;
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => widget.appState.isFarmer
            ? FarmerDashboardScreen(appState: widget.appState)
            : DashboardScreen(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDark;
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final theme = isDark ? vanixDarkTheme(languageCode: widget.appState.languageCode) : vanixLightTheme(languageCode: widget.appState.languageCode);
        return Theme(
          data: theme,
          child: Scaffold(
            // Transparent on purpose. Any Scaffold fill is painted by the
            // canvas, which on Flutter web composites *above* the video's
            // <flt-platform-view> — an opaque colour here tints the whole hero
            // (it read dark green as #111111, washed-out as #F2EDE4).
            // _HeroBackground supplies the warm #F2EDE4 fallback instead.
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned.fill(child: _HeroBackground(controller: _videoReady ? _videoCtrl : null)),
                // Top bar — persona toggle left, language selector right.
                // (Display-mode + dark-mode toggles removed: the app is fixed
                // to image cards + light mode.)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PersonaToggle(
                          label: widget.appState.isOwner
                              ? 'Owner'
                              : (widget.appState.isSingleFarm ? 'Manager · 1' : 'Manager · N'),
                          onTap: widget.appState.cyclePersona,
                        ),
                        const Spacer(),
                        _PillButton(
                          label: VanixLanguage.supported.firstWhere((l) => l.code == widget.appState.languageCode).native,
                          isDark: isDark,
                          onDark: true,
                          onTap: () => showLanguageSheet(context, current: widget.appState.languageCode, onSelect: widget.appState.setLanguage),
                        ),
                      ],
                    ),
                  ),
                ),
                // MyBovine logo — near the top on the landing screen. Same
                // vanix-logo.svg the HTML uses (loaded from mybovine.ai, like
                // the HTML does); styled text is the offline fallback.
                const Align(
                  alignment: Alignment(0, -0.62),
                  child: SafeArea(child: _BrandLogo()),
                ),
                // Landing CTA — slides out as the sheet slides in.
                AnimatedSlide(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  offset: _landing ? Offset.zero : const Offset(0, 2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _landing ? 1 : 0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => setState(() => _landing = false),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 52),
                                backgroundColor: VanixColors.greenInk,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              ),
                              child: Text(t.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Login sheet — slides up once Login is tapped.
                AnimatedSlide(
                  duration: const Duration(milliseconds: 550),
                  curve: const Cubic(0.32, 0.72, 0, 1),
                  offset: _landing ? const Offset(0, 1) : Offset.zero,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _SheetContainer(isDark: isDark, frosted: !_landing, child: _buildPanel(isDark)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanel(bool isDark) {
    switch (_panel) {
      case _Panel.login:
        return _LoginPanel(
          key: const ValueKey('login'),
          t: t,
          isDark: isDark,
          emailCtrl: _emailCtrl,
          currentLanguage: widget.appState.languageCode,
          appState: widget.appState,
          onLanguageTap: () => showLanguageSheet(context, current: widget.appState.languageCode, onSelect: widget.appState.setLanguage),
          onContinue: _goToOtp,
        );
      case _Panel.otp:
        return _OtpPanel(
          key: const ValueKey('otp'),
          t: t,
          isDark: isDark,
          otpCtrls: _otpCtrls,
          otpFocus: _otpFocus,
          secondsLeft: _secondsLeft,
          showResend: _showResend,
          confirmEnabled: _otpFilled,
          targetEmail: _emailCtrl.text,
          onBack: () {
            _timer?.cancel();
            setState(() => _panel = _Panel.login);
          },
          onResend: _startTimer,
          onChanged: () {
            setState(() {});
            // all 6 digits in — advance automatically, no Confirm tap needed
            if (_otpFilled) {
              FocusScope.of(context).unfocus();
              Future.delayed(const Duration(milliseconds: 250), _confirmOtp);
            }
          },
          onConfirm: _confirmOtp,
        );
    }
  }
}

/// Looping, muted hero video under a 22% dark scrim — mirrors `#s1-video`:
/// `object-fit: cover; object-position: center top` with an
/// `rgba(0,0,0,0.22)` overlay, revealed over `opacity 2.2s ease`.
///
/// The 2.2s reveal is done by fading the warm fallback fill *out* over the
/// video, rather than fading the video *in*. Same result on screen, but it
/// composites correctly: on Flutter web the video is an
/// `<flt-platform-view>` that sits below the canvas, and both opacity on a
/// platform view and an opaque fill left beneath one misbehave there — an
/// underlay ends up washing the video out instead of hiding behind it.
class _HeroBackground extends StatelessWidget {
  final VideoPlayerController? controller;
  const _HeroBackground({this.controller});

  @override
  Widget build(BuildContext context) {
    final ready = controller != null && controller!.value.isInitialized;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (ready)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: controller!.value.size.width,
              height: controller!.value.size.height,
              child: VideoPlayer(controller!),
            ),
          ),
        // Warm #F2EDE4 fallback (the prototype's `body` background), fading
        // away to reveal the video.
        IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 2200),
            opacity: ready ? 0 : 1,
            child: const ColoredBox(color: VanixColors.bgWarm),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: 0.22)),
      ],
    );
  }
}

/// Demo persona switcher (top-left on login): Owner → Farmer·N → Farmer·1.
class _PersonaToggle extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PersonaToggle({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// The real MyBovine logo (same vanix-logo.svg the HTML landing uses).
/// Fetched defensively: renders the SVG only if the download really returned
/// SVG markup; otherwise (offline, tests, bad response) shows the styled
/// wordmark fallback — no uncaught parse errors.
class _BrandLogo extends StatefulWidget {
  const _BrandLogo();

  @override
  State<_BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<_BrandLogo> {
  String? _svg;

  static const _fallback = Text.rich(TextSpan(children: [
    TextSpan(text: 'My', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
    TextSpan(text: 'Bovine', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF4DDE95))),
  ]));

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse('https://mybovine.ai/assets/logos/vanix-logo.svg'));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        if (body.contains('<svg') && mounted) setState(() => _svg = body);
      }
      client.close();
    } catch (_) {
      // Keep the wordmark fallback.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_svg == null) return _fallback;
    return SvgPicture.string(_svg!, width: 250);
  }
}

/// The frosted login sheet. Mirrors `#s1-sheet`:
///   background: rgba(255,255,255,0.9)      (dark: rgba(16,16,16,0.62))
///   backdrop-filter: blur(26px) saturate(1.5)
///   border-top: 1px rgba(255,255,255,0.7)  (dark: 0.18)
///   border-radius: 24px 24px 0 0
///   padding: 0 32px 40px
///
/// The inline `box-shadow: 0 -8px 32px` is overridden away by the global
/// `[id$="-sheet"] { box-shadow: none !important }` rule, so the sheet renders
/// with no shadow — verified against getComputedStyle. Don't add one back.
class _SheetContainer extends StatelessWidget {
  final bool isDark;
  final Widget child;

  /// Whether to actually apply the frost. A [BackdropFilter] filters the whole
  /// surface painted beneath it — not just its own bounds — so leaving one
  /// mounted while the sheet is parked off-screen (the landing state) washes
  /// out the entire hero video. Only frost while the sheet is on screen.
  final bool frosted;

  const _SheetContainer({required this.isDark, required this.frosted, required this.child});

  // CSS saturate(1.5) as a colour matrix, using the sRGB luminance
  // coefficients from the filter-effects spec (0.213 / 0.715 / 0.072).
  static const List<double> _saturate15 = <double>[
    1.3935, -0.3575, -0.0360, 0, 0, //
    -0.1065, 1.1425, -0.0360, 0, 0, //
    -0.1065, -0.3575, 1.4640, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(24));
    final surface = AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x9E101010) : Colors.white.withValues(alpha: 0.90),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.70))),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: child),
      ),
    );

    return ClipRRect(
      borderRadius: radius,
      child: frosted
          ? BackdropFilter(
              filter: ImageFilter.compose(
                outer: const ColorFilter.matrix(_saturate15),
                inner: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              ),
              child: surface,
            )
          : surface,
    );
  }
}

class _LoginPanel extends StatelessWidget {
  final VanixStrings t;
  final bool isDark;
  final TextEditingController emailCtrl;
  final String currentLanguage;
  final AppState appState;
  final VoidCallback onLanguageTap, onContinue;

  const _LoginPanel({
    super.key,
    required this.t,
    required this.isDark,
    required this.emailCtrl,
    required this.currentLanguage,
    required this.appState,
    required this.onLanguageTap,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    // Language selection lives only in the top-right of the landing page —
    // the login sheet itself carries no language pill.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // #s1-login-panel: padding-top 26px, then the email block at margin-top 20px.
        const SizedBox(height: 26),
        Text(t.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.2, color: textColor)),
        const SizedBox(height: 20),
        _FieldLabel(t.email, isDark: isDark),
        _UnderlineField(controller: emailCtrl, hint: t.phEmail, isDark: isDark),
        // #s1-continue: margin-top 24px, 52px tall, radius 26px.
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: VanixColors.greenInk,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: Text(t.cont, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 14),
        _ConsentLine(t: t, isDark: isDark, appState: appState),
      ],
    );
  }
}

/// "By continuing you are accepting the Privacy Policy and Terms of Service".
/// Mirrors the consent paragraph under `#s1-continue`: 11px, centred,
/// line-height 1.5, `--text2` body with bold + underlined tappable links in
/// `--text1`.
class _ConsentLine extends StatelessWidget {
  final VanixStrings t;
  final bool isDark;
  final AppState appState;
  const _ConsentLine({required this.t, required this.isDark, required this.appState});

  @override
  Widget build(BuildContext context) {
    final bodyColor = isDark ? const Color(0xA6FFFFFF) : VanixColors.textHint;
    final linkColor = isDark ? Colors.white : VanixColors.textPrimary;
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    // Opens the very same legal pages the Account tab uses — mirrors the
    // prototype, which reveals #page-privacy / #page-terms from here.
    void open(String title, List<LegalSection> sections) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LegalPage(appState: appState, title: title, sections: sections)),
        );

    TextSpan link(String label, VoidCallback onTap) => TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 11,
            height: 1.5,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            color: linkColor,
            fontFamily: family,
          ),
          recognizer: TapGestureRecognizer()..onTap = onTap,
        );

    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 11, height: 1.5, color: bodyColor, fontFamily: family),
          children: [
            TextSpan(text: '${t.loginConsentPre} '),
            link(t.rowPrivacy, () => open(t.rowPrivacy, privacySections)),
            TextSpan(text: ' ${t.loginConsentAnd} '),
            link(t.rowTerms, () => open(t.rowTerms, termsSections)),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _OtpPanel extends StatelessWidget {
  final VanixStrings t;
  final bool isDark;
  final List<TextEditingController> otpCtrls;
  final List<FocusNode> otpFocus;
  final int secondsLeft;
  final bool showResend, confirmEnabled;
  final String targetEmail;
  final VoidCallback onBack, onResend, onChanged, onConfirm;

  const _OtpPanel({
    super.key,
    required this.t,
    required this.isDark,
    required this.otpCtrls,
    required this.otpFocus,
    required this.secondsLeft,
    required this.showResend,
    required this.confirmEnabled,
    required this.targetEmail,
    required this.onBack,
    required this.onResend,
    required this.onChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    // On-glass secondary text is #5F5A52 (`#s1-sheet #s1-v-desc`, `#s1-nootp`),
    // not --text2 — verified via computed style.
    final hintColor = isDark ? const Color(0xA6FFFFFF) : const Color(0xFF5F5A52);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        _BackRow(title: t.vtitle, isDark: isDark, onBack: onBack),
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: textColor, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily),
              children: [
                TextSpan(text: '${t.sent} '),
                TextSpan(text: targetEmail.isEmpty ? 'you@example.com' : targetEmail, style: const TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
              ],
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.only(top: 6), child: Text(t.desc, style: TextStyle(fontSize: 13, color: hintColor))),
        // #s1-l-otp: margin 32px 0 12px — the 32 is a full top gap (the desc
        // above has no bottom margin), the 12 = label's 10 + the 2 below.
        const SizedBox(height: 32),
        _FieldLabel(t.enterotp, isDark: isDark),
        const SizedBox(height: 2),
        // #s1-otp-boxes: six 44×52 boxes, radius 10, fixed 10px gaps.
        Row(
          children: [
            for (var i = 0; i < 6; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              SizedBox(
                width: 44,
                height: 52,
                child: TextField(
                  controller: otpCtrls[i],
                  focusNode: otpFocus[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  // OTP digits use the Latin face (font-family: var(--font-en)),
                  // not the Devanagari body font.
                  style: TextStyle(fontSize: 20, color: textColor, fontFamily: 'NotoSans'),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? const Color(0x66FFFFFF) : const Color(0xFF9A948A)),
                    ),
                    // #s1-otp-boxes input:focus — greendeep border + 1px ring.
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: VanixColors.greenDeep, width: 2),
                    ),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) otpFocus[i + 1].requestFocus();
                    onChanged();
                  },
                ),
              ),
            ],
          ],
        ),
        // Timer sits left; the resend prompt only appears once it runs out.
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${t.timer} 0:${secondsLeft < 10 ? '0$secondsLeft' : secondsLeft}s',
              style: TextStyle(fontSize: 13, color: textColor),
            ),
            if (showResend)
              Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 13, color: hintColor, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily),
                  children: [
                    TextSpan(text: '${t.nootp} '),
                    TextSpan(
                      text: t.resend,
                      style: TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.underline, color: textColor),
                      recognizer: TapGestureRecognizer()..onTap = onResend,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: confirmEnabled ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: Text(t.confirm, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ── shared bits ──────────────────────────────────────────────

class _BackRow extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onBack;
  const _BackRow({required this.title, required this.isDark, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white : VanixColors.textPrimary;
    return Row(
      children: [
        IconButton(onPressed: onBack, icon: Icon(Icons.chevron_left, color: color), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 34, minHeight: 34)),
        const SizedBox(width: 4),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FieldLabel(this.label, {required this.isDark});

  // p[id^="s1-l-"]: 11px / w500 / letter-spacing .1em / uppercase.
  // Colour is the on-glass override #5F5A52, not --text2.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.1,
          color: isDark ? const Color(0xA6FFFFFF) : const Color(0xFF5F5A52),
        ),
      ),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  const _UnderlineField({required this.controller, required this.hint, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : VanixColors.textPrimary;
    // #s1-sheet input { border-bottom-color: #9A948A !important } beats the
    // inline #CCCCCC, so the on-glass underline is #9A948A.
    final lineColor = isDark ? const Color(0x66FFFFFF) : const Color(0xFF9A948A);
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 17, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        // #s1-sheet input::placeholder { font-size: 13px }. The colour is the
        // UA default #757575 — the #5F5A52 on-glass override applies to the
        // label paragraphs, not the placeholder (verified via computed style).
        hintStyle: TextStyle(fontSize: 13, color: isDark ? const Color(0x73FFFFFF) : const Color(0xFF757575)),
        filled: false,
        contentPadding: const EdgeInsets.only(bottom: 10),
        border: UnderlineInputBorder(borderSide: BorderSide(color: lineColor)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: lineColor)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: VanixColors.greenDeep)),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  // onDark: the over-photo landing variant — dark translucent fill + white
  // border + white text, matching the Owner persona pill on the left.
  final bool onDark;
  const _PillButton({required this.label, required this.isDark, required this.onTap, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final textColor = onDark ? Colors.white : (isDark ? Colors.white : VanixColors.textPrimary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: onDark ? Colors.white.withValues(alpha: 0.35) : (isDark ? const Color(0x4DFFFFFF) : VanixColors.border)),
          color: onDark ? Colors.black.withValues(alpha: 0.28) : (isDark ? Colors.black.withValues(alpha: 0.30) : Colors.white.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 14, color: textColor),
          ],
        ),
      ),
    );
  }
}
