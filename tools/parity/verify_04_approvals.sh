#!/usr/bin/env bash
# Verification audit — screen 04 (Approvals, #page-approvals).
# Every check asserts a value MEASURED off the live prototype via
# getComputedStyle is present in the Flutter source.
F=~/Downloads/Vanix/flutter_app/lib/screens/approvals_screen.dart
pass=0; fail=0; failed=()

ck()   { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn()  { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm()  { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }

# ── page shell ──
ck "page bg bgWarm"             "$F" 'backgroundColor: VanixColors\.bgWarm'
ck "list pad 16/16/16/40"       "$F" 'fromSTEB\(16, 16, 16, 40\)'

# ── hero header ──
ck "hero pad 16/14/16/14"       "$F" 'fromSTEB\(16, 14, 16, 14\)'
ck "hero bottom radius 14"      "$F" 'vertical\(bottom: Radius\.circular\(14\)\)'
ck "hero shadow 0 12 28 @18%"   "$F" 'alpha: 0\.18\), blurRadius: 28, offset: const Offset\(0, 12\)'
ck "back btn 36x36"             "$F" 'width: 36,\s*$|width: 36,'
ck "back btn circle + card bg"  "$F" 'backgroundColor: _cardBg, shape: const CircleBorder\(\)'
ck "back chevron 18"           "$F" 'Icons\.chevron_left, size: 18'
ckn "back chevron NOT 20"       "$F" 'Icons\.chevron_left, size: 20'
ck "hero row gap 10"            "$F" 'SizedBox\(width: 10\)'
ck "title 22/w600"              "$F" 'fontSize: 22, fontWeight: FontWeight\.w600'

# ── filter chips (.s7-bchip) ──
ck "chips pad 16/14"            "$F" 'fromSTEB\(16, 14, 16, 0\)'
ck "chip height 34"             "$F" 'height: 34'
ck "chip radius 17"             "$F" 'BorderRadius\.circular\(17\)'
ck "chip pad-h 16"              "$F" 'symmetric\(horizontal: 16\)'
ck "chip row gap 8"             "$F" 'SizedBox\(width: 8\)'
ck "chip scrolls horizontally"  "$F" 'scrollDirection: Axis\.horizontal'
# .on is a solid --text1 fill with white text, not a green outline.
ck "active chip solid _text1"   "$F" 'color: on \? _text1 : _cardBg,'
ck "active chip border _text1"  "$F" 'Border\.all\(color: on \? _text1 : _border\)'
ck "active label inverse"       "$F" 'color: on \? _cardBg : _text1'
ck "chip 13 w500/w400"          "$F" 'fontSize: 13, fontWeight: on \? FontWeight\.w500 : FontWeight\.w400'
ckn "no greenInk chip outline"  "$F" 'on \? VanixColors\.greenInk : _border'
ckn "no 1.4 active border"      "$F" 'width: on \? 1\.4 : 1'
ck "4 filters"                  "$F" "\\['all', 'pending', 'approved', 'denied'\\]"

# ── section labels ──
ck "section label 11/w700"      "$F" 'fontSize: 11, fontWeight: FontWeight\.w700'
ck "section label ls 0.55"      "$F" 'letterSpacing: 0\.55'
ckn "section label NOT ls 0.6"  "$F" 'letterSpacing: 0\.6[^0-9]'
ck "section label --text2"      "$F" 'letterSpacing: 0\.55, color: VanixColors\.textHint'
ck "section label margin 10"    "$F" 'only\(bottom: 10\)'
ck "history buckets present"    "$F" "'today', 'yesterday', 'thisWeek', 'lastWeek', 'lastMonth'"

# ── approval row (.approval-row) ──
ck "row radius 16"              "$F" 'BorderRadius\.circular\(16\)'
ck "row pad 16/14"              "$F" 'fromSTEB\(16, 14, 16, 14\)'
ck "row gap 8"                  "$F" 'only\(bottom: 8\)'
ck "row uses shared shadow"     "$F" 'VanixShadow\.cardDark : VanixShadow\.card'
ckn "no offsetless shadow"      "$F" 'alpha: 0\.06\), blurRadius: 16\)'
ck "title 14/w600"              "$F" 'fontSize: 14, fontWeight: FontWeight\.w600, color: _text1'
ck "header row top-aligned"     "$F" 'crossAxisAlignment: CrossAxisAlignment\.start'
ck "title/badge gap 10"         "$F" 'SizedBox\(width: 10\)'
ck "sub 12/--text2"             "$F" 'fontSize: 12, color: VanixColors\.textHint'
ck "sub gap 3"                  "$F" 'SizedBox\(height: 3\)'
ck "farm 11/--text2"            "$F" 'fontSize: 11, color: VanixColors\.textHint'
ck "farm Latin face"            "$F" "fontSize: 11, color: VanixColors\.textHint, fontFamily: 'NotoSans'"
ck "farm gap 4"                 "$F" 'SizedBox\(height: 4\)'

# ── status badge ──
ck "badge 10/w700"              "$F" 'fontSize: 10, fontWeight: FontWeight\.w700'
ck "badge ls 0.4"               "$F" 'letterSpacing: 0\.4'
# Anchored so it can't be satisfied by the legitimate 0.55 elsewhere.
ckn "badge NOT ls 0.5"          "$F" 'letterSpacing: 0\.5[^0-9]'
ck "badge uppercased"           "$F" '_t\(key\)\.toUpperCase\(\)'
ck "pending = warning"          "$F" "status == 'pending' \? VanixColors\.warning"
ck "approved = greenInk"        "$F" "'approved' \? VanixColors\.greenInk"
ck "denied = danger"            "$F" 'VanixColors\.danger\)'

# ── action buttons ──
ck "actions gap 10 above"       "$F" 'SizedBox\(height: 10\)'
ck "buttons min-h 40"           "$F" 'minimumSize: const Size\(0, 40\)'
ck "buttons radius 20"          "$F" 'BorderRadius\.circular\(20\)'
ck "buttons gap 8"              "$F" 'SizedBox\(width: 8\)'
ck "both buttons flex 1"        "$F" 'Expanded\(\s*$|Expanded\('
ck "deny outlined + --border"   "$F" 'side: BorderSide\(color: _border\)'
ck "deny label ✕"               "$F" "'✕ \\\$\\{_t\\('denyWord'\\)\\}'"
ck "approve greenInk fill"      "$F" 'backgroundColor: VanixColors\.greenInk'
ck "approve label ✓"            "$F" "'✓ \\\$\\{_t\\('approveWord'\\)\\}'"
ck "buttons 13/w600"            "$F" 'fontWeight: FontWeight\.w600, fontSize: 13'
ck "actions only when pending"  "$F" 'if \(showActions\)'

total=$((pass+fail))
echo "── Screen 04 Approvals verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
