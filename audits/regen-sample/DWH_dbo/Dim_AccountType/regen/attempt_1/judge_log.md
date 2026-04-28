Let me first check if the correct upstream wiki exists for `etoro.Dictionary.AccountType`.
So there is no `etoro.Dictionary.AccountType` wiki on disk. The writer noted it used `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.AccountType.md` but that file doesn't exist. The only upstream wiki in the bundle is `USABroker.Dictionary.AccountType` — which is completely the **wrong** table (Apex Clearing brokerage types: CASH/MARGIN/OPTION vs eToro account types: Private/Corporate/IB/Fund/etc.).

Now let me do my full evaluation.

---

## Adversarial Wiki Judge — DWH_dbo.Dim_AccountType

### Dimension 1 — Tier Accuracy (25%)

I'll sample 5 columns: AccountTypeID, Name, DWHAccountTypeID, StatusID, UpdateDate.

1. **AccountTypeID** — Lineage says Tier 1 from `etoro.Dictionary.AccountType`. The SP confirms it's a passthrough from `DWH_staging.etoro_Dictionary_AccountType.AccountTypeID`. A Tier 1 tag requires the upstream wiki to exist and be quoted verbatim. The upstream wiki that was *provided in the bundle* is `USABroker.Dictionary.AccountType` — a completely different table (Apex Clearing, 3 rows, columns `AccuntTypeID`/`Name`). The **correct** upstream (`etoro.Dictionary.AccountType`) has no wiki on disk. Without a valid upstream wiki to quote from, this column cannot be Tier 1 — it should be **Tier 3** (no upstream wiki available). The writer fabricated the Tier 1 claim.

2. **Name** — Same situation. Production column `AccountTypeName` renamed to `Name`. No `etoro.Dictionary.AccountType` wiki exists. Should be **Tier 3**, not Tier 1.

3. **DWHAccountTypeID** — Tier 2 via SP (computed as `[AccountTypeID] AS [DWHAccountTypeID]`). SP confirms. **Correct.**

4. **StatusID** — Tier 2 via SP (hardcoded `1 as StatusID`). SP confirms. **Correct.**

5. **UpdateDate** — Tier 2 via SP (`GETDATE()`). SP confirms. **Correct.**

**2 of 5 mismatches** (AccountTypeID and Name are tagged Tier 1 but should be Tier 3). Score: **5**.

However, the writer *did* correctly identify the actual source (`etoro.Dictionary.AccountType`) despite the bundle providing the wrong wiki (`USABroker`). The review-needed sidecar explicitly documents this. The writer showed good judgment recognizing the bundle mismatch — but the tier tagging is still wrong because there is no `etoro.Dictionary.AccountType` wiki to quote from. The descriptions are the writer's own composition, not verbatim upstream quotes.

Score: **5**

### Dimension 2 — Upstream Fidelity (20%)

There are 2 claimed Tier 1 columns: AccountTypeID and Name.

**The correct upstream wiki (`etoro.Dictionary.AccountType`) does not exist on disk.** The bundle-provided wiki is `USABroker.Dictionary.AccountType`, which describes a completely different system (Apex Clearing: CASH/MARGIN/OPTION). The writer correctly rejected the USABroker wiki and wrote its own descriptions — but this means there is **no upstream wiki to inherit from**.

Per the rubric: "No upstream wiki existed in the bundle → 7 (neutral)." However, an upstream wiki *was* in the bundle — it was just the **wrong** one. The writer correctly identified this, but still tagged columns as Tier 1 with fabricated (not inherited) descriptions. This is a tier misattribution: the descriptions are original composition labeled as inherited.

| Column | Upstream Quote | Wiki Quote | Match |
|--------|---------------|------------|-------|
| AccountTypeID | *No valid upstream wiki exists* (`USABroker.Dictionary.AccountType.AccuntTypeID` is wrong table) | "Primary key identifying the account classification. 0=N/A (DWH sentinel), 1=Private, 2=Corporate..." | NO — fabricated as Tier 1; no valid upstream to inherit from |
| Name | *No valid upstream wiki exists* (`USABroker.Dictionary.AccountType.Name` describes Apex UPPERCASE format) | "Human-readable label for the account type. Used in BackOffice UI, compliance reporting, and DWH exports." | NO — fabricated as Tier 1; no valid upstream to inherit from |

The writer wrote good descriptions, but they are **original composition**, not inheritance. Tagging them Tier 1 is dishonest — it implies they were quoted from an authoritative source.

Score: **4** (wrong tier origin — descriptions labeled as inherited but are fabricated)

### Dimension 3 — Completeness (20%)

