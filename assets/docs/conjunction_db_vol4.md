# VEDIC ASTROLOGY CONJUNCTION DATABASE — VOLUME 4

## DEGREE-SENSITIVE, STRENGTH, VARGA, ASPECT & DAŚĀ ENGINE

**Edition:** 03 October 2026  
**Position:** Extension of Volumes 2 and 3
**Scope:** Exact longitudes, conjunction distance, combustion, planetary war, retrogression, dignity, Vargas, aspects, Shadbala, Daśā activation, Rahu/Ketu and timing metadata.

> **Research principle:** Volume 4 is a calculation engine specification plus database schema. It does not pretend that a numerical threshold or modern scoring convention is itself a classical prediction. Every calculated field is tagged by source/method and can be configured where traditions differ.

## 1. VOLUME STACK

```text
VOLUME 1  → Classical conjunction research
VOLUME 2  → 21 pair × Bhāva × Rāśi database
VOLUME 3  → 120 multi-planet clusters × Bhāva × Rāśi
VOLUME 4  → Degree + strength + Varga + aspect + timing engine
              │
              ├── exact planetary longitude
              ├── conjunction separation
              ├── combustion
              ├── planetary war
              ├── retrogression / motion
              ├── dignity
              ├── Vargas
              ├── Graha/Bhāva aspects
              ├── Shadbala
              ├── Rahu/Ketu
              └── Vimśottarī Daśā activation
```

## 2. REQUIRED INPUT PRECISION

| Input | Required for |
|---|---|
| Birth date | natal longitude + Daśā |
| Birth time with seconds where available | Ascendant, houses, Vargas, timing |
| Birth latitude/longitude | Ascendant + local astronomical factors |
| Ayanāṃśa | sidereal longitude |
| Ephemeris | planetary longitude and motion |
| Node model | Rahu/Ketu longitude |
| Daśā convention | timing |

**A sign-only chart is insufficient for this volume.** Degree-sensitive conditions require actual longitudes.

## 3. EXACT LONGITUDE DATA MODEL

Every graha receives a record like:

```json
{
  "graha": "Mercury",
  "longitude_sidereal": 153.482731,
  "rashi": "Virgo",
  "degree_in_rashi": 3.482731,
  "latitude": 1.23,
  "speed": 1.1042,
  "motion": "direct",
  "retrograde": false,
  "ephemeris_source": "configured",
  "ayanamsha": "configured"
}
```

## 4. EXACT CONJUNCTION ENGINE

Two planets are not merely marked 'conjunct' because they share a sign. Volume 4 stores their exact angular separation:

`separation = min(|L1-L2|, 360-|L1-L2|)`

The engine therefore distinguishes:

- same sign but wide separation
- same sign and close conjunction
- conjunction crossing a sign boundary
- applying conjunction
- separating conjunction
- retrograde re-approach
- exact/near-exact conjunction

### Multi-planet cluster geometry

For N planets, calculate every pair:

`C(N,2) = N × (N−1) / 2`

Volume 3 supplies the cluster membership; Volume 4 supplies the exact pair geometry.

## 5. COMBUSTION ENGINE

Combustion is calculated from angular distance from the Sun, not simply from house/sign co-location.

Default configurable orbs stored in this edition:

| Planet | Working combustion orb |
|---|---:|
| Moon | 12° |
| Mars | 17° |
| Mercury | 14° |
| Jupiter | 11° |
| Venus | 10° |
| Saturn | 15° |

> **Important:** these are configuration values, not universal constants. Classical and later authorities use differing rules, and some traditions add distinctions such as retrograde-specific treatment or deeper combustion. The engine therefore stores both the raw Sun-distance and the configured rule used.

Fields:

`combustion_status`, `sun_distance`, `configured_orb`, `deep_combustion_status`, `retrograde_exception`, `source_rule_id`.

Phaladīpikā discusses combustion as a condition affecting planetary strength/results, while its strength chapter also emphasizes motion and brilliance; therefore Volume 4 keeps combustion separate from total strength.

## 6. PLANETARY WAR / GRAHA YUDDHA

Planetary war is degree-sensitive and must not be inferred merely from a same-sign conjunction.

Default classical candidate set:

**Mars, Mercury, Jupiter, Venus and Saturn.**

Sun and Moon are not treated as participants in the ordinary five-planet Graha Yuddha engine.

