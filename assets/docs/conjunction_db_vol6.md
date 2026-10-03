# Vedic Astrology Conjunction Database — Volume 6
## Automated Chart Interpreter & Prediction API
### Architecture, Data Contracts, Rule Engine, Calculation Pipeline, Explainability, Testing & Deployment

**Series:** Vedic Astrology Conjunction Database  
**Volume:** 6  
**Title:** Automated Chart Interpreter & Prediction API  
**Status:** Architecture specification / implementation blueprint  
**Depends on:** Volumes 1–5  
**Primary goal:** Convert the research database into a deterministic, auditable, explainable software engine.

---

## 0. Executive Definition

Volume 6 is the software architecture that turns Volumes 1–5 into an executable system.

It is deliberately divided into two layers:

1. **Astronomical calculation layer**
   - birth time/date/location normalization
   - Julian day
   - sidereal planetary longitudes
   - ayanamsha
   - retrograde/motion state
   - house cusps / whole-sign house mapping
   - Vargas
   - transit positions

2. **Jyotiṣa interpretation layer**
   - Bhāva
   - Rāśi
   - Lagna
   - Bhāveśa
   - conjunctions
   - multi-planet clusters
   - aspects
   - dignity
   - combustion
   - Graha Yuddha
   - Shadbala
   - Ashtakavarga
   - Nakṣatra
   - Vimśottarī Daśā
   - yogas
   - predictive synthesis
   - event windows
   - explanation and provenance

The astronomical layer must never silently change the interpretation layer.

The interpretation layer must never silently alter astronomical calculations.

---

# 1. Design Principle

The system must answer:

> **What does the chart contain, which rules detect it, how strong is it, what modifies it, when is it activated, and what evidence supports the conclusion?**

It must NOT behave like:

> Input birth details → opaque score → prediction.

Every prediction must be traceable to structured evidence.

---

# 2. Six-Volume System Architecture

| Volume | Role |
|---|---|
| Volume 1 | Classical research foundation |
| Volume 2 | Two-planet conjunction database |
| Volume 3 | Multi-planet conjunction database |
| Volume 4 | Degree-sensitive astronomical/astrological calculations |
| Volume 5 | Predictive synthesis engine |
| **Volume 6** | **Automated interpreter + API + execution architecture** |

Future implementation may add:

- Volume 7 — UI / Chart Visualization / Practitioner Workspace
- Volume 8 — Backtesting / Statistical Validation
- Volume 9 — Rectification / Event Matching
- Volume 10 — Production Knowledge Graph

---

# 3. Technology Stack

Recommended reference stack:

```text
Python 3.11+
FastAPI
Pydantic v2
Swiss Ephemeris
PostgreSQL
SQLAlchemy
Alembic
Redis
Celery or ARQ
pytest
httpx
Docker
```

FastAPI is appropriate because request and response models can be declared with Pydantic, and FastAPI generates OpenAPI/JSON Schema documentation automatically. Its interactive documentation is exposed through `/docs`, with the OpenAPI schema available through `/openapi.json`. [FASTAPI-01] [FASTAPI-02] [FASTAPI-03]

Swiss Ephemeris provides astronomical calculation functions and supports sidereal modes including Lahiri variants. The implementation must explicitly store which sidereal mode is used rather than assuming that all "Lahiri" calculations are interchangeable. [SE-01] [SE-02]

---

# 4. Non-Negotiable Versioning

Every calculation must carry:

```json
{
  "engine_version": "6.0.0",
  "rule_set_version": "jyotisha-rules-1.0.0",
  "ephemeris_version": "swisseph-x.x",
  "ayanamsha": "LAHIRI_ICRC",
  "house_system": "WHOLE_SIGN",
  "node_mode": "TRUE_NODE",
  "aspect_system": "PARASHARI",
  "dasha_system": "VIMSHOTTARI"
}
```

Never produce an interpretation without recording these settings.

---

# 5. Configuration Object

```json
{
  "calculation": {
    "zodiac": "SIDEREAL",
    "ayanamsha": "LAHIRI_ICRC",
    "house_system": "WHOLE_SIGN",
    "node_type": "TRUE",
    "ephemeris": "SWISS_EPHEMERIS"
  },
  "interpretation": {
    "aspect_system": "PARASHARI",
    "use_graha_yuddha": true,
    "use_combustion": true,
    "use_retrogression": true,
    "use_shadbala": true,
    "use_ashtakavarga": true,
    "use_vargas": true
  },
  "dasha": {
    "system": "VIMSHOTTARI",
    "year_basis": "365.2425"
  }
}
```

The engine must reject unsupported combinations instead of silently falling back.

---

# 6. Birth Input Contract

```json
{
  "birth": {
    "date": "1983-10-25",
    "time": "14:35:20",
    "timezone": "Asia/Kolkata",
    "latitude": 27.123456,
    "longitude": 78.123456,
    "location_name": "Agra"
  }
}
```

Required:

- date
- time
- timezone
- latitude
- longitude

Optional:

- location name
- altitude
- source identifier
- birth-time confidence
- rectification metadata

---

# 7. Birth-Time Quality Model

```json
{
  "time_quality": {
    "source": "birth_certificate",
    "precision": "minute",
    "reported_time": "14:35",
    "uncertainty_minutes": 2,
    "confidence": "HIGH"
  }
}
```

Allowed confidence:

```text
EXACT
HIGH
MEDIUM
LOW
UNKNOWN
```

The interpreter must propagate birth-time uncertainty into:

- Lagna degree
- Bhāva boundaries where applicable
- Navāṃśa
- divisional charts
- Daśā balance
- event timing

---

# 8. Calculation Pipeline

```text
INPUT
  ↓
Validate birth data
  ↓
Normalize timezone
  ↓
UTC timestamp
  ↓
Julian Day
  ↓
Ephemeris calculation
  ↓
Tropical positions
  ↓
Ayanamsha
  ↓
Sidereal positions
  ↓
Lagna / Ascendant
  ↓
House mapping
  ↓
Nakṣatra / Pāda
  ↓
Planetary state
  ↓
Conjunction graph
  ↓
Dignity / combustion / war / retrogression
  ↓
Vargas
  ↓
Aspects
  ↓
Shadbala / Bhāva Bala
  ↓
Ashtakavarga
  ↓
Daśā
  ↓
Yoga detection
  ↓
Rule engine
  ↓
Predictive synthesis
  ↓
Explanation graph
  ↓
API response
```

---

# 9. Astronomical Engine Interface

```python
class EphemerisEngine:
    def planetary_position(
        self,
        datetime_utc,
        body,
        sidereal=True,
        ayanamsha="LAHIRI_ICRC"
    ):
        ...

    def ascendant(
        self,
        datetime_utc,
        latitude,
        longitude,
        house_system="WHOLE_SIGN"
    ):
        ...

    def houses(self, ...):
        ...

    def speed(self, ...):
        ...

    def declination(self, ...):
        ...
```

The astronomy engine returns raw calculations only.

Example:

```json
{
  "body": "JUPITER",
  "longitude": 121.583421,
  "latitude": 0.742,
  "speed_longitude": 0.0834,
  "retrograde": false
}
```

---

# 10. Planetary Normalized Record

Each planet becomes:

```json
{
  "planet": "JUPITER",
  "longitude": 121.583421,
  "sign": "LEO",
  "sign_degree": 1.583421,
  "house": 5,
  "nakshatra": "MAGHA",
  "pada": 1,
  "nakshatra_lord": "KETU",
  "retrograde": false,
  "combust": false,
  "planetary_war": null,
  "dignity": "NEUTRAL",
  "motion": "DIRECT"
}
```