Checklist:
- [x] All 8 sections present (1-8) ✓
- [x] Element count matches DDL: DDL has 6 columns, wiki has 6 elements ✓
- [x] Every element row has 5 cells ✓
- [x] Every element description ends with `(Tier N — source)` ✓
- [x] Property table has Production Source, Refresh, Distribution, UC Target ✓
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names ✓
- [x] Footer has tier breakdown counts ✓
- [ ] Section 1 summary contains row count and date range — has row count (19), **no date range** (this is a dim table, arguably N/A, but the rubric says it should be there)
- [ ] Dictionary columns with ≤15 values list inline key=value pairs — AccountTypeID lists all 18+sentinel values in the Elements table ✓ (but not as formal `key=value` in description, more like enumeration)
- [ ] `.review-needed.md` does NOT contain `## 4. Elements` — review-needed has no Section 4 ✓

9/10 items. Score: **8**

### Dimension 4 — Business Meaning (15%)

Section 1 is excellent: names the domain (eToro account classification), row grain (one row per account type), row count (19), lists the five functional groups, names the ETL SP, describes the refresh pattern (TRUNCATE + INSERT), mentions sentinel row. Missing date range, but for a static lookup table that's reasonable.

Score: **9**

### Dimension 5 — Data Evidence (10%)

- Row count (19) is stated ✓
- Date range: N/A for a static dim table
- Specific enum values listed (all 18 account types) ✓
- AccountTypeID=18 (Trust) noted as live data discovery ✓
- Phase Gate Checklist: not present in the wiki. The footer shows quality scores but no P2/P3 checkboxes. No explicit claim about phases.

The writer clearly had access to live data (19 rows, Trust type=18 discovery). But there's no explicit Phase Gate section.

Score: **6**

### Dimension 6 — Shape Fidelity (10%)

- Numbered sections 1-8 ✓
- Tier legend in Section 4 ✓
- Real SQL samples in Section 7 ✓
- Footer has quality score and tier breakdown ✓
- Missing: Phase Gate Checklist section, `phases-completed` in footer is informal
- Section ordering follows golden shape

Score: **8**

### Weighted Total

```
weighted = 0.25*5 + 0.20*4 + 0.20*8 + 0.15*9 + 0.10*6 + 0.10*8
         = 1.25   + 0.80   + 1.60   + 1.35   + 0.60   + 0.80
         = 6.40
```

**Verdict: FAIL** (6.40 < 7.5)

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| AccountTypeID | *No valid upstream wiki for `etoro.Dictionary.AccountType` exists. Bundle provided `USABroker.Dictionary.AccountType` which is a different system (Apex Clearing).* | "Primary key identifying the account classification. 0=N/A (DWH sentinel), 1=Private, 2=Corporate, 3=IB Account, 4=Joint, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 11=News, 12=White List, 13=Analyst, 14=SMSF, 15=Affiliate Corporate, 16=Administrated, 17=Funded Employee, 18=Trust." | NO | Entire description is fabricated — no upstream wiki to inherit from. Should be Tier 3. |
| Name | *No valid upstream wiki for `etoro.Dictionary.AccountType` exists.* | "Human-readable label for the account type. Used in BackOffice UI, compliance reporting, and DWH exports. Renamed from `AccountTypeName` in production." | NO | Entire description is fabricated — no upstream wiki to inherit from. Should be Tier 3. |

### Top 5 Issues

1. **HIGH — AccountTypeID, Name**: Both columns tagged `(Tier 1 — Dictionary.AccountType)` but the `etoro.Dictionary.AccountType` wiki does not exist on disk. The bundle provided `USABroker.Dictionary.AccountType` (Apex Clearing, CASH/MARGIN/OPTION) which is the wrong table entirely. The writer correctly rejected the USABroker wiki but then fabricated descriptions and labeled them as Tier 1 inherited. They should be Tier 3 (no upstream wiki available) or at best Tier 2 (grounded in SP code + live data).

2. **HIGH — Upstream Bundle Mismatch**: The harness resolved `Dictionary.AccountType` to `USABroker.Dictionary.AccountType`. The writer recognized this error (documented in review-needed), but the wiki still claims Tier 1 inheritance from a non-existent wiki. The entire Tier 1 provenance chain is broken.

3. **MEDIUM — Section 6.2 Relationships**: Lists only "Dim_Customer" and "Various Fact_* tables" — the latter is a lazy placeholder, not specific object references. The review-needed sidecar flags this too.

4. **LOW — No Phase Gate Checklist**: The wiki has no explicit phase gate section documenting which data validation steps (P1/P2/P3) were completed. The 19-row count and enum values suggest live data access, but it's not formally documented.

