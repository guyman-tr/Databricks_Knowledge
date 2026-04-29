I need to carefully review this wiki against the DDL, lineage, upstream bundle, and SP code. Let me start by checking the critical details.

First, the DDL nullable definitions vs wiki claims:

**DDL**:
- `Name varchar(50) NULL`
- `StatusID int NULL`
- `UpdateDate datetime NULL`
- `InsertDate datetime NULL`

**Wiki Elements table** claims all four are `NOT NULL`. That's 4 nullable mismatches.

Second, the SP code for the ID=0 placeholder — let me verify the wiki's claim about it.

The SP clearly contains:

```sql
INSERT INTO [DWH_dbo].[Dim_AccountType]
     ([AccountTypeID],[Name],[DWHAccountTypeID],[StatusID],[UpdateDate],[InsertDate])
VALUES (0,'N/A',0,1,@ddate,@ddate)
```

The wiki states: *"ID=0 (N/A) is a DWH placeholder row from the production source itself (no separate placeholder insert in the SP)."* This is **factually wrong** — the SP explicitly inserts the ID=0 row after the staging load.

Third, and most critically: the upstream wiki mismatch.

---

## Per-Dimension Scores

### Dimension 1 — Tier Accuracy: 6/10

Sampling all 6 columns (only 6 exist):

| Column | Wiki Tier | Lineage Transform | Correct Tier | Match? |
|---|---|---|---|---|
| AccountTypeID | Tier 1 — Dictionary.AccountType | passthrough | Tier 1 | YES (tier) |
| Name | Tier 1 — Dictionary.AccountType | passthrough (renamed) | Tier 1 | YES (tier) |
| DWHAccountTypeID | Tier 2 — SP | ETL-computed | Tier 2 | YES |
| StatusID | Tier 2 — SP | ETL-computed (hardcoded) | Tier 2 | YES |
| UpdateDate | Tier 2 — SP | ETL-computed (GETDATE) | Tier 2 | YES |
| InsertDate | Tier 2 — SP | ETL-computed (GETDATE) | Tier 2 | YES |

Tier assignments are correct: 0 mismatches → base 10. However, both Tier 1 columns have catastrophic paraphrasing failures. The upstream wiki (Dictionary.AccountType from USABroker) describes Apex Clearing with 3 values (1=CASH, 2=MARGIN, 3=OPTION), while the wiki describes eToro with 19 values (1=Private, 2=Corporate, etc.). The Tier 1 tag claims verbatim inheritance, but the content bears zero resemblance to the upstream wiki. **-2 per paraphrasing failure × 2 = -4.**

Score: **6**

### Dimension 2 — Upstream Fidelity: 3/10

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|---|---|---|---|---|
| AccountTypeID | "Primary key. Typo in column name (missing 'o' - should be AccountTypeID). Values: 1=CASH, 2=MARGIN, 3=OPTION. Referenced by Apex.UserData.AccountTypeID." | "Primary key identifying the account classification. 0=N/A (DWH placeholder), 1=Private, 2=Corporate, 3=IB Account [...] 18=Trust. Controls feature access, regulatory treatment [...] Referenced by Dim_Customer.AccountTypeID." | NO | Completely different domain. Upstream describes Apex Clearing brokerage types (CASH/MARGIN/OPTION); wiki describes eToro account ownership types (Private/Corporate/IB/etc.). FK target changed from Apex.UserData to Dim_Customer. Typo note dropped. |
| Name | "Display name for the account type. UPPERCASE format matching Apex Clearing's API conventions." | "Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification." | NO | Dropped vendor name (Apex Clearing), dropped UPPERCASE format note, completely rewritten. |

Both Tier 1 columns are total non-matches. The root cause is that the upstream bundle resolved `etoro.Dictionary.AccountType` to `USABroker.Dictionary.AccountType` — a completely different system. The writer appears to have recognized the mismatch and described the actual eToro data, but still tagged them Tier 1 with a verbatim claim that is false.

Score: **3** (2+ paraphrased, effectively wrong tier origin — claiming verbatim from a wiki that describes a different system)

### Dimension 3 — Completeness: 6/10

| Check | Pass? |
|---|---|
| All 8 sections present | YES |
| Element count matches DDL (6 = 6) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | PARTIAL — row count yes, no date range (static dim, arguable) |
| Dictionary columns ≤15 values list key=value | YES (19 values listed, slightly over 15 but appropriate) |
| .review-needed.md does NOT contain `## 4. Elements` | YES |

9/10 checks → **8**. However, 4 nullable columns are wrong (DDL says NULL, wiki says NOT NULL). This is a significant accuracy error that undermines the Elements table. **Deducting 2** for systematic nullable misreporting.

Score: **6**

### Dimension 4 — Business Meaning: 7/10

