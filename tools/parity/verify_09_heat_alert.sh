#!/usr/bin/env bash
# Verification audit — screen 09 (Heat Alert, #ev-alert-fullscreen + fsBuildCards()).
# Every check asserts a value MEASURED off the live prototype via
# getComputedStyle is present in the Flutter source.
F=~/Downloads/Vanix/flutter_app/lib/screens/heat_alert_screen.dart
pass=0; fail=0; failed=()

ck()   { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn()  { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm()  { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckfail() { fail=$((fail+1)); failed+=("$1"); }

# ── shell (#ev-alert-fullscreen) ──
# measured background-color: rgb(242,237,228) = --bgwarm
ck "shell bg bgWarm (light)"      "$F" 'VanixColors\.darkPrimary : VanixColors\.bgWarm'
ckn "shell NOT Colors.black"      "$F" 'backgroundColor: Colors\.black'
ck "3 alerts in carousel"         "$F" "_HeatAlertData\(name: 'Dhauli'"
ck "carousel is a PageView"       "$F" 'PageView\.builder'

# ── #ev-fs-strip transition: transform 0.35s cubic-bezier(0.32,0.72,0,1) ──
ck "strip duration 350ms"         "$F" 'Duration\(milliseconds: 350\)'
ck "strip curve cubic .32/.72/0/1" "$F" 'Cubic\(0\.32, 0\.72, 0, 1\)'
ckn "strip NOT easeOutCubic"      "$F" 'Curves\.easeOutCubic'

# ── #ev-fs-count (class="en") ──
ck "count top 18 / left 22"       "$F" 'fromSTEB\(22, 18, 22, 0\)'
ckm "count 12/w600 white"          "$F" 'fontSize: 12,\s*fontWeight: FontWeight\.w600,\s*color: Colors\.white'
ck "count Latin face"             "$F" "fontFamily: 'NotoSans'"
# text-shadow: rgba(0,0,0,0.5) 0 1px 4px  →  0x80000000, not Colors.black54
ck "count shadow 0/1/4 @50%"      "$F" 'Shadow\(color: Color\(0x80000000\), blurRadius: 4, offset: Offset\(0, 1\)\)'
ckn "count shadow NOT black54"    "$F" 'Shadow\(color: Colors\.black54'
ck "count reads 'N of 3'"         "$F" "of \\\$\\{_kAlerts\.length\\}'"

# ── #ev-fs-close is display:none !important (prototype.html:848 id collision) ──
ckn "no ✕ close button"           "$F" 'Icons\.close'
ckn "no 32x32 circle chrome btn"  "$F" 'width: 32,'

# ── #ev-fs-prev / #ev-fs-next (.fs-circle-btn) ──
ckm "arrow 34x34"                  "$F" 'width: 34,\s*height: 34,'
ck "arrow bg rgba(0,0,0,0.4)"     "$F" 'Color\(0x66000000\)'
ck "arrow circle shape"           "$F" 'shape: const CircleBorder\(\)'
# font-size / line-height: 18px
ck "arrow glyph 18"               "$F" 'color: Colors\.white, size: 18'
ckn "arrow glyph NOT 20"          "$F" 'Colors\.white, size: 20'
ck "arrow backdrop blur 6"        "$F" 'ImageFilter\.blur\(sigmaX: 6, sigmaY: 6\)'
ck "arrow left/right inset 10"    "$F" 'left: 10,'
ck "arrow right inset 10"         "$F" 'right: 10,'
# top:50% + translateY(-50%) — centred on the FULL height, not inset 60 at bottom
ckmn "arrows NOT inset bottom 60" "$F" 'left: 10,\s*top: 0,\s*bottom: 60,'
ckm "arrows centred full height"  "$F" 'left: 10,\s*top: 0,\s*bottom: 0,'

# ── photo card background ──
ck "photo cows/nandini.jpg"       "$F" "assets/images/cows/nandini\.jpg"
ck "background-size cover"        "$F" 'fit: BoxFit\.cover'
# background-position: 50% 18%  →  Alignment.y = 2*0.18 - 1 = -0.64
ck "bg-position 18% => y -0.64"   "$F" 'Alignment\(0, -0\.64\)'
ckn "bg-position NOT -0.6"        "$F" 'Alignment\(0, -0\.6\)'

# ── six-stop scrim gradient (measured, not the inline 5-stop guess) ──
ckm "gradient top->bottom"         "$F" 'begin: Alignment\.topCenter,\s*end: Alignment\.bottomCenter'
ck "stop 0%  rgba .6"             "$F" 'Color\(0x99000000\)'
ck "stop 20% rgba .28"            "$F" 'Color\(0x47000000\)'
ck "stop 42% rgba .5"             "$F" 'Color\(0x80000000\)'
ck "stop 60% rgba .75"            "$F" 'Color\(0xBF000000\)'
ck "stop 78% rgba .9"             "$F" 'Color\(0xE6000000\)'
ck "stop 100% rgba .97"           "$F" 'Color\(0xF7000000\)'
ck "gradient stops 0/.2/.42/.6/.78/1" "$F" 'stops: \[0\.0, 0\.20, 0\.42, 0\.60, 0\.78, 1\.0\]'
ckn "no transparent mid stop"     "$F" 'Color\(0x00000000\)'
ckn "no 0.55 stop"                "$F" 'stops: \[0\.0, 0\.18, 0\.55'

# ── card body box (min-height:100%; padding:14px 24px 40px; overflow-y:auto) ──
ck "card pad 24/14/24/40"         "$F" 'fromSTEB\(24, 14, 24, 40\)'
ck "min-height 100% of viewport"  "$F" 'minHeight: constraints\.maxHeight'
ck "overflow-y auto => scrolls"   "$F" 'SingleChildScrollView'
ck "flex:1 spacer => bottom anchor" "$F" 'mainAxisAlignment: MainAxisAlignment\.end'
ckn "no fixed bottom:40 Positioned" "$F" 'bottom: 40,'

# ── caption text ──
ck "title 23/w800 white"          "$F" 'fontSize: 23, fontWeight: FontWeight\.w800, color: Colors\.white'
# letter-spacing:-0.02em at 23px = -0.46px
ck "title ls -0.46"               "$F" 'letterSpacing: -0\.46'
ckn "title NOT ls -0.2"           "$F" 'letterSpacing: -0\.2[^0-9]'
ck "title gap 6"                  "$F" 'SizedBox\(height: 6\)'
# opacity:0.95 on #fff → 0xF2FFFFFF
ck "name line 14/w600 @95%"       "$F" 'fontSize: 14, fontWeight: FontWeight\.w600, color: Color\(0xF2FFFFFF\)'
ckn "name line NOT solid white"   "$F" 'FontWeight\.w600, color: Colors\.white\)'
ck "name gap 3"                   "$F" 'SizedBox\(height: 3\)'
# opacity:0.8 on #fff → 0xCCFFFFFF
ck "farm line 12/w500 @80%"       "$F" 'fontSize: 12, fontWeight: FontWeight\.w500, color: Color\(0xCCFFFFFF\)'
ck "farm p margin-bottom 14"      "$F" 'SizedBox\(height: 14\)'
# .ev-fs-actions margin-top:16 — total farm→actions gap is 14 + 16 = 30
ck "actions margin-top 16"        "$F" 'EdgeInsets\.only\(top: 16\)'
ckmn "no bare 16 gap before CTAs" "$F" "detected \\\$\\{data\.time\\}'.*?SizedBox\(height: 16\)"

# ── .ev-fs-yes ──
ck "yes greenInk fill"            "$F" 'backgroundColor: VanixColors\.greenInk'
ck "yes min-height 52"            "$F" 'minimumSize: const Size\(double\.infinity, 52\)'
ck "yes radius 26"                "$F" 'BorderRadius\.circular\(26\)'
ck "yes 17/w700"                  "$F" 'fontSize: 17, fontWeight: FontWeight\.w700'
ck "yes border:none => elev 0"    "$F" 'elevation: 0,'

# ── .ev-fs-no ──
ck "no bg white @14%"             "$F" 'Colors\.white\.withValues\(alpha: 0\.14\)'
ck "no border 1.5 white @60%"     "$F" 'BorderSide\(color: Color\(0x99FFFFFF\), width: 1\.5\)'
ck "no min-height 48"             "$F" 'minimumSize: const Size\(double\.infinity, 48\)'
ck "no radius 24"                 "$F" 'BorderRadius\.circular\(24\)'
ck "no 14/w600"                   "$F" 'fontSize: 14, fontWeight: FontWeight\.w600\)'
ck "no gap 8 below yes"           "$F" 'SizedBox\(height: 8\)'
ck "buttons width:100%"           "$F" 'CrossAxisAlignment\.stretch'
ckmn "no zero-width padding hack" "$F" 'height: 52,\s*child: ElevatedButton'

# ── .fs-ack ──
ckm "ack 13/w600"                  "$F" 'fontSize: 13,\s*fontWeight: FontWeight\.w600,'
# .fs-ack { color:var(--greenink) } / #flow-root.dark .fs-ack { --greendeep }
ck "ack greenInk light/Deep dark" "$F" 'isDark \? VanixColors\.greenDeep : VanixColors\.greenInk'
ckn "ack NOT always greenDeep"    "$F" 'color: VanixColors\.greenDeep\)'
ck "ack margin-top 6"             "$F" 'EdgeInsets\.only\(top: 6\)'
ck "ack text-align start"         "$F" 'textAlign: TextAlign\.start'
ck "ack wording"                  "$F" "Acknowledged ✓ — \\\$\\{data\.name\\} marked"

# ── behaviour measured off fsAction() / fsGo() ──
ck "auto-advance after 500ms"     "$F" 'Duration\(milliseconds: 500\)'
ck "advance to next unresolved"   "$F" '_decisions\.indexWhere\(\(d\) => d == null\)'
ck "final pop uses card 0"        "$F" 'pop\(_decisions\[0\]\)'
ck "No pops null (restricted)"    "$F" 'onNo: \(\) => Navigator\.of\(context\)\.pop\(null\)'
ck "fsGo clamps index"            "$F" 'if \(i < 0 \|\| i >= _kAlerts\.length\) return;'

# ── genuinely unfixed ──
# #flow-root.dark #ev-alert-fullscreen is a linear-gradient(180deg, --dark1 0%,
# #1C1C1C 100%), not a flat fill. Flat darkPrimary used instead (invisible
# behind the photo, but not a match). Deferred to the dark pass.
ckfail "dark shell gradient dark1->#1C1C1C (flat fill used)"

total=$((pass+fail))
echo "── Screen 09 Heat Alert verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
