# Vedic Astrology Production Knowledge Graph
## Production Knowledge Graph Specification
### Integration Layer for the Existing Astrology Application

**Status:** Production architecture / implementation specification  
**Purpose:** Provide a durable, queryable, versioned knowledge graph for the existing Vedic astrology application.  
**Scope:** Classical sources, astrological ontology, chart facts, rules, evidence, conjunctions, yogas, timing, predictions, provenance and temporal versioning.

---

# 1. Executive Architecture

The existing application remains the application.

The Production Knowledge Graph becomes its knowledge layer:

```text
Existing Application
        │
        ├── Chart Calculation
        ├── Interpretation
        ├── Prediction
        └── UI/API
                │
                ▼
        Knowledge Graph API
                │
        ┌───────┴────────┐
        ▼                ▼
   Knowledge Store   Evidence Store
        │                │
        └───────┬────────┘
                ▼
       Provenance / Versioning
```

The graph must not replace the application's deterministic astronomical calculator.

It stores and connects:

- canonical astrological entities
- relationships
- classical rules
- derived rules
- source references
- chart-derived facts
- evidence
- event domains
- activation conditions
- timing
- predictions
- explanation chains

---

# 2. Primary Design Goal

The graph must answer questions such as:

```text
What does this conjunction mean?
Which classical sources support it?
Which houses/signs modify it?
Which yogas involve these planets?
Which Vargas confirm it?
Which Dashas activate it?
Which transits activate it?
Which predictions depend on this evidence?
Why did the engine reach this conclusion?
Which rule-set version produced it?
```

The graph is therefore both:

1. a knowledge graph
2. an explanation/provenance graph

---

# 3. Recommended Production Model

Recommended logical model:

```text
PostgreSQL
    +
JSONB
    +
pgvector optional
    +
Graph projection / graph traversal layer
```

A dedicated graph database may be added later if graph traversal becomes a bottleneck.

For the first production implementation, the ontology should remain database-neutral.

This prevents the knowledge model from becoming coupled to a particular graph vendor.

---

# 4. Canonical Identifier Policy

Every entity receives a permanent ID.

Format:

```text
planet:Sun
planet:Moon

sign:Aries
sign:Taurus

bhava:1
bhava:10

pair:P02
cluster:C000001

nakshatra:Ashwini

rule:P02-BHAVA10-001

source:Phaladipika:18

yoga:Dhana:001

event:career
event:wealth

chart:CHT_...
prediction:PRED_...
```

IDs must be immutable.

Names may change.

IDs must not.

---

# 5. URI / IRI Strategy

Production URIs:

```text
https://vedic.example.org/ontology/planet/Sun
https://vedic.example.org/ontology/sign/Aries
https://vedic.example.org/rule/P02-BHAVA10-001
https://vedic.example.org/source/Phaladipika/18
```

The domain is configurable.

For local deployments:

```text
urn:vedic:planet:Sun
```

---

# 6. Entity Classes

Core classes:

```text
Planet
Node
Lagna
Sign
Bhava
Nakshatra
Pada
Varga
HouseLordship
Aspect
Conjunction
ConjunctionCluster
Dignity
PlanetaryState
Yoga
Karaka
Rule
RuleSet
Source
SourcePassage
Evidence
EventDomain
Activation
DashaPeriod
Transit
Prediction
PredictionWindow
Chart
Calculation
Configuration
Tradition
```

---

# 7. Planet Ontology

```text
Planet
 ├── Sun
 ├── Moon
 ├── Mars
 ├── Mercury
 ├── Jupiter
 ├── Venus
 ├── Saturn
 ├── Rahu
 └── Ketu
```

Properties:

```text
canonical_name
sanskrit_name
short_name
planet_type
natural_benefic
natural_malefic
gender
element
```

Natural benefic/malefic status must be treated as a traditional classification, not an absolute physical property.

---

# 8. Sign Ontology

Each Sign:

```text
index
name
sanskrit_name
lord
element
modality
polarity
gender
```

Relationships:

```text
sign:Aries
    --HAS_LORD--> planet:Mars
    --HAS_ELEMENT--> element:Fire
    --HAS_MODALITY--> modality:Movable
```

---

# 9. Bhava Ontology

Each Bhava:

```text
number
sanskrit_name
english_name
domains
natural_signification
```

Example:

```text
bhava:10
    name = Karma
    domains = [
      career,
      profession,
      authority,
      reputation
    ]
```

---

# 10. Lagna Ontology

Lagna is represented separately:

```text
Lagna
    --HAS_SIGN--> sign:Capricorn
    --HAS_LORD--> planet:Saturn
    --CREATES_HOUSE--> bhava:1
```

A chart-specific Lagna is an observation:

```text
chart:CHT001
    --HAS_LAGNA_OBSERVATION--> observation:LAGNA001
```

---

# 11. House Lordship Model

Do not store house lordship as an immutable property of a planet.

It is chart-dependent.

Example:

```text
chart:CHT001
    --HOUSE_LORD--> relation:H10L
```

```json
{
  "house": 10,
  "lord": "Venus",
  "chart_id": "CHT001"
}
```

This prevents incorrect global assumptions.

---

# 12. Planet-in-House Observation

A natal observation:

```text
observation:PJUP001
    planet = Jupiter
    house = 10
    sign = Libra
    longitude = 196.4231
    degree = 16.4231
```

Edges:

```text
observation:PJUP001
    --OBSERVES--> planet:Jupiter
    --IN_HOUSE--> bhava:10
    --IN_SIGN--> sign:Libra
```

---

# 13. Planet-in-Sign Observation

The graph must preserve both:

```text
absolute longitude
relative sign degree
```

Example:

```json
{
  "longitude": 196.4231,
  "sign": "Libra",
  "sign_degree": 16.4231
}
```

Never discard absolute longitude.

---

# 14. Nakshatra Model

```text
Nakshatra
 └── Pada
```

27 Nakshatras × 4 Padas.

Each observation:

```text
planet
nakshatra
pada
degree_within_nakshatra
nakshatra_lord
```

---

# 15. Varga Model