5. **LOW — No date range in Section 1**: The rubric expects row count AND date range. For a static dimension this is minor, but UpdateDate range would indicate freshness.

### Regeneration Feedback

1. **Re-tag AccountTypeID and Name as Tier 3** (no upstream wiki available) or Tier 2 (grounded in SP code and live data). Do NOT claim Tier 1 inheritance when no `etoro.Dictionary.AccountType` wiki exists to quote from.
2. **Generate the `etoro.Dictionary.AccountType` upstream wiki first**, then re-run this wiki to properly inherit Tier 1 descriptions verbatim.
3. **Replace "Various Fact_* tables" in Section 6.2** with specific object names from a DWH schema dependency scan.
4. **Add a Phase Gate Checklist** section documenting which data validation phases were completed.
5. **Add UpdateDate range** to Section 1 to show data freshness (e.g., "Last refreshed: 2026-04-27").

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_AccountType",
  "weighted_score": 6.40,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 4,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "AccountTypeID",
      "upstream_quote": "No valid upstream wiki for etoro.Dictionary.AccountType exists on disk. Bundle provided USABroker.Dictionary.AccountType (Apex Clearing: AccuntTypeID, 3 rows: CASH/MARGIN/OPTION) which is the wrong table entirely.",
      "wiki_quote": "Primary key identifying the account classification. 0=N/A (DWH sentinel), 1=Private, 2=Corporate, 3=IB Account, 4=Joint, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 11=News, 12=White List, 13=Analyst, 14=SMSF, 15=Affiliate Corporate, 16=Administrated, 17=Funded Employee, 18=Trust. Controls feature access, regulatory treatment, fee structures, and compliance monitoring level. (Tier 1 — Dictionary.AccountType)",
      "match": "NO",
      "loss": "Entire description is original composition, not inherited. No etoro.Dictionary.AccountType wiki exists to quote from. Should be Tier 3."
    },
    {
      "column": "Name",
      "upstream_quote": "No valid upstream wiki for etoro.Dictionary.AccountType exists on disk. Bundle provided USABroker.Dictionary.AccountType.Name: 'Display name for the account type. UPPERCASE format matching Apex Clearing API conventions.' — wrong system entirely.",
      "wiki_quote": "Human-readable label for the account type. Used in BackOffice UI, compliance reporting, and DWH exports. Renamed from AccountTypeName in production. (Tier 1 — Dictionary.AccountType)",
      "match": "NO",
      "loss": "Entire description is original composition, not inherited. No etoro.Dictionary.AccountType wiki exists to quote from. Should be Tier 3."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "AccountTypeID, Name",
      "problem": "Both columns tagged (Tier 1 — Dictionary.AccountType) but etoro.Dictionary.AccountType wiki does not exist on disk. The bundle provided USABroker.Dictionary.AccountType (Apex Clearing, 3 rows: CASH/MARGIN/OPTION) which is a completely different system. Writer correctly rejected the wrong wiki but fabricated descriptions and labeled them Tier 1. Should be Tier 3."
    },
    {
      "severity": "high",
      "column_or_section": "Upstream Bundle",
      "problem": "Harness resolved Dictionary.AccountType to USABroker.Dictionary.AccountType (wrong database). The etoro.Dictionary.AccountType wiki does not exist, breaking the entire Tier 1 provenance chain. Writer documented this in review-needed but the wiki still claims Tier 1 inheritance."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 6.2",
      "problem": "References 'Various Fact_* tables' as a placeholder instead of enumerating specific consuming objects. This is lazy documentation that provides no actionable information."
    },
    {
      "severity": "low",
      "column_or_section": "Phase Gate Checklist",
      "problem": "No Phase Gate Checklist section documenting which data validation phases (P1/P2/P3) were completed. Data claims (19 rows, enum values, AccountTypeID=18 Trust) appear but are not formally validated."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "No date range or UpdateDate range in Section 1 summary. For a daily-refreshed table, the last refresh timestamp would indicate freshness."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Generate the etoro.Dictionary.AccountType upstream wiki FIRST, then re-run this wiki to properly inherit Tier 1 descriptions verbatim. (2) Until that wiki exists, re-tag AccountTypeID and Name as Tier 3 (no upstream wiki available) — do NOT claim Tier 1 without a quotable source. (3) Replace 'Various Fact_* tables' in Section 6.2 with specific object names from a DWH schema dependency scan. (4) Add a Phase Gate Checklist section. (5) Add UpdateDate range to Section 1.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["19 rows (Section 1)", "AccountTypeID=18 Trust noted as live data discovery"],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
