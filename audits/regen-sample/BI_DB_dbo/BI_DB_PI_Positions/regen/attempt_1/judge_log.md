## Judge Review: BI_DB_dbo.BI_DB_PI_Positions

### Dimension 1 — Tier Accuracy: **3/10**

Sampled columns: CID (#2), Amount (#5), ParentPositionID (#9), CloseDateID (#13), IsSettled (#16).

- **CID**: Tier 1 — Trade.PositionTbl. Correct ✓
- **Amount**: Tier 1 — Trade.PositionTbl. Correct tier, but paraphrased (dropped "PositionOpen divides by 100 from cents"). ✓ tier, -2 paraphrase.
- **ParentPositionID**: Tier 1 — Trade.PositionTbl. Correct ✓
- **CloseDateID**: Tagged Tier 2 — Dim_Position. It is a passthrough from Dim_Position which has a wiki → should be Tier 1. ✗
- **IsSettled**: Tagged Tier 2 — Dim_Position. Dim_Position wiki documents it as "(Tier 5 — Expert Review)". As a passthrough with upstream wiki present, this should be Tier 1 — Dim_Position. ✗

2 mismatches → base 5. One paraphrasing failure on Amount (dropped cents conversion detail) → -2. **Score: 3.**

Systematic issue: The writer split columns into Tier 1 (production-origin passthroughs) and Tier 2 (ETL-computed-in-Dim_Position passthroughs). But ALL 17 data columns are direct `SELECT dp.X FROM Dim_Position dp` passthroughs — the passthrough rule applies uniformly. Six columns (OpenDateID, CloseDateID, Volume, FullCommissionOnCloseOrig, IsSettled, FullCommissionByUnits) are tagged Tier 2 when they should be Tier 1.

### Dimension 2 — Upstream Fidelity: **5/10**

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| PositionID | "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position." | "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| CID | "Customer ID. References Customer.Customer." | "Customer ID. References Customer.Customer. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). Passthrough from Dim_Position." | MINOR | Added filter context |
| InstrumentID | "FK to Trade.Instrument. Financial instrument being traded." | "FK to Trade.Instrument. Financial instrument being traded. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| Leverage | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| Amount | "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents)." | "Position size in currency. Must be >= 0. Stored in dollars. Synced via UPDATE when value changes in Dim_Position. Passthrough from Dim_Position." | NO | Dropped "(PositionOpen divides by 100 from cents)" — lost production-layer conversion detail |
| IsBuy | "1 = Long/Buy (profit when price rises), 0 = Short/Sell." | "1 = Long/Buy (profit when price rises), 0 = Short/Sell. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| OpenOccurred | "When position was persisted (mapped from Occurred in production). Default getutcdate()." | "When position was persisted (mapped from Occurred in production). Passthrough from Dim_Position." | NO | Dropped "Default getutcdate()" |
| CloseOccurred | "When close was persisted." | "When close was persisted. '1900-01-01 00:00:00' sentinel = still open. Synced via UPDATE from Dim_Position." | MINOR | Enriched with sentinel info |
| ParentPositionID | "Copy-trade parent. 0/1 = root. Positive = child of referenced position." | "Copy-trade parent. 0/1 = root. Positive = child of referenced position. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| OrigParentPositionID | "Original parent before any detachment." | "Original parent before any detachment. Passthrough from Dim_Position." | MINOR | Added passthrough note |
| MirrorID | "FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position." | "FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. Used to filter manual positions (MirrorID=0) for PI classification and instrument analysis. Passthrough from Dim_Position." | MINOR | Added usage context |

The 11 claimed Tier 1 columns are mostly faithful with contextual additions. Two have minor semantic loss (Amount, OpenOccurred). Base score: ~7.

**Missed inheritance**: FullCommissionByUnits is documented as "(Tier 1 — Trade.Position)" in the Dim_Position wiki, but the writer tagged it as "(Tier 2 — Dim_Position)". This is a clear missed inheritance (the upstream dim says Tier 1, the writer downgraded to Tier 2). Deduct 2.

**Score: 7 - 2 = 5.**

### Dimension 3 — Completeness: **10/10**

All checks pass:
- [x] All 8 sections present
- [x] Element count matches DDL (18/18)
- [x] Every element row has 5 cells
- [x] Every description ends with (Tier N — source)
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real SP names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (~24.1M) and date range (Jan 2009 to Apr 2024)
- [x] IsBuy values documented inline (1/0)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable: names the domain (PI shadow cache of Dim_Position), row grain (trading positions for active PIs/CopyFunds), ETL SP with section references, three data paths (backfill/incremental/close sync), consumers (sections 2.4-2.8, 3.6), row count, date range, and data freshness note. An analyst reading this knows exactly what the table is, why it exists, and when to query it.

