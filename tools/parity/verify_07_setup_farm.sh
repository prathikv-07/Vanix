#!/usr/bin/env bash
# Verification audit — screen 07 (Setup Farm).
#
# NOTE ON TARGET: there is no "#page-setup-farm" in prototype.html. The Farms
# list's "Setup Farm" pill calls openSetupFarm() -> openFmChoose(farmId), which
# shows the #fm-choose-sheet bottom sheet ("Manage farm manager": Assign
# Manager / Invite Manager / Assign to Self); "Invite Manager" then swaps in
# #fm-sheet (name/email/phone + "Confirm & assign"). Every check below asserts a
# value MEASURED off the live prototype via getComputedStyle.
F=~/Downloads/Vanix/flutter_app/lib/screens/setup_farm_screen.dart
pass=0; fail=0; failed=()

ck()   { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn()  { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm()  { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }

# ── overlay shell (#fm-backdrop) ──
# Measured: rgba(0, 0, 0, 0.35). The sheet floats over the farms list, so the
# Scaffold itself must not paint an opaque page background.
ck "backdrop 35% black"          "$F" 'Colors\.black\.withValues\(alpha: 0\.35\)'
ck "scaffold transparent"        "$F" 'backgroundColor: Colors\.transparent'
ckn "not a bgWarm page"          "$F" 'backgroundColor: (isDark \?[^,]*: )?VanixColors\.bgWarm'
ck "sheet pinned to bottom"      "$F" 'bottom: 0,'
ck "backdrop tap dismisses"      "$F" 'onTap: \(\) => Navigator\.of\(context\)\.pop\(\)'

# ── sheet chrome (both #fm-choose-sheet and #fm-sheet) ──
# Measured: padding 8px 24px 28px; border-radius 24px 24px 0 0.
ck "sheet pad 24/8/24/28"        "$F" 'fromSTEB\(24, 8, 24, 28\)'
ck "sheet top radius 24"         "$F" 'BorderRadius\.vertical\(top: Radius\.circular\(24\)\)'
# TRAP: prototype.html:986 `[id$="-sheet"] { box-shadow: none !important }`
# overrides the inline `0 -8px 32px rgba(0,0,0,0.18)`. Measured boxShadow: none.
ckmn "no box-shadow on sheet"    "$F" 'boxShadow'
ckmn "no VanixShadow on sheet"   "$F" 'VanixShadow'
ck "sheet hugs its content"      "$F" 'mainAxisSize: MainAxisSize\.min'

# ── grabber ──
# Measured: wrapper padding 6px 0 2px, centred; pill 36x4, --border, radius 2.
ck "grabber wrap pad 0/6/0/2"    "$F" 'fromSTEB\(0, 6, 0, 2\)'
ck "grabber 36 wide"             "$F" 'width: 36,'
ck "grabber 4 tall"              "$F" 'height: 4,'
ck "grabber radius 2"            "$F" 'BorderRadius\.circular\(2\)'
ck "grabber uses --border"       "$F" 'color: borderCol,'

# ── title row ──
# Measured: margin-top 10px, align-items center; h3 18px/700 in --text1.
ck "title row margin-top 10"     "$F" 'only\(top: 10\)'
ck "title row centred"           "$F" 'crossAxisAlignment: CrossAxisAlignment\.center'
ck "title 18/w700"               "$F" 'fontSize: 18, fontWeight: FontWeight\.w700'
ckn "title NOT 22/w600"          "$F" 'fontSize: 22, fontWeight: FontWeight\.w600'
ck "chooser title manageFarmMgr" "$F" "FS\.t\(_lang, 'manageFarmMgr'\)"
ck "invite title swaps in"       "$F" "_t\('inviteFarmMgrTitle'\)"

# ── close button (#fm-close / #fm-choose-close) ──
# Measured: 36x36, border-radius 50%, background --bgwarm, 14px ✕ in --text1.
ckm "close 36x36"                "$F" 'width: 36,\s*height: 36,'
ck "close is a circle"           "$F" 'shape: const CircleBorder\(\)'
ck "close bg --bgwarm well"      "$F" 'color: wellBg,'
ck "close glyph ✕ at 14"         "$F" "'✕', style: TextStyle\(fontSize: 14"
ckn "no chevron back button"     "$F" 'Icons\.chevron_left'

# ── farm-name line (#fm-choose-farm / #fm-sheet-farm) ──
# Measured: 12px, --text2 rgb(140,135,128); margin 6px 0 14px on the chooser and
# 6px 0 0 on the invite sheet. TRAP: class="en" => Latin face "Noto Sans".
ck "farm line 12/--text2"        "$F" 'fontSize: 12, color: text2'
ck "farm line Latin face"        "$F" "fontSize: 12, color: text2, fontFamily: 'NotoSans'"
ck "farm margin 6 top"           "$F" 'fromSTEB\(0, 6, 0, isInvite \? 0 : 14\)'
ck "--text2 is textHint"         "$F" 'text2 = VanixColors\.textHint'

# ── chooser option buttons ──
# Measured: min-height 48, padding 0 14, radius 14, 1px --border, --bgcard fill,
# 14px/500, text-align start, margin-bottom 8 (last 0).
ck "option min-h 48"             "$F" 'minimumSize: const Size\(double\.infinity, 48\)'
ck "option pad-h 14"             "$F" 'symmetric\(horizontal: 14\)'
ck "option radius 14"            "$F" 'BorderRadius\.circular\(14\)'
ck "option 1px --border side"    "$F" 'side: BorderSide\(color: borderCol\)'
ck "option 14/w500"              "$F" 'fontSize: 14, fontWeight: FontWeight\.w500'
ck "option start-aligned"        "$F" 'AlignmentDirectional\.centerStart'
ck "option gap 8"                "$F" 'SizedBox\(height: 8\)'
ck "three chooser options"       "$F" "_t\('assignMgrWord'\)"
ck "invite option present"       "$F" "_t\('inviteMgrWord'\)"
ck "assign-self option present"  "$F" "_t\('assignSelfWord'\)"

# ── invite form fields (#fm-name / #fm-email / #fm-phone) ──
# Measured: min-height 44, --bgwarm fill, 1px --border, radius 10, padding 0 12,
# font-size 13. First field carries margin-top 14.
ck "field min-h 44"              "$F" 'BoxConstraints\(minHeight: 44\)'
ck "field radius 10"             "$F" 'BorderRadius\.circular\(10\)'
ck "field pad-h 12"              "$F" 'symmetric\(horizontal: 12, vertical: 12\)'
ck "field 13px"                  "$F" 'fontSize: 13, color: text1'
ckm "field filled --bgwarm"      "$F" 'filled: true,\s*fillColor: wellBg'
ck "first field margin-top 14"   "$F" 'SizedBox\(height: 14\)'
ck "email field Latin"           "$F" 'latin: true'
ck "name/email/phone hints"      "$F" "FS\.t\(_lang, 'mgrNamePh'\)"
ck "email placeholder key"       "$F" "FS\.t\(_lang, 'emailPh'\)"
ck "phone placeholder key"       "$F" "FS\.t\(_lang, 'phonePh'\)"
ckn "fields are not borderless"  "$F" 'border: InputBorder\.none'

# ── confirm & assign button (#fm-assign-save) ──
# Measured: min-height 48, margin-top 8, radius 24, --greenink rgb(30,122,82),
# white, 14px/600, no border.
ck "save radius 24"              "$F" 'BorderRadius\.circular\(24\)'
ck "save greenInk fill"          "$F" 'backgroundColor: VanixColors\.greenInk'
ck "save 14/w600 white"          "$F" 'fontSize: 14, fontWeight: FontWeight\.w600, color: Colors\.white'
ck "save flat (no elevation)"    "$F" 'elevation: 0,'
ck "save label confirmAssign"    "$F" "FS\.t\(_lang, 'confirmAssign'\)"
# The prototype has NO "Send invite" / "Done" / "or" divider on this flow.
ckn "no invented Send-invite"    "$F" "sfSendInvite"
ckn "no invented Done button"    "$F" "sfDoneBtn"
ckn "no invented 'or' divider"   "$F" "sfOrWord"
ckn "no invented card titles"    "$F" "sfInviteTitle|sfAssignTitle"

# ── behaviour parity ──
# fm-assign-save: "A farm manager is assigned immediately — there's no
# confirmation step to wait on (unlike a vet invite)". So managerStatus goes
# straight to active and no PENDING chip is ever rendered.
ck "manager assigned at once"    "$F" 'managerInvitePending = false'
ckmn "never sets pending true"   "$F" 'managerInvitePending = true'
ckmn "no PENDING chip"           "$F" "vetPending|warningBg|warningInk"
# sfManagerAssigned(): f.status = 'healthy'
ck "farm flips to healthy"       "$F" 'status = FarmStatus\.healthy'
ck "assign-self is James"        "$F" "'James Redmark', 'जेम्स रेडमार्क'"
ck "chooser -> invite swap"      "$F" '_sheet = _SfSheet\.invite'
ck "only one sheet at a time"    "$F" 'enum _SfSheet \{ choose, invite \}'

# ── genuine gaps still open, counted honestly ──
# These are real parity shortfalls that no passing check above covers. Left as
# failures on purpose so the score reflects the screen, not the harness.
ckfail() { fail=$((fail+1)); failed+=("$1"); }

# openSetupFarm() shows #fm-choose-sheet over the farms list behind a 35%
# scrim. farms_screen.dart pushes an opaque MaterialPageRoute, so the list
# doesn't show through. Needs PageRouteBuilder(opaque:false) / a modal sheet.
ckfail "sheet shows over the farms list (needs non-opaque route)"
# #fm-mgrlist-sheet — "Assign Manager" should open a manager picker. No
# manager roster exists in Flutter state, so it falls through to the invite form.
ckfail "#fm-mgrlist-sheet manager picker not implemented"
# sfManagerAssigned() chains into Add Cattle and then #sf-success-sheet.
ckfail "post-assign Add-Cattle -> #sf-success-sheet chain not implemented"

total=$((pass+fail))
echo "── Screen 07 Setup Farm verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