---

# 11. Canonical Planet IDs

```text
SUN
MOON
MARS
MERCURY
JUPITER
VENUS
SATURN
RAHU
KETU
LAGNA
```

Lagna is treated as an angular reference, not as a physical planet.

---

# 12. Sign Model

```json
{
  "sign": "ARIES",
  "index": 0,
  "lord": "MARS",
  "element": "FIRE",
  "modality": "MOVABLE",
  "gender": "MASCULINE"
}
```

The canonical sign registry must contain all 12 rāśis.

---

# 13. House Model

```json
{
  "house": 10,
  "name_sanskrit": "KARMA",
  "domains": [
    "profession",
    "authority",
    "reputation",
    "visible_action"
  ],
  "lord": "SATURN"
}
```

The house lord depends on the Lagna and therefore must be computed, never hard-coded per chart.

---

# 14. Lagna Engine

Input:

```text
Ascendant longitude
```

Output:

```json
{
  "lagna_sign": "CAPRICORN",
  "lagna_degree": 14.3821,
  "lagna_lord": "SATURN",
  "house_signs": {
    "1": "CAPRICORN",
    "2": "AQUARIUS",
    "3": "PISCES",
    "4": "ARIES",
    "5": "TAURUS",
    "6": "GEMINI",
    "7": "CANCER",
    "8": "LEO",
    "9": "VIRGO",
    "10": "LIBRA",
    "11": "SCORPIO",
    "12": "SAGITTARIUS"
  }
}
```

---

# 15. Conjunction Detection

A conjunction must not be represented only as:

```json
{
  "planets": ["SUN", "MARS"]
}
```

It must contain exact geometry:

```json
{
  "pair_id": "P02",
  "planets": ["SUN", "MARS"],
  "separation": 3.7421,
  "applying": true,
  "same_sign": true,
  "same_house": true,
  "orb_policy": "RULE_SET_1"
}
```

---

# 16. Pair Database Integration

The 21 canonical pair IDs from Volume 2 remain stable.

```text
P01 Sun–Moon
P02 Sun–Mars
P03 Sun–Mercury
P04 Sun–Jupiter
P05 Sun–Venus
P06 Sun–Saturn
P07 Moon–Mars
P08 Moon–Mercury
P09 Moon–Jupiter
P10 Moon–Venus
P11 Moon–Saturn
P12 Mars–Mercury
P13 Mars–Jupiter
P14 Mars–Venus
P15 Mars–Saturn
P16 Mercury–Jupiter
P17 Mercury–Venus
P18 Mercury–Saturn
P19 Jupiter–Venus
P20 Jupiter–Saturn
P21 Venus–Saturn
```

Rahu/Ketu combinations are separate node rules and should not corrupt the canonical seven-planet pair registry.

---

# 17. Multi-Planet Cluster Engine

Given planets:

```text
Sun + Mercury + Venus + Saturn
```

the engine generates:

```text
P03 Sun–Mercury
P05 Sun–Venus
P06 Sun–Saturn
P17 Mercury–Venus
P18 Mercury–Saturn
P21 Venus–Saturn
```

and additionally creates:

```json
{
  "cluster_id": "C_4_001",
  "planets": ["SUN", "MERCURY", "VENUS", "SATURN"],
  "size": 4,
  "pair_edges": 6,
  "degree_span": 12.438,
  "center_longitude": 201.27
}
```

This is a graph problem:

```text
Planet = node
Conjunction = edge
Cluster = connected component
```

---

# 18. Cluster Compression

The engine must calculate:

- cluster size
- degree span
- nearest pair
- widest pair
- central planet
- dispositor
- dominant dignity
- combustion
- retrograde count
- node involvement
- house concentration
- sign concentration

Example:

```json
{
  "cluster_strength": {
    "compactness": 0.82,
    "dignity_coherence": 0.66,
    "house_coherence": 1.0,
    "activation_potential": 0.73
  }
}
```

These values are engineering diagnostics, not classical scores.

---

# 19. Classical vs Derived vs Synthetic

Every rule must carry:

```json
{
  "rule_id": "PD18-12",
  "classification": "DIRECT_CLASSICAL",
  "source": "PHALADIPIKA",
  "chapter": 18,
  "verse": null,
  "interpretation": "..."
}
```

Allowed classifications:

```text
DIRECT_CLASSICAL
CLASSICAL_DERIVED
MULTI_SOURCE_CONVERGENCE
SYSTEMATIC_SYNTHESIS
CONFIGURABLE_TRADITION
ENGINEERING_HEURISTIC
INSUFFICIENT_INPUT
```

No engineering heuristic may be presented as scripture.

---

# 20. Rule Registry

Example:

```json
{
  "rule_id": "BHAVA-10-001",
  "domain": "CAREER",
  "input": [
    "house_10",
    "house_10_lord",
    "occupants_10",
    "aspects_10",
    "dasha"
  ],
  "classification": "CLASSICAL_DERIVED",
  "priority": 70,
  "enabled": true
}
```

---

# 21. Rule Execution Contract

```python
class Rule:
    id: str
    name: str
    classification: str
    priority: int

    def applies(self, chart_context) -> bool:
        ...

    def evaluate(self, chart_context) -> dict:
        ...
```

The rule engine should never directly modify chart data.

Rules produce evidence.

---

# 22. Evidence Object

```json
{
  "evidence_id": "EV-000012",
  "rule_id": "P02-BHAVA10",
  "domain": "CAREER",
  "factor": "SUN_MARS_CONJUNCTION",
  "direction": "SUPPORTIVE",
  "strength": "MODERATE",
  "house": 10,
  "sign": "LEO",
  "class": "CLASSICAL_DERIVED",
  "explanation": "The conjunction links solar authority with Martian initiative in the tenth house.",
  "source_refs": [
    "PHALADIPIKA_CH18",
    "VOLUME2_P02"
  ]
}
```

---

# 23. Evidence Is Not Prediction

The engine first builds evidence:

```text
Evidence
  ↓
Synthesis
  ↓
Activation
  ↓
Timing
  ↓
Prediction
```

Never skip directly from a single rule to an event prediction.

---

# 24. Bhāva Evidence Engine

For each house:

```text
House
House sign
House lord
House lord placement
House lord dignity
Occupants
Occupant dignity
Aspects
Karaka
Relevant conjunctions
Vargas
Shadbala
Ashtakavarga
Dasha activation
Transit activation
```

Output:

```json
{
  "house": 10,
  "domain": "CAREER",
  "promise": [],
  "supporting_factors": [],
  "modifiers": [],
  "contradictions": [],
  "activation": []
}
```

---

# 25. Bhāveśa Chain

The interpreter recursively evaluates:

```text
10th house
  ↓
10th lord
  ↓
lord's sign
  ↓
sign lord / dispositor
  ↓
dispositor's house
  ↓
dispositor strength
  ↓
aspects
  ↓
Varga confirmation
```

Maximum recursion depth should be configurable.

Default:

```text
3 levels
```

This prevents runaway interpretive chains.

---

# 26. Dignity Engine

Dignity states:

```text
EXALTED
MOOLATRIKONA
OWN
FRIEND
NEUTRAL
ENEMY
DEBILITATED
COMBUST
RETROGRADE
VARGOTTAMA
```

These states should be stored independently.

Do not collapse all of them into one universal score.

---

# 27. Combustion Engine

For every applicable planet:

