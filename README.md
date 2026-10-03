# Jyotish Cosmic 🌌

Jyotish Cosmic is a Vedic Astrology application for Android built with Flutter. It combines the traditional, table-driven rules of Jyotish with optional AI interpretations. All calculations happen on the device with the Swiss Ephemeris, and all profiles stay on the device.

## Features ✨

- **Swiss Ephemeris calculations:** Planetary longitudes, speeds (retrogression), the ascendant, Placidus cusps, sunrise/sunset and solar returns come from the Swiss Ephemeris ([`sweph`](https://pub.dev/packages/sweph)). The bundled `sepl_18`/`semo_18` files cover 1800–2400 CE; outside that range Swiss Ephemeris falls back to its built-in Moshier ephemeris. Sidereal zodiac with Lahiri ayanamsa (Krishnamurti ayanamsa for KP), mean lunar nodes.
- **Birth charts:** North, South and East Indian chart styles with degrees and retrograde markers; the 16 Shodashvarga divisional charts.
- **Vimshottari Dasha:** Mahadasha, Antardasha and Pratyantardasha with the exact balance at birth.
- **Panchang:** Tithi, Nakshatra, Yoga, Karana and Vara (sunrise to sunrise), with sunrise/sunset, Rahu Kaal, Yamaganda and Gulika — for today or at birth.
- **Ashtakoot Guna Milan:** The 36-point system (Varna, Vashya, Tara, Yoni, Graha Maitri, Gana, Bhakoot, Nadi) using the standard tables, plus Manglik comparison.
- **Yogas:** About 85 classical checks: all 32 Nabhasa yogas, the Pancha Mahapurusha, Moon and Sun yogas, Raja yogas (Kendra-Trikona, Yogakaraka, Dharma-Karmadhipati, Parvata, Kahala, Sankha, Bheri, Chamara), Dhana, Lakshmi, Saraswati, Vasumati, Amala, Adhi, Viparita (Harsha, Sarala, Vimala), Parivartana (Maha, Khala, Dainya), Neecha Bhanga, Kartari, Daridra, Pravrajya and Arishta/Arishta-bhanga. Each yoga shows its exact rule, classical source, how it forms in the chart, strength factors (dignity, combustion, retrogression, Navamsa, cancellations) and whether the current Dasha activates it. The bundled *Comprehensive Guide to Yogas* is readable in the app.
- **Conjunction Database (Volumes 2-3):** Every conjunction of 2-7 classical planets in the chart is matched to its database record (120 clusters × 12 Bhāvas × 12 Rāśis = 17,280 records, generated in the app and checked field-by-field against the published volumes), decomposed into all its pairs with exact separations, applying/separating motion, combustion and planetary war, the dispositor, Lagna lordship, named yogas and the Daśā periods that activate it. Rahu/Ketu associations are a separate node layer. The full database can be browsed.
- **Strength and precision (Volume 4):** Shadbala (all six components with sub-components, Ishta/Kashta Phala) and Bhāva Bala; exact longitude, latitude and speed, stationary/retrograde motion, degree-sensitive dignity (Moolatrikona ranges, distance from deep exaltation), Vargottama, combustion with the exact Sun distance, Graha Yuddha by latitude, degree-sensitive aspects with BPHS sputa drishti, and quality-control checks on every chart.
- **Ashtakavarga:** Bhinnāṣṭakavarga with every contribution, Sarvāṣṭakavarga, Trikona and Ekādhipatya Shodhana, Shodhya Pinda, and transit support.
- **Predictive synthesis (Volume 5):** For 14 life domains the app lists the evidence layer by layer (natal promise, strength, Daśā, transit, Varga, Ashtakavarga), each item with a rule ID, source tier and classical rule, plus Bhāva-lord chains, conflicts, technical status (e.g. `PARTIAL_CONVERGENCE`), event windows from future Daśā periods, Jupiter/Saturn contacts and an audit log. Known life events can be backtested and candidate birth times compared (rectification) without changing the saved time.
- **Calculation conventions:** Node aspects, the planetary-war rule and the close-conjunction orb are configurable; every report records the rules it used.
- **Knowledge Base:** The research documents (Yoga guide, Conjunction Database Volumes 2, 4 and 5) are readable in the app.
- **Also included:** Transits (Gochar), Varshaphal (annual chart), KP system (star and sub lords), doshas (Manglik, Kaal Sarp, Sade Sati, Pitru, Grahan, Guru Chandal, Kemadruma), planetary avasthas, Lal Kitab and remedies.
- **Offline birthplace search:** A bundled GeoNames extract (about 70,000 places, including all Indian towns above 1,000 people) with IANA time zones. The UTC offset at birth is derived automatically, including daylight saving time and historical offsets.
- **Optional AI interpretations:** OpenAI, Anthropic (Claude), Gemini, DeepSeek, Grok, or any OpenAI-compatible server (for example a local Ollama). Uses your own API key. Answers stream in as they are written, are rendered as Markdown and can be saved to a profile. Settings loads the current model list from your provider, so new models can be picked without an app update.
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
