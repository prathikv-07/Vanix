#!/usr/bin/env bash
# Verification audit — screen 01 (Login/OTP).
# Each check asserts a value MEASURED from the live prototype via
# getComputedStyle is present in the Flutter source. Repeatable.
F=~/Downloads/Vanix/flutter_app/lib/screens/login_screen.dart
S=~/Downloads/Vanix/flutter_app/lib/i18n/strings.dart
pass=0; fail=0; failed=()

ck() { # ck <label> <file> <regex>
  if grep -qE "$3" "$2"; then pass=$((pass+1));
  else fail=$((fail+1)); failed+=("$1"); fi
}
ckn() { # ckn <label> <file> <regex>  — must NOT match
  if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1");
  else pass=$((pass+1)); fi
}
ckm() { # ckm <label> <file> <regex> — multiline (slurped), for styles split over lines
  if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1));
  else fail=$((fail+1)); failed+=("$1"); fi
}
ckfail() { # ckfail <label> — a known, unfixed parity gap. Counted as a failure.
  fail=$((fail+1)); failed+=("$1")
}

# ── sheet (#s1-sheet) ──
ck "sheet fill 0.90"                "$F" 'withValues\(alpha: 0\.90\)'
ck "sheet border-top 0.70"          "$F" 'alpha: isDark \? 0\.18 : 0\.70'
ck "sheet radius 24"                "$F" 'Radius\.circular\(24\)'
ck "sheet padding 32/40"            "$F" 'fromLTRB\(32, 0, 32, 40\)'
ck "sheet blur sigma 26"            "$F" 'sigmaX: 26, sigmaY: 26'
ck "sheet saturate(1.5) matrix"     "$F" '1\.3935'
ckn "sheet has NO shadow"           "$F" 'boxShadow.*blurRadius: 32'
ck "sheet dark fill 0x9E101010"     "$F" '0x9E101010'

# ── login panel ──
ck "title 22/w600/1.2"              "$F" 'fontSize: 22, fontWeight: FontWeight\.w600, height: 1\.2'
ck "padding-top 26"                 "$F" 'SizedBox\(height: 26\)'
ck "title->email gap 20"            "$F" 'SizedBox\(height: 20\)'
ck "email->continue gap 24"         "$F" 'SizedBox\(height: 24\)'
ckm "label 11/w500/ls1.1"              "$F" 'fontSize: 11,\s+fontWeight: FontWeight\.w500,\s+letterSpacing: 1\.1'
ck "label colour #5F5A52"           "$F" '0xFF5F5A52'
ck "label uppercased"               "$F" 'label\.toUpperCase\(\)'
ck "label margin-bottom 10"         "$F" 'EdgeInsets\.only\(bottom: 10\)'
ck "input 17px"                     "$F" 'fontSize: 17'
ck "underline #9A948A"              "$F" '0xFF9A948A'
ckn "underline NOT #CCCCCC"         "$F" '0xFFCCCCCC'
ck "placeholder 13px"               "$F" 'fontSize: 13, color: isDark'
ck "placeholder #757575"            "$F" '0xFF757575'
ck "input padding-bottom 10"        "$F" 'contentPadding: const EdgeInsets\.only\(bottom: 10\)'
ck "continue 52 tall"               "$F" 'minimumSize: const Size\(0, 52\)'
ck "continue radius 26"             "$F" 'BorderRadius\.circular\(26\)'
ck "continue greenInk"              "$F" 'backgroundColor: VanixColors\.greenInk'
ck "continue 16/w600"               "$F" 'fontSize: 16, fontWeight: FontWeight\.w600'