```json
{
  "planet": "MERCURY",
  "sun_distance": 4.82,
  "combust": true,
  "rule_version": "COMBUSTION-1.0"
}
```

Combustion thresholds must be versioned because different traditions/rules can use different thresholds.

---

# 28. Graha Yuddha Engine

For eligible planets:

```json
{
  "planet_a": "MARS",
  "planet_b": "VENUS",
  "eligible": true,
  "angular_separation": 0.31,
  "winner_rule": "CONFIGURED",
  "winner": "MARS"
}
```

The engine must retain both:

- geometric fact
- selected interpretive tradition

---

# 29. Retrogression

```json
{
  "planet": "SATURN",
  "retrograde": true,
  "speed_longitude": -0.0183
}
```

Retrogression is a state, not automatically a positive or negative modifier.

---

# 30. Aspect Engine

Default configuration:

```text
PARASHARI
```

Base rule:

- all planets aspect the 7th from themselves
- Mars has special 4th and 8th
- Jupiter has special 5th and 9th
- Saturn has special 3rd and 10th

Rahu/Ketu aspects must be configurable.

Output:

```json
{
  "from": "JUPITER",
  "to_house": 10,
  "aspect_type": "SPECIAL_10TH",
  "tradition": "PARASHARI"
}
```

---

# 31. Varga Engine

Minimum implementation target:

```text
D1  Rāśi
D2  Hora
D3  Drekkana
D4  Chaturthamsha
D7  Saptamsha
D9  Navamsha
D10 Dashamsha
D12 Dvadashamsha
D16 Shodashamsha
D20 Vimshamsha
D24 Chaturvimshamsha
D27 Bhamsa
D30 Trimshamsha
D40 Khavedamsha
D45 Akshavedamsha
D60 Shashtiamsha
```

Each Varga must be a separate calculation module.

---

# 32. Vargottama

```json
{
  "planet": "JUPITER",
  "rashi": "SAGITTARIUS",
  "navamsha": "SAGITTARIUS",
  "vargottama": true
}
```

Vargottama is evidence, not an automatic event guarantee.

---

# 33. Nakṣatra Engine

Output:

```json
{
  "planet": "MOON",
  "nakshatra": "ROHINI",
  "pada": 2,
  "lord": "MOON",
  "degree_within_nakshatra": 7.31
}
```

The Nakṣatra lord becomes a major input into Daśā calculation.

---

# 34. Vimśottarī Daśā Engine

Input:

```text
Moon longitude
Moon Nakṣatra
Nakṣatra lord
fraction elapsed
```

Output:

```json
{
  "birth_dasha": "VENUS",
  "remaining_fraction": 0.642,
  "remaining_years": 12.51
}
```

Then recursively generate:

```text
Mahadasha
  └── Antardasha
       └── Pratyantardasha
            └── Sookshma
```

Depth should be configurable.

---

# 35. Daśā Activation

A rule is activated when one or more of these are true:

```text
Mahadasha lord represents event house
Antardasha lord represents event house
Planet occupies event house
Planet owns event house
Planet is joined with event-house lord
Planet is strong in relevant Varga
Planet is activated by transit
```

Activation is evidence.

It does not guarantee manifestation.

---

# 36. Transit Engine

Input:

```json
{
  "date": "2027-03-01",
  "location": {
    "latitude": 27.17,
    "longitude": 78.04
  }
}
```

Calculate:

```text
Sun
Moon
Mars
Mercury
Jupiter
Venus
Saturn
Rahu
Ketu
```

Then test:

```text
transit → natal planet
transit → natal house
transit → natal house lord
transit → conjunction
transit → Lagna
transit → Moon
```

---

# 37. Transit Trigger Record

```json
{
  "transit": "JUPITER",
  "target": "NATAL_10TH_LORD",
  "aspect": "7TH",
  "orb": 0.84,
  "applying": true,
  "trigger_strength": "HIGH"
}
```

---

# 38. Ashtakavarga Engine

Store:

```text
Bhinna Ashtakavarga
Sarvashtakavarga
Shodhya Pinda
House bindus
Planet-specific bindus
```

Example:

```json
{
  "house": 10,
  "sarvashtakavarga": 34,
  "interpretive_band": "HIGHER_SUPPORT"
}
```

The actual interpretation must remain rule-set dependent.

---

# 39. Shadbala Engine

Architecture:

```text
Sthana Bala
Dig Bala
Kala Bala
Cheshta Bala
Naisargika Bala
Drik Bala
```

Output:

```json
{
  "planet": "JUPITER",
  "shadbala": {
    "sthana": 145.2,
    "dig": 33.4,
    "kala": 112.1,
    "cheshta": 14.2,
    "naisargika": 37.2,
    "drik": 18.1,
    "total": 360.2
  }
}
```

Store raw components before any normalized score.

---

# 40. Kāraka Engine

Minimum:

```text
Atmakaraka
Amatyakaraka
Bhratrikaraka
Matrikaraka
Putrakaraka
Gnatikaraka
Darakaraka
```

The selected Jaimini convention must be configurable.

Degrees must be calculated consistently according to the selected tradition.

---

# 41. Yoga Engine

Architecture:

```text
Yoga Registry
   ↓
Eligibility Test
   ↓
Planetary Conditions
   ↓
House Conditions
   ↓
Strength Conditions
   ↓
Cancellation / Modification
   ↓
Evidence
```

Example:

```json
{
  "yoga_id": "DHANA_001",
  "name": "Dhana Yoga",
  "present": true,
  "strength": "MODERATE",
  "conditions_met": [
    "2L_connected_to_11L",
    "both_planets_have_required_strength"
  ]
}
```

---

# 42. Yoga Cancellation

A yoga should have:

```text
primary conditions
support conditions
cancellation conditions
modification conditions
activation conditions
```

This avoids the common software error:

```text
Yoga found = guaranteed result
```

---

# 43. Event Domain Registry

```json
[
  "IDENTITY",
  "WEALTH",
  "EDUCATION",
  "COMMUNICATION",
  "HOME_PROPERTY",
  "CHILDREN_CREATIVITY",
  "HEALTH_SERVICE",
  "MARRIAGE_PARTNERSHIP",
  "TRANSFORMATION",
  "FORTUNE_HIGHER_LEARNING",
  "CAREER",
  "GAINS_NETWORK",
  "FOREIGN_RETREAT"
]
```

---

# 44. Event Model

```json
{
  "event_id": "CAREER_001",
  "domain": "CAREER",
  "subdomain": "PROMOTION",
  "promise": [],
  "evidence": [],
  "modifiers": [],
  "contradictions": [],
  "activation": [],
  "timing": [],
  "confidence": "MODERATE",
  "status": "ACTIVATED"
}
```

---

# 45. Prediction Statuses

```text
NOT_SUPPORTED
NATAL_PROMISE
SUPPORTED
ACTIVATED
TIMING_WINDOW
CONFIRMED_BY_TRANSIT
CONFLICTED
INSUFFICIENT_DATA
```

These are states, not numerical rankings.

---

# 46. Prediction Confidence

Do not expose a fake percentage such as:

```text
87% promotion
```

Instead use evidence states:

```text
LOW
MODERATE
STRONG
VERY_STRONG
CONFLICTED
INSUFFICIENT
```

Internally the engine may maintain component measurements, but these must not be presented as empirically calibrated probabilities unless a separate statistical validation system establishes that calibration.

---

# 47. Conflict Engine

Example:

```text
Career-supporting factors:
+ 10th lord strong
+ Jupiter activates 10th
+ D10 confirmation

Career-modifying factors:
- 10th lord combust
- Saturn affliction
- weak Ashtakavarga

Result:
CONFLICTED_SUPPORT
```

