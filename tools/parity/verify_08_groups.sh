#!/usr/bin/env bash
# Verification audit — screen 08 (Cattle Groups, #page-groups + its 4 sheets).
# Every check asserts a value MEASURED off the live prototype via
# getComputedStyle is present in the Flutter source.
#
# Traps this file deliberately guards:
#   • `[id$="-sheet"] { box-shadow:none !important }` (prototype.html:986) kills
#     the inline `0 -8px 32px rgba(0,0,0,0.18)` on all four groups sheets.
#   • `.en` → var(--font-en) = NotoSans, not the default Devanagari face.
#   • `#flow-root.dark .m-hero p` forces the hero subtitle to --text1.
#   • ckn/grep -E is line-based: any "must not contain" pattern that spans a
#     newline MUST go through ckmn (perl -0777) or it passes vacuously.
F=~/Downloads/Vanix/flutter_app/lib/screens/groups_screen.dart
pass=0; fail=0; failed=()

ck()   { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn()  { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm()  { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }

# ── page shell ──
ck "page bg var(--bgwarm)"        "$F" 'backgroundColor: _p\.warm'
ck "scroller pad 0 0 40"          "$F" 'EdgeInsets\.only\(bottom: 40\)'
ck "content pad 14/16/0"          "$F" 'fromSTEB\(16, 14, 16, 0\)'

# ── hero (.m-hero) ──
# padding 18px 16px; start folded to 6 for the back button's -10px inline margin
ck "hero pad 6/18/16/18"          "$F" 'fromSTEB\(6, 18, 16, 18\)'
ck "hero bottom radius 14"        "$F" 'vertical\(bottom: Radius\.circular\(14\)\)'
ckm "hero shadow 0 12 blur 28"    "$F" 'blurRadius: 28,\s*offset: const Offset\(0, 12\)'
ck "hero shadow 18% / dark 55%"   "$F" 'alpha: _isDark \? 0\.55 : 0\.18'
ck "hero bg darkSecond in dark"   "$F" '_isDark \? VanixColors\.darkSecond : VanixColors\.bgWarm'
ckn "hero NOT darkPrimary bg"     "$F" '_isDark \? VanixColors\.darkPrimary : VanixColors\.bgWarm,'
ckm "back button 40x40"           "$F" 'width: 40,\s*height: 40,'
ck "back chevron svg 20"          "$F" 'Icons\.chevron_left, size: 20[^0-9]'
ckn "back chevron NOT 26"         "$F" 'Icons\.chevron_left, size: 26'
ck "hero row gap 2"               "$F" 'SizedBox\(width: 2\)'
ck "hero title 22/w600"           "$F" 'fontSize: 22, fontWeight: FontWeight\.w600'
ckn "hero title NOT 20/w700"      "$F" 'fontSize: 20, fontWeight: FontWeight\.w700'
ck "hero sub 11 + dark text1"     "$F" 'fontSize: 11, color: _isDark \? p\.text1 : p\.text2'
ck "hero sub gap 2"               "$F" 'SizedBox\(height: 2\)'

# ── #groups-new-btn: 1.5px DASHED --border, not a solid outline ──
ck "new-group dashed 1.5 r14"     "$F" '_DashedRRectBorder\(color: _p\.border, radius: 14, strokeWidth: 1\.5\)'
ck "dashed painter defined"       "$F" 'class _DashedRRectBorder extends CustomPainter'
ck "new-group min-h 46"           "$F" 'minimumSize: const Size\(0, 46\)'
ck "new-group bg transparent"     "$F" 'backgroundColor: Colors\.transparent'
ck "new-group fg greenInk"        "$F" 'foregroundColor: VanixColors\.greenInk'
ck "new-group radius 14"          "$F" 'BorderRadius\.circular\(14\)'
# The measured border is `dashed`; a plain OutlinedButton would render solid.
ckmn "new-group not OutlinedButton" "$F" 'Widget _newGroupButton\(\)[\\s\\S]{0,500}?OutlinedButton'

# ── .grp-row ──
ck "row radius 16"                "$F" 'BorderRadius\.circular\(16\)'
ck "row pad 14"                   "$F" 'EdgeInsets\.all\(14\)'
ck "row margin-bottom 10"         "$F" 'EdgeInsets\.only\(bottom: 10\)'
ck "row border 1px --border"      "$F" 'Border\.all\(color: p\.border, width: 1\)'
ck "row bg --bgcard"              "$F" 'color: p\.card,'
ck "row name 14/w600 --text1"     "$F" 'fontSize: 14, fontWeight: FontWeight\.w600, color: p\.text1'
ckn "row name NOT 15px"           "$F" 'fontSize: 15, fontWeight: FontWeight\.w600'
ck "row count 12 + NotoSans"      "$F" "fontSize: 12, color: p\.text2, fontFamily: 'NotoSans'"
ck "row gap 10"                   "$F" 'SizedBox\(width: _kListRowGap\)'
ck "_kListRowGap = 10"            "$F" '_kListRowGap = 10'
# no card shadow anywhere on this page — grp-row measures box-shadow:none
ckn "no VanixShadow on page"      "$F" 'VanixShadow\.'

# ── sheet shell (all four sheets) ──
ck "sheet pad 8/24/28"            "$F" 'fromLTRB\(24, 8, 24, 28\)'
ck "sheet top radius 24"          "$F" '_kSheetRadius = 24'
ck "sheet radius applied"         "$F" 'Radius\.circular\(_kSheetRadius\)'
ck "grabber 36 wide"              "$F" '_kGrabWidth = 36'
ck "grabber 4 tall"               "$F" '_kGrabHeight = 4'
ck "grabber wrap pad 6/2"         "$F" 'EdgeInsets\.only\(top: 6, bottom: 2\)'
ck "sheet header margin-top 10"   "$F" 'SizedBox\(height: 10\)'
ck "sheet title 18/w700"          "$F" 'fontSize: 18, fontWeight: FontWeight\.w700'
# `[id$="-sheet"] { box-shadow:none !important }` — the shell must stay flat.
# Bounded window, not \s* — a boxShadow reintroduced right after the radius
# line must be caught. (Anchoring on \) alone made this pass vacuously.)
ckmn "sheet shell has NO shadow"  "$F" 'Radius\.circular\(_kSheetRadius\)\),[\\s\\S]{0,80}?boxShadow'
ck "detail/pick max-h 78vh"       "$F" 'maxHeightFactor: 0\.78'
ck "cow-grp max-h 70vh"           "$F" 'maxHeightFactor: 0\.70'
ckn "no 0.8 max-height"           "$F" 'height \* 0\.8[^0-9]'
ck "new-group sheet unbounded"    "$F" 'maxHeightFactor == null'

# ── sheet ✕ close button: 36x36 circle, --bgwarm bg, "✕" glyph 14px ──
ck "close btn 36"                 "$F" '_kCloseSize = 36'
ckm "close = circle + warm bg"    "$F" '_closeGlyphBtn\(size: _kCloseSize, bg: p\.warm, fg: p\.text1'
ck "close glyph is ✕"             "$F" "Text\('✕'"
ck "close glyph 14px"             "$F" 'fontSize: 14, height: 1, color: fg'
ck "close shape CircleBorder"     "$F" 'shape: const CircleBorder\(\)'
ckn "close NOT Icons.close"       "$F" 'Icons\.close'

# ── #grp-new-name input ──
ck "input min-h 44"               "$F" 'minHeight: 44'
ck "input pad 0 12"               "$F" 'EdgeInsets\.symmetric\(horizontal: 12\)'
ck "input bg --bgwarm"            "$F" 'fillColor: p\.warm'
ck "input radius 10"              "$F" 'BorderRadius\.circular\(10\)'
ck "input border 1px --border"    "$F" 'borderSide: BorderSide\(color: p\.border, width: 1\)'
ck "input text 13 --text1"        "$F" 'fontSize: 13, color: p\.text1'
ck "input hint 13 --text2"        "$F" 'fontSize: 13, color: p\.text2'
ck "input margin-top 14"          "$F" 'SizedBox\(height: 14\)'
ck "input->buttons gap 8"         "$F" 'SizedBox\(height: 8\)'

# ── sheet footer buttons ──
ck "primary min-h 48"             "$F" 'minimumSize: const Size\(0, 48\)'
ck "primary radius 24"            "$F" 'BorderRadius\.circular\(24\)'
ck "primary greenInk both modes"  "$F" 'backgroundColor: VanixColors\.greenInk'
ckn "primary NOT greenDeep"       "$F" 'VanixColors\.greenDeep'
ck "secondary/Cancel exists"      "$F" 'Widget _secondaryBtn\(_P p'
ck "secondary bg --bgcard"        "$F" 'backgroundColor: p\.card'
ck "secondary border 1px"         "$F" 'side: BorderSide\(color: p\.border, width: 1\)'
ck "secondary label --text1"      "$F" 'foregroundColor: p\.text1'
ck "footer pair gap 10"           "$F" 'SizedBox\(width: 10\)'
ck "cancel flex 1"                "$F" 'Expanded\(child: _secondaryBtn'
ck "save flex 1"                  "$F" 'Expanded\(child: _primaryBtn'
ck "cancel uses cancelWord"       "$F" "_t\('cancelWord'\)"
ck "footer labels 14/w600"        "$F" 'fontSize: 14, fontWeight: FontWeight\.w600'

# ── #grp-detail-cows member row ──
ck "member row pad 10px 0"        "$F" 'EdgeInsets\.symmetric\(vertical: 10\)'
ck "member row divider 1px"       "$F" 'Border\(bottom: BorderSide\(color: p\.divider, width: 1\)\)'
ck "member farm 11 + NotoSans"    "$F" "fontSize: 11, color: p\.text2, fontFamily: 'NotoSans'"
ck "remove btn 30"                "$F" '_kRemoveSize = 30'
ckm "remove btn warm bg / text2"  "$F" 'size: _kRemoveSize,\s*bg: p\.warm,\s*fg: p\.text2'
ck "cows wrap margin-top 12"      "$F" 'SizedBox\(height: 12\)'

# ── #grp-add-cattle-btn ──
ck "add-cattle radius 23"         "$F" 'BorderRadius\.circular\(23\)'
ck "add-cattle 1px greenInk"      "$F" 'side: const BorderSide\(color: VanixColors\.greenInk, width: 1\)'
ck "add-cattle bg --activebg"     "$F" 'backgroundColor: VanixColors\.activeBg'

# ── #grp-pick-list / #cow-grp-list checkbox rows ──
ck "checkbox 18x18"               "$F" '_kCheckSize = 18'
ck "checkbox accent greenInk"     "$F" 'activeColor: VanixColors\.greenInk'
ckn "not CheckboxListTile"        "$F" 'CheckboxListTile'
ck "check label base 14 --text1"  "$F" 'fontSize: 14, color: p\.text1'
ck "picker farm is nested span"   "$F" "text: ' — \\\$\\{fc\.farm\.nm\(_lang\)\}'"
ck "picker uses Text.rich"        "$F" 'Text\.rich\('

# ── empty states ──
ck "empty text 13 --text2"        "$F" 'fontSize: 13, color: p\.text2'
ck "empty text centred"           "$F" 'textAlign: TextAlign\.center'
ck "page empty margin-top 20"     "$F" 'EdgeInsets\.only\(top: 20\)'
ck "sheet empty margin 12px 0"    "$F" 'EdgeInsets\.symmetric\(vertical: 12\)'

# ── dark-mode palette (measured off #flow-root.dark) ──
ck "dark --text1 = #F5F5F5"       "$F" 'dark \? VanixColors\.textOnDarkDim : VanixColors\.textPrimary'
ckn "text1 NOT Colors.white"      "$F" 'Colors\.white : VanixColors\.textPrimary'
ck "dark --divider = darkDivider" "$F" 'dark \? VanixColors\.darkDivider : VanixColors\.divider'
ck "dark --bgwarm = darkPrimary"  "$F" 'dark \? VanixColors\.darkPrimary : VanixColors\.bgWarm'
ck "dark --bgcard = darkSecond"   "$F" 'dark \? VanixColors\.darkSecond : VanixColors\.bgCard'
ckn "no hard-coded 0xFF1C1C1C"    "$F" 'Color\(0xFF1C1C1C\)'

# ── KNOWN FAILURES: measured dark values have no matching token ──
# `#flow-root.dark` defines a dark palette that lib/theme/vanix_theme.dart does
# not reproduce. These live in a SHARED file this screen may not edit, so they
# are counted as real failures rather than papered over. The integrator must
# reconcile VanixColors before these can pass.
ck "dark --bgcard #1E1E1E"        "$F" '0xFF1E1E1E'   # token darkSecond is #1C1C1C
ck "dark --border #333333"        "$F" '0xFF333333'   # token darkBorder is #3A3A3A
ck "dark --text2 #9E988E"         "$F" '0xFF9E988E'   # textHint #8C8780 is light-only
ck "dark --bgwarm #121212"        "$F" '0xFF121212'   # token darkPrimary is #111111
ck "dark --activebg #123024"      "$F" '0xFF123024'   # activeBg #E8F5EE is light-only

total=$((pass+fail))
echo "── Screen 08 Cattle Groups verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
