# Moinsen Punch Cards

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Powered by Moinsen.dev](https://img.shields.io/badge/Powered%20by-Moinsen.dev-orange.svg)](https://moinsen.dev)

A Flutter application for creating, editing, and learning about punch card programming. Built with AI assistance as a showcase of modern rapid development.

## Features

### Visual Editor
- Direct punch mode with a full 12-row x 80-column interactive grid
- Instruction-based programming mode
- AI-assisted punch card analysis via Gemini
- Live SVG preview of punch cards
- Save, reorder, duplicate, and manage multiple cards
- Shake-to-shuffle with haptic feedback and sound

### Games
- **Challenge Mode** — Solve AI-validated programming challenges against the clock
- **Tutorial Mode** — Quiz-based learning with scoring, difficulty progression, and timed rounds

### Settings
- Light / Dark / System theme switching
- Gemini API key configuration
- Secure on-device storage

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.24+ (Dart) |
| State | Provider + ChangeNotifier |
| AI | Google Gemini 2.0 Flash Lite |
| Persistence | SharedPreferences |
| Audio | audioplayers |
| Sensors | sensors_plus (shake detection) |

## Getting Started

```bash
git clone git@github.com:moinsen-dev/moinsen_punch_cards.git
cd moinsen_punch_cards
flutter pub get
flutter run
```

Requires a Google Gemini API key for AI features (configurable in Settings).

## Project Structure

```
lib/
├── main.dart                     # Entry point
├── app.dart                      # MaterialApp, routing, providers
├── models/
│   └── challenge.dart            # Challenge data model
├── providers/
│   ├── challenge_provider.dart
│   └── settings_provider.dart
├── screens/
│   ├── welcome_screen.dart       # Onboarding
│   ├── punch_card_editor.dart    # Main editor + saved cards
│   ├── game_screen.dart          # Game mode selection
│   ├── challenge_screen.dart     # Timed challenge gameplay
│   ├── tutor_screen.dart         # Tutorial quiz
│   └── settings_screen.dart      # Theme & API key
├── services/
│   ├── ai_service.dart           # Gemini integration
│   ├── challenge_service.dart
│   └── settings_service.dart
├── widgets/
│   ├── punch_card_workspace.dart # Reusable editor grid
│   ├── segmented_number.dart     # 7-segment display widget
│   ├── challenge_question.dart
│   └── info_carousel.dart
├── punchcard.dart                # Image processing (legacy)
└── punchcard_generator.dart      # Models, SVG generation, JSON parsing
```

## Publishing

See [RELEASE.md](RELEASE.md) for build & deployment instructions.

## License

MIT — see [LICENSE](LICENSE).

---

Built with vibe coding and love by [Ulrich Diedrichsen](https://moinsen.dev).
