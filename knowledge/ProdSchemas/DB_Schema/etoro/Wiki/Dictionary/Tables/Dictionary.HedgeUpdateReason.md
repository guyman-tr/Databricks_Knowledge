# Dictionary.HedgeUpdateReason

> Lookup table defining five reasons for hedge position updates — reconciliation corrections, rerouting between LPs, manual direct hedging, and other adjustments that explain why a hedge position was modified outside the normal automated flow.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ReasonID (SMALLINT IDENTITY, CLUSTERED PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (PK + unique on Reason) |

---

## 1. Business Meaning

Dictionary.HedgeUpdateReason classifies the reasons why a hedge position was manually updated or adjusted outside the normal automated hedging flow. Most hedge operations happen automatically in response to customer trades, but operational needs — reconciliation after a system failure, rerouting positions between liquidity providers, or direct manual intervention by the hedge desk — require separate classification for audit and reporting.

This table exists because hedge updates carry financial and regulatory significance. Every modification to a hedge position must be explainable — auditors and risk managers need to know whether an update was due to automated reconciliation, operational rerouting, or manual human intervention. The reason classification drives reporting in the hedge operations dashboard.

The ReasonID is consumed by the Dictionary.GetAllHedgeUpdateReasons stored procedure, which returns the full list for UI dropdowns in the hedge management interface.

---

## 2. Business Logic

### 2.1 Update Reason Categories

**What**: Five reasons classify why hedge positions were modified, from automated corrections to manual interventions.

**Columns/Parameters Involved**: `ReasonID`, `Reason`

**Rules**:
- **Unknown (0)**: Default/unclassified. The update was applied but the reason was not specified. Should be investigated if occurring frequently.
- **Reconciliation (1)**: Automated correction after a comparison between local and LP records identified a discrepancy. The system adjusted the local position to match the LP's confirmed state.
- **Reroute (2)**: Position was moved from one liquidity provider to another. Happens when an LP has liquidity issues, pricing problems, or during planned LP migrations.
- **Manual Hedging directly to LP (3)**: The hedge operations team placed or modified a hedge order directly with the liquidity provider, bypassing eToro's automated hedge server. Used for emergency situations or complex multi-leg hedges.
- **Other (4)**: Catch-all for updates that don't fit the above categories. Should include a freeform description in the related log entry.

**Diagram**:
```
Hedge Update Reasons:
├── Automated
│     ├── Reconciliation (1)    — System auto-corrected discrepancy
│     └── Reroute (2)           — Moved between liquidity providers
│
├── Manual
│     └── Direct to LP (3)     — Operator placed order directly
│
└── Unclassified
      ├── Unknown (0)          — Not specified (investigate)
      └── Other (4)            — Catch-all with description
```

---

## 3. Data Overview

| ReasonID | Reason | Meaning |
|---|---|---|
| 0 | Unknown | Default reason when no specific classification was provided. May indicate a legacy update before reason tracking was implemented, or an operator who skipped the reason field. Should be investigated if frequent. |
| 1 | Reconciliation | Automated correction triggered by a mismatch between local hedge records and liquidity provider records. The system detected a discrepancy (position size, state, or existence) and corrected the local records. |
| 2 | Reroute | Position was intentionally moved from one liquidity provider to another. Typically occurs during LP transitions, when an LP experiences issues, or when better pricing is available elsewhere. |
| 3 | Manual Hedging directly to the Liquidity Provider | The hedge operations team bypassed the automated hedge server and placed or modified orders directly with the LP. Used for emergency corrections, complex multi-leg strategies, or when the automated system is unavailable. |
| 4 | Other | Catch-all for updates that don't fit standard categories. The related log entry should contain additional context explaining the specific reason. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReasonID | smallint | NO | IDENTITY(0,1) | VERIFIED | Primary key (auto-incrementing from 0) identifying the hedge update reason. 0=Unknown, 1=Reconciliation, 2=Reroute, 3=Manual Hedging directly to LP, 4=Other. Consumed by Dictionary.GetAllHedgeUpdateReasons for UI dropdowns. |
| 2 | Reason | varchar(100) | NO | - | VERIFIED | Human-readable description of the update reason. Constrained by unique index (unique_reason) — no duplicate reasons allowed. Displayed in hedge management interfaces, audit logs, and operational reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.GetAllHedgeUpdateReasons | - | Reader | Returns the full list for UI dropdowns in hedge management interface |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.GetAllHedgeUpdateReasons | Stored Procedure | Reads — returns all reasons for dropdown population |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| pk_Reasons | CLUSTERED PK | ReasonID ASC | - | - | Active |
| unique_reason | UNIQUE NC | Reason ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| pk_Reasons | PRIMARY KEY | Unique reason identifier (auto-incrementing from 0) |
| unique_reason | UNIQUE | No duplicate reason descriptions allowed |

---

## 8. Sample Queries

### 8.1 List all update reasons
```sql
SELECT  ReasonID,
        Reason
FROM    [Dictionary].[HedgeUpdateReason] WITH (NOLOCK)
ORDER BY ReasonID;
```

### 8.2 Use the GetAllHedgeUpdateReasons procedure
```sql
EXEC [Dictionary].[GetAllHedgeUpdateReasons];
```

### 8.3 Categorize reasons by intervention type
```sql
SELECT  ReasonID,
        Reason,
        CASE
            WHEN ReasonID IN (1, 2) THEN 'Automated/System'
            WHEN ReasonID = 3       THEN 'Manual/Human'
            ELSE                         'Unclassified'
        END AS InterventionType
FROM    [Dictionary].[HedgeUpdateReason] WITH (NOLOCK)
ORDER BY ReasonID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HedgeUpdateReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HedgeUpdateReason.sql*
