import 'package:flutter/material.dart';
import '../i18n/farm_strings.dart';
import '../models/farm_models.dart';
import '../state/app_state.dart';
import '../theme/vanix_theme.dart';

/// Add Cattle — mirrors #page-add-cattle in prototype.html (converted from a
/// bottom sheet to a full page this session): back chevron + "Add Cattle"
/// title (no subtitle), a Cattle Detail / Device Details tab row, a
/// centered 160×160 photo-upload tile at the top of Cattle Detail with all
/// other fields (Name/Type/Breed/Gender) stacked full-width below it in
/// larger (52px) boxes, an Age/Status row, an "Add cow history" link that
/// swaps the same header/body into a Cow History sub-page (reusing the
/// back-button slot rather than opening a new sheet), Device Details
/// (Belt Number/MAC ID), and a Cancel/Save footer.
class AddCattleScreen extends StatefulWidget {
  final AppState appState;
  final FarmModel farm;
  const AddCattleScreen({super.key, required this.appState, required this.farm});

  @override
  State<AddCattleScreen> createState() => _AddCattleScreenState();
}

class _AddCattleScreenState extends State<AddCattleScreen> {
  String _tab = 'cow'; // cow | device
  bool _showHistory = false;
  bool _fillHistory = true;
  int _lactation = 2;

  String get _lang => widget.appState.languageCode;
  bool get _isDark => widget.appState.isDark;

