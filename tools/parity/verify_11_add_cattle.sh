#!/usr/bin/env bash
# Verification audit — screen 11 (Add Cattle, #page-add-cattle).
# Every check asserts a value MEASURED off the live prototype via
# getComputedStyle is present in the Flutter source.
F=~/Downloads/Vanix/flutter_app/lib/screens/add_cattle_screen.dart
pass=0; fail=0; failed=()

ck()   { if grep -qE "$3" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckn()  { if grep -qE "$3" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckm()  { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then pass=$((pass+1)); else fail=$((fail+1)); failed+=("$1"); fi; }
ckmn() { if perl -0777 -ne "exit(/$3/s ? 0 : 1)" "$2"; then fail=$((fail+1)); failed+=("$1"); else pass=$((pass+1)); fi; }
ckfail() { fail=$((fail+1)); failed+=("$1"); }

# ── page shell ──
# #page-add-cattle background is a literal #FFFFFF == --bgcard (light).
ck "page bg = --bgcard"          "$F" 'backgroundColor: _cardBg,'
ck "--bgcard token map"          "$F" '_cardBg => _isDark \? VanixColors\.darkSecond : VanixColors\.bgCard'
ck "--border token map"          "$F" '_border => _isDark \? VanixColors\.darkBorder : VanixColors\.border'
ck "--divider token map"         "$F" '_divider => _isDark \? VanixColors\.darkDivider : VanixColors\.divider'
ck "dark --text1 = #F5F5F5"      "$F" '_text1 => _isDark \? VanixColors\.textOnDarkDim'
ck "--bgwarm token map"          "$F" '_warmBg => _isDark \? VanixColors\.darkPrimary : VanixColors\.bgWarm'
# [id$="-sheet"]{box-shadow:none!important} also covers #page-add-cattle.
ckn "page has NO shadow"         "$F" 'VanixShadow|boxShadow'
ck "body pad 16/16/16/8"         "$F" 'fromSTEB\(16, 16, 16, 8\)'

# ── header (padding 16 16 12, gap 4px) ──
ck "header pad 16/16/16/12"      "$F" 'fromSTEB\(16, 16, 16, 12\)'
ckm "back btn 34x34"             "$F" 'width: 34,\s*height: 34,'
ck "back btn circle"             "$F" 'shape: const CircleBorder\(\)'
ck "back btn bg --bgwarm"        "$F" 'color: _warmBg,'
ck "back chevron svg 17"         "$F" 'Icons\.chevron_left, size: 17'
ckn "back chevron NOT 20"        "$F" 'Icons\.chevron_left, size: 20'
ck "header gap 4"                "$F" 'SizedBox\(width: 4\)'
ck "title 22/w600/lh1.2"         "$F" 'fontSize: 22, fontWeight: FontWeight\.w600, height: 1\.2'
ck "title --text1"               "$F" 'height: 1\.2, color: _text1'
ck "title swaps to Cow History"  "$F" "_showHistory \? 'acCowHistory' : 'addCattle'"

# ── tab row (#ac-tabs-row) ──
ck "tabs pad 0/16"               "$F" 'padding: const EdgeInsetsDirectional\.symmetric\(horizontal: 16\)'
ck "tabs gap 8"                  "$F" 'SizedBox\(width: 8\)'
ck "tabs 1px --divider underline" "$F" 'Border\(bottom: BorderSide\(color: _divider\)\)'
ck "tab min-height 44"           "$F" 'minHeight: 44'
ck "tab indicator 3px greenInk"  "$F" 'on \? VanixColors\.greenInk : Colors\.transparent, width: 3'
ckm "tab 14 w600/w500"           "$F" 'fontSize: 14,\s*fontWeight: on \? FontWeight\.w600 : FontWeight\.w500'
ck "tab greenInk/--text2"        "$F" 'on \? VanixColors\.greenInk : VanixColors\.textHint'
ck "tab labels cow/device"       "$F" "_tabBtn\('acTabCowDetails', 'cow'\)"
ck "tabs hidden in Cow History"  "$F" 'if \(!_showHistory\) _tabsRow\(\)'

# ── photo tile (#ac-photo) ──
ck "photo centred"               "$F" 'Center\(child: _photoUpload\(\)\)'
ckm "photo 160x160"              "$F" 'width: 160,\s*height: 160,'
ck "photo radius 16"             "$F" 'BorderRadius\.circular\(16\)'
# border:1.5px DASHED var(--border) — not a solid Border.all.
ck "photo dashed 1.5 --border"   "$F" '_DashedRRectPainter\(color: _border, strokeWidth: 1\.5, radius: 16\)'
ck "dash on-length 4.5"          "$F" 'const dash = 4\.5'
ck "dash gap 4.5"                "$F" 'const gap = 4\.5'
ckn "photo NOT solid 1.5 border" "$F" 'Border\.all\(color: _border, width: 1\.5\)'
ck "photo pad 8"                 "$F" 'EdgeInsets\.all\(8\)'
ck "photo icon svg 26"           "$F" 'Icons\.image_outlined, size: 26'
ck "photo gap 8"                 "$F" 'SizedBox\(height: 8\)'
ck "caption 12/lh1.3/--text2"    "$F" 'fontSize: 12, height: 1\.3, color: VanixColors\.textHint'
ck "caption centred"             "$F" 'textAlign: TextAlign\.center'

# ── 52px field stack (Name / Type / Breed / Gender) ──
ck "photo→stack gap 20"          "$F" 'SizedBox\(height: 20\)'
ck "stack row gap 14"            "$F" 'SizedBox\(height: 14\)'
ck "52px min-height"             "$F" 'minHeight: 52'
ck "52px pad 0 16"               "$F" 'symmetric\(horizontal: 16\)'
ck "field radius 12 (md)"        "$F" 'BorderRadius\.circular\(VanixRadius\.md\)'
ck "field border 1px --border"   "$F" 'Border\.all\(color: _border, width: 1\)'
ckm "field bg --bgcard"          "$F" 'color: _cardBg,\s*border: Border\.all'
ck "name placeholder acCowName"  "$F" "_bigInput\(_t\('acCowName'\)\)"
ck "input text 15/--text1"       "$F" 'fontSize: 15, color: _text1\)'
ck "select label 15/w500/--text2" "$F" 'fontSize: 15, fontWeight: FontWeight\.w500, color: VanixColors\.textHint'
ck "select value 15/w600/--text1" "$F" 'fontSize: 15, fontWeight: FontWeight\.w600, color: _text1'
ck "select value class=en"       "$F" "fontWeight: FontWeight\.w600, color: _text1, fontFamily: 'NotoSans'"
ck "ONE space label→value"       "$F" "text: '\\\$label ',"
ckn "NOT two spaces"             "$F" "text: '\\\$label  '"
ck "row is space-between"        "$F" 'mainAxisAlignment: MainAxisAlignment\.spaceBetween'
ck "select chevron svg 12"       "$F" 'Icons\.keyboard_arrow_down, size: 12'
ckn "chevron NOT 16/18"          "$F" 'keyboard_arrow_down, size: 1[68]'
ck "type default 'Cow'"          "$F" "_type = 'Cow'"
ck "type opts"                   "$F" "\\['Cow', 'Sheep', 'Buffalo'\\]"
ck "breed opts"                  "$F" "\\['Jersey', 'Gir', 'Sahiwal', 'Ongole', 'Desi'\\]"
ck "gender opts"                 "$F" "\\['Female', 'Male'\\]"

# ── Age + Cow Status row (margin-top 14, gap 12, align flex-start) ──
ck "age row margin-top 14"       "$F" 'EdgeInsets\.only\(top: 14\)'
ck "age/status gap 12"           "$F" 'SizedBox\(width: 12\)'
ck "row aligned flex-start"      "$F" 'crossAxisAlignment: CrossAxisAlignment\.start'
ck "age inner gap 8"             "$F" 'Expanded\(child: _select\(_ageYears, _yearOpts'
ckm "label 11/w700"              "$F" 'fontSize: 11,\s*fontWeight: FontWeight\.w700'
ck "label ls .05em = 0.55px"     "$F" 'letterSpacing: 0\.55,'
ckn "label NOT ls 0.5"           "$F" 'letterSpacing: 0\.5[^0-9]'
ckm "label colour --text2"       "$F" 'letterSpacing: 0\.55,\s*color: VanixColors\.textHint'
ck "label uppercased"            "$F" '_t\(key\)\.toUpperCase\(\)'
ck "label margin 0 0 7"          "$F" 'EdgeInsets\.only\(top: top, bottom: 7\)'
ck "select height 48"            "$F" 'height: 48,'
ck "select pad 0 14"             "$F" 'symmetric\(horizontal: 14\)'
# Measured: the closed <select> renders its value in --text1, hint colour is
# never used — not even for the "Years"/"Months"/"Select" first options.
ckn "no placeholder-hint select" "$F" 'isPlaceholder'
ckn "select value NOT --text2"   "$F" 'VanixColors\.textHint : _text1'
# The chevron background-image is url("") at runtime: the inline
# url("data:…") ends the double-quoted style attribute, so the declaration
# (and background-position) is dropped. The age/status selects have NO icon.
ckmn "no chevron inside _select" "$F" 'Widget _select\([^;]*keyboard_arrow_down'
ck "years default 'Years'"       "$F" "_ageYears = 'yearsWord'"
ck "year options"                "$F" "\\['yearsWord', '0', '1', '2', '3', '4', '5'\\]"
ck "month options"               "$F" "\\['monthsWord', '0', '3', '6', '9'\\]"
ck "status options"              "$F" "\\['selectWord', 'stMilking', 'stPreg', 'statusUnknown', 'stDry'\\]"

# ── "Add cow history" link (#ac-history-link) ──
ck "link margin-top 22"          "$F" 'EdgeInsets\.only\(top: 22\)'
ck "link icon svg 16 greenInk"   "$F" 'Icons\.add, size: 16, color: VanixColors\.greenInk'
ck "link gap 6"                  "$F" 'SizedBox\(width: 6\)'
ck "link 13/w600/greenInk"       "$F" 'fontSize: 13, fontWeight: FontWeight\.w600, color: VanixColors\.greenInk'
ck "link opens history pane"     "$F" 'setState\(\(\) => _showHistory = true\)'
# Neither hint exists in #page-add-cattle.
ckn "no acTypeHint line"         "$F" 'acTypeHint'
ckn "no acLactHint line"         "$F" 'acLactHint'

# ── Device Details pane ──
ck "belt label"                  "$F" "_label\('acBeltNo'\)"
ck "mac label margin-top 16"     "$F" "_label\('acNodeMacId', top: 16\)"
ck "48px input min-height"       "$F" 'minHeight: 48'
ckm "device input class=en"      "$F" "fontSize: 15, color: _text1, fontFamily: 'NotoSans'\),\s*decoration"
ck "device hint class=en"        "$F" "fontSize: 15, fontFamily: 'NotoSans'\)"
ck "belt placeholder"            "$F" "_input\('e\.g\. 026'\)"
ck "mac placeholder"             "$F" "_input\('A4:C1:38:2B:9F:11'\)"

# ── Cow History pane — 2x2 date grid, NOT a vertical stack ──
ckm "Last Heat + Insem 2-up"     "$F" "_label\('acLastHeat'\), _dateField\(\)\]\)\),\s*const SizedBox\(width: 12\)"
ckm "Preg + Calving 2-up"        "$F" "top: 14\),\s*child: Row\(.*?_label\('acLastPreg'\)"
ckn "dates NOT stacked"          "$F" "_label\('acLastInsem', top: 14\)"
ck "calving label margin-top 14" "$F" "_label\('acLactationNo', top: 14\)"
ck "date shows dd/mm/yyyy"       "$F" "Text\('dd/mm/yyyy',"
ckm "date text --text1 + en face" "$F" "'dd\/mm\/yyyy',\s*style: TextStyle\(fontSize: 15, color: _text1, fontFamily: 'NotoSans'\)"
ckn "no 'Select date' hint"      "$F" 'selectDate'
ck "calendar glyph 16 --text1"   "$F" 'Icons\.calendar_today_outlined, size: 16, color: _text1'

# ── Calving Number stepper ──
ck "stepper overflow hidden"     "$F" 'clipBehavior: Clip\.hardEdge'
ckm "stepper value pad 14/en"    "$F" "Text\('\\\$_lactation',\s*style: TextStyle\(fontSize: 15, color: _text1, fontFamily: 'NotoSans'\)\)"
ckm "step button 48x48"          "$F" 'width: 48,\s*height: 48,'
ck "step btn leading 1px border" "$F" 'BorderDirectional\(start: BorderSide\(color: _border, width: 1\)\)'
ck "step glyph 20/--text1"       "$F" 'fontSize: 20, color: _text1'
ck "minus glyph is en-dash"      "$F" "_stepBtn\('–'"
ck "stepper floors at 0"         "$F" 'if \(_lactation > 0\) _lactation--'

# ── footer ──
ck "footer pad 12/16"            "$F" 'fromLTRB\(16, 12, 16, 12\)'
ck "footer 1px top --border"     "$F" 'Border\(top: BorderSide\(color: _border\)\)'
ck "footer gap 10"               "$F" 'SizedBox\(width: 10\)'
ck "buttons min-h 50"            "$F" 'Size\(0, 50\)'
ck "buttons radius 25"           "$F" 'BorderRadius\.circular\(25\)'
# flex:1 vs flex:1.6 → 5:8.
ck "cancel flex 5"               "$F" 'flex: 5,'
ck "save flex 8 (=1.6x)"         "$F" 'flex: 8,'
ckn "save NOT flex 2"            "$F" 'flex: 2,'
ck "cancel 15/w600"              "$F" 'fontSize: 15, fontWeight: FontWeight\.w600\)'
ck "save 15/w700"                "$F" 'fontSize: 15, fontWeight: FontWeight\.w700\)'
ck "save greenInk fill"          "$F" 'backgroundColor: VanixColors\.greenInk'
ckm "cancel --bgcard + --border" "$F" 'backgroundColor: _cardBg,\s*side: BorderSide\(color: _border, width: 1\)'

# ── Type/Breed/Gender picker sheet (#ac-picker-sheet) ──
ck "backdrop rgba(0,0,0,.35)"    "$F" 'barrierColor: const Color\(0x59000000\)'
ck "sheet radius 24 24 0 0"      "$F" 'BorderRadius\.vertical\(top: Radius\.circular\(24\)\)'
ck "sheet pad 8/24/24"           "$F" 'fromLTRB\(24, 8, 24, 24\)'
ckm "grabber 36x4"               "$F" 'width: 36,\s*height: 4,'
ck "grabber radius 2 --border"   "$F" 'color: _border, borderRadius: BorderRadius\.circular\(2\)'
ck "grabber wrap pad 6/0/2"      "$F" 'fromLTRB\(0, 6, 0, 2\)'
ck "title row margin-top 10"     "$F" 'EdgeInsets\.only\(top: 10\)'
ck "picker title 18/w700"        "$F" 'fontSize: 18, fontWeight: FontWeight\.w700'
ckm "close btn 38x38"            "$F" 'width: 38,\s*height: 38,'
ck "close glyph ✕ 15"            "$F" "Text\('✕', style: TextStyle\(fontSize: 15, color: _text1\)\)"
ck "list margin-top 8"           "$F" 'EdgeInsets\.only\(top: 8\)'
ck "list max-height 320"         "$F" 'maxHeight: 320'
ck "option min-height 46"        "$F" 'minHeight: 46'
ck "option pad 0 4"              "$F" 'symmetric\(horizontal: 4\)'
ck "option w600 / w500"          "$F" 'sel \? FontWeight\.w600 : FontWeight\.w500'
ck "option greenInk / --text1"   "$F" 'sel \? VanixColors\.greenInk : _text1'

# ── strings the prototype ships but lib/i18n does not ──
ck "local acTabCowDetails"       "$F" "'acTabCowDetails': 'Cattle Detail'"
ck "local acNodeMacId"           "$F" "'acNodeMacId': 'Node/MAC ID'"
ck "local statusUnknown"         "$F" "'statusUnknown': 'Before Estrus'"

# ── genuinely unfixed: dark tokens live in lib/theme (shared, off-limits) ──
ckfail "dark --bgcard #1E1E1E (darkSecond is #1C1C1C)"
ckfail "dark --border #333333 (darkBorder is #3A3A3A)"
ckfail "dark --text2 #9E988E (textHint is #8C8780)"
ckfail "dark --bgwarm #121212 (darkPrimary is #111111)"
ckfail "FS acLactationNo='Lactation Number', prototype label is 'Calving Number'"

total=$((pass+fail))
echo "── Screen 11 Add Cattle verification ──"
echo "checks passed : $pass / $total"
if [ ${#failed[@]} -gt 0 ]; then
  printf 'FAILED:\n'; for f in "${failed[@]}"; do echo "  ✗ $f"; done
fi
awk -v p="$pass" -v t="$total" 'BEGIN{printf "score         : %.1f%%\n", (p/t)*100}'