The system must retain both sides.

---

# 48. Convergence Engine

A high-quality event hypothesis requires convergence across independent layers.

Example:

```text
Natal promise
+
Bhāva lord support
+
Conjunction support
+
Dasha activation
+
Varga confirmation
+
Transit trigger
=
TIMING WINDOW
```

No single conjunction should independently create a major life-event prediction.

---

# 49. Prediction Pipeline

```text
Chart
 ↓
Structural interpretation
 ↓
Natal promises
 ↓
Event hypotheses
 ↓
Strength/modification
 ↓
Daśā activation
 ↓
Transit activation
 ↓
Varga confirmation
 ↓
Ashtakavarga confirmation
 ↓
Conflict resolution
 ↓
Timing window
 ↓
Explanation
 ↓
Prediction response
```

---

# 50. API Architecture

```text
/api/v1
    /charts
    /charts/{chart_id}
    /calculate
    /interpret
    /predictions
    /predictions/{prediction_id}
    /transits
    /dashas
    /conjunctions
    /vargas
    /rules
    /sources
    /health
```

---

# 51. POST /charts

Request:

```json
{
  "name": "Example",
  "birth": {
    "date": "1983-10-25",
    "time": "14:35:20",
    "timezone": "Asia/Kolkata",
    "latitude": 27.17,
    "longitude": 78.04
  },
  "configuration": {
    "ayanamsha": "LAHIRI_ICRC"
  }
}
```

Response:

```json
{
  "chart_id": "CHT_01J...",
  "status": "CALCULATED",
  "engine_version": "6.0.0"
}
```

---

# 52. POST /calculate

Purpose:

Return deterministic chart mathematics without interpretation.

```json
{
  "chart_id": "CHT_01J..."
}
```

Response includes:

```text
planetary positions
houses
Lagna
nakshatras
Vargas
aspects
conjunctions
dignity
combustion
retrogression
Graha Yuddha
Shadbala
Ashtakavarga
Daśā
```

---

# 53. POST /interpret

Purpose:

Convert calculated chart data into structured evidence.

```json
{
  "chart_id": "CHT_01J...",
  "domains": [
    "CAREER",
    "WEALTH",
    "MARRIAGE"
  ]
}
```

Response:

```json
{
  "interpretation_id": "INT_...",
  "domains": [],
  "evidence": [],
  "conflicts": [],
  "sources": []
}
```

---

# 54. POST /predictions

Request:

```json
{
  "chart_id": "CHT_01J...",
  "date_from": "2027-01-01",
  "date_to": "2028-12-31",
  "domains": ["CAREER"],
  "include_transits": true,
  "include_dasha": true
}
```

Response:

```json
{
  "prediction_run_id": "RUN_...",
  "windows": [],
  "explanation_graph": {},
  "audit_log": []
}
```

---

# 55. GET /charts/{chart_id}

Returns complete chart object.

Must include:

```text
input
calculation settings
calculation version
planetary positions
houses
Vargas
Daśā
rule-set version
```

---

# 56. GET /dashas/{chart_id}

Returns:

```json
{
  "mahadasha": [],
  "antardasha": [],
  "pratyantardasha": []
}
```

Each period:

```json
{
  "lord": "JUPITER",
  "start": "2028-02-01",
  "end": "2030-04-10",
  "activation": []
}
```

---

# 57. GET /conjunctions/{chart_id}

Returns:

```text
pairwise conjunctions
multi-planet clusters
degree separations
house/sign
dignity
combustion
Graha Yuddha
retrogression
source references
```

---

# 58. GET /rules

Query:

```text
domain
classification
source
enabled
version
```

Example:

```text
/rules?classification=DIRECT_CLASSICAL
```

---

# 59. GET /sources

Returns:

```json
{
  "source_id": "PHALADIPIKA",
  "edition": "...",
  "chapter": 18,
  "reference": "...",
  "classification": "PRIMARY_SOURCE"
}
```

---

# 60. Explanation API

Every prediction must support:

```text
GET /predictions/{id}/explanation
```

Example response:

```json
{
  "claim": "Career activity is strongly activated during this period.",
  "support": [
    {
      "factor": "10th lord",
      "effect": "supportive"
    },
    {
      "factor": "Mahadasha",
      "effect": "activating"
    },
    {
      "factor": "Transit",
      "effect": "confirming"
    }
  ],
  "modifiers": [],
  "contradictions": [],
  "source_refs": []
}
```

---

# 61. Explanation Graph

Graph:

```text
Prediction
   ↓
Event
   ↓
Activation
   ↓
Dasha
   ↓
Planet
   ↓
House
   ↓
Conjunction
   ↓
Rule
   ↓
Classical Source
```

Every node gets a stable ID.

This enables UI visualization later.

---

# 62. Rule Trace

Example:

```json
{
  "trace_id": "TRACE-0001",
  "steps": [
    {
      "rule": "BHAVA-10-001",
      "result": true
    },
    {
      "rule": "P03-BHAVA10",
      "result": true
    },
    {
      "rule": "DASHA-10-003",
      "result": true
    },
    {
      "rule": "TRANSIT-JUPITER-10",
      "result": true
    }
  ]
}
```

This is essential for debugging.

---

# 63. Prediction Audit Log

```json
{
  "run_id": "RUN-001",
  "timestamp": "2026-10-03T22:00:00+05:30",
  "engine_version": "6.0.0",
  "rule_set": "1.0.0",
  "inputs_hash": "...",
  "calculation_hash": "...",
  "rules_executed": 342,
  "rules_triggered": 67,
  "rules_conflicted": 12
}
```

The same input + same versions should produce the same deterministic result.

---

# 64. Idempotency

Requests should support:

```http
Idempotency-Key: <uuid>
```

Repeated requests must not create duplicate chart records or prediction runs.

---

# 65. Chart Fingerprint

Create:

```text
chart_hash =
SHA256(
 normalized_birth_input
 + calculation_config
 + ephemeris_version
)
```

This allows:

- caching
- reproducibility
- duplicate detection
- auditability

---

# 66. Database Architecture

PostgreSQL recommended.

Core tables:

```text
charts
birth_data
calculation_configs
planet_positions
houses
vargas
nakshatras
conjunctions
conjunction_clusters
aspects
dignities
combustions
planetary_wars
shadbala
ashtakavarga
dashas
yogas
rules
rule_sources
evidence
predictions
prediction_windows
prediction_traces
audit_logs
```

---

# 67. Relational Keys

Every major object gets:

```text
id
chart_id
version
created_at
updated_at
```

Rule-generated objects additionally get:

```text
rule_id
rule_set_version
source_refs
```

---

# 68. Rule Database

Suggested schema:

```sql
CREATE TABLE rules (
    rule_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    domain TEXT NOT NULL,
    classification TEXT NOT NULL,
    priority INTEGER NOT NULL,
    version TEXT NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    definition JSONB NOT NULL
);
```

---

# 69. Source Database

```sql
CREATE TABLE rule_sources (
    rule_id TEXT NOT NULL,
    source_id TEXT NOT NULL,
    chapter TEXT,
    verse TEXT,
    page TEXT,
    note TEXT
);
```

Do not store unsupported quotations as if they were verified.

---

# 70. Pydantic Input Models

Example:

```python
from pydantic import BaseModel, Field

class BirthData(BaseModel):
    date: str
    time: str
    timezone: str
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
```

Production implementation should use strict date/time types where practical.

