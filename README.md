# Jyotish Cosmic 🌌

Jyotish Cosmic is a Vedic Astrology application for Android built with Flutter. It combines the traditional, table-driven rules of Jyotish with optional AI interpretations. All calculations happen on the device with the Swiss Ephemeris, and all profiles stay on the device.

## Features ✨

- **Swiss Ephemeris calculations:** Planetary longitudes, speeds (retrogression), the ascendant, Placidus cusps, sunrise/sunset and solar returns come from the Swiss Ephemeris ([`sweph`](https://pub.dev/packages/sweph)). The bundled `sepl_18`/`semo_18` files cover 1800–2400 CE; outside that range Swiss Ephemeris falls back to its built-in Moshier ephemeris. Sidereal zodiac with Lahiri ayanamsa (Krishnamurti ayanamsa for KP), mean lunar nodes.
- **Hindi and English:** Settings → Style → Language switches the whole app between English and Hindi (हिन्दी): screens, chart labels, engine explanations, doshas, yogas, conjunctions, strength, synthesis, error messages and PDF exports. Hindi text uses the bundled Noto Sans Devanagari font. AI answers follow the language too (Settings → AI → response language). The research documents in the Knowledge Base and technical rule conditions stay in English.
- **Birth charts:** North, South and East Indian chart styles. Each planet shows its degree and state markers, on the Lagna, Transit, Varshaphal and divisional charts: `*` retrograde, `^` combust (within the classical orb of the Sun), `↑` exalted, `↓` debilitated and `□` vargottama (same sign in D1 and D9). A legend is shown under the chart. The 16 Shodashvarga divisional charts are included.
- **In simple words:** Synthesis, Doshas, Yogas, Conjunctions, Strength (Shadbala and Bhāva Bala), Ashtakavarga, Daśā, Transits, Panchang, KP, Avasthas, Remedies and Kundali Milan each open with a plain-language card. It explains what the result means for an ordinary reader: the life area, whether it helps or needs care, when it is active, and what softens it. The texts follow the classical significations (BPHS, Phaladeepika, Saravali, Brihat Jataka) and say where a dosha is a later tradition rather than a classical rule.
- **Vimshottari Dasha:** Mahadasha, Antardasha and Pratyantardasha with the exact balance at birth.
- **Panchang:** Tithi, Nakshatra, Yoga, Karana and Vara (sunrise to sunrise), with sunrise/sunset, Rahu Kaal, Yamaganda and Gulika — for today or at birth.
- **Ashtakoot Guna Milan:** The 36-point system (Varna, Vashya, Tara, Yoni, Graha Maitri, Gana, Bhakoot, Nadi) using the standard tables, plus Manglik comparison.
- **Yogas:** About 85 classical checks: all 32 Nabhasa yogas, the Pancha Mahapurusha, Moon and Sun yogas, Raja yogas (Kendra-Trikona, Yogakaraka, Dharma-Karmadhipati, Parvata, Kahala, Sankha, Bheri, Chamara), Dhana, Lakshmi, Saraswati, Vasumati, Amala, Adhi, Viparita (Harsha, Sarala, Vimala), Parivartana (Maha, Khala, Dainya), Neecha Bhanga, Kartari, Daridra, Pravrajya and Arishta/Arishta-bhanga. Each yoga shows its exact rule, classical source, how it forms in the chart, strength factors (dignity, combustion, retrogression, Navamsa, cancellations) and whether the current Dasha activates it. The bundled *Comprehensive Guide to Yogas* is readable in the app.
- **Conjunction Database (Volumes 2-3):** Every conjunction of 2-7 classical planets in the chart is matched to its database record (120 clusters × 12 Bhāvas × 12 Rāśis = 17,280 records, generated in the app and checked field-by-field against the published volumes), decomposed into all its pairs with exact separations, applying/separating motion, combustion and planetary war, the dispositor, Lagna lordship, named yogas and the Daśā periods that activate it. Rahu/Ketu associations are a separate node layer. The full database can be browsed. Each cluster also shows the sign's dominant modifier and the Phaladeepika ch. 18 pair summaries (from the *Planetary Conjunctions Deep Research* report). It also shows whether the cluster or its pairs repeat in D9/D10, and common-error cautions (Moon–Jupiter is not automatically Gaja-Kesari; Sun–Mercury is not automatically Budha-Āditya). Volume 6 cluster diagnostics are included as well: degree span, centre, nearest and widest pair, central planet, compactness, and dignity, house and activation coherence. These are labelled as engineering heuristics.
- **Strength and precision (Volume 4):** Shadbala (all six components with sub-components, Ishta/Kashta Phala) and Bhāva Bala; exact longitude, latitude and speed, stationary/retrograde motion, degree-sensitive dignity (Moolatrikona ranges, distance from deep exaltation), Vargottama, combustion with the exact Sun distance, Graha Yuddha by latitude, degree-sensitive aspects with BPHS sputa drishti, and quality-control checks on every chart.
- **Ashtakavarga:** Bhinnāṣṭakavarga with every contribution, Sarvāṣṭakavarga, Trikona and Ekādhipatya Shodhana, Shodhya Pinda, and transit support.
- **Predictive synthesis (Volume 5):** For 14 life domains the app lists the evidence layer by layer (natal promise, strength, Daśā, transit, Varga, Ashtakavarga), each item with a rule ID, source tier and classical rule, plus Bhāva-lord chains, conflicts, technical status (e.g. `PARTIAL_CONVERGENCE`), event windows from future Daśā periods, Jupiter/Saturn contacts and an audit log. Known life events can be backtested and candidate birth times compared (rectification) without changing the saved time.
- **Automated interpreter (Volume 6, Master Knowledge Base, Production Knowledge Graph):**
  - **Statuses and confidence.** Each domain carries an event-domain code (E01–E12, plus A01 Education and A02 Spiritual) and its Master KB supporting Vargas. It has a Volume 6 status (`NOT_SUPPORTED` … `CONFIRMED_BY_TRANSIT`, `CONFLICTED`) and a confidence state (`LOW` … `VERY_STRONG`); these are never percentages.
  - **Dependency check.** The Master KB required layers are checked: natal promise, Bhāva-lord chain, strength, conjunction, Daśā and transit.
  - **Rule trace and explanation graph.** Every evidence item links to a registry rule (R001–R030), its classification and its sources (SRC01–SRC19, ENG01). The explanation graph has stable node IDs.
  - **Transit triggers.** Degree-exact triggers cover Jupiter, Saturn, Rahu and Ketu reaching a conjunction or Parashari aspect point of natal planets and cusps. They give entry, exact and separation dates and mark retrograde re-contacts.
  - **Timing windows.** Daśā ∩ transit windows carry activation tags (e.g. `MERCURY_MD, KETU_AD, SATURN_3RD_ASPECT_SUN`). A Timing tab shows the current Daśā chain down to Sūkṣma.
  - **Birth-time sensitivity.** The chart is recomputed at T±2 and T±5 minutes and each factor is reported as stable or sensitive.
  - **Jaimini factors.** Chara Karakas use a 7- or 8-karaka scheme. The engine also computes the Arudha Padas, Upapada and Karakamsa, and uses the Amātyakāraka for career and the Dārakāraka and Upapada for marriage.
  - **Audit and export.** The audit has SHA-256 input and calculation fingerprints, a run ID and counts of rules executed, triggered and conflicted. A reproducibility package can be copied as JSON or shared as a PDF.
- **Rules & Sources and Research:** Browse the rule registry, the classical source records and the coverage report (no orphan sources, no direct-classical rule without a source). The external corpora that the Master KB references are listed but not bundled. Research mode searches all saved charts for a conjunction by house, sign, current-Daśā activation or D9 repetition.
- **Calculation conventions:** These settings are configurable, and every report records the rules it used:
  - ayanamsa: Lahiri, Lahiri ICRC/1940, True Chitra, Raman or Yukteshwar
  - mean or true node
  - Daśā year: 365.25 or 365.2425 days
  - 7 or 8 Chara Karakas
  - transit trigger orb
  - node aspects
  - planetary-war rule
  - close-conjunction orb
- **Knowledge Base:** These research documents are readable in the app: the Yoga guide, Conjunction Database Volumes 2, 4, 5 and 6, the Planetary Conjunctions Deep Research report, and the Master Knowledge Base and Production Knowledge Graph specifications.
- **Also included:** Transits (Gochar), Varshaphal (annual chart), KP system (star and sub lords), doshas (Manglik, Kaal Sarp, Sade Sati, Pitru, Grahan, Guru Chandal, Kemadruma), planetary avasthas, Lal Kitab and remedies.
- **Offline birthplace search:** A bundled GeoNames extract (about 70,000 places, including all Indian towns above 1,000 people) with IANA time zones. The UTC offset at birth is derived automatically, including daylight saving time and historical offsets.
- **Optional AI interpretations:** OpenAI, Anthropic (Claude), Gemini, DeepSeek, Grok, or any OpenAI-compatible server (for example a local Ollama). Uses your own API key. Answers stream in as they are written, are rendered as Markdown and can be saved to a profile. Settings loads the current model list from your provider, so new models can be picked without an app update.
- **PDF export:** Birth chart report and AI life report, in English or Hindi. The PDF library cannot shape Devanagari, so Hindi lines are laid out by Flutter's text engine and embedded as high-resolution images. As a result, Hindi text in the PDF cannot be selected.
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
