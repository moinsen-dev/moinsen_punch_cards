# Store Assets

Everything needed for Google Play and App Store listings.

## Google Play Console

### Store Listing

**App name:** Moinsen Punch Cards

**Short description (80 chars):**
Retro punch card programming with AI-powered editor, challenges & tutorials.

**Full description:**
Moinsen Punch Cards brings the fascinating world of punch card programming to your fingertips. Whether you're a retro computing enthusiast, a student learning about computing history, or just curious about how programs were written in the early days of computing — this app is for you.

**Visual Editor**
- Interactive 12×80 punch card grid with direct punch mode
- Punch holes by tapping cells, with satisfying haptic feedback and animations
- Switch between direct punch mode, instruction-based mode, and AI-assisted input
- Save, reorder, duplicate, and manage multiple punch cards
- Live SVG preview of your punch cards
- Shake your device to shuffle your saved cards!

**Games**
- Challenge Mode: Solve AI-validated programming challenges against the clock with scoring and difficulty progression
- Tutorial Mode: Quiz-based learning with "Who Wants to Be a Millionaire"-style answer buttons, timed rounds, and consecutive correct streaks

**AI-Powered**
- Integrated with Google Gemini AI for intelligent punch card analysis
- Get feedback on your programs, discover issues, and receive improvement suggestions
- Challenge solutions validated by AI with detailed scoring

**Beautiful & Accessible**
- Full dark mode support with Material 3 design
- Responsive layouts for phones, tablets, and web
- Smooth animations and haptic feedback throughout
- Built with Flutter for native performance on every platform

Built with love in Hamburg, Germany by [Moinsen.dev](https://moinsen.dev).

**Category:** Education

**Tags:** punch cards, retro computing, programming, education, AI, Flutter

---

### Required Graphics

| Asset | Size | Description |
|-------|------|-------------|
| App icon | 512×512 | Already exists at `assets/icons/app_icon.png` |
| Feature graphic | 1024×500 | Hero banner for Play Store top of page |
| Phone screenshot 1 | 1080×1920 (or 16:9) | Landing page / home screen |
| Phone screenshot 2 | 1080×1920 | Punch card editor grid with punched holes |
| Phone screenshot 3 | 1080×1920 | Game mode selection (challenge + tutorial cards) |
| Phone screenshot 4 | 1080×1920 | Challenge mode in progress (timer + question) |
| Phone screenshot 5 | 1080×1920 | Tutorial quiz with answer selected |
| Phone screenshot 6 | 1080×1920 | Settings screen (theme switcher) |
| Tablet screenshot 1 | landscape | Editor on tablet |
| Tablet screenshot 2 | landscape | Game on tablet |

---

## App Store Connect

### App Information

**App Name:** Moinsen Punch Cards
**Subtitle:** Retro Computing, Reimagined
**Category:** Education
**Secondary Category:** Entertainment
**Content Rating:** 4+ (No objectionable content)

**Description:**
Moinsen Punch Cards brings the fascinating world of punch card programming to your fingertips.

Explore the history of computing through an interactive visual editor, AI-powered challenges, and guided tutorials.

FEATURES:
• Interactive 12×80 punch card grid with tap-to-punch
- AI analysis powered by Google Gemini
- Challenge Mode: timed programming puzzles
- Tutorial Mode: quiz-based learning with scoring
- Full dark mode support
- Save, reorder, and duplicate punch cards
- Shake to shuffle with haptic feedback

Built with love in Hamburg, Germany.

**Keywords:** punch cards, retro computing, programming, AI, education, history, IBM, editor

**Support URL:** https://moinsen.dev
**Marketing URL:** https://moinsen-dev.github.io/moinsen_punch_cards/

### Required Graphics

| Asset | Size | Notes |
|-------|------|-------|
| App icon | 1024×1024 | No alpha channel — use `assets/icons/app_icon.png` |
| iPhone 6.7" screenshots | 1290×2796 | 2-10 screenshots required |
| iPhone 6.5" screenshots | 1242×2688 | Or use same as 6.7" scaled |
| iPad 12.9" screenshots | 2048×2732 | If supporting iPad |

---

## Screenshot Capture Guide

Run the app on a simulator/device and capture:

1. **Landing page** — initial screen with "Try It Now" button
2. **Editor** — punch some holes to show a pattern (e.g. LOAD/ADD/STORE)
3. **Game selection** — two floating game cards
4. **Challenge mode** — active challenge with timer counting down
5. **Tutorial quiz** — question with one answer highlighted green
6. **Settings** — theme toggle visible

Use `flutter run -d chrome --web-port=8080` for web screenshots or Simulator for iOS.

For automated screenshots, consider integrating `screenshot` + `integration_test` packages.