### Dimension 5 — Data Evidence: **7/10**

- Row count (~24.1M): present ✓
- Date range (2009-01-02 to 2024-04-14): present ✓
- Specific CID count (~3,149 in 2024): present ✓
- GuruStatusID values enumerated: present ✓
- Last UpdateDate (2024-04-15 06:47:28) in review-needed: present ✓
- No explicit Phase Gate Checklist with P2/P3 checkboxes, but footer says "Phases: 11/14"

### Dimension 6 — Shape Fidelity: **9/10**

Numbered sections, tier legend, real SQL in Section 7, footer with quality score and phases-completed list. Minor: tier legend uses simplified format (no stars column) but meaning is clear.

---

### Weighted Total

```
weighted = 0.25*3 + 0.20*5 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*9
         = 0.75 + 1.00 + 2.00 + 1.35 + 0.70 + 0.90
         = 6.70
```

**Verdict: FAIL** (6.70 < 7.5)

---

### Top 5 Issues

1. **HIGH — 6 columns wrongly tagged Tier 2**: OpenDateID, CloseDateID, Volume, FullCommissionOnCloseOrig, IsSettled, FullCommissionByUnits are all direct `SELECT dp.X FROM Dim_Position dp` passthroughs. The Dim_Position wiki documents all of them. They must be Tier 1 — with the origin from the Dim_Position wiki, not Tier 2 via SP.

2. **HIGH — FullCommissionByUnits missed Tier 1 inheritance**: The Dim_Position wiki explicitly marks this column as "(Tier 1 — Trade.Position)". The writer downgraded to "(Tier 2 — Dim_Position)", losing the production origin entirely.

3. **MEDIUM — Amount paraphrased**: Dropped "(PositionOpen divides by 100 from cents)" from the upstream Dim_Position description. This production-layer detail about how Amount is derived (cents to dollars division) should be preserved verbatim.

4. **MEDIUM — OpenOccurred paraphrased**: Dropped "Default getutcdate()" from the upstream. The default value behavior is relevant for understanding NULL semantics.

5. **MEDIUM — IsSettled tier mismatch**: Dim_Position wiki says "(Tier 5 — Expert Review)" indicating the column's derivation is not fully understood upstream. The writer replaced this with "(Tier 2 — Dim_Position)" which misrepresents the upstream confidence level. The review-needed sidecar correctly flags this but the wiki itself should carry the upstream's Tier 5 designation.

### Regeneration Feedback

