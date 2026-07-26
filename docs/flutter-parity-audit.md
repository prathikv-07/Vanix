# Flutter ⇄ prototype.html parity audit

Goal: pixel-exact replication of `prototype.html` in `flutter_app/`.

Method: per screen, diff the prototype markup/CSS/JS against the matching Dart
screen, record concrete gaps, fix, verify visually side-by-side, commit.

Servers for side-by-side verification:
- prototype — `python3 -m http.server 8644` from repo root → `/prototype.html`
- flutter — `flutter run -d web-server --web-port 8643` from `flutter_app/`

Status legend: ☐ open · ☑ fixed · ⊘ won't-fix (with reason)

---

## Foundation — design tokens

☑ `lib/theme/vanix_theme.dart` colour tokens match the prototype `:root`
variables exactly (green/greendeep/greenink/dark1/dark2/bgwarm/bgcard/activebg/
text1/text2/border/divider/warning/danger/warnbg/dangerbg). No changes needed.

---

## Screen 01 — Login / OTP  (`lib/screens/login_screen.dart`)

Prototype source: `prototype.html` lines 1002–1101 (status bar, language pill,
persona toggle, video layer, `#s1-sheet` with `#s1-login-panel` +
`#s1-otp-panel`, `#s1-lang-sheet`) and 1355–1365 (splash logo).

### Confirmed gaps

| # | Gap | Prototype | Flutter (before) |
|---|---|---|---|
| 1 | Video scrim far too dark | `rgba(0,0,0,0.22)` | `alpha: 0.45` — comment even claimed "matches the HTML" |
| 2 | Sheet fill alpha | `rgba(255,255,255,0.9)` | `0.94` |
| 3 | Sheet top-border alpha | `rgba(255,255,255,0.7)` | `0.55` |
| 4 | Sheet backdrop blur absent | `backdrop-filter: blur(26px) saturate(1.5)` | no `BackdropFilter` |
| 5 | Consent line missing entirely | "By continuing you are accepting the **Privacy Policy** and **Terms and Conditions**", 11px, centred, tappable underlined links | absent |
| 6 | Field-label weight + colour | `font-weight:500`, `color:var(--text2)` `#8C8780` | `w600`, `textPrimary` `#111111` |
| 7 | Email underline colour | `#9A948A` (`#s1-sheet input` `!important` override beats the inline `#CCCCCC`) | `#CCCCCC` |
| 8 | Email placeholder size/colour | 13px (`#s1-sheet input::placeholder`), `#5F5A52` | 15px, `#4A453E` |
| 9 | Login panel spacing | title→email block `20px`; email→Continue `24px` | `36` and `44` |
| 10 | OTP box metrics | `44×52`, radius `10`, fixed `gap:10px` | `42×52`, radius `12`, `spaceBetween` |
| 11 | OTP box border colour | `#9A948A` (override beats inline `#BBBBBB`) | `#9A948A` ✓ already right |
| 12 | OTP label spacing | `margin:32px 0 12px` | `20` + label pad `10` + `10` |
| 13 | Timer / resend row swapped | timer **left** (`Time Remaining 0:30s`, 13px, `--text1`); resend **right**, hidden until expiry | "Didn't receive OTP?" left always; timer/resend right; 12px, hint colour |
| 14 | Confirm button top margin | `40px` | `30px` |
| 15 | Status bar (9:41 / signal / wifi / battery) | cosmetic bar, 28px + safe-area, inline padding 22px | absent |
| 16 | Sheet had a shadow it shouldn't | `box-shadow: none` — the global `[id$="-sheet"] { box-shadow:none !important }` beats the inline `0 -8px 32px` | `BoxShadow(…blur 32, offset 0,-8)` |
| 17 | Email placeholder colour | UA default `#757575` (the `#5F5A52` override targets the label `<p>`s, not the placeholder) | `#4A453E` |
| 18 | OTP label top gap | `margin-top: 32px` (full gap — the desc above has no bottom margin) | `20` |
| 19 | OTP digits used the wrong face | `font-family: var(--font-en)` → Noto Sans (Latin) | inherited NotoSansDevanagari |
| 20 | OTP `desc` / resend copy colour | `#5F5A52` on-glass override | `--text2` `#8C8780` |
| 21 | Whole screen tinted dark green | video sits over `body { background: var(--bgwarm) }` `#F2EDE4` | dark-green gradient underlay + `#111111` Scaffold |

Items 16–21 were caught by reading `getComputedStyle` off the live prototype
rather than the markup — the inline styles alone are misleading because several
are overridden by later rules. Worth doing for every screen.

### Verified NOT gaps (checked, already correct)

- Persona label copy — prototype JS (line 3943) emits `Owner` / `Manager · 1` /
  `Manager · N`; Flutter matches. (An older revision said "Farmer"; current
  does not.)
- Logo is network-fetched from `mybovine.ai` in the prototype too (lines 1113,
  1295, 1364) — Flutter's `HttpClient` fetch + wordmark fallback is consistent.
  Landing logo width `250px` matches.
- Disabled Confirm fill `#B5B5B5` already in `elevatedButtonTheme`.
- Language sheet exists in both (`showLanguageSheet` ⇄ `#s1-lang-sheet`).

### OPEN — hero video washed out on Flutter **web** (pre-existing)

Not a regression from this pass: the same wash was present before any changes,
just dark instead of light (the Scaffold fill was `#111111`, so it read as a
dark green cast; once that became `#F2EDE4` it read as a light one).

What is established, with evidence:

- The video decodes and plays. `<video>` `readyState: 4`, `duration: 16s`,
  correct asset, and geometry is right — `1444×812 @ x=-534` in a 375-wide
  viewport is exactly `BoxFit.cover` + `object-position: center top`.
- **The video renders correctly.** Hiding the upper `flt-canvas-container`
  inside `flt-glass-pane`'s shadow root shows the hero at full brightness —
  and it is the same bright, hazy sprinkler frame the prototype shows. Video
  and scrim are both fine.
- Something near-opaque and light is painted in the canvas **above** the
  platform view. Flutter's layer split is itself correct:
  `canvas (below) → flt-clip > flt-platform-view-slot (video) → canvas (above)`.
- Ruled out by direct test: the `Scaffold.backgroundColor` (now transparent),
  and the sheet's `BackdropFilter` (now gated to only mount while the sheet is
  on screen). The wash survives both.
- The remaining suspect is the fading fallback `ColoredBox`, which sits in that
  upper canvas — but it should be at `opacity: 0` whenever the platform view
  exists at all, since both are driven by the same `ready` flag. That
  contradiction is unresolved.

Worth knowing before spending more on it: this is very likely specific to the
**web** renderer's platform-view compositing. The real target is iOS/Android,
where video is a normal texture in the single canvas and paint order is
honoured. Next step should be to check a real device/emulator build *first* —
if the hero is correct there, this is a web-preview artifact and not worth
chasing in app code.

### Judgment calls

- **#15 status bar** — this is a prototype-only device mock (fake 9:41 clock,
  fake battery). On a real device the OS draws the true status bar, so
  reproducing it would double-draw. Flagged for the user rather than
  implemented; trivial to add if wanted for demo fidelity.
