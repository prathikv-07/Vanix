import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

/// Setup Farm — opened by the "Setup Farm" pill on the Farms list.
///
/// Mirrors the prototype's `openSetupFarm()` flow, which is NOT a full-screen
/// page: it calls `openFmChoose(farmId)`, showing the `#fm-choose-sheet` bottom
/// sheet ("Manage farm manager") with three options — Assign Manager / Invite
/// Manager / Assign to Self. Picking "Invite Manager" swaps in `#fm-sheet`
/// (name / email / phone + "Confirm & assign").
///
/// Measured off the live prototype via getComputedStyle. Two traps captured
/// here: the global `[id$="-sheet"] { box-shadow: none !important }` rule at
/// prototype.html:986 kills the inline `0 -8px 32px rgba(0,0,0,0.18)` on both
/// sheets, and the farm-name line carries `class="en"` so it renders in the
/// Latin face (NotoSans), not the default Devanagari.
class SetupFarmScreen extends StatefulWidget {
  final AppState appState;
  final FarmModel farm;
  const SetupFarmScreen({super.key, required this.appState, required this.farm});

  @override
  State<SetupFarmScreen> createState() => _SetupFarmScreenState();
}

/// Which sheet is showing — the prototype closes the chooser before opening the
/// invite form, so only ever one is visible.
enum _SfSheet { choose, invite }