For every candidate pair, store:

- absolute longitude separation
- latitude if available
- northern/southern position where the selected rule requires it
- apparent brilliance/rays where the selected source requires it
- winner/loser status
- source rule
- rule version

**Do not hard-code one universal winner algorithm.** Classical descriptions include positional/brilliance criteria, and Bṛhat Saṃhitā also describes different types of planetary conjunction/war based on apparent approachment.

## 7. RETROGRESSION / MOTION ENGINE

Store actual instantaneous speed and motion state:

| Field | Meaning |
|---|---|
| `motion` | direct / retrograde / stationary |
| `speed_deg_day` | signed apparent daily motion |
| `stationary_flag` | near-zero speed under configured tolerance |
| `applying` | whether pair separation is decreasing |
| `separating` | whether pair separation is increasing |
| `motion_source` | ephemeris/source |

Phaladīpikā's Shadbala chapter explicitly includes retrograde motion in Cheshta Bala and notes the role of retrograde planets in strength.

## 8. DIGNITY ENGINE

Degree-sensitive dignity is stored separately from interpretive outcome.

### Exaltation / debilitation points

| Planet | Exaltation | Debilitation |
|---|---|---|
| Sun | Aries 10° | Libra 10° |
| Moon | Taurus 3° | Scorpio 3° |
| Mars | Capricorn 28° | Cancer 28° |
| Mercury | Virgo 15° | Pisces 15° |
| Jupiter | Cancer 5° | Capricorn 5° |
| Venus | Pisces 27° | Virgo 27° |
| Saturn | Libra 20° | Aries 20° |

### Mūlatrikona

| Planet | Sign | Degree range |
|---|---|---|
| Sun | Leo | 0°–20° |
| Moon | Taurus | 4°–30° |
| Mars | Aries | 0°–12° |
| Mercury | Virgo | 16°–20° |
| Jupiter | Sagittarius | 0°–10° |
| Venus | Libra | 0°–15° |
| Saturn | Aquarius | 0°–20° |

Additional dignity states:

- own sign
- exaltation
- mūlatrikona
- great/friendly/neutral/enemy sign according to configured relationship table
- debilitation
- Vargottama
- Pushkara / special divisional conditions where implemented

## 9. VARGA ENGINE

BPHS describes a sixteen-division framework. Volume 4 therefore stores the divisional sign for each planet rather than merely a text label.

| Varga | Chart | Primary use in this engine |
|---|---|---|
| Rāśi | D1 | overall chart/physical life |
| Horā | D2 | wealth/resources |
| Drekkāṇa | D3 | siblings/initiative |
| Chaturthāṃśa | D4 | property/fortune |
| Saptāṃśa | D7 | children/progeny |
| Navāṃśa | D9 | dharma/marriage/planetary refinement |
| Daśāṃśa | D10 | profession/status |
| Dvādaśāṃśa | D12 | parents/ancestry |
| Ṣoḍaśāṃśa | D16 | vehicles/comforts |
| Viṃśāṃśa | D20 | spiritual practice |
| Caturviṃśāṃśa | D24 | learning/education |
| Bhāṃśa | D27 | strengths/weaknesses |
| Triṃśāṃśa | D30 | adversity/negative factors |
| Khavedāṃśa | D40 | auspicious/inauspicious lineage factors |
| Akṣavedāṃśa | D45 | character/lineage |
| Ṣaṣṭiāṃśa | D60 | fine-grained karmic/character assessment |

Core implemented degree-to-varga mappings in the engine schema:

- D1 Rāśi
- D2 Horā
- D3 Drekkāṇa
- D9 Navāṃśa
- D10 Daśāṃśa
- D12 Dvādaśāṃśa
- D60 Ṣaṣṭiāṃśa

The remaining Vargas are represented as extensible calculation modules rather than silently substituting a non-Parāśari rule.

## 10. VARGOTTAMA ENGINE

`vargottama = (D1 sign == D9 sign)`

Store:

`is_vargottama`, `d1_sign`, `d9_sign`, `vargottama_source`.

Phaladīpikā explicitly discusses Vargottama/Navāṃśa strength as a modifier, so the flag must not be treated as a generic cosmetic label.

## 11. ASPECT ENGINE

### Parāśari Graha Dṛṣṭi

All seven classical planets receive a full 7th-house aspect in the basic model.

