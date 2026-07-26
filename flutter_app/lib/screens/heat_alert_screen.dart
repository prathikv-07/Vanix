import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../theme/vanix_theme.dart';

/// One heat alert's data for the full-screen carousel.
class _HeatAlertData {
  final String name, breed, farm, time;
  const _HeatAlertData({required this.name, required this.breed, required this.farm, required this.time});
}

/// Multiple cows in heat at once — same card design, different data.
/// Mirrors `FS_ALERTS` in prototype.html. Only Gauri has a dedicated photo
/// today — reused (`cows/nandini.jpg`) for all three as a placeholder pending
/// real per-cow photos, matching the prototype's `a.photo || 'cows/nandini.jpg'`
/// fallback.
const List<_HeatAlertData> _kAlerts = [
  _HeatAlertData(name: 'Gauri', breed: 'Desi', farm: 'Green Valley Farm · Belt 41', time: '04:30'),
  _HeatAlertData(name: 'Mohini', breed: 'Gir/Sahiwal', farm: 'Sunrise Dairy · Belt 91', time: '05:10'),
  _HeatAlertData(name: 'Dhauli', breed: 'Sahiwal', farm: 'Green Valley Farm · Belt 17', time: '05:45'),
];

/// Full-screen "push notification" heat alert carousel — the entry point of
/// the "View full cycle" walkthrough. Mirrors `#ev-alert-fullscreen` +
/// `fsBuildCards()` in prototype.html.
///
/// Swipe or use the arrows to move between cards; actioning one auto-advances
/// to the next unresolved card. Once every card is actioned, pops with the
/// FIRST card's (Gauri's) decision — 'yes' / 'no' — since she is the cow the
/// walkthrough narrates. "No" pops null and the caller opens the walkthrough
/// in "restricted" detail mode.
///
/// NOTE — there is deliberately no ✕ close button. The prototype markup has one
/// (`#ev-fs-close`, prototype.html:2412) but the id collides with the filter
/// sheet's close button, and prototype.html:848
/// (`#farms-fs-close, #cattle-fs-close, #ev-fs-close, #s7-close
/// { display:none !important; }`) hides BOTH — measured `display: none`. "No"
/// is the only dismissal affordance in the live prototype, so it is here too.
class HeatAlertScreen extends StatefulWidget {
  /// Follows the app-wide theme — light farmers get a light alert screen.
  final bool isDark;
  const HeatAlertScreen({super.key, required this.isDark});

  @override
  State<HeatAlertScreen> createState() => _HeatAlertScreenState();
}

class _HeatAlertScreenState extends State<HeatAlertScreen> {
  /// `#ev-fs-strip` transition: `transform 0.35s cubic-bezier(0.32,0.72,0,1)`.
  static const Duration _stripDuration = Duration(milliseconds: 350);
  static const Cubic _stripCurve = Cubic(0.32, 0.72, 0, 1);

  final _pageCtrl = PageController();
  int _index = 0;
  final List<String?> _decisions = List.filled(_kAlerts.length, null);

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    if (i < 0 || i >= _kAlerts.length) return;
    _pageCtrl.animateToPage(i, duration: _stripDuration, curve: _stripCurve);
  }

  void _action(int i, String decision) {
    if (_decisions[i] != null) return;
    setState(() => _decisions[i] = decision);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final next = _decisions.indexWhere((d) => d == null);
      if (next >= 0) {
        _goTo(next);
      } else {
        Navigator.of(context).pop(_decisions[0]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // `#ev-alert-fullscreen` sits on --bgwarm (measured rgb(242,237,228));
    // the photo card covers it, so it only shows if the asset fails to load.
    final shellBg = widget.isDark ? VanixColors.darkPrimary : VanixColors.bgWarm;
    return Scaffold(
      backgroundColor: shellBg,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _kAlerts.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _AlertCard(
                  isDark: widget.isDark,
                  shellBg: shellBg,
                  data: _kAlerts[i],
                  decision: _decisions[i],
                  onYes: () => _action(i, 'yes'),
                  // "No" defers the decision to the in-app card — pop
                  // null so the caller opens the restricted sheet view.
                  onNo: () => Navigator.of(context).pop(null),
                ),
              ),
            ),
            // `#ev-fs-count` — top:18px; left:22px; 12/600 #fff,
            // text-shadow: 0 1px 4px rgba(0,0,0,0.5); class="en".
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(22, 18, 22, 0),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${_index + 1} of ${_kAlerts.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'NotoSans',
                        shadows: [Shadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(0, 1))],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // `#ev-fs-prev` / `#ev-fs-next` — top:50% translateY(-50%),
            // i.e. centred on the FULL container height, not inset.
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(child: _ArrowButton(onTap: () => _goTo(_index - 1), icon: Icons.chevron_left)),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(child: _ArrowButton(onTap: () => _goTo(_index + 1), icon: Icons.chevron_right)),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.fs-circle-btn` inside `#ev-alert-fullscreen` — 34x34 circle,
/// background rgba(0,0,0,0.4), colour #fff, backdrop-filter: blur(6px),
/// font-size/line-height 18px.
class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Material(
          color: const Color(0x66000000),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(child: Icon(icon, color: Colors.white, size: 18)),
            ),
          ),
        ),
      ),
    );
  }
}