FastAPI's Pydantic integration supports validation and JSON Schema generation for request and response models. [FASTAPI-03]

---

# 71. Strict Input Validation

Reject:

```text
invalid latitude
invalid longitude
unknown timezone
invalid date
invalid time
unsupported ayanamsha
unsupported house system
missing required birth data
```

Never silently substitute:

```text
India → IST
Agra → guessed coordinates
Lahiri → arbitrary Lahiri variant
```

unless the caller explicitly enables fallback behavior.

---

# 72. Error Contract

```json
{
  "error": {
    "code": "INVALID_BIRTH_TIMEZONE",
    "message": "The supplied timezone is not recognized.",
    "field": "birth.timezone",
    "details": {}
  },
  "request_id": "REQ_..."
}
```

Canonical error codes should be versioned.

---

# 73. API Security

Minimum:

```text
API key / OAuth2
rate limiting
request size limits
input validation
audit logging
CORS policy
secret management
HTTPS in production
```

Do not expose database credentials or ephemeris paths through API responses.

---

# 74. Privacy

Birth data is highly personal.

Store only what is required.

Recommended:

```text
PII encryption at rest
database encryption
TLS
access control
audit log
data deletion endpoint
retention policy
```

A public API should not expose one user's chart through predictable IDs.

---

# 75. Caching

Cache deterministic calculations:

```text
chart calculation
Varga calculation
Dasha calculation
natal conjunction graph
```

Cache key:

```text
chart_hash + engine_version + rule_set_version
```

Transit calculations may use:

```text
date + location + ephemeris_version + configuration
```

---

# 76. Background Jobs

Use a worker for expensive requests:

```text
POST /predictions
        ↓
queue
        ↓
worker
        ↓
calculation
        ↓
interpretation
        ↓
prediction
        ↓
database
```

Small chart calculations may remain synchronous.

---

# 77. API Response Size

Do not return the entire rule trace by default.

Use:

```text
?detail=summary
?detail=full
?include_sources=true
?include_trace=true
```

This prevents enormous JSON responses.

---

# 78. Summary Response

```json
{
  "chart_id": "CHT...",
  "lagna": "CAPRICORN",
  "moon_sign": "TAURUS",
  "current_dasha": {
    "mahadasha": "JUPITER",
    "antardasha": "SATURN"
  },
  "domains": {
    "career": "ACTIVATED",
    "wealth": "SUPPORTED",
    "marriage": "CONFLICTED"
  }
}
```

This is a summary, not a prediction verdict.

---

# 79. Full Response

```json
{
  "chart": {},
  "calculation": {},
  "interpretation": {},
  "evidence": [],
  "predictions": [],
  "timing_windows": [],
  "sources": [],
  "audit": {}
}
```

---

# 80. Natural-Language Renderer

The API should first create structured facts.

Only afterward:

```text
structured evidence
      ↓
prediction object
      ↓
language renderer
```

This prevents the LLM from inventing astrology calculations.

---

# 81. LLM Integration Rule

If an LLM is used:

```text
LLM = explanation layer
NOT calculation authority
```

The LLM receives:

```json
{
  "chart_facts": {},
  "evidence": [],
  "rules": [],
  "sources": [],
  "prediction": {}
}
```

It does not receive permission to change:

- planetary longitude
- house
- dasha date
- aspect geometry
- source classification
- rule outcome

---

# 82. Structured-to-Text Prompt

Example:

```text
You are an astrology explanation renderer.

Use ONLY the supplied structured evidence.

Do not invent:
- planetary positions
- rules
- sources
- dates
- yogas

Clearly distinguish:
1. classical evidence
2. derived synthesis
3. configurable tradition
4. uncertainty

Do not convert an interpretive state into a certainty claim.
```

---

# 83. Prediction Language Templates

Instead of:

> You will definitely get promoted.

Use:

> The chart shows career-related activation during this period. The main supporting factors are X, Y and Z. The timing is supported by A and B, while C acts as a modifying factor.

This preserves evidence and uncertainty.

---

# 84. Career Interpreter

Primary:

```text
10th house
10th lord
Sun
Saturn
Amatyakaraka
D10
6th house
11th house
```

Secondary:

```text
2nd house
9th house
relevant conjunctions
Daśā
transits
Ashtakavarga
```

---

# 85. Wealth Interpreter

Primary:

```text
2nd
11th
2nd lord
11th lord
Jupiter
Venus
D2
Dasha
```

Secondary:

```text
5th
9th
8th
10th
```

---

# 86. Marriage Interpreter

Primary:

```text
7th house
7th lord
Venus
Darakaraka
Navamsha
Upapada where configured
```

Secondary:

```text
2nd
5th
8th
11th
Moon
Daśā
transits
```

---

# 87. Education Interpreter

Primary:

```text
4th
5th
9th
Mercury
Jupiter
D24
```

Secondary:

```text
Moon
2nd
Dasha
```

---

# 88. Property Interpreter

Primary:

```text
4th
4th lord
Moon
Mars
D4
```

Secondary:

```text
2nd
8th
10th
11th
Daśā
transits
```

---

# 89. Foreign Travel / Residence

Primary:

```text
12th
12th lord
9th
9th lord
Rahu
Moon
Dasha
transits
```

Secondary:

```text
4th / 4th lord
7th
```

The engine must distinguish:

```text
foreign travel
foreign stay
foreign residence
foreign career
retreat/isolation
```

They are not equivalent.

---

# 90. Health / Service

The engine may describe traditional astrological indicators involving:

```text
1st
6th
8th
12th
Lagna lord
Sun
Moon
relevant Vargas
Daśā
```

It must not present astrology as a medical diagnosis or substitute for medical evaluation.

---

# 91. Prediction Window Algorithm

For every event domain:

```text
1. establish natal promise
2. identify activating planets
3. generate dasha windows
4. generate transit windows
5. intersect windows
6. apply strength/modifier filters
7. rank by evidence state
8. preserve conflicts
```

Do not call the result a calibrated probability.

---

# 92. Window Representation

```json
{
  "start": "2028-04-15",
  "end": "2028-08-22",
  "event_domain": "CAREER",
  "activation": [
    "JUPITER_MD",
    "SATURN_AD",
    "JUPITER_TRANSIT_10TH"
  ],
  "status": "TIMING_WINDOW"
}
```

---

# 93. Applying vs Separating Transit

Store:

```json
{
  "orb": 1.21,
  "applying": true,
  "exact_date": "2028-06-14",
  "separating_date": "2028-06-29"
}
```

This enables more precise windows without pretending that one exact day is guaranteed.

---

# 94. Birth-Time Sensitivity Engine

Run:

```text
T - 5 min
T - 2 min
T
T + 2 min
T + 5 min
```

Compare:

```text
Lagna
Bhāva
D9
D10
D60
Daśā boundaries
prediction windows
```

Output:

```json
{
  "stable": [
    "Moon sign",
    "Sun sign"
  ],
  "sensitive": [
    "D10 Lagna",
    "D60"
  ]
}
```

---

# 95. Rectification Interface

Input:

```json
{
  "candidate_times": [],
  "known_events": [
    {
      "date": "2012-06-10",
      "domain": "CAREER"
    }
  ]
}
```

Output:

```text
candidate chart
event activation
match evidence
```

This module belongs in Volume 6 architecture but should not claim statistical validity until Volume 8 backtesting.

---

# 96. Backtesting Interface

```http
POST /backtest
```

Input:

```json
{
  "charts": [],
  "events": [],
  "rule_set": "1.0.0"
}
```