Section 1 is specific: names the domain (eToro account classification), row grain (one per account type), ETL SP, refresh pattern (daily TRUNCATE+INSERT), and row count (19). The value map in Section 2 is excellent. The gotchas section is genuinely useful (DWHAccountTypeID redundancy, Name vs AccountTypeName rename, etc.).

**But**: The claim that "ID=0 (N/A) is a DWH placeholder row from the production source itself (no separate placeholder insert in the SP)" is factually wrong — the SP explicitly inserts the 0-row after the staging load. This is a dangerous falsehood for an analyst relying on this wiki to understand data provenance.

Score: **7**

### Dimension 5 — Data Evidence: 5/10

- Row count (19): Present in Section 1 ✓
- Date range: N/A for static dim
- Specific enum values: Full 19-row value map ✓
- NULL-rate claims: None
- Phase Gate: Footer says "Phases: 7/14 (simple-dict fast-path: P3/P5/P6/P7/P9B/P10 skipped)" — P3 skipped means no live-data validation phase. Value map and row count could be from SP code inspection or fabricated.

Score: **5**

### Dimension 6 — Shape Fidelity: 8/10

Numbered sections present, tier legend in Section 4, real SQL in Section 7, footer has quality score and phases list. Minor deviations: tier tag format uses dashes instead of em-dashes, no Phase Gate Checklist section with `[x]` checkboxes. Generally good shape.

Score: **8**

---

## Weighted Total

```
weighted = 0.25×6 + 0.20×3 + 0.20×6 + 0.15×7 + 0.10×5 + 0.10×8
         = 1.50 + 0.60 + 1.20 + 1.05 + 0.50 + 0.80
         = 5.65
```

**Verdict: FAIL** (< 6.0)

---

## Top 5 Issues

1. **CRITICAL — Wrong upstream wiki resolution, Tier 1 claims unsubstantiated** (`AccountTypeID`, `Name`): The bundle resolved `etoro.Dictionary.AccountType` to `USABroker.Dictionary.AccountType` (Apex Clearing, 3 rows: CASH/MARGIN/OPTION). The DWH table contains eToro data (19 rows: Private/Corporate/IB/etc.). Tier 1 tags claim verbatim inheritance from a wiki describing a completely different system.

2. **HIGH — Factual error on ID=0 origin** (Section 1, Section 2, Section 3.4): Wiki claims "ID=0 (N/A) is a DWH placeholder row from the production source itself (no separate placeholder insert in the SP)." The SP has an explicit `INSERT INTO Dim_AccountType VALUES (0,'N/A',0,1,@ddate,@ddate)` after the staging load. The 0-row IS a DWH placeholder inserted by the SP.

3. **HIGH — 4 nullable columns misreported** (`Name`, `StatusID`, `UpdateDate`, `InsertDate`): DDL declares these as NULL-able; wiki marks them NOT NULL. An analyst building constraints or validation rules based on this wiki would get it wrong.

4. **MEDIUM — No acknowledgment of upstream wiki mismatch** (Section 4, review-needed sidecar): The writer should have flagged that the upstream wiki describes Apex Clearing (CASH/MARGIN/OPTION) while the DWH table contains eToro account types. Instead, the Tier 1 tag silently claims verbatim sourcing. The review-needed sidecar mentions ID=18 Trust but not the fundamental domain mismatch.

5. **MEDIUM — eToro-specific business claims unverifiable** (Section 2): Category groupings (Retail, Corporate, Partner, Internal, Managed), system references (BackOffice, Trade, Hedge, Billing, Compliance), and behavioral claims (copy trading, fund allocation routing) appear to be domain knowledge not grounded in any source provided in the bundle. P3/P5 skipped means no live validation.

---

## Regeneration Feedback

