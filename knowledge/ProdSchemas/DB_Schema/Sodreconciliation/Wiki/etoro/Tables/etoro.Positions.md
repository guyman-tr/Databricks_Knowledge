# etoro.Positions

> Stores eToro's internal position data fetched from the eToro Data API during reconciliation, used as the eToro-side comparison source against Apex Clearing's EXT871 position snapshot.

| Property | Value |
|----------|-------|
| **Schema** | etoro |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 4 active (1 PK + 3 NC) |

---

## 1. Business Meaning

This table stores eToro's internal position data as fetched from the eToro Data API during the SOD reconciliation process (Flow 2). When an EXT871 (Position Activity) file is imported from Apex, the reconciliation flow fetches eToro's position data for the same date and stores it here. This becomes the eToro-side source for comparison against Apex positions.

Per Confluence: "Positions data is fetched if the processing file format is EXT871, data is saved to [etoro].[Positions] table." The data is then compared to Apex's EXT871 data, with discrepancies written to `recon.PositionReconciliation`.

Each row represents one eToro position for a specific account/instrument on a given reconciliation date. The `ApexPositionActivityId` FK links to the matched Apex position row when a match is found.

---

## 2. Business Logic

### 2.1 Apex Position Matching

**What**: Each eToro position can optionally be linked to its matching Apex position.

**Columns/Parameters Involved**: `ApexPositionActivityId`

**Rules**:
- ApexPositionActivityId: FK to apex.EXT871_PositionActivity.Id. Set when a matching Apex position is found.
- NULL when no Apex match exists (eToro-only position - a break)
- Unique filtered index ensures 1:1 mapping between eToro and Apex positions

---

## 3. Data Overview

Populated per reconciliation cycle. Sample eToro positions (well-known US stocks):

| AccountNumber | Cusip | Symbol | TradeQuantity | AverageOpenPrice | InstrumentId | Meaning |
|---|---|---|---|---|---|---|
| xxxx | 654106103 | NKE | 0.12995 | 115.43 | 1042 | Fractional Nike position. 0.13 shares at $115.43 avg open. |
| xxxx | 92826C839 | V | 0.24345 | 205.35 | 1046 | Fractional Visa position. |
| xxxx | 30303M102 | FB | 0.32663 | 214.31 | 1003 | Fractional Meta/Facebook position. Symbol still "FB" (pre-rename). |
| xxxx | 037833100 | AAPL | 0.145 | 137.93 | 1001 | Fractional Apple position. |
| xxxx | 76954A103 | RIVN | 4.71168 | 45.25 | 9287 | Rivian position - larger holding at $45.25 avg. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. |
| 2 | SodFileId | uniqueidentifier | NO | - | VERIFIED | FK to apex.SodFiles.Id. Links to the EXT871 file import that triggered this data fetch. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | eToro/Apex account number (MASKED for PII). |
| 4 | Cusip | varchar(12) | YES | - | CODE-BACKED | CUSIP of the held security. |
| 5 | TradeQuantity | decimal(28,10) | NO | - | CODE-BACKED | Position quantity (number of shares/units) as reported by eToro. Compared against Apex's TradeQuantity. |
| 6 | Symbol | nvarchar(max) | YES | - | CODE-BACKED | Ticker symbol of the security. |
| 7 | AverageOpenPrice | decimal(28,10) | YES | - | CODE-BACKED | Average opening price of the position from eToro's records. |
| 8 | InstrumentId | int | NO | 0 | CODE-BACKED | eToro internal instrument identifier. Default 0 when not resolved. |
| 9 | ApexPositionActivityId | uniqueidentifier | YES | - | VERIFIED | FK to apex.EXT871_PositionActivity.Id. The matched Apex position. NULL = no match found (potential break). Unique filtered index ensures 1:1. |
| 10 | AverageClosePrice | decimal(28,10) | YES | - | CODE-BACKED | Average close price for closed positions from eToro's records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (CASCADE DELETE) | Links to triggering file import |
| ApexPositionActivityId | apex.EXT871_PositionActivity | FK | Matched Apex position |

### 5.2 Referenced By (other objects point to this)

No direct FK consumers. Used indirectly by the reconciliation comparison logic.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
etoro.Positions (table)
├── apex.SodFiles (table)
└── apex.EXT871_PositionActivity (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId (CASCADE) |
| apex.EXT871_PositionActivity | Table | FK from ApexPositionActivityId |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EtoroPositions | CLUSTERED PK | Id | - | - | Active |
| IX_EtoroPositions_ApexPositionActivityId | UNIQUE NC | ApexPositionActivityId | - | WHERE ApexPositionActivityId IS NOT NULL | Active |
| IX_EtoroPositions_SodFileId_CoveringIndex | NC | SodFileId | AccountNumber, Cusip, TradeQuantity, Symbol, AverageOpenPrice, InstrumentId | - | Active |
| IX_SodFileId | NC | SodFileId, AccountNumber | Cusip, Symbol, ApexPositionActivityId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_EtoroPositions_SodFiles_SodFileId | FOREIGN KEY | CASCADE DELETE, WITH NOCHECK |
| FK_EtoroPositions_EXT871_PositionActivity_ApexPositionActivityId | FOREIGN KEY | WITH NOCHECK |
| (default) | DEFAULT | newsequentialid() for Id, 0 for InstrumentId |

---

## 8. Sample Queries

### 8.1 Get eToro positions for a reconciliation run

```sql
SELECT AccountNumber, Symbol, Cusip, TradeQuantity, AverageOpenPrice, InstrumentId
FROM etoro.Positions WITH (NOLOCK)
WHERE SodFileId = '{sod-file-id}'
ORDER BY AccountNumber, Symbol;
```

### 8.2 Find unmatched eToro positions (no Apex match)

```sql
SELECT AccountNumber, Symbol, TradeQuantity
FROM etoro.Positions WITH (NOLOCK)
WHERE SodFileId = '{sod-file-id}' AND ApexPositionActivityId IS NULL;
```

### 8.3 Compare eToro vs Apex quantities

```sql
SELECT ep.AccountNumber, ep.Symbol, ep.TradeQuantity AS EtoroQty, ap.TradeQuantity AS ApexQty
FROM etoro.Positions ep WITH (NOLOCK)
JOIN apex.EXT871_PositionActivity ap WITH (NOLOCK) ON ep.ApexPositionActivityId = ap.Id
WHERE ep.SodFileId = '{sod-file-id}'
ORDER BY ep.AccountNumber;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | Flow 2: "Positions data is fetched if the processing file format is EXT871, data is saved to [etoro].[Positions] table" |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: etoro.Positions | Type: Table | Source: Sodreconciliation/Sodreconciliation/etoro/Tables/etoro.Positions.sql*