  void _back() {
    if (_showHistory) {
      setState(() => _showHistory = false);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDark ? vanixDarkTheme(languageCode: _lang) : vanixLightTheme(languageCode: _lang);
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: _isDark ? VanixColors.darkSecond : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // header — back chevron (pops the whole page, or just the Cow
              // History sub-view) + title, no subtitle.
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34, height: 34,
                      child: Material(
                        color: VanixColors.bgWarm,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _back,
                          child: Icon(Icons.chevron_left, size: 20, color: textColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(FS.t(_lang, _showHistory ? 'acCowHistory' : 'addCattle'),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
                  ],
                ),
              ),
              // tabs row — hidden while viewing Cow History.
              if (!_showHistory)
                Container(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _isDark ? VanixColors.darkDivider : VanixColors.divider))),
                  child: Row(children: [
                    Expanded(child: _tabBtn('acTabCowDetails', 'cow')),
                    Expanded(child: _tabBtn('acTabDeviceDetails', 'device')),
                  ]),
                ),
              // body
              Expanded(
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
                  children: _showHistory
                      ? _historyFields()
                      : _tab == 'cow'
                          ? _cowFields()
                          : _deviceFields(),
                ),
              ),
              // footer
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: _isDark ? VanixColors.darkSecond : Colors.white,
                  border: Border(top: BorderSide(color: _isDark ? VanixColors.darkBorder : VanixColors.border)),
                ),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        side: BorderSide(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
                        foregroundColor: textColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(FS.t(_lang, 'cancelWord')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: VanixColors.greenInk,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(FS.t(_lang, 'saveWord'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String labelKey, String value) {
    final on = _tab == value;
    return InkWell(
      onTap: () => setState(() => _tab = value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: on ? VanixColors.greenInk : Colors.transparent, width: 3))),
        child: Text(FS.t(_lang, labelKey),
            style: TextStyle(fontSize: 14, fontWeight: on ? FontWeight.w600 : FontWeight.w500, color: on ? VanixColors.greenInk : VanixColors.textHint)),
      ),
    );
  }

  // ── Cattle Detail pane — photo centered top, all fields stacked full
  // width below it in larger (52px) boxes. ──
  List<Widget> _cowFields() => [
        Center(child: _photoUpload()),
        const SizedBox(height: 20),
        _bigInput(FS.t(_lang, 'acCowName')),
        const SizedBox(height: 14),
        _bigSelect('Type', 'Cow'),
        const SizedBox(height: 14),
        _bigSelect(FS.t(_lang, 'breedWord'), FS.t(_lang, 'selectWord')),
        const SizedBox(height: 14),
        _bigSelect(FS.t(_lang, 'genderWord'), FS.t(_lang, 'selectWord')),
        const SizedBox(height: 14),
        _hint('acTypeHint'),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('ageWord'),
                Row(children: [
                  Expanded(child: _select(FS.t(_lang, 'yearsWord'))),
                  const SizedBox(width: 8),
                  Expanded(child: _select(FS.t(_lang, 'monthsWord'))),
                ]),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('cowStatusWord'), _select(FS.t(_lang, 'selectWord'))])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: InkWell(
            onTap: () => setState(() => _showHistory = true),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.add, size: 16, color: VanixColors.greenInk),
              const SizedBox(width: 6),
              Text(FS.t(_lang, 'acAddHistory'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VanixColors.greenInk)),
            ]),
          ),
        ),
      ];

  List<Widget> _deviceFields() => [
        _label('acBeltNo'),
        _input('e.g. 026'),
        _label('acNodeMacId', top: 16),
        _input('A4:C1:38:2B:9F:11'),
      ];

  List<Widget> _historyFields() => [
        _label('acLastHeat'),
        _dateField(),
        _label('acLastInsem', top: 14),
        _dateField(),
        _label('acLastPreg', top: 14),
        _dateField(),
        _label('acLastCalving', top: 14),
        _dateField(),
        _label('acLactationNo', top: 14),
        _stepper(),
        _hint('acLactHint'),
      ];

  Widget _label(String key, {double top = 0, bool big = false}) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 7),
        child: Text(FS.t(_lang, key).toUpperCase(),
            style: TextStyle(fontSize: big ? 12 : 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: VanixColors.textHint)),
      );

  Widget _hint(String key) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(FS.t(_lang, key), style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: VanixColors.textHint)),
      );

  BoxDecoration get _fieldDeco => BoxDecoration(
        color: _isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border),
        borderRadius: BorderRadius.circular(VanixRadius.md),
      );

  Widget _input(String placeholder) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _fieldDeco,
      alignment: AlignmentDirectional.centerStart,
      child: TextField(
        style: TextStyle(fontSize: 15, color: textColor),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: placeholder,
          hintStyle: const TextStyle(color: VanixColors.textHint, fontSize: 15),
        ),
      ),
    );
  }

  // Larger (52px) full-width text field — used for Name on the Cattle
  // Detail pane, matching #ac-name-input's min-height:52px.
  Widget _bigInput(String placeholder) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      decoration: _fieldDeco,
      alignment: AlignmentDirectional.centerStart,
      child: TextField(
        style: TextStyle(fontSize: 15, color: textColor),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: placeholder,
          hintStyle: const TextStyle(color: VanixColors.textHint, fontSize: 15),
        ),
      ),
    );
  }

  // Larger (52px) "Label  Value ▾" selector row — used for Type/Breed/
  // Gender on the Cattle Detail pane, matching #ac-type-btn etc.
  Widget _bigSelect(String label, String value) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      decoration: _fieldDeco,
      child: Row(children: [
        Expanded(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(text: '$label  ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: VanixColors.textHint)),
              TextSpan(text: value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
            ]),
          ),
        ),
        const Icon(Icons.keyboard_arrow_down, size: 16, color: VanixColors.textHint),
      ]),
    );
  }

  Widget _select(String value) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    final isPlaceholder = value == FS.t(_lang, 'selectWord') ||
        value == FS.t(_lang, 'yearsWord') ||
        value == FS.t(_lang, 'monthsWord');
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _fieldDeco,
      child: Row(children: [
        Expanded(child: Text(value, style: TextStyle(fontSize: 15, color: isPlaceholder ? VanixColors.textHint : textColor))),
        const Icon(Icons.keyboard_arrow_down, size: 18, color: VanixColors.textHint),
      ]),
    );
  }

  // Centered 160×160 dashed photo-upload tile — matches #ac-photo.
  Widget _photoUpload() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: _isDark ? VanixColors.darkSecond : VanixColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isDark ? VanixColors.darkBorder : VanixColors.border, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, size: 26, color: VanixColors.textHint),
            const SizedBox(height: 8),
            Text(FS.t(_lang, 'acPhotoHint'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: VanixColors.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _dateField() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _fieldDeco,
      child: Row(children: [
        Expanded(child: Text(FS.t(_lang, 'selectDate'), style: const TextStyle(fontSize: 15, color: VanixColors.textHint))),
        const Icon(Icons.calendar_today_outlined, size: 16, color: VanixColors.textHint),
      ]),
    );
  }

  Widget _stepper() {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return Container(
      height: 48,
      decoration: _fieldDeco,
      child: Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$_lactation', style: TextStyle(fontSize: 15, color: textColor)),
          ),
        ),
        _stepBtn('–', () => setState(() { if (_lactation > 0) _lactation--; })),
        _stepBtn('+', () => setState(() => _lactation++)),
      ]),
    );
  }

  Widget _stepBtn(String glyph, VoidCallback onTap) {
    final textColor = _isDark ? Colors.white : VanixColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: _isDark ? VanixColors.darkBorder : VanixColors.border))),
        child: Text(glyph, style: TextStyle(fontSize: 20, color: textColor)),
      ),
    );
  }
}