1. Re-tag OpenDateID, CloseDateID, Volume, FullCommissionOnCloseOrig, IsSettled, FullCommissionByUnits as **Tier 1** — they are direct passthroughs from Dim_Position which has a documented wiki. Use the Dim_Position wiki's own origin citation (e.g., `Tier 1 — SP_Dim_Position_DL_To_Synapse` for OpenDateID, `Tier 1 — Trade.Position` for FullCommissionByUnits, `Tier 5 — Expert Review` for IsSettled).
2. For all Tier 1 columns, quote the Dim_Position wiki description **verbatim** — do not drop specifics like "(PositionOpen divides by 100 from cents)" or "Default getutcdate()". Append BI_DB-specific context (sync behavior, filter context) AFTER the verbatim quote.
3. For IsSettled, preserve the upstream's Tier 5 — Expert Review designation rather than overriding to Tier 2. The upstream explicitly signals low confidence.
4. Update the tier legend to reflect that Tier 1 descriptions come from the Dim_Position wiki (which itself traces to Trade.PositionTbl and SP_Dim_Position_DL_To_Synapse), not directly from Trade.PositionTbl.
5. Update footer tier counts to reflect the corrected tiers (17 T1, 1 T2 for UpdateDate only).

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PI_Positions",
  "weighted_score": 6.70,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 3,
    "upstream_fidelity": 5,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "PositionID",
      "upstream_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position.",
      "wiki_quote": "Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position.",
      "match": "MINOR",
      "loss": "Added passthrough note — no semantic loss"
    },
    {
      "column": "CID",
      "upstream_quote": "Customer ID. References Customer.Customer.",
      "wiki_quote": "Customer ID. References Customer.Customer. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9). Passthrough from Dim_Position.",
      "match": "MINOR",
      "loss": "Added filter context — no semantic loss from upstream"
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded.",
      "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded. Passthrough from Dim_Position.",
      "match": "MINOR",
      "loss": "Added passthrough note — no semantic loss"
    },
    {
      "column": "Leverage",
      "upstream_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.",
      "wiki_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position.",
      "match": "MINOR",
      "loss": "Added passthrough note — no semantic loss"
    },
    {
      "column": "Amount",
      "upstream_quote": "Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents).",
      "wiki_quote": "Position size in currency. Must be >= 0. Stored in dollars. Synced via UPDATE when value changes in Dim_Position. Passthrough from Dim_Position.",
      "match": "NO",
      "loss": "Dropped '(PositionOpen divides by 100 from cents)' — production-layer cents-to-dollars conversion detail lost"
    },
    {
      "column": "IsBuy",
      "upstream_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell.",
      "wiki_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell. Passthrough from Dim_Position.",
      "match": "MINOR",
      "loss": "Added passthrough note — no semantic loss"
    },
    {
      "column": "OpenOccurred",
      "upstream_quote": "When position was persisted (mapped from Occurred in production). Default getutcdate().",
      "wiki_quote": "When position was persisted (mapped from Occurred in production). Passthrough from Dim_Position.",
      "match": "NO",
      "loss": "Dropped 'Default getutcdate()' — lost default value semantics"
    },
    {
      "column": "CloseOccurred",
      "upstream_quote": "When close was persisted.",
      "wiki_quote": "When close was persisted. '1900-01-01 00:00:00' sentinel = still open. Synced via UPDATE from Dim_Position.",
      "match": "MINOR",
      "loss": "Enriched with sentinel info — no upstream content lost"
    },
    {
      "column": "ParentPositionID",
      "upstream_quote": "Copy-trade parent. 0/1 = root. Positive = child of referenced position.",
      "wiki_quote": "Copy-trade parent. 0/1 = root. Positive = child of referenced position. Passthrough from Dim_Position.",
      "match": "MINOR",
      "loss": "Added passthrough note — no semantic loss"
    },
    {
      "column": "OrigParentPositionID",
      "upstream_quote": "Original parent before any detachment.",
      "wiki_quote": "Original parent before any detachment. Passthrough from Dim_Position.",
      "match": "MINOR",
      "loss": "Added passthrough note — no semantic loss"
    },
    {
      "column": "MirrorID",
      "upstream_quote": "FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position.",
      "wiki_quote": "FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. Used to filter manual positions (MirrorID=0) for PI classification and instrument analysis. Passthrough from Dim_Position.",
      "match": "MINOR",
      "loss": "Added usage context — no upstream content lost"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "OpenDateID, CloseDateID, Volume, FullCommissionOnCloseOrig, IsSettled, FullCommissionByUnits",
      "problem": "6 columns tagged Tier 2 — Dim_Position but are direct SELECT dp.X FROM Dim_Position dp passthroughs with an upstream wiki available. Per passthrough rule, all should be Tier 1 with the origin from the Dim_Position wiki."
    },
    {
      "severity": "high",
      "column_or_section": "FullCommissionByUnits",
      "problem": "Dim_Position wiki explicitly marks this column as '(Tier 1 — Trade.Position)'. Writer downgraded to '(Tier 2 — Dim_Position)', losing the production origin Trade.Position entirely. Clear missed Tier 1 inheritance."
    },
    {
      "severity": "medium",
      "column_or_section": "Amount",
      "problem": "Upstream says 'Stored in dollars (PositionOpen divides by 100 from cents)'. Wiki drops the cents conversion detail, replacing with 'Stored in dollars. Synced via UPDATE when value changes in Dim_Position.' Paraphrasing failure on a Tier 1 column."
    },
    {
      "severity": "medium",
      "column_or_section": "IsSettled",
      "problem": "Dim_Position wiki says '(Tier 5 — Expert Review)' signaling low upstream confidence. Writer replaced with '(Tier 2 — Dim_Position)' which misrepresents the upstream's own confidence level. The review-needed sidecar correctly flags this but the wiki itself should carry the Tier 5 designation."
    },
    {
      "severity": "medium",
      "column_or_section": "OpenOccurred",
      "problem": "Upstream says 'Default getutcdate()'. Wiki drops this, losing the default value behavior documentation."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag OpenDateID, CloseDateID, Volume, FullCommissionOnCloseOrig, IsSettled, FullCommissionByUnits as Tier 1 — they are direct passthroughs from Dim_Position which has a wiki. Use the Dim_Position wiki's own origin citation for each (e.g. 'Tier 1 — Trade.Position' for FullCommissionByUnits, 'Tier 1 — SP_Dim_Position_DL_To_Synapse' for OpenDateID). (2) For IsSettled, preserve the upstream Tier 5 — Expert Review designation. (3) Quote all Tier 1 descriptions verbatim from the Dim_Position wiki — do not drop specifics like '(PositionOpen divides by 100 from cents)' for Amount or 'Default getutcdate()' for OpenOccurred. Append BI_DB-specific context AFTER the verbatim upstream quote. (4) Update footer tier counts to reflect corrected tiers (17 T1, 1 T2).",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P10 — Atlassian search skipped (regen harness mode)"]
  }
}
</JUDGE_VERDICT>