Special aspects:

| Planet | Additional full aspects |
|---|---|
| Mars | 4th, 8th |
| Jupiter | 5th, 9th |
| Saturn | 3rd, 10th |

Bṛhat Jātaka explicitly describes the ordinary seventh aspect and the special aspect pattern of Mars, Jupiter and Saturn; BPHS has a dedicated chapter on evaluation of planetary aspects.

### Degree-sensitive aspect metadata

Store:

- source house
- target house
- exact angular distance
- aspect type
- applying/separating where applicable
- aspect strength under the selected calculation
- receiving planet
- receiving house
- source rule.

### Rahu/Ketu aspects

Node aspect conventions vary significantly among schools. Volume 4 therefore stores node aspects as a **configurable rule set** rather than asserting one universal convention.

## 12. SHADBALA ENGINE

Shadbala is treated as a separate quantitative layer.

The six components are:

1. Sthāna Bala
2. Dig Bala
3. Kāla Bala
4. Cheṣṭā Bala
5. Naisargika Bala
6. Dṛk Bala

BPHS Chapter 29 covers these strength calculations and planetary war; Phaladīpikā Chapter 4 also presents the sixfold strength framework.

### Shadbala storage

```json
{
  "planet": "Jupiter",
  "sthana_bala": {},
  "dig_bala": {},
  "kala_bala": {},
  "cheshta_bala": {},
  "naisargika_bala": {},
  "drik_bala": {},
  "total_virupas": null,
  "total_rupas": null,
  "minimum_required_virupas": 390,
  "ratio_to_minimum": null
}
```

### Minimum reference values

| Planet | Minimum reference (Virūpas) |
|---|---:|
| Sun | 390 |
| Moon | 360 |
| Mars | 300 |
| Mercury | 420 |
| Jupiter | 390 |
| Venus | 330 |
| Saturn | 300 |

These minimums are stored as reference values, not as a universal ranking of planets.

## 13. ISHTA / KASHTA PHALA

Where the selected Shadbala implementation supports it, store:

- Ishta Phala
- Kashta Phala
- component inputs
- calculation version

Do not convert Ishta/Kashta directly into a generic 'good/bad planet' label. Lordship and chart context remain separate layers.

## 14. BHĀVA BALA

Volume 4 also stores Bhāva Bala independently from planetary Shadbala.

Fields:

- Bhāva Adhipati Bala
- Bhāva Dig Bala / Kendra contribution where applicable
- aspects to Bhāva
- Bhāva lord dignity
- occupancy
- Varga confirmation
- composite Bhāva strength

BPHS's strength chapter explicitly includes Bhāva Bala alongside planetary strength.

## 15. RAHU / KETU ENGINE

Rahu and Ketu are now first-class nodes in Volume 4, but they are kept distinct from the seven classical grahas.

Each node record stores:

- exact sidereal longitude
- sign
- house
- nakṣatra
- nakṣatra lord
- dispositor
- retrograde status
- conjunctions
- aspects under configured school
- dignity-by-dispositor framework
- D9 and other Varga positions
- Daśā eligibility
- transit position

### Node conjunction model

Rahu/Ketu + planet is not automatically treated as identical to an ordinary two-planet conjunction. The engine records:

`node_pair_type = Rahu-graha / Ketu-graha`

and preserves the planet's own dignity and dispositor separately.

## 16. NODE AXIS INTEGRITY

Rahu and Ketu must remain exactly opposite:

`Ketu longitude = Rahu longitude + 180° (normalized)`

The engine should reject a chart where the two node longitudes violate the configured tolerance.

## 17. NAKṢATRA LAYER

Every longitude is mapped to:

- Nakṣatra
- Nakṣatra pāda
- Nakṣatra lord
- remaining arc in Nakṣatra

The Nakṣatra layer is required for Vimśottarī Daśā starting balance.

## 18. VIMŚOTTARĪ DAŚĀ ENGINE

BPHS has a dedicated Daśā chapter and identifies Vimśottarī among the principal systems; it also provides separate computation of Antardaśās.

### Mahādaśā sequence and durations

| Lord | Years |
|---|---:|
| Ketu | 7 |
| Venus | 20 |
| Sun | 6 |
| Moon | 10 |
| Mars | 7 |
| Rahu | 18 |
| Jupiter | 16 |
| Saturn | 19 |
| Mercury | 17 |
| **Total** | **120** |

