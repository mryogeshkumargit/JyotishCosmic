# Jyotish Cosmic 🌌

Jyotish Cosmic is a Vedic Astrology application for Android built with Flutter. It combines the traditional, table-driven rules of Jyotish with optional AI interpretations. All calculations happen on the device with the Swiss Ephemeris, and all profiles stay on the device.

## Features ✨

- **Swiss Ephemeris calculations:** Planetary longitudes, speeds (retrogression), the ascendant, Placidus cusps, sunrise/sunset and solar returns come from the Swiss Ephemeris ([`sweph`](https://pub.dev/packages/sweph)). The bundled `sepl_18`/`semo_18` files cover 1800–2400 CE; outside that range Swiss Ephemeris falls back to its built-in Moshier ephemeris. Sidereal zodiac with Lahiri ayanamsa (Krishnamurti ayanamsa for KP), mean lunar nodes.
- **Birth charts:** North, South and East Indian chart styles with degrees and retrograde markers; the 16 Shodashvarga divisional charts.
- **Vimshottari Dasha:** Mahadasha, Antardasha and Pratyantardasha with the exact balance at birth.
- **Panchang:** Tithi, Nakshatra, Yoga, Karana and Vara (sunrise to sunrise), with sunrise/sunset, Rahu Kaal, Yamaganda and Gulika — for today or at birth.
- **Ashtakoot Guna Milan:** The 36-point system (Varna, Vashya, Tara, Yoni, Graha Maitri, Gana, Bhakoot, Nadi) using the standard tables, plus Manglik comparison.
- **Also included:** Transits (Gochar), Varshaphal (annual chart), KP system (star and sub lords), yogas, doshas (Manglik, Kaal Sarp, Sade Sati, Pitru, Grahan, Guru Chandal, Kemadruma), planetary avasthas, Lal Kitab and remedies.
- **Offline birthplace search:** A bundled GeoNames extract (about 70,000 places, including all Indian towns above 1,000 people) with IANA time zones. The UTC offset at birth is derived automatically, including daylight saving time and historical offsets.
- **Optional AI interpretations:** OpenAI, Anthropic (Claude), Gemini, DeepSeek, Grok, or any OpenAI-compatible server (for example a local Ollama). Uses your own API key; answers are rendered as Markdown and can be saved to a profile.
- **PDF export:** Birth chart report and AI life report.
- **Optional Cloud Sync:** Sign in under Settings → Cloud Sync to back up profiles and saved interpretations and keep them in sync across devices. The app remains fully usable offline; edits made offline are uploaded on the next sync.

## Privacy First 🛡️

Jyotish Cosmic works without an account. Profiles live in a local SQLite database, and all calculations run on the device. The app only uses the network for:

- Cloud Sync, only if you sign in (profiles are sent to the sync server shown in Settings);
- an AI interpretation that you explicitly request, sent to the provider you configured with your key;
- the manual "Check for Updates" button, which queries GitHub releases.

Fonts, ephemeris files and the city database are bundled with the app.

## Architecture 🛠️

- **Framework:** Flutter (Dart), Riverpod
- **Local storage:** SQLite via Drift
- **Astronomy engine:** Swiss Ephemeris (`sweph` FFI plugin)
- **Time zones:** `timezone` (IANA database, bundled)

## Building from Source 💻

```bash
git clone https://github.com/mryogeshkumargit/JyotishCosmic.git
cd JyotishCosmic
flutter pub get
flutter build apk
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

### Test builds

Every push runs the GitHub Actions workflow in `.github/workflows/android.yml`: analyze, the full test suite and a release APK. The APK is attached to the run as an artifact and published as a GitHub pre-release named "Test build N".

### Running the tests

The Swiss Ephemeris tests need a host build of the native library (Flutter plugins are not loaded in unit tests):

```bash
tool/build_sweph_test_lib.sh   # compiles libsweph for your machine into build/test_native
flutter test
```

Without that step, the ephemeris-dependent tests are skipped.

## Licensing and attributions

- The Swiss Ephemeris is © Astrodienst AG and is used under the GNU AGPL-3.0 (through the `sweph` package). Distributing the app therefore requires its source code to be available under AGPL-compatible terms, unless you hold a Swiss Ephemeris Professional License.
- City data © [GeoNames](https://www.geonames.org/), licensed under CC BY 4.0.
- Fonts: Inter, Cinzel and Noto Sans Devanagari (SIL Open Font License).
