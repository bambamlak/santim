# Santim - Budget App

A premium, open-source personal finance and budgeting application built with Flutter. Santim features an elegant, AMOLED-friendly UI engineered with a strong focus on smooth animations, dynamic design, and clear financial oversight.

## Features
- **Waterfall Finance Logic**: Automatically deducts "Saving Jars" and "Budget Jars" from your total balance to give you an accurate "Safe to Spend" (STS) metric.
- **Dynamic End-of-Day Insights Chart**: An interactive, smooth Bézier-curved chart demonstrating balance evolution with touch-to-scrub functionality.
- **Daily Allowances**: Computes exactly how much you can spend per day based on your STS and the remaining days of the month.
- **Multiple Currency Support**: Live currency conversion powered by FreeCurrencyAPI, with seamless local database recalculations.
- **Local-First & Offline Ready**: All data is stored locally via `sqflite` so it operates entirely offline by default (except for manual currency syncing).
- **Customizable Theming**: Full support for dark mode, AMOLED pure black mode, and multiple color seed palettes.

## Setup & Run

### Prerequisites
- Flutter SDK (latest stable version recommended)
- Dart SDK

### Running Locally
1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/santim-budget-app.git
   ```
2. Navigate to the project directory:
   ```bash
   cd santim-budget-app
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. **API Key Configuration**: 
   - Get a free API key from [FreeCurrencyAPI](https://freecurrencyapi.com/).
   - Open `lib/data/services/currency_service.dart`.
   - Replace the `_apiKey` placeholder with your actual API key:
     ```dart
     static const String _apiKey = 'YOUR_API_KEY_HERE';
     ```
5. Run the app:
   ```bash
   flutter run
   ```

## Included & Excluded Files
- Almost all files inside the `lib/`, `assets/`, `lottie_assets/`, `android/`, and `ios/` folders should be pushed to GitHub.
- Standard generated files are already excluded via the default Flutter `.gitignore`. Do not commit API keys or sensitive passwords.

## License
MIT License. See `LICENSE` for more information.

---
*Made by Beamlak ❤️*
