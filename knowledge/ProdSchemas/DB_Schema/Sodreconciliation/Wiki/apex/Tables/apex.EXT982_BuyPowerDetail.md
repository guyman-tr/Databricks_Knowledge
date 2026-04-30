# apex.EXT982_BuyPowerDetail

> Position-level buying power detail from Apex Clearing EXT982 extract: per-security margin requirements and option strategy information.

| Property | Value |
|----------|-------|
| **Schema** | apex |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 PK + 1 NC) |

---

## 1. Business Meaning

This table stores the daily position-level buying power detail from Apex Clearing's EXT982 extract. While EXT981 provides account-level buying power summaries, EXT982 breaks down margin requirements at the individual security/position level. Each row shows a single position's contribution to the account's overall margin requirement, including maintenance and concentration requirements.

The EXT982 data is essential for understanding the composition of margin requirements. When investigating why an account has a margin call or reduced buying power, this data identifies which specific positions are driving the requirement. It also captures option strategy information, showing how paired option legs are grouped and their combined margin impact.

Data flows through the standard SOD pipeline: Azure Data Factory pulls the EXT982 CSV from Apex's SFTP, stores it in Azure Blob Storage, Event Grid triggers the SOD Azure Function, which parses the file and bulk-loads rows into this table with a reference to the parent SodFiles record.

---

## 2. Business Logic

### 2.1 Option Strategy Grouping

**What**: Option positions are grouped into strategies for combined margin treatment.

**Columns Involved**: `StrategyId`, `StrategySequence`, `OptionStrategy`, `OptionLeg`, `StrategyMaintenanceRequirement`, `StrategyConcentrationRequirement`

**Rules**:
- StrategyId groups positions belonging to the same option strategy
- StrategySequence orders the legs within a strategy
- OptionStrategy describes the strategy type (e.g., covered call, vertical spread)
- OptionLeg identifies the specific leg within the strategy
- Strategy-level requirements may be lower than the sum of individual leg requirements

### 2.2 Position Margin Breakdown

**What**: Each position has individual and concentration-based requirements.

**Columns Involved**: `MaintenanceRequirement`, `ConcentrationRequirement`, `MarketValue`, `ClosingPrice`, `TradeQuantity`

**Rules**:
- MaintenanceRequirement is the standard margin required for the position
- ConcentrationRequirement is an additional surcharge for overweight positions
- Total position requirement = MaintenanceRequirement + ConcentrationRequirement

---

## 3. Data Overview

N/A - Apex Clearing daily extract data. Rows are bulk-loaded per SodFiles import.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. Auto-generated sequential GUID for each row. |
| 2 | SodFileId | uniqueidentifier | NO | - | CODE-BACKED | FK to apex.SodFiles. Links this row to the specific EXT982 file import. CASCADE DELETE. |
| 3 | AccountNumber | varchar(12) | YES | - | CODE-BACKED | Apex customer account number. MASKED (PII). |
| 4 | Firm | varchar(2) | YES | - | CODE-BACKED | Clearing firm identifier. |
| 5 | OfficeCode | varchar(3) | YES | - | CODE-BACKED | Apex office/branch code. |
| 6 | StrategyId | int | YES | - | CODE-BACKED | Option strategy group identifier linking paired positions. |
| 7 | StrategySequence | int | YES | - | CODE-BACKED | Sequence number of this position within the option strategy. |
| 8 | AccountType | varchar(12) | YES | - | CODE-BACKED | Account type code. |
| 9 | Cusip | varchar(12) | YES | - | CODE-BACKED | CUSIP identifier of the security. |
| 10 | TradeQuantity | decimal(28,10) | YES | - | CODE-BACKED | Trade-date position quantity. |
| 11 | Symbol | varchar(35) | YES | - | CODE-BACKED | Trading symbol of the security. |
| 12 | Description | varchar(40) | YES | - | CODE-BACKED | Security description. |
| 13 | ClosingPrice | decimal(28,10) | YES | - | CODE-BACKED | Closing/market price of the security. |
| 14 | MarketValue | decimal(28,10) | YES | - | CODE-BACKED | Market value of the position (Quantity * ClosingPrice). |
| 15 | SecurityTypeCode | varchar(50) | YES | - | CODE-BACKED | Security type classification code. |
| 16 | UnderlyingSymbol | varchar(50) | YES | - | CODE-BACKED | Underlying security symbol for options/derivatives. |
| 17 | StrikePrice | decimal(28,10) | YES | - | CODE-BACKED | Strike price for option positions. |
| 18 | ISIN | varchar(12) | YES | - | CODE-BACKED | International Securities Identification Number. |
| 19 | Change | decimal(28,10) | YES | - | CODE-BACKED | Price change from prior day close. |
| 20 | PositionType | varchar(50) | YES | - | CODE-BACKED | Position type classification (long, short, etc.). |
| 21 | ProcessDate | smalldatetime | YES | - | CODE-BACKED | Business date of the Apex extract file. |
| 22 | IsSelling | varchar(1) | YES | - | NAME-INFERRED | Flag indicating if there is a pending sell order for this position. |
| 23 | MaintenanceRequirement | decimal(28,10) | YES | - | CODE-BACKED | Maintenance margin requirement for this individual position. |
| 24 | ConcentrationRequirement | decimal(28,10) | YES | - | CODE-BACKED | Additional concentration margin surcharge for this position. |
| 25 | OptionStrategy | varchar(50) | YES | - | CODE-BACKED | Option strategy type description (e.g., covered call, vertical spread). |
| 26 | OptionLeg | varchar(10) | YES | - | CODE-BACKED | Leg identifier within the option strategy. |
| 27 | StrategyMaintenanceRequirement | decimal(28,10) | YES | - | CODE-BACKED | Combined maintenance requirement for the entire option strategy. |
| 28 | StrategyConcentrationRequirement | decimal(28,10) | YES | - | CODE-BACKED | Combined concentration requirement for the entire option strategy. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (ON DELETE CASCADE) | Links to source file import |

