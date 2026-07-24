import 'package:flutter/material.dart';
import '../theme/vanix_theme.dart';

/// One heat alert's data for the full-screen carousel.
class _HeatAlertData {
  final String name, breed, farm, time;
  const _HeatAlertData({required this.name, required this.breed, required this.farm, required this.time});
}

/// Multiple cows in heat at once — same card design, different data.
/// Mirrors FS_ALERTS in vanix_screens.html. Only Gauri has a dedicated
/// photo today — reused (`cows/nandini.jpg`) for all three as a
/// placeholder pending real per-cow photos, matching the HTML's
/// `a.photo || 'cows/nandini.jpg'` fallback.
const List<_HeatAlertData> _kAlerts = [
  _HeatAlertData(name: 'Gauri', breed: 'Desi', farm: 'Green Valley Farm · Belt 41', time: '04:30'),
  _HeatAlertData(name: 'Mohini', breed: 'Gir/Sahiwal', farm: 'Sunrise Dairy · Belt 91', time: '05:10'),
  _HeatAlertData(name: 'Dhauli', breed: 'Sahiwal', farm: 'Green Valley Farm · Belt 17', time: '05:45'),
];

/// Full-screen "push notification" heat alert carousel — the entry point of
/// the "View full cycle" walkthrough, styled after a MyGate-style approval
/// screen. Mirrors #ev-alert-fullscreen in vanix_screens.html.
///
/// Swipe or use the arrows to move between cards; actioning one auto-advances
/// to the next unresolved card. Once every card is actioned, pops with the
/// FIRST card's (Gauri's) decision — 'yes' / 'no' — since she is the cow the
/// walkthrough narrates. Dismissing via ✕ or "View in app instead" pops null,
/// and the caller opens the walkthrough in "restricted" detail mode.
class HeatAlertScreen extends StatefulWidget {
  /// Follows the app-wide theme — light farmers get a light alert screen.
  final bool isDark;
  const HeatAlertScreen({super.key, required this.isDark});

  @override
  State<HeatAlertScreen> createState() => _HeatAlertScreenState();
}

class _HeatAlertScreenState extends State<HeatAlertScreen> {
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
    _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: _kAlerts.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _AlertCard(
                isDark: widget.isDark,
                data: _kAlerts[i],
                decision: _decisions[i],
                onYes: () => _action(i, 'yes'),
                // "No" defers the decision to the in-app card — pop
                // null so the caller opens the restricted sheet view.
                onNo: () => Navigator.of(context).pop(null),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(22, 4, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_index + 1} of ${_kAlerts.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))])),
                  _CircleBtn(icon: Icons.close, onTap: () => Navigator.of(context).pop(null)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 0,
            bottom: 60,
            child: Center(child: _ArrowButton(onTap: () => _goTo(_index - 1), icon: Icons.chevron_left)),
          ),
          Positioned(
            right: 10,
            top: 0,
            bottom: 60,
            child: Center(child: _ArrowButton(onTap: () => _goTo(_index + 1), icon: Icons.chevron_right)),
          ),
        ],
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

class _ArrowButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.isDark, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.08), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, color: isDark ? Colors.white : VanixColors.textPrimary, size: 20),
      ),
    );
  }
}

// Full-bleed real cow photo, dark top/bottom gradient scrim, bottom-anchored
// title/name-breed-belt/farm-time caption + stacked Yes/No — mirrors
// `imageMode = true` in prototype.html's FS_ALERTS carousel (the only
// variant reachable — the avatar+graphs layout is dead code there).
class _AlertCard extends StatelessWidget {
  final bool isDark;
  final _HeatAlertData data;
  final String? decision;
  final VoidCallback onYes, onNo;
  const _AlertCard({required this.isDark, required this.data, required this.decision, required this.onYes, required this.onNo});

  @override
  Widget build(BuildContext context) {
    final farmParts = data.farm.split(' · ');
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/cows/nandini.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.6),
          errorBuilder: (context, error, stack) => const ColoredBox(color: Color(0xFF0A2318)),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x99000000), Color(0x47000000), Color(0x00000000),
                Color(0x00000000), Color(0xBF000000), Color(0xF7000000),
              ],
              stops: [0.0, 0.20, 0.42, 0.58, 0.78, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Heat Cycle Detected', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
              const SizedBox(height: 6),
              Text('${data.name} · ${data.breed} · ${farmParts.length > 1 ? farmParts[1] : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 3),
              Text('${farmParts.first} · detected ${data.time}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xCCFFFFFF))),
              const SizedBox(height: 16),
              if (decision != null)
                Text('Acknowledged ✓ — ${data.name} marked ${decision == 'yes' ? 'in heat' : 'not in heat'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenDeep))
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: VanixColors.greenInk, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
                    onPressed: onYes,
                    child: const Text('Yes, in heat', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      side: const BorderSide(color: Color(0x99FFFFFF), width: 1.5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: onNo,
                    child: const Text('No', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

