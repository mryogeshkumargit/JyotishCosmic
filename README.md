# Jyotish Cosmic 🌌

Jyotish Cosmic is an advanced, AI-powered Vedic Astrology application for Android. It seamlessly fuses the ancient, mathematically rigorous rules of traditional Hindu astrology (Jyotish) with cutting-edge artificial intelligence to provide highly accurate, beautifully presented, and deeply personalized astrological insights.

## Features ✨

- **Exact Astronomical Calculations:** Powered by the state-of-the-art Swiss Ephemeris (`swisseph`), ensuring pinpoint precision for planetary longitudes, ascendants (Lagna), and house cusps.
- **Dynamic Birth Charts:** Renders authentic North Indian and South Indian style Kundali charts interactively, complete with exact planetary degrees and zodiac mapping.
- **Ashtakoot Guna Milan (Matchmaking):** A strict, table-driven implementation of the traditional 36-point Ashtakoot compatibility system, including Varna, Vashya, Tara, Yoni, Graha Maitri, Gana, Bhakoot, and Nadi Kootas.
- **AI-Driven Interpretations:** Connects directly to OpenAI's GPT-4o (or compatible models) via your own API key to generate deep, personalized readings of your birth chart and matchmaking compatibility.
- **Profile Management:** Store and manage unlimited profiles seamlessly using secure, local SQLite databases.
- **Live Over-The-Air (OTA) Updates:** Built-in seamless update functionality. Keep your app up to date directly from GitHub releases or a local development server without needing the Play Store.

## Privacy First 🛡️

Jyotish Cosmic respects your privacy. All your deeply personal birth data is stored **100% locally** on your device using SQLite. Your data only leaves your device when you explicitly request an AI interpretation, at which point the required astrological data is sent securely to the LLM endpoint you configure using your own API key.

## Architecture 🛠️

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod
- **Local Storage:** SQLite (sqflite)
- **Astrology Engine:** Swiss Ephemeris (`swisseph_api`)
- **AI Integration:** Direct REST API (`dio`) with Markdown rendering.

## Setup & Installation 🚀

1. Download the latest `app-release.apk` from the Releases page.
2. Install the APK on your Android device. (Make sure "Install from Unknown Sources" is enabled in your Android settings).
3. Open the app, navigate to **Settings**, and enter your OpenAI API key to unlock the AI interpretation engine.
4. Add your profile in the **Profiles** tab and begin your cosmic journey!

## Building from Source 💻

If you wish to compile the app yourself:

```bash
git clone https://github.com/mryogeshkumargit/JyotishCosmic.git
cd JyotishCosmic
flutter pub get
flutter build apk
```

The resulting APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.