```text
Varga
 ├── D1
 ├── D2
 ├── D3
 ├── D4
 ├── D7
 ├── D9
 ├── D10
 ├── D12
 ├── D16
 ├── D20
 ├── D24
 ├── D27
 ├── D30
 ├── D40
 ├── D45
 └── D60
```

A chart observation stores:

```text
chart
planet
varga
varga_sign
calculation_version
```

---

# 16. Vargottama Relationship

```text
observation:PlanetD1
    --SAME_SIGN_AS--> observation:PlanetD9
```

Derived property:

```text
vargottama = true
```

Do not store Vargottama as an unexplained boolean only.

Store the observations from which it was derived.

---

# 17. Conjunction Ontology

A conjunction is an observation, not merely a pair label.

```text
Conjunction
 ├── pair_id
 ├── planet_a
 ├── planet_b
 ├── separation
 ├── applying
 ├── same_sign
 ├── same_house
 ├── orb_policy
 ├── calculation_version
```

---

# 18. Canonical Pair Registry

The 21 Volume 2 pair IDs remain canonical:

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

---

# 19. Multi-Planet Cluster

A cluster:

```text
cluster:C0001
    --CONTAINS--> planet:Sun
    --CONTAINS--> planet:Mercury
    --CONTAINS--> planet:Venus
    --CONTAINS--> planet:Saturn
```

Derived pair edges:

```text
P03
P05
P06
P17
P18
P21
```

Store the cluster independently so it can carry its own interpretation.

---

# 20. Graph Edge Semantics

Use typed relationships.

Core:

```text
OCCUPIES
LORDS
DISPOSED_BY
ASPECTS
CONJOINS
PART_OF_CLUSTER
IN_SIGN
IN_HOUSE
IN_VARGA
HAS_NAKSHATRA
HAS_PADA
ACTIVATES
SUPPORTS
MODIFIES
CONFLICTS_WITH
DERIVED_FROM
SUPPORTED_BY
CITED_BY
APPLIES_TO
TRIGGERS
CONFIRMED_BY
```

---

# 21. Relationship Metadata

Edges can have properties.

Example:

```json
{
  "type": "ASPECTS",
  "from": "planet:Jupiter",
  "to": "bhava:10",
  "aspect_type": "SPECIAL_10TH",
  "tradition": "PARASHARI",
  "rule_set_version": "1.0.0"
}
```

---

# 22. Rule Ontology

A Rule contains:

```text
rule_id
name
domain
classification
version
priority
conditions
conclusion
source_refs
tradition
enabled
```

Classifications:

```text
DIRECT_CLASSICAL
CLASSICAL_DERIVED
MULTI_SOURCE_CONVERGENCE
SYSTEMATIC_SYNTHESIS
CONFIGURABLE_TRADITION
ENGINEERING_HEURISTIC
```

---

# 23. Rule Provenance

Every rule must connect to:

```text
Rule
   ↓
SourcePassage
   ↓
Source
```

Example:

```text
rule:P02-BHAVA10-001
   --SUPPORTED_BY-->
source_passage:PHALADIPIKA-18-X
   --PART_OF-->
source:PHALADIPIKA
```

---

# 24. Source Ontology

Source:

```text
title
author
tradition
language
edition
publisher
publication_year
source_type
```

Source types:

```text
CLASSICAL_TEXT
COMMENTARY
TRANSLATION
SECONDARY_RESEARCH
MODERN_SYNTHESIS
ENGINEERING_DOCUMENT
```

---

# 25. Source Passage

A passage is more precise than a source.

```json
{
  "passage_id": "PHALADIPIKA-18-12",
  "source_id": "PHALADIPIKA",
  "chapter": "18",
  "verse": "12",
  "page": null,
  "locator": "Ch.18, Sloka 12"
}
```

If exact verse identification is unavailable, use the strongest verified locator available and mark the uncertainty.

---

# 26. Evidence Ontology

Evidence is a first-class entity.

```text
Evidence
    --DERIVED_FROM--> Rule
    --ABOUT--> Entity
    --SUPPORTS--> Event
    --MODIFIES--> Event
    --CONFLICTS_WITH--> Evidence
```

Properties:

```text
direction
strength
explanation
calculation_version
rule_set_version
```

---

# 27. Evidence Direction

Allowed values:

```text
SUPPORTIVE
MODIFYING
CONTRADICTORY
NEUTRAL
INSUFFICIENT
```

Do not encode this as a permanent property of the planet itself.

It is context-dependent.

---

# 28. Evidence Strength

```text
VERY_WEAK
WEAK
MODERATE
STRONG
VERY_STRONG
```

These are engine evidence bands, not empirical probabilities.

---

# 29. Event Domain Ontology

```text
event:identity
event:wealth
event:education
event:communication
event:home_property
event:children_creativity
event:health_service
event:marriage_partnership
event:transformation
event:fortune_higher_learning
event:career
event:gains_network
event:foreign_retreat
```

---

# 30. Event Hierarchy

Example:

```text
career
 ├── promotion
 ├── job_change
 ├── authority
 ├── business
 ├── public_recognition
 └── professional_reorientation
```

The hierarchy is extensible.

---

# 31. Activation Ontology

Activation connects:

```text
Dasha
Transit
Natal Factor
Varga
Event
```

Example:

```text
activation:A001
    --ACTIVATES--> event:career
    --BY_DASHA--> dasha:Jupiter-Saturn
    --BY_TRANSIT--> transit:Jupiter-10th
```

---

# 32. Daśā Ontology

```text
DashaPeriod
 ├── Mahadasha
 ├── Antardasha
 ├── Pratyantardasha
 └── Sookshma
```

Each has:

```text
lord
start
end
level
parent_period
```

---

# 33. Transit Ontology

A transit is a time-indexed observation:

```json
{
  "transit_id": "TR_2028_JUPITER_001",
  "planet": "Jupiter",
  "datetime": "2028-06-14T12:00:00Z",
  "longitude": 142.22
}
```

Relationships:

```text
TRANSIT_OF
ASPECTS_NATAL
CONJOINS_NATAL
ACTIVATES_EVENT
```