class _SetupFarmScreenState extends State<SetupFarmScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  _SfSheet _sheet = _SfSheet.choose;

  String get _lang => widget.appState.languageCode;

  /// Labels the prototype defines (`assignMgrWord`, `inviteMgrWord`,
  /// `assignSelfWord`, `inviteFarmMgrTitle`) that have no equivalent key in
  /// lib/i18n/farm_strings.dart yet. Kept local so this screen touches no
  /// shared file; the integrator should migrate these into FS.
  static const Map<String, Map<String, String>> _local = {
    'en': {
      'assignMgrWord': 'Assign Manager',
      'inviteMgrWord': 'Invite Manager',
      'assignSelfWord': 'Assign to Self',
      'inviteFarmMgrTitle': 'Invite Manager',
    },
    'hi': {
      'assignMgrWord': 'प्रबंधक नियुक्त करें',
      'inviteMgrWord': 'प्रबंधक आमंत्रित करें',
      'assignSelfWord': 'खुद को नियुक्त करें',
      'inviteFarmMgrTitle': 'प्रबंधक आमंत्रित करें',
    },
  };

  String _t(String key) => (_local[_lang] ?? _local['hi']!)[key] ?? _local['en']![key] ?? key;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// `sfManagerAssigned()` in the prototype flips the farm to healthy and
  /// re-renders the farms list once a manager lands.
  void _finish(String name, String nameHi) {
    widget.farm.manager = name;
    widget.farm.managerHi = nameHi;
    // The prototype comments this explicitly: a farm manager is assigned
    // immediately — unlike a vet invite there is no pending confirmation step.
    widget.farm.managerInvitePending = false;
    widget.farm.managerInviteEmail = '';
    widget.farm.status = FarmStatus.healthy;
    Navigator.of(context).pop();
  }

  void _assignSelf() => _finish('James Redmark', 'जेम्स रेडमार्क');

  void _confirmAssign() {
    final nm = _nameCtrl.text.trim();
    final em = _emailCtrl.text.trim();
    if (nm.isEmpty && em.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final label = nm.isNotEmpty ? nm : em;
    _finish(label, label);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final isDark = widget.appState.isDark;
        final theme = isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);

        // --text1 / --text2 / --border / --bgcard / --bgwarm
        final text1 = isDark ? VanixColors.textOnDarkDim : VanixColors.textPrimary;
        const text2 = VanixColors.textHint;
        final borderCol = isDark ? VanixColors.darkBorder : VanixColors.border;
        final sheetBg = isDark ? VanixColors.darkSecond : VanixColors.bgCard;
        final wellBg = isDark ? VanixColors.darkPrimary : VanixColors.bgWarm;

        return Theme(
          data: theme,
          child: Scaffold(
            // The sheet floats over the farms list behind a 35% scrim.
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // #fm-backdrop — rgba(0,0,0,0.35)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _sheetShell(
                    bg: sheetBg,
                    borderCol: borderCol,
                    text1: text1,
                    text2: text2,
                    wellBg: wellBg,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shared sheet chrome: padding 8px 24px 28px, radius 24 24 0 0, and — per the
  /// measured `box-shadow: none` — no elevation at all.
  Widget _sheetShell({
    required Color bg,
    required Color borderCol,
    required Color text1,
    required Color text2,
    required Color wellBg,
  }) {
    final isInvite = _sheet == _SfSheet.invite;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 28),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grabber — wrapper padding 6px 0 2px, pill 36x4 in --border, radius 2.
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 6, 0, 2),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderCol,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Title row — margin-top 10, vertically centred.
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      isInvite ? _t('inviteFarmMgrTitle') : FS.t(_lang, 'manageFarmMgr'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: text1),
                    ),
                  ),
                  // #fm-close / #fm-choose-close — 36x36 circle on --bgwarm, 14px ✕.
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Material(
                      color: wellBg,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: Center(
                          child: Text('✕', style: TextStyle(fontSize: 14, color: text1)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Farm name — class="en" so it uses the Latin face; margin 6px 0 14px
            // on the chooser, 6px 0 0 on the invite sheet.
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 6, 0, isInvite ? 0 : 14),
              child: Text(
                widget.farm.nm(_lang),
                style: TextStyle(fontSize: 12, color: text2, fontFamily: 'NotoSans'),
              ),
            ),
            if (isInvite)
              ..._inviteBody(borderCol: borderCol, text1: text1, wellBg: wellBg)
            else
              ..._chooseBody(borderCol: borderCol, text1: text1),
          ],
        ),
      ),
    );
  }

  /// #fm-choose-sheet — three start-aligned option buttons.
  List<Widget> _chooseBody({required Color borderCol, required Color text1}) {
    return [
      _optionButton(
        label: _t('assignMgrWord'),
        borderCol: borderCol,
        text1: text1,
        // The prototype opens #fm-mgrlist-sheet (pick an existing manager).
        // No manager roster exists in Flutter state yet, so this falls through
        // to the invite form rather than dead-ending.
        onTap: () => setState(() => _sheet = _SfSheet.invite),
      ),
      const SizedBox(height: 8),
      _optionButton(
        label: _t('inviteMgrWord'),
        borderCol: borderCol,
        text1: text1,
        onTap: () => setState(() => _sheet = _SfSheet.invite),
      ),
      const SizedBox(height: 8),
      _optionButton(
        label: _t('assignSelfWord'),
        borderCol: borderCol,
        text1: text1,
        onTap: _assignSelf,
      ),
    ];
  }

  /// min-height 48, padding 0 14, radius 14, 1px --border, --bgcard, 14/500,
  /// text-align start.
  Widget _optionButton({
    required String label,
    required Color borderCol,
    required Color text1,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
          alignment: AlignmentDirectional.centerStart,
          side: BorderSide(color: borderCol),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? VanixColors.darkSecond
              : VanixColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: text1,
        ),
        onPressed: onTap,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: text1)),
        ),
      ),
    );
  }

  /// #fm-sheet — name / email / phone then "Confirm & assign".
  List<Widget> _inviteBody({
    required Color borderCol,
    required Color text1,
    required Color wellBg,
  }) {
    return [
      // First input carries margin-top 14.
      const SizedBox(height: 14),
      _field(
        controller: _nameCtrl,
        hint: FS.t(_lang, 'mgrNamePh'),
        borderCol: borderCol,
        text1: text1,
        wellBg: wellBg,
      ),
      const SizedBox(height: 8),
      _field(
        controller: _emailCtrl,
        hint: FS.t(_lang, 'emailPh'),
        borderCol: borderCol,
        text1: text1,
        wellBg: wellBg,
        keyboardType: TextInputType.emailAddress,
        // class="en"
        latin: true,
      ),
      const SizedBox(height: 8),
      _field(
        controller: _phoneCtrl,
        hint: FS.t(_lang, 'phonePh'),
        borderCol: borderCol,
        text1: text1,
        wellBg: wellBg,
        keyboardType: TextInputType.phone,
        latin: true,
      ),
      // Button margin-top 8 on top of the last field's margin-bottom 8.
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: VanixColors.greenInk,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          onPressed: _confirmAssign,
          child: Text(
            FS.t(_lang, 'confirmAssign'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    ];
  }

  /// min-height 44, --bgwarm fill, 1px --border, radius 10, padding 0 12, 13px.
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required Color borderCol,
    required Color text1,
    required Color wellBg,
    TextInputType? keyboardType,
    bool latin = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderCol),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 13, color: text1, fontFamily: latin ? 'NotoSans' : null),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 13,
            color: VanixColors.textHint,
            fontFamily: latin ? 'NotoSans' : null,
          ),
          filled: true,
          fillColor: wellBg,
          isDense: true,
          contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 12),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
        ),
      ),
    );
  }
}