# ── consent line ──
ck "consent widget exists"          "$F" 'class _ConsentLine'
ck "consent gap 14"                 "$F" 'SizedBox\(height: 14\)'
ck "consent 11px/lh1.5"             "$F" 'fontSize: 11, height: 1\.5'
ck "consent body --text2"           "$F" 'VanixColors\.textHint'
ck "consent centred"                "$F" 'textAlign: TextAlign\.center'
ckm "link w700 + underline"          "$F" 'fontWeight: FontWeight\.w700,\s+decoration: TextDecoration\.underline'
ck "link tappable"                  "$F" 'TapGestureRecognizer'
ck "links open real legal pages"    "$F" 'LegalPage\(appState'
ck "consent strings en"             "$S" "loginConsentPre: 'By continuing you are accepting the'"
ck "rowTerms is 'Terms of Service'" "$S" "rowTerms: 'Terms of Service'"
ck "consent strings hi"             "$S" 'loginConsentPre: .जारी रखकर आप स्वीकार करते हैं'
ck "consent strings bho"            "$S" 'loginConsentPre: .जारी राखे पर रउरा स्वीकार करत बानी'

# ── OTP panel ──
ck "back title 15/w600"             "$F" 'fontSize: 15, fontWeight: FontWeight\.w600'
ck "otp panel top 22"               "$F" 'SizedBox\(height: 22\)'
ck "sent line 14px"                 "$F" 'fontSize: 14, color: textColor'
ck "sent margin-top 28"             "$F" 'EdgeInsets\.only\(top: 28\)'
ck "desc margin-top 6"              "$F" 'EdgeInsets\.only\(top: 6\)'
ck "desc/hint #5F5A52"              "$F" 'hintColor = isDark \? const Color\(0xA6FFFFFF\) : const Color\(0xFF5F5A52\)'
ck "otp label gap 32"               "$F" 'SizedBox\(height: 32\)'
ck "otp box 44 wide"                "$F" 'width: 44'
ck "otp box 52 tall"                "$F" 'height: 52'
ck "otp box radius 10"              "$F" 'BorderRadius\.circular\(10\)'
ck "otp gaps fixed 10"              "$F" 'SizedBox\(width: 10\)'
ck "otp digits 20px"                "$F" 'fontSize: 20'
ck "otp digits Latin face"          "$F" "fontFamily: 'NotoSans'"
ck "otp focus greendeep"            "$F" 'color: VanixColors\.greenDeep, width: 2'
ck "timer 13px"                     "$F" 'fontSize: 13, color: textColor'
ck "timer row gap 16"               "$F" 'SizedBox\(height: 16\)'
ck "timer row space-between"        "$F" 'mainAxisAlignment: MainAxisAlignment\.spaceBetween'
ck "resend only when expired"       "$F" 'if \(showResend\)'
ck "confirm gap 40"                 "$F" 'SizedBox\(height: 40\)'

# ── hero / landing ──
ck "scrim 0.22"                     "$F" 'alpha: 0\.22'
ckn "scrim NOT 0.45"                "$F" 'alpha: 0\.45'
ck "video BoxFit.cover"             "$F" 'fit: BoxFit\.cover'
ck "video top-aligned"              "$F" 'alignment: Alignment\.topCenter'
ck "fallback bgWarm"                "$F" 'ColoredBox\(color: VanixColors\.bgWarm\)'
ck "reveal 2200ms"                  "$F" 'milliseconds: 2200'
ck "logo 250 wide"                  "$F" 'width: 250'
ck "pill height 30"                 "$F" 'height: 30'
ck "pill radius 15"                 "$F" 'BorderRadius\.circular\(15\)'
ck "pill border white .35"          "$F" 'Colors\.white\.withValues\(alpha: 0\.35\)'
ck "pill fill black .28"            "$F" 'Colors\.black\.withValues\(alpha: 0\.28\)'
ck "pill 12/w600"                   "$F" 'fontSize: 12, fontWeight: FontWeight\.w600'
ck "frost gated off-screen"         "$F" 'frosted: !_landing'

# ── genuine parity gaps still open (counted honestly, not grep-able) ──
# The hero reads tinted under the Flutter web renderer's platform-view
# compositing. Video + scrim verified correct in isolation; an unidentified
# light paint in the canvas above still washes it. Real visual difference.
ckfail "hero video renders untinted (web)"

# EXCLUDED, not counted either way: the prototype's cosmetic status bar
# (fake 9:41 / signal / wifi / battery). On a real device the OS draws the
# true status bar, so reproducing it would double-draw. Won't-fix by design.

total=$((pass+fail))
echo "── Screen 01 Login/OTP verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