### Birth balance

The starting Mahādaśā is determined from the Moon's Nakṣatra lord. The remaining portion is proportional to the unused arc of the Moon's Nakṣatra.

`remaining_years = mahadasha_years × remaining_nakshatra_arc / nakshatra_arc`

### Antardaśā

For Mahādaśā lord M and Antardaśā lord A:

`AD duration = M years × A years / 120`

Store exact start/end timestamps rather than only age ranges.

## 19. DAŚĀ ACTIVATION OF A CONJUNCTION

A conjunction becomes a timing object when one or more participating planets is active in:

- Mahādaśā
- Antardaśā
- Pratyantardaśā
- finer subperiods where implemented

Activation fields:

`active_grahas`, `cluster_match`, `house_match`, `lordship_match`, `dasha_start`, `dasha_end`, `strength_context`.

BPHS Antardaśā descriptions explicitly condition results on disposition, configuration, strength and relationships between the Daśā lords, Ascendant and other chart factors.

## 20. DAŚĀ × CONJUNCTION MATRIX

For every Volume 3 cluster, Volume 4 can generate:

`cluster × active Mahādaśā × active Antardaśā`

and evaluate:

1. Is the planet a member of the cluster?
2. What house does it occupy?
3. What houses does it own?
4. What is its dignity?
5. What is its Shadbala?
6. Is it combust?
7. Is it retrograde?
8. Is it in Graha Yuddha?
9. What Vargas support it?
10. What aspects modify it?
11. What is the dispositor doing?

## 21. TRANSIT ACTIVATION

Volume 4 is designed to accept a transit ephemeris and calculate:

- transit-to-natal conjunction
- transit-to-natal opposition
- transit-to-natal special aspect
- transit over natal cluster
- transit through cluster's sign/house
- applying/separating phase
- retrograde re-contact

Phaladeepika contains dedicated transit results, including separate treatment of Rahu and Ketu in transit rules.

## 22. DEGREE-SENSITIVE CONJUNCTION RECORD

Every pair inside a Volume 3 cluster can become a record:

```json
{
  "record_id": "V4-P-SUN-MERCURY-001",
  "graha_a": "Sun",
  "graha_b": "Mercury",
  "longitude_a": null,
  "longitude_b": null,
  "separation_deg": null,
  "same_rashi": null,
  "applying": null,
  "separating": null,
  "combustion": null,
  "planetary_war": null,
  "dignity_a": null,
  "dignity_b": null,
  "vargottama_a": null,
  "vargottama_b": null,
  "aspect_links": [],
  "dasha_activation": [],
  "source_rule_ids": []
}
```

## 23. MULTI-PLANET DEGREE GRAPH

For a triple A+B+C:

```text
        A
       / \
      /   \
     B-----C
```

Every edge is a measured angular relationship.

For four planets:

```text
      A------B
      |\    /|
      | \  / |
      |  \/  |
      |  /\  |
      | /  \ |
      C------D
```

The graph is preferable to a single undifferentiated 'triple strength' number because it preserves which planets are actually close to one another.

## 24. DEGREE-WEIGHTED CLUSTER METADATA

Volume 4 stores descriptive metrics:

- minimum pair separation
- maximum pair separation
- mean pair separation
- median pair separation
- number of pairs within configurable close-conjunction threshold
- number of combustion links
- number of Graha Yuddha candidate links
- number of retrograde participants
- number of Vargottama participants

These are **descriptive metrics**, not classical predictive scores.

## 25. SOURCE / RULE VERSIONING

Every calculation must record:

- `source_family`
- `source_chapter`
- `translation_or_edition`
- `rule_id`
- `rule_version`
- `ayanamsha`
- `ephemeris`
- `node_model`
- `varga_school`
- `aspect_school`
- `combustion_orb_table`
- `planetary_war_rule`

This prevents two astrologers using different conventions from silently receiving different answers from the same database.

## 26. CONFIDENCE / STATUS FLAGS

| Flag | Meaning |
|---|---|
| `CLASSICAL_DIRECT` | exact classical rule identified |
| `CLASSICAL_DERIVED` | direct calculation from classical method |
| `CONFIGURABLE_TRADITION` | multiple established conventions exist |
| `SYSTEMATIC_SYNTHESIS` | database synthesis, not a quoted classical rule |
| `INSUFFICIENT_INPUT` | required degree/time/ephemeris data missing |