---

# 34. Prediction Ontology

Prediction is the output of synthesis.

```text
Prediction
    --ABOUT--> Event
    --SUPPORTED_BY--> Evidence
    --ACTIVATED_BY--> Activation
    --HAS_WINDOW--> PredictionWindow
    --EXPLAINED_BY--> Explanation
```

Properties:

```text
status
confidence_band
engine_version
rule_set_version
created_at
```

---

# 35. Prediction Status

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

---

# 36. Prediction Window

```json
{
  "start": "2028-04-15",
  "end": "2028-08-22",
  "status": "TIMING_WINDOW"
}
```

Additional properties:

```text
peak_date
applying_phase
exact_trigger
separating_phase
```

Do not interpret an exact trigger date as certainty of a real-world event.

---

# 37. Chart Ontology

Chart:

```text
chart_id
birth_data
calculation_config
engine_version
ephemeris_version
rule_set_version
chart_hash
created_at
```

A chart owns observations.

---

# 38. Observation Pattern

Use an explicit observation layer:

```text
Chart
  ↓
Observation
  ↓
Canonical Entity
```

Example:

```text
chart:CHT001
  ↓
observation:OBS001
  ↓
planet:Jupiter
```

This prevents chart-specific facts from contaminating global knowledge.

---

# 39. Calculation Entity

Every generated chart calculation should be represented:

```text
Calculation
    input_hash
    configuration_hash
    engine_version
    ephemeris_version
    timestamp
```

Relationships:

```text
Calculation
   --GENERATES--> Observation
```

---

# 40. Configuration Entity

Store:

```text
ayanamsha
house_system
node_type
aspect_system
combustion_policy
graha_yuddha_policy
varga_policy
dasha_system
year_basis
```

---

# 41. Tradition Entity

A tradition defines a set of interpretive conventions.

```text
Tradition
 ├── PARASHARI
 ├── JAIMINI
 ├── CONFIGURED_CUSTOM
 └── future traditions
```

A rule may belong to multiple traditions.

---

# 42. Rule Set Entity

```text
RuleSet
    version
    tradition
    effective_from
    effective_to
    status
```

Statuses:

```text
DRAFT
TESTING
ACTIVE
DEPRECATED
ARCHIVED
```

Never delete an active historical rule set.

---

# 43. Temporal Knowledge

Production KG must support time.

Use:

```text
valid_from
valid_to
observed_at
calculated_at
```

This is essential because:

- rule sets evolve
- source metadata may be corrected
- calculations may be recalculated
- transits are temporal
- predictions are temporal

---

# 44. Bitemporal Recommendation

For high-value records, distinguish:

```text
valid time
transaction time
```

Example:

```text
valid_from = 2028-01-01
valid_to   = 2028-12-31

recorded_at = 2026-10-03
```

This enables historical reconstruction.

---

# 45. Immutable Prediction Runs

Never overwrite a prediction.

Instead:

```text
PredictionRun:RUN001
PredictionRun:RUN002
```

Both may use the same chart with different rule sets.

---

# 46. Provenance Chain

A production prediction should be traceable:

```text
Prediction
 ↓
Event
 ↓
Evidence
 ↓
Rule
 ↓
Observation
 ↓
Calculation
 ↓
Birth Input
```

and:

```text
Rule
 ↓
Source Passage
 ↓
Source
 ↓
Edition
```

---

# 47. Full Explanation Chain

Example:

```text
Prediction P001
    ↓
Career Event
    ↓
Evidence E001
    ↓
Rule P02-BHAVA10-001
    ↓
Sun–Mars Conjunction
    ↓
Observation O101
    ↓
Jupiter Dasha
    ↓
Dasha Period D501
    ↓
Transit T801
    ↓
Source Passage
```

The UI can render this as a clickable evidence tree.

---

# 48. Knowledge Graph Query Types

The production layer must support:

### Entity lookup

```text
Find everything known about Jupiter.
```

### Relationship lookup

```text
What does Jupiter aspect?
```

### Rule lookup

```text
Which rules involve Sun–Mars?
```

### Source lookup

```text
Which classical passages support P02?
```

### Chart lookup

```text
Which observations contain P02 in Bhava 10?
```

### Prediction explanation

```text
Why was career activated?
```

### Research

```text
Find all charts containing a given pattern.
```

---

# 49. Example Graph Query

Pseudo-Cypher:

```cypher
MATCH (r:Rule)-[:SUPPORTED_BY]->(p:SourcePassage)
WHERE r.rule_id = 'P02-BHAVA10-001'
RETURN r, p;
```

---

# 50. Example Conjunction Query

```cypher
MATCH (c:Conjunction)-[:USES_PAIR]->(p:Pair)
WHERE p.pair_id = 'P02'
RETURN c;
```

---

# 51. Example Prediction Explanation Query

```cypher
MATCH path =
  (pred:Prediction)-[:SUPPORTED_BY*1..5]->(x)
WHERE pred.prediction_id = $prediction_id
RETURN path;
```

Production implementation should constrain relationship types and depth rather than allowing unbounded traversal.

---

# 52. Example Chart Query

```cypher
MATCH (chart:Chart {chart_id: $chart_id})
      -[:HAS_OBSERVATION]->(obs:Observation)
      -[:OBSERVES]->(planet:Planet)
RETURN chart, obs, planet;
```

---

# 53. Example Multi-Hop Query

Question:

```text
Which career predictions are activated by a Dasha planet connected to the 10th lord?
```

Logical traversal:

```text
Prediction
 → Event:Career
 → Activation
 → Dasha
 → Planet
 → House Lord
 → Bhava 10
```

---

# 54. Graph Projection

For an existing relational database, construct a graph projection:

```text
PostgreSQL tables
      ↓
canonical IDs
      ↓
entity projection
      ↓
edge projection
      ↓
graph API
```

The relational database remains authoritative for transactional data.

---

# 55. Knowledge Authority

Authority hierarchy:

```text
1. Astronomical calculation
2. Stored canonical ontology
3. Verified source metadata
4. Versioned rule registry
5. Chart observation
6. Evidence
7. Prediction synthesis
8. Natural-language rendering
```

Lower layers must never rewrite higher layers.

---

# 56. No Semantic Mutation

An LLM must not be allowed to:

```text
create an unverified classical rule
change source classification
change planetary longitude
change house lordship
change Dasha dates
change rule result
```

It may:

```text
summarize
translate
explain
format
```

---

# 57. Source Verification State

Source passages should have:

```text
UNVERIFIED
PARTIALLY_VERIFIED
VERIFIED
DISPUTED
```

This is particularly important for OCR/translations.

---

# 58. Classical Text Representation

Store:

```text
original_language
transliteration
translation
commentary
locator
edition
page
verse
verification_status
```

Do not treat a modern English translation as equivalent to the original textual witness.

---

# 59. Citation Granularity

Preferred:

```text
Source
  ↓
Chapter
  ↓
Verse
  ↓
Passage
```

If verse is unavailable:

```text
Chapter
+
page
+
edition
```

---

# 60. Rule Evidence Matrix

Each rule should declare:

```text
required facts
optional facts
supporting source
contradicting factors
modifiers
activation conditions
```

Example:

```yaml
rule_id: CAREER-10L-001

required:
  - tenth_lord

supporting:
  - tenth_lord_strong

modifiers:
  - combustion
  - retrogression

activation:
  - dasha_of_tenth_lord
  - transit_to_tenth_lord
```

---

# 61. Graph Ontology for Strength

Strength must remain decomposable:

```text
Planet
 ├── Sthana Bala
 ├── Dig Bala
 ├── Kala Bala
 ├── Cheshta Bala
 ├── Naisargika Bala
 └── Drik Bala
```

Do not only store:

```text
strength = 82
```

without components.

---

# 62. Ashtakavarga Graph

```text
Planet
   ↓
Bhinna Ashtakavarga
   ↓
Sign
   ↓
Bindu observation
```

And:

```text
Chart
 ↓
Sarvashtakavarga
 ↓
House
 ↓
Bindu count
```

---

# 63. Yoga Graph

```text
Yoga
 ├── HAS_CONDITION
 ├── REQUIRES_PLANET
 ├── REQUIRES_HOUSE
 ├── HAS_CANCELLATION
 ├── HAS_MODIFIER
 ├── ACTIVATED_BY
 └── SUPPORTED_BY
```

A yoga record must retain the exact conditions that were satisfied.

---

# 64. Yoga Explanation

Instead of:

```text
Dhana Yoga = TRUE
```

store:

```json
{
  "yoga": "Dhana Yoga",
  "conditions": [
    {
      "condition": "2nd lord connected with 11th lord",
      "satisfied": true
    },
    {
      "condition": "required strength",
      "satisfied": true
    }
  ],
  "cancellations": [],
  "modifiers": []
}
```

---

# 65. Conjunction Explanation

For P02:

```text
Sun–Mars
 ↓
house = 10
 ↓
sign = Leo
 ↓
Sun dignity
 ↓
Mars dignity
 ↓
exact separation
 ↓
combustion state
 ↓
aspect network
 ↓
10th lord relationship
 ↓
Dasha activation
```

This becomes a graph traversal, not a text-only lookup.

---

# 66. Rule Dependency Graph

Rules can depend on other rules:

```text
RULE-A
  ↓ DEPENDS_ON
RULE-B
  ↓ DEPENDS_ON
RULE-C
```

Store:

```text
DEPENDS_ON
```

This allows topological execution.

---

# 67. Rule Execution DAG

```text
Astronomical Facts
        ↓
Structural Rules
        ↓
Pattern Rules
        ↓
Strength Rules
        ↓
Activation Rules
        ↓
Synthesis Rules
```

No circular dependencies.

---

# 68. Circular Dependency Detection

At rule deployment:

```text
build dependency graph
run cycle detection
reject RuleSet if cycle exists
```

Example invalid:

```text
RULE-A → RULE-B
RULE-B → RULE-A
```

---

# 69. Rule Testing Entity

Each rule should have:

```text
RuleTest
 ├── input_fixture
 ├── expected_result
 ├── expected_evidence
 └── test_version
```

Production deployment should reject untested production rules.

---

# 70. Evidence Deduplication

The same fact may support several predictions.

Do not create duplicate evidence unnecessarily.

Use:

```text
evidence_hash =
SHA256(
 chart_id
 + observation_id
 + rule_id
 + rule_set_version
 + context
)
```

---

# 71. Confidence Model

Do not encode:

```text
prediction_probability = 83%
```

unless empirically calibrated.

Use:

```text
evidence_band
source_quality
convergence_count
conflict_count
input_quality
```

These are explainability dimensions, not probabilities.

---

# 72. Evidence Convergence

Example:

```text
Career:
  Natal promise       YES
  10th lord strength  YES
  D10 confirmation    YES
  Dasha activation    YES
  Transit activation  YES
  Conflict            LOW
```

The graph can represent each separately.

---

# 73. Input Uncertainty

Birth-time uncertainty should propagate:

```text
Birth uncertainty
 ↓
Lagna uncertainty
 ↓
Varga uncertainty
 ↓
Rule uncertainty
 ↓
Prediction uncertainty
```

Store:

```text
sensitivity = STABLE / SENSITIVE / UNSTABLE
```

---

# 74. Chart Versioning

A chart may be recalculated under:

```text
engine v6.0
engine v6.1
```

Never overwrite the original calculation.

Create:

```text
Calculation:C001
Calculation:C002
```

Both point to the same normalized birth input.

---

# 75. Rule-Set Versioning

Prediction:

```text
PRED001
```

must reference:

```text
rule_set = jyotisha-rules-1.2.0
```

This is mandatory for reproducibility.

---

# 76. Knowledge Package Format

Production import/export:

```text
knowledge-package/
├── manifest.json
├── ontology.json
├── entities.ndjson
├── relationships.ndjson
├── rules.ndjson
├── sources.ndjson
├── tests.ndjson
└── checksums.sha256
```