// Full-bleed real cow photo, six-stop dark gradient scrim, bottom-anchored
// title / name-breed-belt / farm-time caption + stacked Yes/No — mirrors
// `imageMode = true` in prototype.html's fsBuildCards() (the only variant
// reachable — the avatar+sparkline layout is dead code there).
class _AlertCard extends StatelessWidget {
  final bool isDark;
  final Color shellBg;
  final _HeatAlertData data;
  final String? decision;
  final VoidCallback onYes, onNo;
  const _AlertCard({
    required this.isDark,
    required this.shellBg,
    required this.data,
    required this.decision,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    final farmParts = data.farm.split(' · ');
    return Stack(
      fit: StackFit.expand,
      children: [
        // background-size: cover; background-position: 50% 18%
        // → Alignment.y = 2 * 0.18 - 1 = -0.64
        Image.asset(
          'assets/images/cows/nandini.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.64),
          errorBuilder: (context, error, stack) => ColoredBox(color: shellBg),
        ),
        // linear-gradient(to bottom, rgba(0,0,0,0.6) 0%, rgba(0,0,0,0.28) 20%,
        //   rgba(0,0,0,0.5) 42%, rgba(0,0,0,0.75) 60%, rgba(0,0,0,0.9) 78%,
        //   rgba(0,0,0,0.97) 100%)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x99000000),
                Color(0x47000000),
                Color(0x80000000),
                Color(0xBF000000),
                Color(0xE6000000),
                Color(0xF7000000),
              ],
              stops: [0.0, 0.20, 0.42, 0.60, 0.78, 1.0],
            ),
          ),
        ),
        // min-height:100%; display:flex; flex-direction:column;
        // padding:14px 24px 40px; box-sizing:border-box; overflow-y:auto
        // — a flex:1 spacer pushes the caption to the bottom.
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 14, 24, 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Heat Cycle Detected',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.46),
                    ),
                    const SizedBox(height: 6),
                    // opacity:0.95 on a #fff element → 0xF2FFFFFF
                    Text(
                      '${data.name} · ${data.breed} · ${farmParts.length > 1 ? farmParts[1] : ''}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xF2FFFFFF)),
                    ),
                    const SizedBox(height: 3),
                    // opacity:0.8 → 0xCCFFFFFF
                    Text(
                      '${farmParts.first} · detected ${data.time}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xCCFFFFFF)),
                    ),
                    // p margin-bottom:14px
                    const SizedBox(height: 14),
                    // .ev-fs-actions { width:100%; margin-top:16px }
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: decision != null
                          // .fs-ack { font-size:13px; font-weight:600;
                          //   margin:6px 0 0; color:var(--greenink) }
                          //   — #flow-root.dark .fs-ack → var(--greendeep)
                          ? Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Acknowledged ✓ — ${data.name} marked ${decision == 'yes' ? 'in heat' : 'not in heat'}',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? VanixColors.greenDeep : VanixColors.greenInk,
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // .ev-fs-yes — width:100%; min-height:52px;
                                // background:var(--greenink); border-radius:26px;
                                // 17px/700 #FFFFFF
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: VanixColors.greenInk,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(double.infinity, 52),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                  ),
                                  onPressed: onYes,
                                  child: const Text('Yes, in heat', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(height: 8),
                                // .ev-fs-no — min-height:48px; margin-top:8px;
                                // background:rgba(255,255,255,0.14);
                                // border:1.5px solid rgba(255,255,255,0.6);
                                // border-radius:24px; 14px/600 #fff
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                                    side: const BorderSide(color: Color(0x99FFFFFF), width: 1.5),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  ),
                                  onPressed: onNo,
                                  child: const Text('No', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