## 27. COMPLETE VOLUME 4 DATA OBJECT

```json
{
  "chart": {},
  "grahas": {},
  "nodes": {},
  "clusters": {},
  "degrees": {},
  "combustion": {},
  "graha_yuddha": {},
  "retrogression": {},
  "dignity": {},
  "vargas": {},
  "aspects": {},
  "shadbala": {},
  "bhavabala": {},
  "nakshatra": {},
  "vimshottari": {},
  "transits": {},
  "rule_versions": {}
}
```

## 28. QUALITY-CONTROL TESTS

Before accepting a chart calculation:

1. All longitudes must be normalized to 0–360°.
2. Rahu/Ketu must be 180° apart within tolerance.
3. Ascendant and house system must be internally consistent.
4. D1 signs must match raw longitudes.
5. D9 must be reproducible from the configured rule.
6. Vargottama must equal D1=D9 under the configured mapping.
7. Combustion must use the stored Sun distance and orb version.
8. Graha Yuddha must only be evaluated for configured eligible planets.
9. Retrograde status must come from ephemeris motion, not sign.
10. Shadbala totals must equal the six stored components.
11. Vimśottarī Mahādaśā totals must equal 120 years.
12. Antardaśā durations must sum to the Mahādaśā duration.
13. Dasha starting balance must reproduce from Moon Nakṣatra.
14. No interpretive score may overwrite raw astronomical data.

## 29. WHAT VOLUME 4 ADDS TO VOLUMES 2–3

| Layer | Vol. 2 | Vol. 3 | Vol. 4 |
|---|---:|---:|---:|
| Pair combinations | ✓ | ✓ | ✓ |
| Multi-planet clusters | — | ✓ | ✓ |
| Bhāva | ✓ | ✓ | ✓ |
| Rāśi | ✓ | ✓ | ✓ |
| Dispositor | ✓ | ✓ | ✓ |
| Functional lordship | ✓ | ✓ | ✓ |
| Exact degrees | — | — | ✓ |
| Combustion | — | — | ✓ |
| Planetary war | — | — | ✓ |
| Retrogression | — | — | ✓ |
| Degree dignity | — | — | ✓ |
| Vargas | framework | framework | **calculated** |
| Aspects | framework | framework | **calculated** |
| Shadbala | — | — | ✓ |
| Bhāva Bala | — | — | ✓ |
| Rahu/Ketu | separate | separate | **integrated** |
| Nakṣatra | — | — | ✓ |
| Vimśottarī Daśā | — | — | ✓ |
| Transit activation | — | — | ✓ framework |

## 30. IMPORTANT LIMITATION

Volume 4 cannot produce a genuine degree-sensitive chart result from the Volume 3 placement record alone. It needs the **actual birth date, exact birth time, birthplace coordinates, ayanāṃśa and ephemeris**.

Therefore the database stores formulas, raw inputs and derived values separately. This is intentional: it prevents a sign-level database from pretending to contain astronomical precision it does not possess.

## 31. RESEARCH SOURCES

- Bṛhat Parāśara Horā Śāstra: chapters on planetary positions, sixteen divisions, aspects, strength, Daśā systems and Antardaśā computation.
- Phaladīpikā Chapter 4: sixfold planetary strength, retrogression, planetary war and divisional strength.
- Bṛhat Jātaka Chapter 2: planetary aspects.
- Bṛhat Saṃhitā Chapter 17: conjunction / Graha Yuddha classifications.

## 32. FINAL ARCHITECTURE

```text
                    VOLUME 4
                       │
          ┌────────────┴────────────┐
          │                         │
   ASTRONOMICAL LAYER          JYOTISHA LAYER
          │                         │
   longitude / speed          dignity / lordship
   retrograde                Vargas
   latitude                  aspects
   conjunction distance      Shadbala
   node axis                 Bhāva Bala
          │                    Nakṣatra
          │                    Daśā
          └──────────┬───────────┘
                     │
              TIMING ENGINE
                     │
          Daśā + Transit + Activation
                     │
              INTERPRETATION
                     │
          Classical / Derived /
          Configurable / Synthetic
```

**Volume 4 is therefore the precision layer that turns the Volume 3 conjunction database into a chart-computation architecture.**