Output:

```json
{
  "sample_size": 100,
  "metrics": {},
  "false_positive_rate": null,
  "calibration": null
}
```

No metric should be invented before testing.

---

# 97. Test Strategy

Four levels:

```text
Unit tests
Integration tests
Golden-chart tests
Property tests
```

---

# 98. Unit Tests

Examples:

```text
test_sign_from_longitude()
test_house_from_sign()
test_nakshatra_from_longitude()
test_pada_from_longitude()
test_conjunction_separation()
test_retrograde_detection()
test_dasha_balance()
test_vargottama()
```

---

# 99. Golden Chart Tests

Maintain known charts with frozen:

```text
birth input
configuration
planet positions
Lagna
houses
Vargas
Dasha
conjunctions
```

Any library upgrade must compare output against the golden fixtures.

---

# 100. Regression Testing

Before deployment:

```text
old engine
vs
new engine
```

Compare:

```text
planet longitude
house
Varga
dasha dates
conjunction membership
rule results
prediction windows
```

Allow only explicitly documented changes.

---

# 101. Property-Based Tests

Examples:

```text
longitude always in [0, 360)
sign always in 12 signs
nakshatra always in 27
pada always 1–4
house always 1–12
Varga sign always valid
Dasha periods do not overlap
cluster pair count = n(n-1)/2
```

For a cluster of `n` planets:

```text
pairs = n(n-1)/2
```

---

# 102. API Contract Testing

Test:

```text
valid request → 200
invalid request → 422
missing chart → 404
unsupported config → 400
internal calculation failure → 500
```

Response schemas must remain stable across patch versions.

---

# 103. Determinism Test

Same:

```text
birth data
configuration
ephemeris
rule set
```

must generate:

```text
same planetary positions
same houses
same evidence
same prediction windows
```

If not, the engine has a reproducibility defect.

---

# 104. Source Integrity Test

Every classical claim must resolve to:

```text
source_id
chapter
verse/page where available
rule_id
```

No orphaned classical claims.

---

# 105. Rule Coverage Test

Generate a report:

```text
total rules
enabled rules
disabled rules
rules without source
rules without tests
rules without explanation
```

Target:

```text
0 production rules without tests
0 DIRECT_CLASSICAL rules without source reference
```

---

# 106. API Project Structure

```text
vedic_engine/
│
├── app/
│   ├── main.py
│   ├── config.py
│   ├── dependencies.py
│   │
│   ├── api/
│   │   └── v1/
│   │       ├── charts.py
│   │       ├── calculate.py
│   │       ├── interpret.py
│   │       ├── predictions.py
│   │       ├── dashas.py
│   │       ├── transits.py
│   │       ├── conjunctions.py
│   │       ├── rules.py
│   │       └── sources.py
│   │
│   ├── schemas/
│   ├── astronomy/
│   ├── astrology/
│   ├── rules/
│   ├── synthesis/
│   ├── timing/
│   ├── explanation/
│   ├── persistence/
│   └── services/
│
├── tests/
├── migrations/
├── rule_data/
├── source_data/
├── Dockerfile
├── docker-compose.yml
├── pyproject.toml
└── README.md
```

---

# 107. Service Separation

Recommended services:

```text
API Service
Calculation Service
Rule Engine
Prediction Service
Worker
PostgreSQL
Redis
```

For an initial local build, these can run in one Python process.

Scale only after correctness is established.

---

# 108. Local Development Mode

Recommended:

```text
FastAPI
SQLite/PostgreSQL
local Swiss Ephemeris
pytest
uvicorn
```

Run:

```bash
uvicorn app.main:app --reload
```

FastAPI provides interactive API documentation at `/docs` and an OpenAPI schema at `/openapi.json`. [FASTAPI-01] [FASTAPI-02]

---

# 109. Docker Architecture

```text
docker-compose
│
├── api
├── worker
├── postgres
└── redis
```

Optional:

```text
nginx
```

Only introduce Nginx when deployment requires it.

---

# 110. Docker Health Checks

```text
GET /health
GET /ready
```

Example:

```json
{
  "status": "ready",
  "database": "ok",
  "ephemeris": "ok",
  "rules": "ok"
}
```

---

# 111. Observability

Record:

```text
request ID
chart ID
calculation duration
rule execution duration
prediction duration
database duration
errors
```

Never log raw birth data unnecessarily.

---

# 112. Performance Targets

Initial engineering targets:

```text
basic chart calculation: < 1 second
full interpretation: < 3 seconds
short prediction window: < 5 seconds
long transit scan: asynchronous
```

These are engineering targets, not guaranteed measurements.

---

# 113. Parallelization

Independent calculations can run concurrently:

```text
D1
D2
D3
D9
D10
D12
D60
```

Likewise:

```text
Aspects
Conjunctions
Dignity
Nakshatra
Shadbala
```

Do not parallelize operations that depend on earlier results.

---

# 114. Calculation DAG

```text
Birth Input
   ↓
Ephemeris
   ├── Planet Positions
   ├── Motion
   └── Ayanamsha
          ↓
       D1 Chart
       ├── Houses
       ├── Nakshatra
       ├── Conjunctions
       ├── Aspects
       ├── Dignity
       └── Planetary States
             ↓
          Vargas
             ↓
          Strength
             ↓
          Daśā
             ↓
          Rules
             ↓
          Synthesis
             ↓
          Prediction
```

---

# 115. Knowledge Graph Model

Entities:

```text
Planet
Sign
House
Nakshatra
Varga
Yoga
Rule
Source
Dasha
Transit
Event
Prediction
```

Relationships:

```text
PLANET → OCCUPIES → HOUSE
PLANET → IN → SIGN
PLANET → LORDS → HOUSE
PLANET → ASPECTS → HOUSE
PLANET → CONJOINS → PLANET
PLANET → ACTIVATES → EVENT
RULE → SUPPORTED_BY → SOURCE
PREDICTION → DERIVED_FROM → EVIDENCE
```

This can later be migrated to a graph database if needed.

---

# 116. LLM-Friendly Context Object

For an LLM explanation call:

```json
{
  "chart_summary": {},
  "event_domain": "CAREER",
  "natal_promise": [],
  "supporting_evidence": [],
  "modifiers": [],
  "contradictions": [],
  "activation": [],
  "timing": [],
  "sources": [],
  "language": "en-IN"
}
```

---

# 117. Multilingual Renderer

Future support:

```text
English
Hindi
Sanskrit terminology
```

Keep canonical internal identifiers in English.

Example:

```json
{
  "canonical": "CAREER",
  "hi": "करियर / व्यवसाय",
  "sa": "कर्म"
}
```

Do not translate identifiers used in APIs.

---

# 118. Frontend Contract

Future UI can consume:

```text
/chart
/planet
/conjunction
/bhava
/dasha
/transit
/prediction
/explanation
```

Suggested screens:

```text
1. Birth Input
2. D1 Chart
3. Planet Table
4. Conjunction Graph
5. Vargas
6. Strength
7. Yogas
8. Dasha Timeline
9. Transit Timeline
10. Prediction Dashboard
11. Explanation / Rule Trace
12. Sources
```

---

# 119. Conjunction Graph UI

Example:

```text
        SUN
       /   \
    MARS  MERCURY
       \   /
      JUPITER
```

Node:

```text
planet
sign
house
degree
strength
```

Edge:

```text
pair ID
degree separation
rule evidence
```

---

# 120. Prediction Dashboard

Each event domain:

```text
CAREER
WEALTH
MARRIAGE
PROPERTY
EDUCATION
FOREIGN
```

