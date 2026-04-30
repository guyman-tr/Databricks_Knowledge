# Dictionary.FinanceReportLevel

> Lookup table that classifies the outcome of crypto wallet balance reconciliation runs comparing eToro, BitGo (custody), and Blox (portfolio tracking) systems.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.FinanceReportLevel defines the classification outcomes for crypto wallet balance reconciliation. Each row represents a distinct reconciliation result type that describes whether balance numbers agree across the three source systems (eToro internal ledger, BitGo custody provider, and Blox portfolio tracker), which system disagrees, or whether an API error prevented comparison.

This table exists because the finance reporting system must categorize every reconciliation run's outcome so that operations teams can filter, prioritize, and investigate discrepancies. Without these classifications, reconciliation results would be opaque -- there would be no way to distinguish a three-way mismatch from an API timeout or a self-resolving temporary discrepancy.

Data flows into consumers (Wallet.FinanceReportRecords and the legacy Wallet.FinanceReportsBalances_old) via the LevelId foreign key. The reconciliation engine assigns one of the 13 classification values to each record after comparing balances from all three sources. The values are static reference data -- they are inserted once and not modified by application logic.

---

## 2. Business Logic

### 2.1 Reconciliation Outcome Classification

**What**: A tiered classification system that categorizes balance comparison results into actionable groups.

**Columns/Parameters Involved**: `Id`, `Name`, `Description`

**Rules**:
- Values 1-4 represent complete comparisons where all three source APIs responded successfully. The classification describes WHICH systems disagree (or if they eventually agreed).
- Values 5-11 represent degraded comparisons where one or more API calls failed (BitGo error, Blox error, or invalid Blox account). The classification captures both the error source AND the outcome of whatever partial comparison was possible.
- Value 12 (InternalError) is a system-level fallback indicating the classification engine itself failed -- the reconciliation result could not be categorized.
- Value 100 (InitialDiscrepancy) is a catch-all default for newly detected discrepancies before deeper classification runs. The large gap from 12 to 100 reserves space for future granular error types.

**Diagram**:
```
Reconciliation Run
       |
       v
  All APIs OK? ----NO----> Which API failed?
       |                         |
      YES                   +---------+---------+
       |                    |         |         |
       v               BitGo err  Blox err  Invalid Blox
  Compare all 3             |         |         |
       |               (5,9,10)   (6,8,11)     (7)
       v
  All match? ---YES--> EventualyConsolidated (1)
       |
      NO
       |
  Which differ?
       |
  +----+----+----+
  |         |    |
AllDiff  EtoroDiff  MultipleAddresses
  (2)      (3)         (4)
```

---

## 3. Data Overview

| Id | Name | Description | Meaning |
|----|------|-------------|---------|
| 1 | EventualyConsolidated | find discrepancy but evantualy numbers matched | Temporary discrepancy that self-resolved -- initial mismatch was detected during the reconciliation window but balances converged by the end. Indicates timing differences rather than true errors. |
| 2 | AllDiff | bitgo blox and etoro have different numbers | Full three-way mismatch requiring manual investigation -- all three sources disagree, meaning no single source can be trusted without further analysis. |
| 3 | EtoroDiffBoth | bitgo and blox have the same number but etoro diferent | The two external systems agree with each other but eToro's internal ledger differs -- strongly suggests an eToro booking, sync, or ledger issue since independent external sources corroborate each other. |
| 5 | BitgoError | bitgo API error | BitGo custody API was unreachable or returned an error, preventing any comparison against the custodian's balance. Requires retry or manual BitGo verification. |
| 100 | InitialDiscrepancy | Unhandled initial discrepancy | Catch-all for newly detected mismatches that have not yet been classified into a more specific category. Often the starting state before the classification engine refines the outcome. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Primary key and classification identifier. Values 1-12 represent specific reconciliation outcomes; value 100 is a catch-all for unhandled initial discrepancies. The numbering gap (12 to 100) reserves space for future granular classifications. Referenced as LevelId in Wallet.FinanceReportRecords and Wallet.FinanceReportsBalances_old. See [Finance Report Level](../../_glossary.md#finance-report-level) for full value definitions. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Machine-readable label for the classification level. Used in application logic and reporting filters. Values follow PascalCase naming (e.g., EventualyConsolidated, AllDiff, EtoroDiffBoth, BitgoError, BloxError, InternalError, InitialDiscrepancy). |
| 3 | Description | varchar(128) | YES | - | CODE-BACKED | Human-readable explanation of what the classification means. Describes the reconciliation scenario in plain English -- which systems match, which differ, or which API failed. Nullable but populated for all current rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.FinanceReportRecords | LevelId | FK (explicit) | Each reconciliation record is classified with a FinanceReportLevel. FK constraint: FK__FinanceReportRecords__LevelId. |
| Wallet.FinanceReportsBalances_old | LevelId | FK (explicit) | Legacy balance reconciliation records. Each row references a classification level. Unnamed FK constraint. |
| History.FinanceReportsBalances | LevelId | FK (implicit) | Archived balance reconciliation records. LevelId classifies the reconciliation outcome after API verification. NULL = no discrepancy, 100 = initial discrepancy, 1-12 = specific classification. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.FinanceReportRecords | Table | FK on LevelId -- each reconciliation record references a classification level |
| Wallet.FinanceReportsBalances_old | Table | FK on LevelId -- legacy balance records reference a classification level |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FinanceReportLevel_Id | CLUSTERED PK | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_FinanceReportLevel_Id | PRIMARY KEY | Clustered on Id. DATA_COMPRESSION = PAGE. Ensures each classification level has a unique integer identifier. |

---

## 8. Sample Queries

### 8.1 List all reconciliation classification levels
```sql
SELECT Id, Name, Description
FROM Dictionary.FinanceReportLevel WITH (NOLOCK)
ORDER BY Id;
```

### 8.2 Find reconciliation records by classification level
```sql
SELECT r.Id, r.LevelId, l.Name AS LevelName, l.Description AS LevelDescription
FROM Wallet.FinanceReportRecords r WITH (NOLOCK)
INNER JOIN Dictionary.FinanceReportLevel l WITH (NOLOCK) ON r.LevelId = l.Id
WHERE l.Name = 'AllDiff';
```

### 8.3 Count reconciliation records by classification level
```sql
SELECT l.Id, l.Name, COUNT(r.Id) AS RecordCount
FROM Dictionary.FinanceReportLevel l WITH (NOLOCK)
LEFT JOIN Wallet.FinanceReportRecords r WITH (NOLOCK) ON r.LevelId = l.Id
GROUP BY l.Id, l.Name
ORDER BY RecordCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Confluence searches for "FinanceReportLevel" and related terms returned no results. Jira MCP was unavailable (410 Gone).

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FinanceReportLevel | Type: Table | Source: WalletBalancesReportDB/Dictionary/Tables/Dictionary.FinanceReportLevel.sql*