---

# 77. Manifest

```json
{
  "package": "vedic-production-kg",
  "version": "1.0.0",
  "ontology_version": "1.0.0",
  "rule_set_version": "1.0.0",
  "generated_at": "2026-10-03T00:00:00Z",
  "format": "NDJSON",
  "encoding": "UTF-8"
}
```

---

# 78. Entity NDJSON

Example:

```json
{"id":"planet:Jupiter","type":"Planet","name":"Jupiter"}
{"id":"sign:Sagittarius","type":"Sign","name":"Sagittarius"}
{"id":"bhava:10","type":"Bhava","number":10}
```

One entity per line.

---

# 79. Relationship NDJSON

```json
{"from":"sign:Sagittarius","type":"HAS_LORD","to":"planet:Jupiter"}
{"from":"planet:Jupiter","type":"ASPECTS","to":"bhava:10"}
```

---

# 80. JSON-LD Compatibility

The knowledge package should be convertible to JSON-LD.

Example:

```json
{
  "@id": "planet:Jupiter",
  "@type": "Planet",
  "name": "Jupiter"
}
```

This enables future semantic-web interoperability without forcing RDF internally.

---

# 81. SHACL / Constraint Layer

If RDF/semantic validation is adopted later, define constraints for:

```text
Planet
Sign
Bhava
Rule
Source
Evidence
Prediction
```

Examples:

```text
Planet must have canonical_name.
Rule must have classification.
DIRECT_CLASSICAL Rule must have source reference.
Prediction must have rule_set_version.
```

---

# 82. Graph Integrity Constraints

Production invariants:

```text
every Rule has classification
every DIRECT_CLASSICAL Rule has source
every Prediction has rule_set
every Observation belongs to a Chart
every DashaPeriod belongs to a Chart
every PredictionWindow belongs to a Prediction
every chart calculation has configuration
every conjunction has exact geometry
```

---

# 83. Referential Integrity

No dangling:

```text
rule_id
source_id
chart_id
observation_id
prediction_id
dasha_id
transit_id
```

Database foreign keys should be used wherever the implementation storage supports them.

---

# 84. Soft Deletion

Knowledge entities should normally never be hard-deleted.

Use:

```text
status = ACTIVE
status = DEPRECATED
status = ARCHIVED
```

For accidental records, use controlled administrative deletion with audit logging.

---

# 85. Access Control

Roles:

```text
VIEWER
PRACTITIONER
RESEARCHER
RULE_EDITOR
SOURCE_EDITOR
ADMIN
```

Permissions:

```text
VIEWER:
  read

PRACTITIONER:
  read + chart creation

RESEARCHER:
  read + research queries

RULE_EDITOR:
  rules + tests

SOURCE_EDITOR:
  source metadata

ADMIN:
  system management
```

---

# 86. Rule Publishing Workflow

```text
DRAFT
 ↓
REVIEW
 ↓
TEST
 ↓
APPROVED
 ↓
ACTIVE
 ↓
DEPRECATED
```

A rule should not become ACTIVE merely because it was inserted into the database.

---

# 87. Source Publishing Workflow

```text
UNVERIFIED
 ↓
REVIEW
 ↓
VERIFIED
```

Disputed passages remain marked as disputed rather than silently normalized.

---

# 88. Research Sandbox

Researchers need isolated rule sets:

```text
production
research/alex
research/yogesh
experimental/v2
```

Experimental rules must not contaminate production predictions.

---

# 89. Tenant / Workspace Isolation

If the existing app becomes multi-user:

```text
workspace_id
```

should be attached to:

```text
charts
predictions
research datasets
custom rules
custom configurations
```

Canonical ontology can remain global.

---

# 90. Custom Rules

Users may create:

```text
custom rule
```

but it must be marked:

```text
classification = USER_DEFINED
```

It must never appear as classical authority.

---

# 91. User Rule Provenance

```json
{
  "rule_id": "user:yogesh:career:001",
  "classification": "USER_DEFINED",
  "created_by": "user_id",
  "workspace_id": "workspace_001"
}
```

---

# 92. Graph API

Recommended internal endpoints:

```text
GET /kg/entities/{id}
GET /kg/entities/{id}/neighbors
GET /kg/entities/{id}/path
POST /kg/query
GET /kg/rules/{id}
GET /kg/sources/{id}
GET /kg/predictions/{id}/graph
```

---

# 93. Neighbor Query

```http
GET /kg/entities/planet:Jupiter/neighbors?depth=2
```

Return:

```text
nodes
edges
metadata
```

Limit depth to prevent accidental graph explosions.

---

# 94. Path Query

```http
GET /kg/path?from=prediction:P001&to=source:Phaladipika
```

Response:

```json
{
  "paths": [
    [
      "prediction:P001",
      "evidence:E001",
      "rule:P02-BHAVA10-001",
      "source_passage:PH18-12",
      "source:Phaladipika"
    ]
  ]
}
```

---

# 95. Graph Query Security

Never expose unrestricted database query execution to public clients.

Instead:

```text
parameterized query templates
```

for public API.

Research/admin users may receive expanded query capabilities behind authorization.

---

# 96. Caching Strategy

Cache:

```text
canonical entities
rule metadata
source metadata
chart subgraphs
prediction explanation graphs
```

Invalidate when:

```text
rule-set changes
ontology changes
chart calculation changes
```

---

# 97. Search Layer

Add full-text search over:

```text
source title
source passage
rule name
rule explanation
yoga
planet
conjunction
event domain
```

Optional vector search:

```text
semantic source retrieval
```

Vector similarity must not override exact rule/source IDs.

---

# 98. Vector Search Policy

If pgvector or another vector store is used:

```text
vector retrieval = discovery aid
```

not:

```text
vector retrieval = authority
```

The final rule engine still requires exact structured rule IDs.

---

# 99. Hybrid Retrieval

For an explanation request:

```text
exact rule lookup
+
source ID lookup
+
semantic source search
```

Then combine results.

Never substitute semantic similarity for source verification.

---

# 100. Production Backup

Back up:

```text
PostgreSQL
rule packages
source metadata
ontology
prediction audit logs
configuration
```

Charts containing personal data require stricter backup access controls.

---

# 101. Disaster Recovery

Recommended:

```text
daily full backup
point-in-time recovery
off-machine backup
checksum verification
restore testing
```

The restore process must preserve:

```text
rule-set versions
prediction audit history
```

---

# 102. Observability

Metrics:

```text
kg_query_latency
kg_query_errors
rule_execution_latency
evidence_count
prediction_generation_latency
source_lookup_latency
graph_depth
orphan_entity_count
orphan_rule_count
```

---

# 103. Data Quality Metrics

Track:

```text
% rules with sources
% rules with tests
% source passages verified
% predictions with provenance
% observations with calculation version
% orphaned edges
% duplicate entities
```

Production quality should be measurable.

---

# 104. Duplicate Detection

Canonical entity duplicate candidates:

```text
same normalized name
same ontology class
same canonical ID
```

Source duplicates:

```text
title
author
edition
publication metadata
```

Do not merge automatically when historical editions differ.

---

# 105. Entity Resolution

Aliases:

```text
Jupiter
Guru
Bṛhaspati
Brihaspati
```

Map:

```text
alias → canonical entity
```

Canonical internal ID remains:

```text
planet:Jupiter
```

---

# 106. Sanskrit / Transliteration

Store:

```text
canonical_name
iast_name
devanagari_name
english_name
aliases[]
```

Example:

```json
{
  "canonical_name": "Jupiter",
  "iast": "Guru",
  "devanagari": "गुरु",
  "aliases": ["Bṛhaspati", "Brihaspati"]
}
```

---

# 107. Ontology Governance

Changes require:

```text
proposal
review
migration plan
version bump
backward compatibility analysis
```

Do not casually rename canonical classes.

---

# 108. Ontology Versioning

Example:

```text
ontology 1.0.0
```

Changing:

```text
property meaning
entity semantics
relationship semantics
```

requires a major version.

Adding optional metadata:

```text
minor version
```

Bug corrections:

```text
patch version
```

---

# 109. Production Graph Snapshot

Create immutable snapshots:

```text
KG-SNAPSHOT-2026-10-03
KG-SNAPSHOT-2026-11-01
```

A prediction can reference the snapshot used.

---

# 110. Snapshot Hash

```text
snapshot_hash =
SHA256(
 ontology
 + rules
 + source registry
 + canonical entities
 + relationships
)
```

Store it in every production prediction run.

---

# 111. Explainability Requirement

A production prediction is invalid if:

```text
prediction exists
BUT
no evidence path exists
```

The system should reject such output.

---

# 112. Orphan Prediction Test

Automated test:

```text
find predictions with zero evidence
```

Expected:

```text
0
```

---

# 113. Orphan Classical Rule Test

```text
find DIRECT_CLASSICAL rules
where source_refs is empty
```

Expected:

```text
0
```

---

# 114. Orphan Source Test

Source passages may exist without rules because they are research material.

Therefore:

```text
orphan source = warning
```

not necessarily an error.

---

# 115. Prediction Reproduction

Given:

```text
chart_hash
snapshot_hash
rule_set_version
engine_version
configuration
```

the system should reconstruct the same prediction run.

---

# 116. Reproduction API

```http
POST /kg/reproduce
```

Input:

```json
{
  "prediction_run_id": "RUN001"
}
```

Output:

```json
{
  "reproducible": true,
  "differences": []
}
```

---

# 117. Difference Report

If reproduction differs:

```json
{
  "reproducible": false,
  "differences": [
    {
      "field": "JUPITER.longitude",
      "old": 121.123,
      "new": 121.124,
      "reason": "ephemeris_version_changed"
    }
  ]
}
```

---

# 118. Graph Materialization Strategy

Do not materialize every possible theoretical combination.

Materialize:

```text
canonical ontology
actual chart observations
actual conjunctions
actual rule matches
actual evidence
actual predictions
```

Generate theoretical relationships from rules when needed.

This keeps the graph manageable.

---

# 119. Theoretical Knowledge Layer

Separate:

```text
GLOBAL KNOWLEDGE
```

from:

```text
CHART INSTANCE KNOWLEDGE
```

Global:

```text
Sun
Mars
P02
10th house
classical rules
sources
```

Chart-specific:

```text
Sun at 12.4°
Mars at 15.9°
P02 observed
P02 in 10th
```

---

# 120. Chart Instance Layer

```text
chart:CHT001
   ↓
observation:P02-001
   ↓
pair:P02
```

This distinction is essential for research.

---

# 121. Research Query Example

Question:

```text
Find every chart in the database where P02 occurs in the 10th house and is activated during Jupiter Mahadasha.
```

Traversal:

```text
Chart
 → Conjunction
 → Pair P02
 → House 10
 → Dasha Jupiter
 → Activation
```

---

# 122. Research Dataset Export

Support:

```text
CSV
Parquet
NDJSON
JSON
```

Minimum columns:

```text
chart_id
pair_id
house
sign
degree_separation
applying
combust
retrograde
dasha_lord
event_domain
activation
rule_set_version
```

---

# 123. Statistical Separation

Research statistics must not alter classical rule truth.

Example:

```text
Classical rule:
P02 has interpretation X.

Empirical dataset:
X appeared in 61/100 research cases.
```

These remain separate evidence layers.

---

# 124. Empirical Evidence Entity

Future:

```text
EmpiricalFinding
```

Properties:

```text
sample_size
population
method
date_range
dataset_id
effect_size
uncertainty
```

This prevents anecdotal observations from being presented as classical rules.

---

# 125. Backtesting Graph

```text
EmpiricalFinding
   --TESTS--> Rule
   --USES_DATASET--> Dataset
   --USES_RULESET--> RuleSet
```

---

# 126. Dataset Ontology

```text
Dataset
 ├── source
 ├── sample_size
 ├── population
 ├── collection_period
 ├── inclusion_criteria
 └── exclusion_criteria
```

---

# 127. Research Provenance

Every empirical result:

```text
Dataset
 ↓
Method
 ↓
Rule
 ↓
Finding
 ↓
Metrics
```

---

# 128. Production vs Research

Two namespaces:

```text
prod:
research:
```

Example:

```text
prod:rule:P02-BHAVA10-001
research:rule:test-P02-001
```

Research results cannot silently become production knowledge.

---

# 129. Knowledge Graph Health Job

Run periodically:

```text
check orphan entities
check orphan edges
check invalid references
check missing sources
check duplicate IDs
check rule cycles
check prediction provenance
check snapshot consistency
```

---

# 130. Health Report

```json
{
  "ontology": "PASS",
  "referential_integrity": "PASS",
  "rule_sources": "PASS",
  "rule_tests": "PASS",
  "prediction_provenance": "PASS",
  "cycles": "PASS",
  "duplicates": "WARNING"
}
```

---

# 131. Deployment Topology

```text
                    Internet
                       │
                 Existing App
                       │
                 API Gateway
                       │
          ┌────────────┴────────────┐
          │                         │
   Existing App API          Knowledge API
                                    │
                         ┌──────────┴──────────┐
                         │                     │
                    PostgreSQL             Redis
                         │
                    KG Projection
                         │
                 Optional Graph DB
```

---

# 132. Why Not Force Neo4j Immediately?

The ontology is graph-native, but the application already has transactional data.

Keeping PostgreSQL authoritative gives:

```text
strong transactional consistency
simple backups
familiar migrations
JSONB
SQL analytics
```

A dedicated graph engine can later serve:

```text
deep traversal
large relationship exploration
graph visualization
complex path queries
```

without changing the ontology.

---

# 133. Optional Neo4j Projection

If needed:

```text
PostgreSQL
   ↓
CDC / ETL
   ↓
Neo4j
```

Nodes:

```text
(:Planet)
(:Sign)
(:Bhava)
(:Rule)
(:Source)
(:Chart)
(:Observation)
(:Evidence)
(:Prediction)
```

Edges:

```text
[:LORDS]
[:OCCUPIES]
[:CONJOINS]
[:ASPECTS]
[:SUPPORTED_BY]
[:DERIVED_FROM]
[:ACTIVATES]
```

---

# 134. Graph Database Selection Rule

Choose a dedicated graph database only if measured workload demonstrates that:

```text
deep traversal latency
relationship complexity
graph visualization
or graph analytics
```

justify the additional operational complexity.

---

# 135. API Integration With Existing App

The existing app should call:

```text
Knowledge Service
```

for:

```text
rule lookup
source lookup
explanation
conjunction semantics
yoga semantics
event ontology
research queries
```

It should continue using its current calculation engine for astronomical facts.

---

# 136. Integration Contract

The existing application should send:

```json
{
  "chart_id": "CHT001",
  "calculation_id": "CALC001",
  "rule_set_version": "1.0.0"
}
```

The KG returns:

```json
{
  "knowledge_snapshot": "KG-2026-10-03",
  "evidence": [],
  "rules": [],
  "sources": [],
  "explanation_graph": {}
}
```

---

# 137. Avoid Recalculation

The Knowledge Graph should not recalculate planetary positions if the existing application already has authoritative calculated values.

Instead:

```text
existing app calculation
        ↓
normalized observation contract
        ↓
knowledge graph
```

This avoids two competing astronomy engines.

---

# 138. Normalized Observation Contract

```json
{
  "chart_id": "CHT001",
  "planet": "JUPITER",
  "longitude": 121.583421,
  "sign": "LEO",
  "house": 5,
  "nakshatra": "MAGHA",
  "pada": 1,
  "retrograde": false,
  "calculation_id": "CALC001"
}
```

---

# 139. Ingestion API

```http
POST /kg/ingest/chart
```

Input:

```json
{
  "chart_id": "CHT001",
  "calculation_id": "CALC001",
  "observations": []
}
```

The KG validates the observation contract and materializes graph nodes/edges.

---

# 140. Idempotent Ingestion

Use:

```text
chart_id + calculation_id
```

as ingestion identity.

Repeated ingestion should produce:

```text
same graph state
```

not duplicates.

---

# 141. Event Sourcing Option

For high audit requirements:

```text
ChartCalculated
ObservationCreated
RuleMatched
EvidenceCreated
PredictionCreated
```

Events can reconstruct the graph state.

This is optional, not mandatory for the first production deployment.

---

# 142. Recommended First Production Cut

Implement:

```text
ontology
canonical entities
source registry
rule registry
chart observations
conjunctions
evidence
Dasha
transits
predictions
provenance
versioning
```

Do not begin with a huge graph database migration.

---

# 143. Minimum Graph Node Set

```text
Planet
Sign
Bhava
Nakshatra
Varga
Pair
Rule
Source
SourcePassage
Chart
Observation
Conjunction
DashaPeriod
Transit
Evidence
Event
Prediction
PredictionWindow
RuleSet
Calculation
Configuration
```

---

# 144. Minimum Edge Set

```text
HAS_LORD
OCCUPIES
IN_SIGN
IN_HOUSE
HAS_NAKSHATRA
IN_VARGA
CONJOINS
ASPECTS
USES_PAIR
PART_OF_CLUSTER
SUPPORTED_BY
DERIVED_FROM
APPLIES_TO
SUPPORTS
MODIFIES
CONFLICTS_WITH
ACTIVATES
TRIGGERS
HAS_WINDOW
USES_RULESET
GENERATED_BY
```

---

# 145. Canonical Graph Example

```text
             Source
               ↑
               │ SUPPORTED_BY
              Rule
               ↑
               │ DERIVED_FROM
            Evidence
               ↑
               │ SUPPORTS
            Career
               ↑
               │ ABOUT
          Prediction
               ↑
               │ ACTIVATED_BY
           Activation
             ↙     ↘
          Dasha    Transit
             ↓       ↓
          Planet ← Observation
                    ↓
              Conjunction
                ↙       ↘
              Sun       Mars
```

---

# 146. Explanation UI Contract

The existing app can render:

```text
Prediction
  ├─ Why?
  │   ├─ Career house
  │   ├─ 10th lord
  │   ├─ Sun–Mars conjunction
  │   ├─ Dasha activation
  │   └─ Transit confirmation
  │
  ├─ Modifiers
  ├─ Conflicts
  └─ Sources
```

Every item is clickable.

---

# 147. Graph Export for UI

Response:

```json
{
  "nodes": [
    {
      "id": "planet:Sun",
      "type": "Planet",
      "label": "Sun"
    }
  ],
  "edges": [
    {
      "source": "planet:Sun",
      "target": "planet:Mars",
      "type": "CONJOINS"
    }
  ]
}
```

This can feed Cytoscape, React Flow, D3, or another frontend renderer.

---

# 148. Graph Size Controls

The API should support:

```text
depth
node_types
edge_types
max_nodes
max_edges
```

Example:

```http
/kg/entities/prediction:P001/neighbors
  ?depth=3
  &max_nodes=100
```

---

# 149. Security Boundary

Never expose:

```text
raw database credentials
Cypher endpoint
SQL endpoint
internal source paths
private chart IDs
other users' chart data
```

Use authenticated application-level endpoints.

---

# 150. Auditability

Every administrative mutation should record:

```text
actor
timestamp
old value
new value
reason
request ID
```

Especially:

```text
rule changes
source verification
ontology changes
prediction deletion
```

---

# 151. Data Retention

Define separate retention policies for:

```text
canonical knowledge
source metadata
user charts
predictions
audit logs
research datasets
```

Canonical knowledge should generally be retained indefinitely.

User data may have configurable deletion policies.

---

# 152. Privacy Boundary

The graph must distinguish:

```text
global knowledge
```

from:

```text
personal chart data
```

A global source or rule should never expose a user's birth information.

---

# 153. PII-Minimization

A chart node does not need:

```text
full legal name
phone
email
address
```

The KG can use:

```text
chart_id
```

and keep identifying information in the existing application's secure user store.

---

# 154. Research Anonymization

For research:

```text
original chart_id
        ↓
research_subject_id
```

Do not export personal identifiers.

---

# 155. Knowledge Graph Governance

Ownership:

```text
Ontology Owner
Rule Curator
Source Curator
Engineering Owner
Data Protection Owner
```

Changes should be reviewable.

---

# 156. Production Release Checklist

Before release:

```text
[ ] ontology version frozen
[ ] canonical IDs validated
[ ] rules tested
[ ] sources linked
[ ] source verification status present
[ ] prediction provenance complete
[ ] chart ingestion idempotent
[ ] graph integrity passes
[ ] rule dependency cycles = 0
[ ] orphan production rules = 0
[ ] security tests pass
[ ] backup tested
[ ] restore tested
[ ] snapshot hash generated
```

---

# 157. Production Acceptance Tests

### Test 1 — Planet

```text
planet:Jupiter exists
```

### Test 2 — Pair

```text
pair:P02 exists
```

### Test 3 — Source

```text
P02 rule has source reference
```

### Test 4 — Chart

```text
chart:C001 contains observations
```

### Test 5 — Evidence

```text
evidence points to rule + observation
```

### Test 6 — Prediction

```text
prediction points to evidence
```

### Test 7 — Reproduction

```text
same snapshot reproduces same graph
```

---

# 158. Production Query Example

Question:

> Why did the system identify a career timing window?

Graph traversal:

```text
Prediction
 ↓
Career Event
 ↓
Prediction Window
 ↓
Activation
 ├── Dasha
 └── Transit
 ↓
Evidence
 ├── 10th lord rule
 ├── conjunction rule
 └── Varga confirmation
 ↓
Observations
 ↓
Chart Calculation
 ↓
Source Rules
```

This is the core purpose of the graph.

---

# 159. What NOT to Store as Truth

Do not permanently encode:

```text
"Sun is always bad."
"Saturn always delays."
"Jupiter always gives wealth."
"This conjunction guarantees promotion."
```

Instead store:

```text
specific rule
specific conditions
specific tradition
specific context
specific source
specific evidence
```

---

# 160. Knowledge Graph and Classical Fidelity

The graph must preserve a strict distinction between:

```text
WHAT THE SOURCE SAYS
```

and:

```text
WHAT THE ENGINE DERIVES
```

and:

```text
WHAT THE PREDICTIVE SYNTHESIS PRODUCES
```

This is the single most important semantic rule in the knowledge layer.

---

# 161. Recommended Folder

```text
knowledge-graph/
├── ontology/
│   ├── classes.json
│   ├── properties.json
│   └── constraints.json
├── rules/
│   ├── production/
│   ├── research/
│   └── tests/
├── sources/
│   ├── works.json
│   └── passages.json
├── mappings/
├── schemas/
├── migrations/
├── snapshots/
└── README.md
```

---

# 162. Final Architecture

```text
                     EXISTING APP
                          │
                 ┌────────┴────────┐
                 │                 │
            Chart Engine      Prediction UI
                 │                 │
                 └────────┬────────┘
                          │
                    Normalized Data
                          │
                          ▼
              ┌──────────────────────┐
              │ KNOWLEDGE GRAPH API  │
              └──────────┬───────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
      Ontology        Rules          Sources
          │              │              │
          └──────────────┼──────────────┘
                         ▼
                    Evidence
                         │
                         ▼
                    Activation
                         │
                         ▼
                    Prediction
                         │
                         ▼
                 Explanation Graph
                         │
                         ▼
                    Existing UI
```

---

# 163. Final Principle

The Production Knowledge Graph is not another astrology calculator.

It is the **semantic memory and evidence infrastructure** of the existing application.

The final system becomes:

```text
Astronomical Engine
       +
Astrological Rule Engine
       +
Production Knowledge Graph
       +
Evidence / Provenance
       +
Prediction Synthesis
       +
Existing Application
```

That architecture makes the application:

- inspectable
- versionable
- researchable
- reproducible
- explainable
- extensible
- source-aware
- suitable for future statistical validation

Most importantly, it prevents the application from becoming dependent on opaque narrative generation.

