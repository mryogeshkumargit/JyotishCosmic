# Master Vedic Astrology Knowledge Base v1.0.0

This package unifies five layers:

1. **Jyotisha Corpus** — classical source/rule ingestion
2. **Sanskrit Documents** — primary-text reference layer
3. **Hora / Swiss Ephemeris** — deterministic astronomical calculation layer
4. **Our Volumes 1–5** — structured synthesis layer
5. **Production KG** — provenance, relationships, activation and prediction dependencies

## What is actually populated now

The package contains the complete populated Volumes 1–5/Production-KG dataset already generated:
- 21 conjunction pairs
- 3,024 Pair × Bhāva × Rāśi records
- 120 multi-planet clusters
- 15 rules
- 16 Vargas
- 81 Mahādaśā × Antardaśā activation nodes
- 12 prediction dependency templates
- 329 entities
- 2,202 relationships

It also adds a Master source registry, ontology, ingestion contracts, source-to-layer mapping and production ingestion order.

## External sources

The external repositories are referenced as authoritative integration sources, not copied wholesale into this package. The Master KB should ingest source material according to each repository's provenance/licensing rules.

### Verified references
- Jyotisha Corpus: https://github.com/maximally0/jyotisha-corpus
- Sanskrit Documents Jyotisha: https://sanskritdocuments.org/iast/jyotisha/
- Hora: https://github.com/amitpandeygit/hora
- PyJHora: https://github.com/naturalstupid/PyJHora
- Astrobot architecture reference: https://github.com/imshivraj101/astrobot

## Critical architecture rule

The Master KB is NOT one giant interpretation table.

SOURCE → RULE → CALCULATION → DERIVATION → SYNTHESIS → ACTIVATION → PREDICTION

Each layer retains its provenance and version. A generated systematic synthesis can therefore never masquerade as a classical verse.

## Current limitation

The external GitHub repositories could be verified through their live repository pages, but their full contents could not be cloned into the execution environment. Therefore this package contains the verified integration registry and our populated dataset, rather than silently claiming that the external repositories' full text/rules have been imported.

The next ingestion pass should clone/download the licensed corpus and import its actual rule/text records into SOURCE and RULE layers.