### 5.2 Referenced By (other objects point to this)

No known consumers.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
apex.EXT982_BuyPowerDetail (table)
  └── apex.SodFiles (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EXT982_BuyPowerDetail | CLUSTERED PK | Id | - | - | Active |
| IX_EXT982_BuyPowerDetail_SodFileId | NC | SodFileId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EXT982_BuyPowerDetail | PRIMARY KEY | Unique Id per row |
| FK_EXT982_BuyPowerDetail_SodFiles_SodFileId | FOREIGN KEY (NOCHECK) | SodFileId -> apex.SodFiles.Id (CASCADE DELETE) |
| (default) | DEFAULT | newsequentialid() for Id |

---

## 8. Sample Queries

### 8.1 Get position-level requirements for an account

```sql
SELECT AccountNumber, Symbol, Cusip, TradeQuantity, MarketValue,
       MaintenanceRequirement, ConcentrationRequirement, OptionStrategy, ProcessDate
FROM apex.EXT982_BuyPowerDetail WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 982 AND Status = 2 ORDER BY ProcessDate DESC)
ORDER BY AccountNumber, MaintenanceRequirement DESC;
```

### 8.2 Find positions with concentration surcharges

```sql
SELECT AccountNumber, Symbol, MarketValue, MaintenanceRequirement, ConcentrationRequirement,
       (MaintenanceRequirement + ConcentrationRequirement) AS TotalRequirement
FROM apex.EXT982_BuyPowerDetail WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 982 AND Status = 2 ORDER BY ProcessDate DESC)
  AND ConcentrationRequirement > 0
ORDER BY ConcentrationRequirement DESC;
```

### 8.3 View option strategies and their combined requirements

```sql
SELECT AccountNumber, StrategyId, OptionStrategy, OptionLeg, Symbol, TradeQuantity, StrikePrice,
       MaintenanceRequirement, StrategyMaintenanceRequirement
FROM apex.EXT982_BuyPowerDetail WITH (NOLOCK)
WHERE SodFileId = (SELECT TOP 1 Id FROM apex.SodFiles WITH (NOLOCK) WHERE ApexFormat = 982 AND Status = 2 ORDER BY ProcessDate DESC)
  AND OptionStrategy IS NOT NULL
ORDER BY AccountNumber, StrategyId, StrategySequence;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | SOD file import pipeline architecture |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.5/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 3/11*
*Object: apex.EXT982_BuyPowerDetail | Type: Table | Source: Sodreconciliation/Sodreconciliation/apex/Tables/apex.EXT982_BuyPowerDetail.sql*