Display:

```text
Natal Promise
Current Activation
Upcoming Window
Supporting Evidence
Modifying Evidence
Conflicts
Sources
```

Never display an unexplained score as the primary conclusion.

---

# 121. API Example

```bash
curl -X POST http://localhost:8000/api/v1/charts \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Example",
    "birth": {
      "date": "1983-10-25",
      "time": "14:35:20",
      "timezone": "Asia/Kolkata",
      "latitude": 27.17,
      "longitude": 78.04
    }
  }'
```

---

# 122. Interpretation Example

```bash
curl -X POST http://localhost:8000/api/v1/interpret \
  -H "Content-Type: application/json" \
  -d '{
    "chart_id": "CHT_01",
    "domains": ["CAREER", "WEALTH"]
  }'
```

---

# 123. Prediction Example

```bash
curl -X POST http://localhost:8000/api/v1/predictions \
  -H "Content-Type: application/json" \
  -d '{
    "chart_id": "CHT_01",
    "date_from": "2027-01-01",
    "date_to": "2028-12-31",
    "domains": ["CAREER"]
  }'
```

---

# 124. Example End-to-End Processing

Input:

```text
Birth data
```

Engine discovers:

```text
10th house
10th lord
Sun
Saturn
D10
career conjunctions
current Mahadasha
current Antardasha
Jupiter transit
Saturn transit
```

Then:

```text
Rule evidence
     ↓
Career promise
     ↓
Career activation
     ↓
Timing intersection
     ↓
Explanation
```

The output should identify the chain rather than merely state an outcome.

---

# 125. Rule Priority

Suggested execution order:

```text
100 — astronomical facts
90  — house/sign/lord calculations
80  — conjunction/aspect geometry
70  — classical yoga rules
60  — strength rules
50  — dasha activation
40  — transit activation
30  — synthesis
20  — language rendering
```

Priority controls processing order, not truth.

---

# 126. Rule Conflict Policy

If two rules conflict:

```text
1. preserve both
2. inspect classification
3. inspect source authority
4. inspect applicability
5. inspect strength/modifiers
6. mark unresolved conflict if necessary
```

Do not silently discard a conflicting rule.

---

# 127. Source Hierarchy

Recommended metadata hierarchy:

```text
PRIMARY CLASSICAL SOURCE
      ↓
COMMENTARY / TRADITIONAL INTERPRETATION
      ↓
CLASSICAL DERIVATION
      ↓
SYSTEMATIC SYNTHESIS
      ↓
ENGINEERING HEURISTIC
```

The hierarchy is a provenance mechanism, not a universal claim about every historical school.

---

# 128. Configurable Traditions

Some rules vary among traditions.

Store:

```json
{
  "rule_id": "NODE_ASPECT_001",
  "traditions": [
    "PARASHARI_A",
    "PARASHARI_B"
  ],
  "default": "PARASHARI_A"
}
```

The user must be able to select the tradition.

---

# 129. No Hidden Defaults

The engine must expose:

```text
ayanamsha
node type
house system
aspect convention
Graha Yuddha convention
combustion convention
Dasha year basis
Varga rules
node aspects
```

A calculation without explicit configuration must show which defaults were applied.

---

# 130. Audit-Friendly Prediction

Every prediction must answer:

```text
WHY?
WHICH RULE?
WHICH PLANET?
WHICH HOUSE?
WHICH SIGN?
WHICH CONJUNCTION?
WHICH VARGA?
WHICH DASHA?
WHICH TRANSIT?
WHICH SOURCE?
WHAT CONFLICTS?
WHAT IS UNCERTAIN?
```

---

# 131. Minimum Viable Engine — Phase 1

Implement:

```text
Birth input
Swiss Ephemeris
Sidereal Lahiri
Whole-sign houses
D1
Nakshatra
Lagna
Planetary positions
Conjunctions
Aspects
Dignity
Vimshottari
Basic rule registry
FastAPI
PostgreSQL/SQLite
```

---

# 132. Phase 2

Add:

```text
D9
D10
D2
D3
D12
Combustion
Retrogression
Graha Yuddha
Shadbala
Ashtakavarga
```

---

# 133. Phase 3

Add:

```text
Multi-planet synthesis
Yoga engine
Event-domain engine
Transit engine
Prediction windows
Explanation graph
```

---

# 134. Phase 4

Add:

```text
LLM renderer
Hindi renderer
Frontend
chart visualization
prediction dashboard
source browser
rule debugger
```

---

# 135. Phase 5

Add:

```text
Backtesting
rectification
historical event datasets
statistical calibration
rule effectiveness research
```

Do not claim statistical predictive accuracy before Phase 5.

---

# 136. Recommended Repository

```text
vedic-astrology-engine/
├── backend/
├── frontend/
├── rules/
├── sources/
├── data/
├── tests/
├── notebooks/
├── docs/
└── docker/
```

---

# 137. Rule File Format

Recommended YAML:

```yaml
rule_id: P02-BHAVA10-001
name: Sun-Mars conjunction in tenth
classification: CLASSICAL_DERIVED
domain: CAREER
enabled: true

conditions:
  conjunction:
    pair_id: P02
  house: 10

evidence:
  direction: SUPPORTIVE

sources:
  - PHALADIPIKA_CH18

explanation:
  en: "Authority and initiative are linked in the career house."
```

Rules should be data-driven where practical.

---

# 138. Rule Engine Safety

A rule cannot:

```text
execute arbitrary Python
access filesystem
execute SQL
call external URLs
modify chart facts
```

Rules should be declarative or sandboxed.

---

# 139. Calculation vs Interpretation Boundary

Hard boundary:

```text
ASTRONOMY
↓
FACTS
↓
ASTROLOGICAL STRUCTURE
↓
RULES
↓
EVIDENCE
↓
SYNTHESIS
↓
PREDICTION
↓
LANGUAGE
```

An LLM must never be allowed to move upward in this chain and rewrite facts.

---

# 140. Reproducibility Package

Every prediction run should be exportable as:

```text
prediction.json
chart.json
calculation.json
rules.json
sources.json
audit.json
```

Optional:

```text
human-readable-report.md
```

This makes the result independently inspectable.

---

# 141. Research Mode

Add:

```http
POST /research/query
```

Possible queries:

```text
find all charts containing P02
find all P02 in 10th house
find all P02 + Jupiter
find all activated P02 cases
```

This turns the system into a research database, not merely a horoscope application.

---

# 142. Conjunction Research API

```http
GET /research/conjunctions/P02
```

Filters:

```text
house
sign
Lagna
degree separation
retrograde
combustion
Dasha
Varga
```

Response:

```json
{
  "pair_id": "P02",
  "records": [],
  "rule_sources": []
}
```

---

# 143. Bulk Chart Import

Future endpoint:

```http
POST /charts/import
```

Supported:

```text
JSON
CSV
NDJSON
```

For research datasets:

```text
100
1,000
10,000+
```

Use background workers.

---

# 144. Batch Prediction

```http
POST /predictions/batch
```

Input:

```json
{
  "chart_ids": [],
  "date_from": "2027-01-01",
  "date_to": "2028-01-01",
  "domains": ["CAREER"]
}
```

Output:

```text
job_id
status
progress
result_location
```

---

# 145. Data Quality Dashboard

Track:

```text
charts processed
calculation failures
rule failures
missing source references
unsupported configurations
birth-time sensitivity
prediction conflicts
```

---

# 146. Engine Health Dashboard

