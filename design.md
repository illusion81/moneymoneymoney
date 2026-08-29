# Hivewise — Flutter Design Specification

Source of truth: `design_handoff_hivewise/README.md` (values cross-checked against `Beehive Finance App.dc.html`; prototype wins only for per-keyframe animation details and literals the README omits — every such substitution is flagged). All sizes are CSS px in the handoff; treat them 1:1 as Flutter logical pixels. The prototype was designed in a 402×874 viewport (iPhone-class), so horizontal metrics assume a ~402 dp wide canvas; use flexible layouts, not fixed widths, except where a value is explicitly intrinsic (icon sizes, jar pixels).

Fidelity: **high**. Colors, type, spacing, radii, shadows, copy, and motion are final intent.

Global law: **no borders anywhere. Depth comes only from shadows.** See §4.7 for the one exception class (illustration strokes).

---

## 1. Color scheme

### 1.1 Canonical tokens

Where the README lists several hexes per token, the **canonical** value below is the one to put in the `ThemeExtension`/const palette; alternates are listed with their exact usage context so nothing is lost. All ARGB ints are `Color(0xAARRGGBB)`.

| Token | Canonical hex | Flutter | Alternates (use only where noted) | Intended use |
|---|---|---|---|---|
| `ink` | `#33251A` | `Color(0xFF33251A)` | — | Primary text; dark surfaces (banners, ink buttons, generating card); active nav label |
| `inkMuted` | `rgba(51,37,26,.55)` | `Color(0x8C33251A)` | `.5` = `0x8033251A` (market inactive-tab text, blurb, sub-lines); `.6` = `0x9933251A` (pot legend amounts, regenerate label) | Secondary text |
| `inkFaint` | `rgba(51,37,26,.42)` | `Color(0x6B33251A)` | `.4` = `0x6633251A` (settings group headings, "press for the full flow"); `.45` = `0x7333251A` (task subs, member status, report meta); `.38` = `0x6133251A` (sheet month labels) | Labels, captions |
| `canvas` | `#FBF7EF` | `Color(0xFFFBF7EF)` | — | App background (the "page" behind cards); sheet fill; hexagon knockout colour in the Comb tab icon |
| `surface` | `#FFFFFF` | `Color(0xFFFFFFFF)` | `#F7F2E5` (done-task row background, prototype); `#FFFCF3` (jar body fill) | Cards |
| `surfaceWarm` | `#F8F3E6` | `Color(0xFFF8F3E6)` | — | Inset panels, pot caption panel, selected legend row |
| `surfaceSunk` | `#F1EADB` | `Color(0xFFF1EADB)` | `#F3EDDF` (progress tracks, "quiet" streak tag, Amex logo tile); `#EFE7D6` (sheet bar/breakdown tracks; owned/unaffordable price buttons — README calls these "surfaceSunk", prototype paints this slightly warmer hex) | Track fills, inactive chips, progress tracks |
| `honey` | `#F5B322` | `Color(0xFFF5B322)` | — | Primary accent; income; progress fills; toggle-on track; done-task tick fill; sparkline last bar |
| `honeyLight` | `#FFD972` | `Color(0xFFFFD972)` | `#FFDD8A` (cash jar layer, sparkline 2nd-last bar, refunds sheet row); `#FFE39B` | Gradient tops |
| `honeyDeep` | `#E08C1B` | `Color(0xFFE08C1B)` | `#E8A11B` (income-cell gradient bottom, hive label sub-gradient) | Gradient bottoms; active tab-bar icon dots |
| `honeyText` | `#B8801A` | `Color(0xFFB8801A)` | `#8A5E12` (text inside honeyTint pills/chips: streak count, tag chips, accepted-suggestion button, report kicker) | Amber text on light backgrounds |
| `honeyTint` | `#FFF3D6` | `Color(0xFFFFF3D6)` | `#FDE7B4` (report summary gradient bottom, with honeyTint as top) | Amber pill/chip backgrounds |
| `brown` | `#6E4826` | `Color(0xFF6E4826)` | `#A2764C` (subscriptions sheet row fill, social-hexagon gradient top) | Expense; hive/social category |
| `brownLight` | `#8B6039` | `Color(0xFF8B6039)` | — | Expense gradient top; subscriptions fill |
| `brownDeep` | `#553519` | `Color(0xFF553519)` | `#7A5230` (jar rim/body stroke and settings-gear glyph — README's jar spec names this hex explicitly); `#5A3A20` (hive entrance, stick-figure shapes in art tiles) | Expense gradient bottom |
| `teal` | `#5C8C86` | `Color(0xFF5C8C86)` | light `#7FB0A8` (`Color(0xFF7FB0A8)`), deep `#3F6E68` (`Color(0xFF3F6E68)`) — used in sparkline-style art-tile gradients | Invested / habit category |
| `clay` | `#C4634C` | `Color(0xFFC4634C)` | light `#D98572`, deep `#AE5641` (both used as the two stripes of the debt hatch and badge gradients); sparkline steps `#F0DCD6` → `#E8C3B9` → `#D4806A` → `#C4634C` | Debt / drift warnings; debt amounts |
| `money` | `#2E6B4F` on `#EAF7EF` | `Color(0xFF2E6B4F)` / `Color(0xFFEAF7EF)` | — | Real-money price buttons **only** — never used for honey purchases |
| `positive` | `#7A9B7E` | `Color(0xFF7A9B7E)` | — | "syncing" status text in Settings |
| `cream` (on-dark text) | `#F6EFE0` | `Color(0xFFF6EFE0)` | 80% = `0xCCF6EFE0`; 65% = `0xA6F6EFE0` (swarm note); 50% = `0x80F6EFE0`; 30% = `0x4DF6EFE0` (dimmed gen step); 25% = `0x40F6EFE0` (empty streak hexagon) | All text/icons on ink/dark-gradient surfaces. (README lists this hex under `canvasOuter` — the outer page backdrop `#EFE9DC`/radial `#F6EFE0→#EAE2D2` is **prototype chrome, do not port**) |
| `darkGradientEnd` | `#4C3824` | `Color(0xFF4C3824)` | — | Gradient partner of `ink` (96–150°) on streak banner, swarm-goal card |
| Bee literals | body `#4A3520`, stripe `#FFD972`, wing `rgba(255,255,255,.8)` = `0xCCFFFFFF` (in); body `#F0DFC4`, stripe `#6E4826`, wing `rgba(255,255,255,.55)` = `0x8CFFFFFF` (out) | | | Transaction bees on the home hive |
| Bank logo tiles | Chase `#E9EFF6`/`#3B5C86`, Ally `#EAF0EE`/`#5C8C86`, Amex `#F3EDDF`/`#6E4826` | | | 32 dp rounded tiles, initial in JBM 700 12 |

### 1.2 Category colour map (Comb + shared)

| Category | Colour | Badge gradient (158°, from prototype) | Glyph/label on badge |
|---|---|---|---|
| Saving | honey | `#FFD972 → #F0A81A` | ink; label at 60% ink `0x9933251A` |
| Debt | clay | `#D98572 → #C4634C` | `#FFF6F2` |
| Habit | teal | `#7FB0A8 → #5C8C86` | `#F4FAF8` |
| Hive (social) | brown | `#A2764C → #6E4826` | `#FBF3E6` |

Locked badge cell: surfaceSunk `#F1EADB`, glyph `·` at 30% ink `0x4D33251A`, label "Locked" at 35% ink `0x5933251A`.

### 1.3 Suggested `ColorScheme` wiring

`primary` = honey `0xFFF5B322`; `secondary` = brown `0xFF6E4826`; `tertiary` = teal `0xFF5C8C86`; `surface`/`onSurface` = `0xFFFFFFFF`/`0xFF33251A`; `error` = clay `0xFFC4634C`; `onSurfaceVariant` = inkMuted `0x8C33251A`; scaffold background = canvas `0xFFFBF7EF`. Everything beyond these slots lives in one `ThemeExtension` (HiveColors) keyed by the token names in §1.1 — widgets must reference tokens, never raw hex, except the per-context alternates above.

---

## 2. Typography

Three families, all via **google_fonts**: Caveat (`GoogleFonts.caveat`, weight 700 only), Plus Jakarta Sans (`GoogleFonts.plusJakartaSans`, weights 500/600/700/800), JetBrains Mono (`GoogleFonts.jetBrainsMono`, weights 500/700).

Rules: Caveat line-height is **1.12 minimum** (1.0 clips descenders) — set `height: 1.12` in the TextStyle and add 2 dp bottom padding on titles as the prototype does. Flutter `letterSpacing` is px, so the em values below are pre-converted (px = em × size). Body copy wraps naturally — no forced single lines (CSS `text-wrap: pretty` → default Flutter soft wrap; keep `maxLines: null` except where a chip is explicitly nowrap).

| Role | Font | Size (px) | Weight | Height (lh) | Spacing | Maps to TextTheme slot | Seen at |
|---|---|---|---|---|---|---|---|
| Screen title | Caveat | 36 | 700 | 1.12 | 0 | `displaySmall` override | "What the hive noticed", "Trade your honey", "Sam's comb", "Sam's five", "Your setup" |
| Greeting | Caveat | 34 | 700 | 1.12 | 0 | `displaySmall` variant | Home "Morning, Sam" |
| Card title | Caveat | 24–25 | 700 | 1.12 | 0 | `headlineSmall` override (24) | "Sam's honey pot" 24; "Today, in your words" 25 |
| Level name | Caveat | 21 | 700 | 1.12 | 0 | `titleLarge` | (home level display) |
| Uppercase label — micro | PJS | 9.5 | 800 | ~1.2 | .11em → 1.05 px, `textStyle: allCaps` | `labelSmall`-style custom | INCOME / EXPENSE kickers |
| Uppercase label — group | PJS | 10.5 | 700 | ~1.2 | .1em → 1.05 px, allCaps | `overline` override | Settings groups, "THE SHORT OF IT", sheet kicker |
| Uppercase label — stat | PJS | 10.5–11.5 | 600–700 | ~1.2 | .06em → 0.63–0.69 px, allCaps | `overline` variant | "Tuesday, 12 Aug" (11.5/600), Saved/Debt burn (10.5/700) |
| Title / button | PJS | 13–13.5 | 700 | ~1.3 | −.01em → −0.13 px on titles | `titleMedium` / `labelLarge` | Row titles, "Where it went", buttons (market tabs 11.5/700, task title 13.5/700) |
| Body | PJS | 12–12.5 | 600 | 1.45–1.5 | 0 (−.01em on 13.5 report body) | `bodyMedium` | Report body 13.5/600 lh1.5; suggestion text 12.5/600 lh1.45; flash 12/600 |
| Secondary | PJS | 11–11.5 | 500 | 1.4–1.45 | 0 | `bodySmall` | Descriptions, subs, notes, captions |
| Figure — hero | JBM | 22–26 | 700 | ~1.1 | −.03em (24 px → −0.72; 26 px → −0.78) | `headlineMedium` custom (monospace!) | Income/expense figures 24; sheet amount 26; stat figures 19; pot total 15 |
| Figure — pill | JBM | 11.5–12.5 | 700 | ~1.1 | 0 | `labelLarge` custom | Streak "18" 12.5, honey balance 12.5, swarm "28/35" 12 |
| Figure — meta | JBM | 9.5–11 | 500 | ~1.15–1.4 | .04em (0.38 px) on "press for the full flow" 9.5; .01em (0.11 px) on report meta 11 | `labelSmall` custom | Jar sub 9.5; meta lines 10.5–11; footer "level 7 · 66% spent…" 10.5 |
| Tag chip | JBM | 8.5–9 | 700 (tags) / 500 (streak tags) | ~1.1 | .06em → 0.51 px on market tags | custom | "POPULAR/NEW/BEST", "31d/quiet/you" |

Weight discipline: PJS **800 only for the uppercase micro-labels**; 600/700/500 carry everything else. Never let Material's default Roboto leak — wire all three faces through the theme (`textTheme: ...` built from `GoogleFonts.xTextStyle`), and set `fontFamilyFallback` sensibly for digits if needed.

---

## 3. Spacing

- **Screen padding:** 18 px horizontal · 62 px top (clears status bar; use `EdgeInsets.fromLTRB(18, 62, 18, 100)` on the scroll body, or `SafeArea` + 18/26 once the real status bar replaces the fake) · **100 px bottom** (clearance for the floating tab bar).
- **Vertical rhythm between blocks:** 14 px (Report, Market, Hive-mates column gaps) or 16 px (Home, Comb, Settings column gaps). Pick per-screen to match §per-screen list above; default new screens to 16.
- **Inside cards:** 9–14 px between rows; card internal padding 13–17 px (pot card 16, market rows 14, task rows 13/14, settings rows 13/14, summary 17, generating card 22/18).
- **Inline gaps:** 2 px label→figure stacks; 3 px header column gaps; 4 px column gaps; 5 px hive/badge cell gaps (home cells: 1 px gap + −15 px row overlap); 6 px chip gaps and button icon↔label; 7–8 px legend rows; 9–10 px icon↔text and pill↔pill; 12 px row item gaps and tick↔text; 13 px art-tile↔text; 16 px jar↔legend.

Suggested scale tokens: `gap.xs 4 · gap.sm 8 · gap.md 12 · gap.lg 16 · gap.xl 22`, with the named 9/10/13/14 values kept as literals where the design is pixel-precise (they are).

---

## 4. Component styles

### 4.1 Radii

| Component | Radius |
|---|---|
| Cards | 16–20 (pot card 20; market item 18; report summary/stat cards 18/16; suggestion 16; settings row 15; task row 15; friends/invite 16; comb next-badge 18; member rows 16) |
| Sheet | 26 on the two top corners only (`BorderRadius.vertical(top: Radius.circular(26))`) |
| Pills / buttons | 10–11 (streak pill 11, settings button 11, price button 11, market tab 11, small action pills 10, "Add as task" 10); wide CTAs 14 (regenerate 46 px tall, sheet footer 46 px tall) |
| Chips (tag, legend text-chip) | 5 (market tag, streak tag); category chip 11 |
| Progress bars | fully rounded: height 7–8 → radius 4–5 |
| Caption / flash / inset panels | 12 (caption panel, flash card, sheet rows), streak banner 13, segmented track 12 with 9 inner |
| Logo tiles | 9 |

### 4.2 Shadow recipes (drop straight into `BoxShadow`)

Format: CSS in handoff → Flutter. Multi-layer shadows are the array in order.

| Name | CSS (handoff) | Flutter |
|---|---|---|
| **card** (default) | `0 2px 4px rgba(51,37,26,.05), 0 14px 30px -12px rgba(51,37,26,.3)` | `[BoxShadow(color: Color(0x0D33251A), offset: Offset(0,2), blurRadius: 4), BoxShadow(color: Color(0x4D33251A), offset: Offset(0,14), blurRadius: 30, spreadRadius: -12)]` |
| **owned / accepted card** | `0 1px 2px rgba(224,140,27,.3), 0 8px 20px -10px rgba(224,140,27,.45)` | `[BoxShadow(color: Color(0x4DE08C1B), offset: Offset(0,1), blurRadius: 2), BoxShadow(color: Color(0x73E08C1B), offset: Offset(0,8), blurRadius: 20, spreadRadius: -10)]` (prototype variant on accepted suggestions: `.28/.4` at `8px 18px -10px` — use the README canonical) |
| **completed-task card** | `0 1px 3px rgba(51,37,26,.07)` | `[BoxShadow(color: Color(0x1233251A), offset: Offset(0,1), blurRadius: 3)]` — done rows also drop to `#F7F2E5` bg (not-done task rows use the standard card shadow; prototype paints `0 14px 28px -12px .28`, treat as card) |
| **pill (honey)** | `0 2px 5px rgba(224,140,27,.28)` | `[BoxShadow(color: Color(0x47E08C1B), offset: Offset(0,2), blurRadius: 5)]` — streak pill, balance pill |
| **pill (neutral control)** | `0 2px 6px rgba(51,37,26,.14)` | `[BoxShadow(color: Color(0x2433251A), offset: Offset(0,2), blurRadius: 6)]` — settings gear button |
| **tab bar (lift)** | `0 -8px 24px -10px rgba(51,37,26,.25)` | `[BoxShadow(color: Color(0x4033251A), offset: Offset(0,-8), blurRadius: 24, spreadRadius: -10)]` — negative offset = shadow casts **up**; no top hairline |
| **sheet** | `0 -8px 40px rgba(51,37,26,.25)` | `[BoxShadow(color: Color(0x4033251A), offset: Offset(0,-8), blurRadius: 40)]` |
| **market tab — active** | `0 2px 6px -1px rgba(51,37,26,.35)` | `[BoxShadow(color: Color(0x5933251A), offset: Offset(0,2), blurRadius: 6, spreadRadius: -1)]` |
| **market tab — inactive** | README: `0 2px 6px rgba(51,37,26,.14)` (prototype: `0 1px 2px .08`) | `[BoxShadow(color: Color(0x2433251A), offset: Offset(0,2), blurRadius: 6)]` — README picked |
| **summary card (amber)** | `0 1px 3px rgba(224,140,27,.2)` | `[BoxShadow(color: Color(0x33E08C1B), offset: Offset(0,1), blurRadius: 3)]` |
| **toggle knob** | `0 1px 3px rgba(51,37,26,.28)` | `[BoxShadow(color: Color(0x4733251A), offset: Offset(0,1), blurRadius: 3)]` |
| **pot layer selected** | `inset 0 0 0 2.5px ink` | No Flutter inset-shadow API — draw as a 2.5 px `ink` ring inside the layer rect (foreground `Border`-like stroke painted within the layer, or a `Container` foregroundDecoration `ShapeDecoration` with a 2.5 px ink border **drawn over the fill**; this is the sanctioned selection ring, not a card border) |

### 4.3 Elevation rules

- `Material.elevation`/`shadowColor` are **0 everywhere**; all depth is the explicit `boxShadow` array on the `BoxDecoration`. No Material ink-splash elevation changes (use `InkResponse`/`InkWell` with highlight only, or gesture wrappers).
- No surface tint, no ambient/spot light, no `Divider`s anywhere. The tab bar and sheet float on their upward shadows over content.
- States change **shadow identity**, not height: pending → card shadow; owned/accepted → amber owned shadow; completed → whisper shadow.
- Hover states in the prototype (buttons warming to `#F6EFE0`) map to `MaterialStateProperty` pressed/selected tints on mobile; keep them if using `FilledButton`-style widgets, otherwise drop.

### 4.4 Chips & pills

- **Streak pill**: 34 dp tall, `padding: EdgeInsets.symmetric(horizontal: 11)`, radius 11, bg honeyTint, pill-honey shadow; jar glyph 13×15 (lid 8×3 r2 `#7A5230` at top inset 2.5 L/R; body gradient `#FFD972→#E8A11B`, radius 3 3 6 6), gap 6, count JBM 700 12.5 `#8A5E12`.
- **Market tag chip**: JBM 700 8.5, letter-spacing 0.51 px, `padding: EdgeInsets.symmetric(horizontal:5, vertical:2)`, radius 5, bg honeyTint, text `#8A5E12`.
- **Streak tag chip** (friends): JBM 500 9, same padding/radius; streak ≥ 25 → honeyTint bg / `#8A5E12`; 0 < streak < 25 → `#F3EDDF` bg / inkMuted-50 `0x8033251A`; "quiet" → `#F3EDDF` / inkMuted; "you" → ink bg / honey text.
- **Buttons**: ink = bg `#33251A`, text cream `#F6EFE0` 11.5–12.5/700, radius 10 (30 dp pills) or 14 (46 dp full-width CTAs). Money button: bg `#2E6B4F`, text `#EAF7EF`. Unaffordable honey price: bg `#EFE7D6`, text `0x6633251A` (40% ink). Owned: bg `#EFE7D6`, text `0x8033251A`, labels "Owned"/"Active"/"Started".
- **Invite pill**: 30 dp, radius 10, ink bg, cream JBM 700 11, 10×12 jar glyph (lid `#B8801A`, body honey).

### 4.5 Tab bar

Fixed bottom, `padding: EdgeInsets.fromLTRB(10, 9, 10, 26)`, bg `Color(0xEBFBF7EF)` (canvas @ 92%), `BackdropFilter` with `ImageFilter.blur(14, 14)`, lift shadow (§4.2), row gap 2. Five equal flex items, column: icon box 20×18 → label PJS 9.5/700, gap 5, item vertical padding 5. Active: icon `#E08C1B` + ink label; inactive: icon `0x3333251A` (20%) + label `0x6633251A` (40%). Icons are **drawn** (painter or shape-built), never glyph fonts: Hive = three 8×9 pointy hexes (2 over 1, bottom `margin-top:-2`); Report = three 3.5-wide bars h 8/15/11, r2, gap 2.5; Market = jar (lid 8×3 r2 + body 14×12 r3 3 6 6, 4 px apart); Comb = 15×17 hex with 8×9 canvas-coloured hex knockout; Hive-mates = two Ø10 circles overlapping −4 px, right one ringed 2 px canvas.

### 4.6 Sheets — the shared detail sheet

Scrim `Color(0x6633251A)` (ink @ 40%), tap-to-dismiss. Sheet: canvas bg, top radius 26, sheet shadow, `padding: EdgeInsets.fromLTRB(18, 18, 18, 30)`, column gap 15. Grab handle 38×4 r3 `0x2E33251A`, centred. Header row gap 13: 46×52 hexagon tinted by source (income `158° #FFD05C→#E08C1B`, expense `158° #8B6039→#553519`, pot `158° #FFD972→#5C8C86`); kicker 10.5/700/.1em allCaps `0x6B33251A`; amount JBM 700 26, spacing −0.78 px, ink; close button 32×32 r10 surfaceSunk `#F1EADB`, × 15/700 inkMuted-50. Bar row: 56 dp tall, six bars flex-1, gap 4, r3 — current month full accent, second-highest accent @ `0xAA` alpha (67%), rest `#EFE7D6`; month labels JBM 500 8.5 `0x6133251A`. Breakdown rows (gap 11 between rows, 6 within): label PJS 12.5/700 ink + amount JBM 500 12 `Color(0xB333251A)` (70%); track 7 dp r4 `#EFE7D6` with coloured % fill (income fills: DEEP, honey, teal, `#FFDD8A`; expense: `#6E4826`, clay, `#8B6039`, `#A2764C`; pot: `#FFDD8A`, honey, teal, clay); note PJS 10.5/500 `0x7333251A`. Footer: full-width 46 dp, r14, ink bg, cream 12.5/700 "Back to the hive".

### 4.7 The no-border law

No UI element draws a border: not cards, chips, tiles, toggles, nor the tab bar/sheet edges (the settings gear "knob" rings are 2 px `#7A5230` **circle strokes inside a drawn glyph** — illustration, not border). Allowed ink-painted strokes: the honey jar's 3 px `#7A5230` body outline and 9×9 selection rings — both are artwork/selection affordances the README specifies as strokes. If in doubt, express separation with `surface` vs `canvas` vs `surfaceWarm` fills + shadow, never a hairline.

---

## 5. Hexagon geometry

Pointy-top regular hexagon. CSS: `polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%)`.

Flutter: a reusable clip/border with vertices, for a box of width w × height h, in order: `moveTo(w/2, 0) → lineTo(w, h/4) → lineTo(w, 3h/4) → lineTo(w/2, h) → lineTo(0, 3h/4) → lineTo(0, h/4) → close`. Ship it two ways: `HexagonBorder extends ShapeBorder` (for `ClipPath(clipper:...)` / `ShapeDecoration`) and a `CustomClipper<Path>` (`HexPointyClipper`). **Width:height ratio ≈ 1 : 1.12** (measured: 52×58, 26×29, 104×116, 8×9 — the 25/75-stop polygon is mathematically 1:1.155, but all handoff assets were authored at ~1.12; author cells at the given w×h pairs, don't force regularity).

Observed sizes and roles:

| Size (w×h) | Use |
|---|---|
| 8×9 | streak banner dots, regenerate-step bullets, tab-bar Hive icon cells |
| 9×10 / 11×12.5 | Comb legend chips / report kicker hex |
| 26×29 (range 27–33) | check-in task tick hexes |
| 34×38 | invite "+" hex |
| 46×52, 46×53 | sheet header hex, market art tiles (range 46–52) |
| 52×58 | home honeycomb cells — gap 1, row overlap `margin-top:-15` on every row after the first |
| 104×116 | Comb badge cells — gap 5, row overlap `margin-top:-29` |

Home-comb generation (procedural, do not hand-place): total cells = `level + round(expense/income × level)` (7 + 5 = 12 today); rows fill greedily alternating 3, 4, 3, 2… (HTML's `buildHive`: first row 3, then alternate 4/3 until exhausted), centre-aligned so the interlock offset emerges automatically. A cell is **income** iff its horizontal centre in cell-units across the widest row, `centre = (widestRow − rowCount)/2 + colIndex + 0.5`, is < `incomeCells/totalCells × widestRow` — left/right split, never top/bottom. Income cells `158° #FFD972→#E8A11B`, expense cells `158° #8B6039→#553519`; no ghost/dimmed cells, no text inside cells.

---

## 6. Component inventory (reusable primitives)

Everything is drawable — **no image assets, no icon fonts, no Lottie**. Fonts from `google_fonts`. "Painter?" = should it be a `CustomPainter`.

| Primitive | What it draws | Painter? |
|---|---|---|
| `HexagonBorder` / `HexPointyClipper` | the §5 pointy-top hex as ShapeBorder + clipper; reused by every hex below | No (Path math); trivial |
| `HoneycombView` | the unified home hive: procedural income/expense tessellation (§5), tappable cells routed to income/expense sheets | **Yes — CustomPainter** (README: cheaper than a Column/Row of ClipPaths and makes the split maths trivial) |
| `BeeSwarm` | 1 bee per transaction, ≤5 per direction: 9×6 r4 body + 2×4 stripe + 6×4 ellipse wing; amber bees fly in over honey side, cream bees fly out under brown side; per-bee duration `4.4 + 0.55i`s, delay `0.9i`s, start `left: 4+i×18 %`, `top: 34+(i%3)×15 %` (out-bees bottom-anchored) | Widgets (Stack of tiny Containers) + `AnimationController`s; painter optional |
| `HoneyJar` | 118×176 pot: rim 88×9 r4 `#7A5230`; body inset 4 L/R, top 20, 3 px `#7A5230` stroke, radii TL16 TR16 BR44 BL44, fill `#FFFCF3`; bottom-anchored layers Debt 0–22 (hatched `repeating-linear-gradient 115° #C4634C 0 7px / #AE5641 7–14px`), Invested 22–56 teal, Savings 56–98 honey, Cash 98–130 `#FFDD8A`; glass shine 9×54 r6 white@55% at (12, 26); tappable layers with ink selection ring | **Yes** for the hatched debt band (2-stripe shader); rest can be positioned Containers under a clip |
| `BreathingHive` | member avatar: 56×56 slot, three stacked rounded bands (widths 52/76/100 %, each 34 % of hive height tall, 1 px overlap, colours `#FFD972→#F5B322→#E08C1B`, radii 7) + 8×7 `#5A3A20` entrance at bottom centre; **hive size = `26 + min(1, honey/2500) × 20` dp**; `hum` breathing; orbiting 4 px ink-dot bees: count from streak (≥25→3, ≥10→2, >0→1), wrapper spins `2.6+0.7i`s delay `0.9i`s, dot at `top: 5i−1` px | No — pure Stack + transforms |
| `MarketArtTile` | 46×53 hex-clipped tile: 150° background gradient + 1–3 absolutely positioned rects/ellipses (some rotated, opacity .5–.95) per item; all 25 tile definitions are in the prototype's `ART` map — port as data (bg gradient + shape list), render generically | **Yes, or ClipPath+Stack** — data-driven either way |
| `TabBarIcon` set | five drawn icons (§4.5) | Yes (painters) or shape-built widgets — **never glyph fonts** |
| `JarGlyph` | the little jar at 13×15 (pills) and 10×12 (price buttons/invite): lid bar + rounded-gradient body | No — two stacked containers; share one parameterised widget |
| `DetailSheet` | §4.6 composition; opened via overlay/`showModalBottomSheet` with transparent barrier custom scrim | No |
| `Sparkline` | 6 bars, flex widths, r2, fixed colour ramps per card (§Report) | No |
| `ProgressBar` | track 7–8 dp r4–5, fully-rounded fill, optional 90° honey gradient (`#F5B322→#E08C1B`) | No |
| `Toggle` | 44×26 r14, 3 px padding, track honey on / `#E2DAC9` off, Ø20 white knob with knob shadow, animate knob 180–220 ms ease | No |
| `SegmentedControl` | surfaceSunk `#F1EADB` track r12 p4 gap6; 30 dp segments r9; active = white bg + ink text 11.5/700, inactive transparent 45% ink | No |

### Motion appendix (exact keyframes → Flutter)

All loops infinite + decorative; gate every one on `AppLifecycleState` background and `MediaQuery.disableAnimations`.

| Name | Period / easing | What it does (Flutter translation) |
|---|---|---|
| `fall` (honey drops) | 2.8 s `cubic-bezier(.35,0,.85,.45)` (in Flutter: `Curve` via `Cubic(0.35,0,0.85,0.45)`), 2nd drop delayed 1.4 s | translateY 0→40 px (72%)→48 px, scale (.7,.8)→(1,1.3)→(1.4,.35)→(1.6,.2), opacity 0→1 @12% →.5 @88% →0; drops are 7×11 and 6×9 teardrops, radius `50% 50% 60% 60% / 70% 70% 40% 40%`, honey gradients |
| `swell` (impact ripple) | 2.8 s ease-out, same phase as `fall` | 5 dp amber ellipse (left/right 16%, bottom 128 inside jar): scaleX .4→1 @72%→1.5, opacity 0→.85→0, dead until 55% |
| `drip` (debt leak) | 2.6 s ease-in | 6×9 clay teardrop below jar: translateY 0→14, opacity 0→1 @30%→0 |
| `beeIn` | 4.4 s + .55 s/bee, linear, stagger .9 s/bee, infinite | translate (−26,34)→(26,10) @62%→(58,−10); rotate −14°→6°→10°; opacity 0→1 @18%, →fade from 86% |
| `beeOut` | same timing, mirrored | (34,−6)→(2,16) @58%→(−30,38); rotate 8°→−6°→−16° |
| `flap` (wings) | 0.28 s ease-in-out **alternate** | wing scaleY .5→1, rotate −8°→10° |
| `hum` (hives breathe) | 3.4 s ease-in-out | keyframes 0/100%: translateY 0, rotate −1°; 50%: translateY −2, rotate +1° (equivalent to README's "alternate" description) |
| `spin` (orbiting bees) | `2.6+0.7i` s linear infinite, delay `.9i` s | full 360° rotation of the bee-dot wrapper around hive centre |
| `rise` (cash layer) | height 32→35→32 @ 0/60/80/100 % | gentle cash-level pulse in the jar |
| `pulseSoft` | opacity .35↔.9, infinite | generic soft blink (defined in prototype) |
| Flash line | auto-dismiss after **3.2 s** | Market purchase toast |
| Regenerate | **2 s** dark "Reading the hive…" card, then refreshed meta | replace report body |

Implementation: one `AnimationController` per repeating motif (or one shared ticker with staggered `Interval`s); `Transform.translate` + `Transform.rotate` + `Transform.scale` composed via `Matrix4`.
