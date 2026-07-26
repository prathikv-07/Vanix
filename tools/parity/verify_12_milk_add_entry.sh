#!/usr/bin/env bash
# Verification audit — screen 12 (Add Milk Entry, #s8-page + #s8-warn-backdrop
# + #s7-dup-backdrop). Every check asserts a value MEASURED off the live
# prototype via getComputedStyle (viewport 375x812) is present in the Flutter
# source. Nothing here was read off the markup: inline styles lose to the
# later <style> block, and paint() rewrites the session-pill inline styles.
F=~/Downloads/Vanix/flutter_app/lib/screens/milk_add_entry_screen.dart
pass=0; fail=0; failed=()

ck()   { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn()  { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm()  { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckfail() { fail=$((fail+1)); failed+=("$1"); }

# ── page shell ── #s8-page background:var(--bgwarm) = rgb(242,237,228)
ck "page bg = --bgwarm"           "$F" 'backgroundColor: _warmBg,'
ck "--bgwarm dark = #121212"      "$F" '_warmBg => _isDark \? VanixColors\.darkBgWarm : VanixColors\.bgWarm'
ck "--bgcard dark = #1E1E1E"      "$F" '_cardBg => _isDark \? VanixColors\.darkBgCard : VanixColors\.bgCard'
ck "--border dark = #333333"      "$F" '_border => _isDark \? VanixColors\.darkBorder : VanixColors\.border'
ck "--text1 dark = #F5F5F5"       "$F" '_text1 => _isDark \? VanixColors\.textOnDarkDim : VanixColors\.textPrimary'
ck "--text2 dark = #9E988E"       "$F" '_text2 => _isDark \? VanixColors\.darkTextHint : VanixColors\.textHint'
ck "--warnbg dark token"          "$F" '_warnBg => _isDark \? VanixColors\.darkWarningBg : VanixColors\.warningBg'
# #s8-page box-shadow computes to none; only the confirm card carries a shadow.
ckn "page uses no VanixShadow"    "$F" 'VanixShadow'
# #s8-body padding:14px 24px 0
ck "body pad 14/24/0"             "$F" 'fromSTEB\(24, 14, 24, 0\)'

# ── header row (gap 6px, align-items:center, height 40) ──
ck "header gap 6"                 "$F" 'SizedBox\(width: 6\)'
ckm "back btn 40x40"              "$F" 'width: 40,\s*height: 40,'
ck "back btn circle"              "$F" 'shape: BoxShape\.circle,'
ckm "back btn bg --bgcard"        "$F" 'shape: BoxShape\.circle,\s*color: _cardBg,'
ckm "back btn 1px --border"       "$F" 'color: _cardBg,\s*border: Border\.all\(color: _border, width: 1\)'
# textContent is '‹' at font-size 18px / line-height 18px, colour --text1.
ck "back glyph is U+2039"         "$F" "Text\('‹', style: TextStyle\(fontSize: 18, height: 1, color: _text1\)\)"
ckn "back is NOT a chevron icon"  "$F" 'Icons\.chevron_left'
# #s8-title font:22px/600, line-height:40px → height 40/22.
ck "title 22/w600/lh 40px"        "$F" 'fontSize: 22, fontWeight: FontWeight\.w600, height: 40 / 22, color: _text1'
ck "title swaps on edit"          "$F" "widget\.editing != null \? 'Edit Milk Entry' : 'Add Milk Entry'"
ckn "no trailing delete action"   "$F" 'Icons\.delete_outline'

# ── group labels: 11px/w500, ls .1em @11px = 1.1px, uppercase, --text2, .en ──
ckm "label 11/w500"               "$F" 'fontSize: 11, fontWeight: FontWeight\.w500'
ck "label ls .1em = 1.1px"        "$F" 'letterSpacing: 1\.1,'
ckn "label NOT ls 0.55 (11px .05em)" "$F" 'letterSpacing: 0\.55'
ckn "label NOT ls 1.0"            "$F" 'letterSpacing: 1(\.0+)?[,)]'
ckm "label colour --text2"        "$F" 'letterSpacing: 1\.1, color: _text2'
ck "label class=en → NotoSans"    "$F" "letterSpacing: 1\.1, color: _text2, fontFamily: 'NotoSans'"
ck "label uppercased"             "$F" 'text\.toUpperCase\(\)'
ck "label margin-bottom 6"        "$F" 'double bottom = 6'
ck "LITRES label margin-bottom 10" "$F" "_label\('Litres', bottom: 10\)"

# ── .sel <select> shell (FARM / COW) ──
ck "select height 46"             "$F" 'height: 46,'
# padding:0 32px 0 14px — .sel adds padding-right:32px !important.
ck "select pad start14/end32"     "$F" 'EdgeInsetsDirectional\.only\(start: 14, end: 32\)'
ckm "select bg --bgcard"          "$F" 'color: _cardBg,\s*border: Border\.all\(color: _border, width: 1\),\s*borderRadius: BorderRadius\.circular\(12\)'
ck "select text 15/--text1"       "$F" 'TextStyle\(fontSize: 15, color: _text1\)'
# TRAP: inline `background:var(--bgcard)` resets .sel's data-URI chevron, so
# computed background-image is "none" — the selects render NO chevron at all.
ckmn "select has NO chevron"      "$F" 'Widget _select<T>\(.*?keyboard_arrow_down'
ck "select icon suppressed"       "$F" 'icon: const SizedBox\.shrink\(\)'
ck "select dropdown bg --bgcard"  "$F" 'dropdownColor: _cardBg'

# ── group vertical rhythm (margin-top) ──
ck "FARM group margin-top 18"     "$F" 'EdgeInsets\.only\(top: 18\)'
ck "FARM is [data-owner-only]"    "$F" 'if \(widget\.appState\.isOwner\)'
ck "COW/DATE/SESS margin-top 14"  "$F" 'EdgeInsets\.only\(top: 14\)'
ck "LITRES group margin-top 28"   "$F" 'EdgeInsets\.only\(top: 28\)'

# ── helper lines: 10px, --text2, --font-hi (NOT .en), margin-top 4 ──
ckm "helper 10px --text2"         "$F" 'fontSize: 10, color: _text2'
ckmn "helper is NOT NotoSans"     "$F" "fontSize: 10, color: _text2, fontFamily"
ck "helper margin-top 4"          "$F" 'EdgeInsets\.only\(top: 4\)'
ck "cow helper copy"              "$F" "_helper\('Only CALVED and MILKING cows are listed'\)"
ck "date helper copy"             "$F" "_helper\('Defaults to today · future dates not allowed'\)"
ck "session helper copy"          "$F" "_helper\('Defaults to the current time of day'\)"

# ── cow option text: "Gauri — Jersey — 112" (no "Belt " prefix) ──
ck "cow label name—breed—belt"    "$F" "'\\\$\{c\.name\} — \\\$\{c\.breed\} — \\\$\{c\.belt\}'"
ckn "cow label has no 'Belt '"    "$F" "— Belt "

# ── #s8-date: same 46px shell, padding 0 14px, class=en, dd/mm/yyyy ──
ck "date pad 0 14 (no gutter)"    "$F" 'EdgeInsets\.symmetric\(horizontal: 14\)'
ck "date text 15/--text1/.en"     "$F" "TextStyle\(fontSize: 15, color: _text1, fontFamily: 'NotoSans'\)"
ck "date renders dd/mm/yyyy"      "$F" "padLeft\(2, '0'\)\}/\\\$\{d\.month\.toString\(\)\.padLeft\(2, '0'\)\}/\\\$\{d\.year\}"
# Chrome's calendar-picker-indicator inherits --text1, not --text2.
ck "calendar glyph 16 --text1"    "$F" 'Icons\.calendar_today_outlined, size: 16, color: _text1'
ckn "calendar glyph NOT --text2"  "$F" 'calendar_today_outlined, size: 16, color: _text2'
ck "dateInput.max = today"        "$F" 'lastDate: widget\.today'

# ── #s8-sessions pills ──
ck "session row gap 8"            "$F" 'SizedBox\(width: 8\)'
ck "pill height 42"               "$F" 'height: 42,'
ck "pill radius 21"               "$F" 'BorderRadius\.circular\(21\)'
ck "pill ON fill greenInk"        "$F" 'on \? VanixColors\.greenInk : Colors\.transparent'
ck "pill ON ring greenInk"        "$F" 'color: on \? VanixColors\.greenInk :'
ckm "pill ON 14/w600, OFF w500"   "$F" 'fontSize: 14,\s*fontWeight: on \? FontWeight\.w600 : FontWeight\.w500'
ck "pill ON text #FFFFFF"         "$F" 'color: on \? Colors\.white : offInk'
# paint() blanks the inline color/border-color on the OFF pill, so the UA
# button defaults win and BOTH compute to rgb(0,0,0) — not --text1/--border.
ck "pill OFF ink is #000000"      "$F" 'offInk = _isDark \? VanixColors\.textOnDarkDim : const Color\(0xFF000000\)'
ckn "pill OFF ink is NOT --text1" "$F" 'color: on \? Colors\.white : _text1'
ckn "pill OFF ring is NOT --border only" "$F" 'VanixColors\.greenInk : borderColor'
ck "pill locked opacity 0.4"      "$F" 'opacity: locked \? 0\.4 : 1'
ckm "pill locked pointer-events"  "$F" 'IgnorePointer\(\s*ignoring: locked'
ck "border width 1 on pill"       "$F" ': offInk\), width: 1\)'

# ── session state machine (measured off the prototype JS, not assumed) ──
# var current = h < 16 ? 'Morning' : 'Evening'  — 16, not 17.
ck "default-session cutoff = 16"  "$F" '_currentSessionCutoff = 16'
ckn "cutoff is NOT 17"            "$F" '_currentSessionCutoff = 17'
# locked = sess==='Evening' && isToday() && h < 17 — a separate threshold.
ck "evening lock hour = 17"       "$F" '_eveningLockHour = 17'
ck "SESS_HOURS Morning = 7"       "$F" '_morningHour = 7'
ck "SESS_HOURS Evening = 18"      "$F" '_eveningHour = 18'
ckm "past date → no warning"      "$F" 'if \(!_isToday\) \{\s*setState\(\(\) => _session = target\);\s*return;'
ckm "target==current → no warning" "$F" 'if \(target == _currentSession\) \{\s*setState'
ck "warn 'N hours after/before'"  "$F" "diff > 0 \? '\\\$\{diff\.abs\(\)\} hours after' : '\\\$\{diff\.abs\(\)\} hours before'"
ck "date change resets to Morning" "$F" '_isToday && _hour < _eveningLockHour\) _session = MilkSession\.morning'

# ── LITRES row ──
ck "litres row padding-bottom 10" "$F" 'EdgeInsets\.only\(bottom: 10\)'
ck "litres rule 1.5px #9A948A"    "$F" '_litresRule = Color\(0xFF9A948A\)'
ck "litres rule width 1.5"        "$F" '_litresRule, width: 1\.5'
ck "litres row gap 10"            "$F" 'SizedBox\(width: 10\)'
ck "litres row baseline align"    "$F" 'crossAxisAlignment: CrossAxisAlignment\.baseline'
ck "litres input 32/w700/.en"     "$F" "fontSize: 32, fontWeight: FontWeight\.w700, color: _text1, fontFamily: 'NotoSans'"
ck "litres placeholder '0.0'"     "$F" "hintText: '0\.0'"
ck "placeholder colour #757575"   "$F" '_placeholder = Color\(0xFF757575\)'
ckn "placeholder NOT --text2"     "$F" "hintStyle: TextStyle\(fontSize: 32, fontWeight: FontWeight\.w700, color: _text2"
ck "Ltrs 16/w500/--text2/.en"     "$F" "fontSize: 16, fontWeight: FontWeight\.w500, color: _text2, fontFamily: 'NotoSans'"
ck "litres input no padding"      "$F" 'contentPadding: EdgeInsets\.zero'

# ── .s8-actions (sticky bottom:0) ──
ck "actions bg --bgwarm"          "$F" 'color: _warmBg,\s*$'
ck "actions pad 12/0/16 + 24 gut" "$F" 'fromSTEB\(24, 12, 24, 16\)'
ck "actions gap 10"               "$F" 'SizedBox\(width: 10\)'
ck "buttons height 50"            "$F" 'height: 50,'
ck "buttons radius 25"            "$F" 'BorderRadius\.circular\(25\)'
ckm "cancel transparent + 1px"    "$F" 'backgroundColor: Colors\.transparent,\s*foregroundColor: _text1,\s*padding: EdgeInsets\.zero,\s*side: BorderSide\(color: _border, width: 1\),\s*shape: RoundedRectangleBorder\(borderRadius: BorderRadius\.circular\(25\)\)'
ck "cancel 16/w500"               "$F" "Text\('Cancel', style: TextStyle\(fontSize: 16, fontWeight: FontWeight\.w500\)\)"
ck "save greenInk fill"           "$F" 'backgroundColor: VanixColors\.greenInk,\s*$'
ck "save 16/w600 white"           "$F" "Text\('Save', style: TextStyle\(fontSize: 16, fontWeight: FontWeight\.w600\)\)"
ck "save elevation 0 (no shadow)" "$F" 'elevation: 0,'

# ── confirm card, shared by #s8-warn-backdrop and #s7-dup-backdrop ──
ck "backdrop rgba(0,0,0,0.45)"    "$F" 'barrierColor: const Color\(0x73000000\)'
ck "backdrop padding 28"          "$F" 'insetPadding: const EdgeInsets\.all\(28\)'
ck "card width 100%"              "$F" 'width: double\.infinity,'
ck "card pad 26px 22px"           "$F" 'EdgeInsets\.symmetric\(horizontal: 22, vertical: 26\)'
ck "card radius 20"               "$F" 'BorderRadius\.circular\(20\)'
ckm "card bg --bgcard"            "$F" 'color: _cardBg,\s*borderRadius: BorderRadius\.circular\(20\)'
ck "card shadow 0 24 60 /.30"     "$F" 'BoxShadow\(color: Color\(0x4D000000\), offset: Offset\(0, 24\), blurRadius: 60\)'
ck "card text-align center"       "$F" 'textAlign: TextAlign\.center,'
ckm "warn icon 46x46 circle"      "$F" 'width: 46,\s*height: 46,'
ckm "warn icon bg --warnbg"       "$F" 'shape: BoxShape\.circle,\s*color: _warnBg,'
ck "warn icon 1px --warning"      "$F" 'Border\.all\(color: VanixColors\.warning, width: 1\)'
# The ⚠ span inherits the card's default colour — computed rgb(0,0,0).
ck "glyph ⚠ 20px #000000"         "$F" "Text\('⚠', style: TextStyle\(fontSize: 20, color: Color\(0xFF000000\)\)\)"
ck "h3 17/w600/--text1"           "$F" 'fontSize: 17, fontWeight: FontWeight\.w600, color: _text1'
ck "h3 margin-top 14"             "$F" 'EdgeInsets\.only\(top: 14\)'
ck "body 13/lh1.6/--text2"        "$F" 'fontSize: 13, height: 1\.6, color: _text2'
ck "body margin-top 8"            "$F" 'EdgeInsets\.only\(top: 8\)'
ck "dialog buttons height 48"     "$F" 'height: 48,'
ck "dialog buttons radius 24"     "$F" 'BorderRadius\.circular\(24\)'
ck "confirm 15/w600 greenInk"     "$F" "confirmLabel, style: const TextStyle\(fontSize: 15, fontWeight: FontWeight\.w600\)"
ck "confirm margin-top 20"        "$F" 'EdgeInsets\.only\(top: 20\)'
ck "dialog cancel 15/w500"        "$F" "Text\('Cancel', style: TextStyle\(fontSize: 15, fontWeight: FontWeight\.w500\)\)"
ckm "dialog cancel 1px --border"  "$F" 'side: BorderSide\(color: _border, width: 1\),\s*shape: RoundedRectangleBorder\(borderRadius: BorderRadius\.circular\(24\)\)'

# ── copy + flow, both confirm dialogs ──
ck "warn title copy"              "$F" "title: 'Logging a past session\\?'"
ck "warn body copy"               "$F" "'This is \\\$when the usual \\\$\{target\.label\} milking time\. Are you sure\\?'"
ck "warn confirm = Proceed"       "$F" "confirmLabel: 'Proceed'"
ck "dup title copy"               "$F" "title: 'Entry already exists'"
ck "dup confirm = Yes, continue"  "$F" "confirmLabel: 'Yes, continue'"
ck "dup body copy"                "$F" "already has a \\\$\{_session\.label\} entry today \\(\\\$\{dup\.litres\} L\\)\. \\\$tail"
ck "dup owner tail"               "$F" "'Your entry will be added to it\. Continue\\?'"
ck "dup manager tail"             "$F" "added to it after the Farm Owner approves\. Continue\\?"
# `if (dateInput.value === todayStr)` — the dup scan never looks at past dates.
ckm "dup guard is today-only"     "$F" 'MilkEntry\? _existingDuplicate\(\) \{\s*if \(!_isToday\) return null;'
# litres = Math.round((parseFloat(v)||0) * 10) / 10
ck "litres rounded to 1dp"        "$F" '\(\(double\.tryParse\(_litresCtrl\.text\) \?\? 0\) \* 10\)\.round\(\) / 10'
ckm "dup pending label copy"      "$F" 'pendingLabel: .\+\$litres L \(second entry\)'

# ── genuinely unfixed ──
# Seed data lives in lib/models/milk_models.dart, shared with milk_log_screen.
# The seed lives in the shared lib/models/milk_models.dart, so these were
# logged as unconditional failures by the screen agent. Now corrected against
# the prototype's own dropdown values, so they are real checks.
M=~/Downloads/Vanix/flutter_app/lib/models/milk_models.dart
ck "seed farms match prototype"  "$M" "farms = \\['Ravi Kumar Farm', 'Green Valley Farm'\\]"
ck "seed belt Gauri 112"         "$M" "Cow\\('Gauri', 'Jersey', '112'\\)"
ck "seed belt Lakshmi 47"        "$M" "Cow\\('Lakshmi', 'Ongole', '47'\\)"
ck "seed belt Dhauli 208"        "$M" "Cow\\('Dhauli', 'Gir/Sahiwal', '208'\\)"
# Chrome's UA calendar-picker-indicator has no queryable box; 16px is the
# closest match measured off the 2x screenshot (~10px glyph in a 20px box).
ckfail "date calendar glyph size approximated at 16 (UA shadow-DOM box not measurable)"

total=$((pass+fail))
echo "── Screen 12 Add Milk Entry verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