```text
Ephemeris: OK
Rules: OK
Database: OK
Cache: OK
Workers: OK
Source registry: OK
```

---

# 147. Semantic Versioning

```text
MAJOR
breaking API / interpretation architecture

MINOR
new rules or features

PATCH
bug fixes without intended interpretation changes
```

A rule-set version is independent from application version.

---

# 148. Migration Policy

If a rule changes:

```text
rule_set_version 1.0.0
        ↓
rule_set_version 1.1.0
```

Old prediction runs must remain reproducible.

Never overwrite historical interpretations.

---

# 149. Golden Prediction Record

Store:

```json
{
  "chart_hash": "...",
  "rule_set_version": "1.0.0",
  "expected_events": [],
  "expected_evidence": [],
  "expected_status": []
}
```

This becomes a regression fixture.

---

# 150. Example Golden Test

```python
def test_career_prediction_golden():
    result = engine.predict(chart, period)
    assert result.status == expected.status
    assert result.windows == expected.windows
```

Exact floating-point astronomical values should use appropriate tolerances.

---

# 151. Floating-Point Policy

Use:

```text
decimal where financial-like precision is needed
float64 for astronomical calculations
explicit angular normalization
tolerance comparisons
```

Never compare floating-point degrees using exact equality.

Example:

```python
abs(a - b) < 1e-8
```

with circular-angle handling.

---

# 152. Circular Angle Utility

```python
def angular_distance(a, b):
    d = abs(a - b) % 360
    return min(d, 360 - d)
```

This utility should be centralized.

---

# 153. Timezone Policy

Birth time must be converted:

```text
local civil time
→ timezone-aware datetime
→ UTC
→ Julian day
```

Historical timezone rules should use a real timezone database rather than a fixed UTC offset.

---

# 154. Location Policy

Store:

```text
latitude
longitude
timezone
location_name
```

Coordinates are authoritative for astronomical calculation.

Location names are metadata.

---

# 155. Ephemeris Files

Deployment must package or mount the required ephemeris resources.

Do not rely on a developer's local installation.

The deployment manifest must specify:

```text
ephemeris version
ephemeris path
license requirements
```

---

# 156. Licensing

Before distributing a hosted or commercial implementation, verify the applicable Swiss Ephemeris licensing terms and any obligations associated with the selected distribution model.

Do not treat the Python package installation as a substitute for license review.

---

# 157. API Documentation

FastAPI can expose:

```text
Swagger UI
ReDoc
OpenAPI JSON
```

Recommended:

```text
/docs
/redoc
/openapi.json
```

These should document the public contract. [FASTAPI-01] [FASTAPI-02]

---

# 158. OpenAPI Tags

Suggested tags:

```text
Charts
Calculation
Interpretation
Predictions
Timing
Dashas
Transits
Conjunctions
Rules
Sources
Research
System
```

---

# 159. Client SDK Generation

Because the API exposes OpenAPI/JSON Schema, client SDKs can later be generated for:

```text
TypeScript
Python
Java
C#
Go
```

Keep schemas stable.

---

# 160. Future Event Webhooks

Optional:

```http
POST /webhooks
```

Events:

```text
prediction_window_started
prediction_window_updated
calculation_completed
batch_job_completed
```

Useful for future mobile/web applications.

---

# 161. Notification Layer

Separate notification from prediction.

```text
Prediction Engine
       ↓
Event Window
       ↓
Notification Policy
       ↓
Email / App / Webhook
```

The prediction engine must not send notifications directly.

---

# 162. Final Volume 6 Architecture

```text
                    ┌─────────────────────┐
                    │   Birth Input/API   │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Validation & Config │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Astronomical Engine │
                    │ Swiss Ephemeris     │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Chart Structure     │
                    │ D1 / Houses / Signs │
                    └──────────┬──────────┘
                               ↓
          ┌────────────────────┼────────────────────┐
          ↓                    ↓                    ↓
     Conjunctions           Vargas               Strength
          ↓                    ↓                    ↓
          └────────────────────┼────────────────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Rule Engine         │
                    │ Classical + Derived │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Evidence Graph      │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Predictive Synthesis│
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Dasha + Transit     │
                    │ Timing Engine       │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Explanation Graph   │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ REST / JSON API     │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Web / Mobile / LLM  │
                    └─────────────────────┘
```

---

# 163. Volume 6 Completion Criteria

Volume 6 is considered architecturally complete when the implementation can:

- accept a birth chart
- calculate a reproducible sidereal chart
- generate D1 and configured Vargas
- calculate houses and Lagna
- identify conjunctions
- identify multi-planet clusters
- calculate aspects
- calculate planetary states
- calculate Nakṣatra
- generate Vimśottarī Daśā
- calculate configured strength systems
- detect configured yogas
- execute versioned rules
- generate evidence
- synthesize event domains
- calculate activation windows
- integrate transits
- resolve conflicts
- produce an explanation graph
- return structured JSON
- preserve source provenance
- preserve calculation provenance
- reproduce historical results
- pass regression tests

---

# 164. What Volume 6 Adds to Volumes 1–5

```text
Volume 1
Knowledge
   ↓
Volume 2
Pair database
   ↓
Volume 3
Multi-planet database
   ↓
Volume 4
Degree-sensitive calculation
   ↓
Volume 5
Predictive synthesis
   ↓
Volume 6
EXECUTABLE ENGINE + API
```

This is the transition from a research corpus to a software system.

---

# 165. Recommended Next Build Order

Do not start with the prediction UI.

Build in this order:

```text
1. Project skeleton
2. Configuration system
3. Swiss Ephemeris adapter
4. D1 chart calculator
5. Nakṣatra calculator
6. House/Lagna engine
7. Conjunction graph
8. Aspect engine
9. Dignity/state engine
10. Varga engine
11. Daśā engine
12. Rule registry
13. Evidence engine
14. Synthesis engine
15. Transit engine
16. Prediction engine
17. Explanation engine
18. FastAPI endpoints
19. PostgreSQL persistence
20. Test suite
21. Docker
22. Frontend
```

---

# 166. Critical Engineering Rule

The most important architectural decision is:

> **Never let prediction logic calculate astronomy.**

And the second:

> **Never let an LLM invent rule execution.**

The deterministic engine produces facts and evidence.

The explanation layer describes those facts and evidence.

---

# 167. Source Register

### Astronomical / calculation infrastructure

**[SE-01] Swiss Ephemeris documentation**  
Swiss Ephemeris documentation covering sidereal ephemerides and Lahiri ayanamsha variants.

**[SE-02] Swiss Ephemeris programming interface**  
Documentation of sidereal modes and house-position functionality.

### API infrastructure

**[FASTAPI-01] FastAPI — First Steps**  
Automatic interactive documentation and OpenAPI generation.

**[FASTAPI-02] FastAPI — Metadata and OpenAPI**  
OpenAPI schema and documentation endpoints.

**[FASTAPI-03] FastAPI — Request Body / Pydantic**  
Pydantic request models, validation and JSON Schema integration.

The source register should be expanded in the implementation repository with exact editions, URLs, access dates, and license metadata.

---

# 168. Final Design Principle

Volume 6 should not become a mystical chatbot with a database behind it.

It should become:

```text
A deterministic calculation engine
+
A versioned Jyotiṣa rule engine
+
An evidence graph
+
A timing engine
+
An auditable prediction API
+
An optional natural-language interface
```

That architecture allows every result to be inspected, reproduced, challenged, modified, and tested.

**Volume 6 therefore completes the bridge from classical research → structured knowledge → computation → predictive synthesis → production API.**