1. **Re-tag AccountTypeID and Name as Tier 3** (no matching upstream wiki) or flag the bundle misresolution and request the correct upstream wiki for `etoro.Dictionary.AccountType` before claiming Tier 1.
2. **Fix the ID=0 origin claim**: The SP explicitly inserts `(0,'N/A',0,1,@ddate,@ddate)` — this IS a DWH placeholder inserted by the SP, not from the production source.
3. **Fix nullable values** for Name, StatusID, UpdateDate, InsertDate — all are NULL per DDL, not NOT NULL.
4. **Add a prominent note** in the review-needed sidecar that the upstream wiki (`USABroker.Dictionary.AccountType`) describes a different system (Apex Clearing, 3 brokerage types) than the actual source (`etoro.Dictionary.AccountType`, 19 eToro account types). This is a bundle resolution error that must be corrected before Tier 1 can be claimed.
5. **Ground business logic claims** (Section 2 category groups, system references) in verifiable sources or mark them as domain-expert assertions pending validation.

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_AccountType",
  "weighted_score": 5.65,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 6,
    "upstream_fidelity": 3,
    "completeness": 6,
    "business_meaning": 7,
    "data_evidence": 5,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "AccountTypeID",
      "upstream_quote": "Primary key. Typo in column name (missing 'o' - should be AccountTypeID). Values: 1=CASH, 2=MARGIN, 3=OPTION. Referenced by Apex.UserData.AccountTypeID.",
      "wiki_quote": "Primary key identifying the account classification. 0=N/A (DWH placeholder), 1=Private, 2=Corporate, 3=IB Account, 4=Joint Account, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 11=News, 12=White List, 13=Analyst, 14=SMSF, 15=Affiliate Corporate, 16=Administrated, 17=Funded Employee, 18=Trust. Controls feature access, regulatory treatment, fee structures, and compliance monitoring level. Referenced by Dim_Customer.AccountTypeID.",
      "match": "NO",
      "loss": "Completely different domain. Upstream describes Apex Clearing brokerage types (CASH/MARGIN/OPTION, 3 rows); wiki describes eToro account ownership types (Private/Corporate/IB/etc., 19 rows). FK target changed from Apex.UserData to Dim_Customer. Column typo note (AccuntTypeID) dropped. Bundle resolved etoro.Dictionary.AccountType to wrong wiki (USABroker.Dictionary.AccountType)."
    },
    {
      "column": "Name",
      "upstream_quote": "Display name for the account type. UPPERCASE format matching Apex Clearing's API conventions.",
      "wiki_quote": "Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification.",
      "match": "NO",
      "loss": "Dropped vendor name (Apex Clearing), dropped UPPERCASE format convention, completely rewritten description. Upstream describes Apex Clearing naming conventions; wiki describes generic DWH labeling."
    }
  ],
  "issues": [
    {
      "severity": "critical",
      "column_or_section": "AccountTypeID, Name (Tier 1 claims)",
      "problem": "Upstream bundle resolved etoro.Dictionary.AccountType to USABroker.Dictionary.AccountType — a completely different system (Apex Clearing, 3 brokerage types: CASH/MARGIN/OPTION). DWH table contains eToro account types (19 rows: Private/Corporate/IB/etc.). Tier 1 tags claim verbatim inheritance from a wiki describing a different domain. Either the bundle resolution is wrong or these should be Tier 3."
    },
    {
      "severity": "high",
      "column_or_section": "Section 1, Section 2, Section 3.4 (ID=0 origin)",
      "problem": "Wiki claims 'ID=0 (N/A) is a DWH placeholder row from the production source itself (no separate placeholder insert in the SP).' The SP explicitly contains: INSERT INTO Dim_AccountType VALUES (0,'N/A',0,1,@ddate,@ddate) after the staging load. The 0-row IS a DWH placeholder inserted by the SP, contradicting the wiki's claim."
    },
    {
      "severity": "high",
      "column_or_section": "Name, StatusID, UpdateDate, InsertDate (nullable)",
      "problem": "DDL declares Name as varchar(50) NULL, StatusID as int NULL, UpdateDate as datetime NULL, InsertDate as datetime NULL. Wiki Elements table marks all four as NOT NULL. 4 out of 6 columns have incorrect nullable reporting."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 4, review-needed sidecar",
      "problem": "No acknowledgment anywhere that the upstream wiki (USABroker.Dictionary.AccountType) describes a completely different system than what the DWH table contains. The review-needed sidecar flags ID=18 Trust and DWHAccountTypeID redundancy but misses the fundamental domain mismatch between upstream wiki and actual data."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 2 (business logic categories)",
      "problem": "Category groupings (Retail, Corporate, Partner, Internal, Managed), system references (BackOffice, Trade, Hedge, Billing, Compliance), and behavioral claims (copy trading routing, fund allocation) are not grounded in any source in the bundle. With P3/P5 skipped, these are unverifiable domain assertions presented as fact."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag AccountTypeID and Name as Tier 3 (no matching upstream wiki available) OR fix the bundle resolution to find the correct etoro.Dictionary.AccountType wiki before claiming Tier 1. (2) Fix ID=0 origin: the SP explicitly inserts (0,'N/A',0,1,@ddate,@ddate) — this IS a DWH SP placeholder, not from production source. (3) Fix nullable values for Name, StatusID, UpdateDate, InsertDate — all NULL per DDL, not NOT NULL. (4) Add upstream wiki mismatch note to review-needed sidecar: USABroker.Dictionary.AccountType describes Apex Clearing (3 brokerage types), not eToro account types. (5) Mark Section 2 business logic groupings as unverified domain assertions or ground them in a citable source.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Section 1 claims 19 rows (IDs 0-18)",
      "Section 2 full value map with 19 rows and category assignments"
    ],
    "skipped_phases": [
      "P3 (data profiling)",
      "P5",
      "P6",
      "P7",
      "P9B",
      "P10"
    ]
  }
}
</JUDGE_VERDICT>
