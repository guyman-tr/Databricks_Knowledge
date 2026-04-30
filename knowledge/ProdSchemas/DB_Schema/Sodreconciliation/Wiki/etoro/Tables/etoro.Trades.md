# etoro.Trades

> Stores eToro's internal trade data fetched from the eToro Data API during reconciliation, used as the eToro-side comparison source against Apex Clearing's EXT872 trade activity.

| Property | Value |
|----------|-------|
| **Schema** | etoro |
| **Object Type** | Table |
| **Key Identifier** | Id (uniqueidentifier, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 active (1 PK + 2 NC) |

---

## 1. Business Meaning

This table stores eToro's internal trade data as fetched from the eToro Data API during the SOD reconciliation process. When an EXT872 (Trade Activity) file is imported from Apex, the reconciliation flow fetches eToro's trade data for the same date and stores it here for comparison.

Per Confluence: "Trades data is fetched if the processing file format is EXT872, data is saved to [etoro].[Trades] table." Discrepancies between this data and Apex's EXT872 data are written to `recon.TradeReconciliation`.

Each row represents one eToro trade execution for a specific account/instrument. Rich metadata includes position IDs, copy-trading mirror IDs, and open/close action types from eToro's internal system.

---

## 2. Business Logic

### 2.1 Apex Trade Matching

**What**: Each eToro trade can be linked to its matching Apex trade.

**Columns/Parameters Involved**: `ApexTradeActivityId`, `PositionIdApexFormat`

**Rules**:
- ApexTradeActivityId: FK to apex.EXT872_TradeActivity.Id. Set when matched.
- PositionIdApexFormat: eToro's position ID formatted for Apex order ID matching (used as the primary matching key)
- Unique filtered index on ApexTradeActivityId ensures 1:1

### 2.2 eToro-Specific Trade Context

**What**: Captures eToro platform-specific trade metadata not available in Apex data.

**Columns/Parameters Involved**: `PositionId`, `MirrorId`, `PositionOpenActionType`, `PositionCloseActionType`, `IsBuy`

**Rules**:
- PositionId: eToro's internal position ID (bigint)
- MirrorId: Copy-trading mirror ID (non-zero for copied trades)
- PositionOpenActionType/PositionCloseActionType: eToro action type codes
- IsBuy: Trade direction (1=Buy, 0=Sell)

---

## 3. Data Overview

Populated per reconciliation cycle. Sample eToro trades (all buys from a single reconciliation run):

| AccountNumber | Symbol | TradeQuantity | TradePrice | TradeDate | IsBuy | PositionId | MirrorId | Meaning |
|---|---|---|---|---|---|---|---|---|
| xxxx | MSFT | 3.83642 | 260.66 | 2022-05-23 16:35 | 1 | 2193508296 | NULL | Microsoft buy. Direct trade (MirrorId NULL = not copied). |
| xxxx | AMZN | 1.0 | 2111.98 | 2022-05-23 15:52 | 1 | 2193470753 | NULL | Amazon buy. Whole share at $2112 (pre-split price). |
| xxxx | COIN | 14.78197 | 67.65 | 2022-05-23 18:09 | 1 | 2193574599 | NULL | Coinbase buy. ~15 fractional shares. |
| xxxx | IDEX | 178.03098 | 0.56 | 2022-05-23 14:01 | 1 | 2193307213 | NULL | Ideanomics buy. Penny stock - 178 shares at $0.56. |
| xxxx | GLD | 3.75267 | 173.21 | 2022-05-23 14:11 | 1 | 2193332948 | NULL | SPDR Gold ETF buy. Fractional gold exposure. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | newsequentialid() | CODE-BACKED | Primary key. |
| 2 | SodFileId | uniqueidentifier | NO | - | VERIFIED | FK to apex.SodFiles.Id. Links to the EXT872 file import. CASCADE DELETE. |
| 3 | AccountNumber | nvarchar(max) | YES | - | CODE-BACKED | eToro/Apex account number (MASKED for PII). |
| 4 | Cusip | nvarchar(max) | YES | - | CODE-BACKED | CUSIP of the traded security. |
| 5 | TradeQuantity | decimal(28,10) | NO | - | CODE-BACKED | Trade quantity from eToro. Compared against Apex's Quantity. |
| 6 | TradePrice | decimal(28,10) | NO | - | CODE-BACKED | Execution price from eToro. Compared against Apex's Price. |
| 7 | TradeDate | datetime2(7) | NO | - | CODE-BACKED | Trade execution date from eToro. |
| 8 | ChangeType | nvarchar(max) | YES | - | NAME-INFERRED | Type of trade change/action (open, close, partial close, etc.). |
| 9 | InstrumentId | int | NO | 0 | CODE-BACKED | eToro internal instrument identifier. Default 0 when unresolved. |
| 10 | PositionId | bigint | NO | CONVERT(bigint,0) | CODE-BACKED | eToro internal position ID associated with this trade. |
| 11 | PositionIdApexFormat | nvarchar(max) | YES | - | CODE-BACKED | eToro position ID formatted for Apex order ID matching. Primary matching key between eToro trades and Apex's OrderId field. |
| 12 | Symbol | nvarchar(max) | YES | - | CODE-BACKED | Ticker symbol. |
| 13 | IsBuy | bit | NO | CONVERT(bit,0) | CODE-BACKED | Trade direction: 1=Buy/Long, 0=Sell/Short. Default 0. |
| 14 | MirrorId | int | YES | - | CODE-BACKED | eToro copy-trading mirror ID. Non-zero for trades copied from another trader. NULL/0 for direct trades. |
| 15 | ApexTradeActivityId | uniqueidentifier | YES | - | VERIFIED | FK to apex.EXT872_TradeActivity.Id. Matched Apex trade. NULL = no match. Unique filtered index. |
| 16 | PositionOpenActionType | int | YES | - | CODE-BACKED | eToro position open action type code (e.g., manual, copy, SL/TP trigger). |
| 17 | PositionCloseActionType | int | YES | - | CODE-BACKED | eToro position close action type code (e.g., manual close, stop loss, take profit). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SodFileId | apex.SodFiles | FK (CASCADE DELETE) | Triggering file import |
| ApexTradeActivityId | apex.EXT872_TradeActivity | FK | Matched Apex trade |

### 5.2 Referenced By (other objects point to this)

No direct FK consumers. Used by reconciliation comparison logic.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
etoro.Trades (table)
├── apex.SodFiles (table)
└── apex.EXT872_TradeActivity (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| apex.SodFiles | Table | FK from SodFileId (CASCADE) |
| apex.EXT872_TradeActivity | Table | FK from ApexTradeActivityId |

### 6.2 Objects That Depend On This

No dependents found in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EtoroTrades | CLUSTERED PK | Id | - | - | Active |
| IX_EtoroTrades_SodFileId_CoveringIndex | NC | SodFileId | AccountNumber, Cusip, Symbol, IsBuy, PositionIdApexFormat, TradeQuantity, TradePrice, TradeDate, InstrumentId, PositionId, MirrorId, PositionOpenActionType, PositionCloseActionType | - | Active |
| IX_Trades_ApexTradeActivityId | UNIQUE NC | ApexTradeActivityId | - | WHERE ApexTradeActivityId IS NOT NULL | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_EtoroTrades_SodFiles_SodFileId | FOREIGN KEY | CASCADE DELETE, WITH NOCHECK |
| FK_Trades_EXT872_TradeActivity_ApexTradeActivityId | FOREIGN KEY | WITH NOCHECK |
| (defaults) | DEFAULT | newsequentialid() for Id, 0 for InstrumentId, CONVERT(bigint,0) for PositionId, CONVERT(bit,0) for IsBuy |

---

## 8. Sample Queries

### 8.1 Get eToro trades for a reconciliation run

```sql
SELECT AccountNumber, Symbol, Cusip, TradeQuantity, TradePrice, TradeDate, IsBuy, PositionId
FROM etoro.Trades WITH (NOLOCK)
WHERE SodFileId = '{sod-file-id}'
ORDER BY AccountNumber, Symbol;
```

### 8.2 Find unmatched eToro trades

```sql
SELECT AccountNumber, Symbol, TradeQuantity, TradePrice, PositionIdApexFormat
FROM etoro.Trades WITH (NOLOCK)
WHERE SodFileId = '{sod-file-id}' AND ApexTradeActivityId IS NULL;
```

### 8.3 Find copy-traded transactions

```sql
SELECT AccountNumber, Symbol, TradeQuantity, MirrorId, PositionId
FROM etoro.Trades WITH (NOLOCK)
WHERE SodFileId = '{sod-file-id}' AND MirrorId IS NOT NULL AND MirrorId <> 0;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Design and flows](https://etoro-jira.atlassian.net/wiki/spaces/view/2169700393) | Confluence | Flow 2: "Trades data is fetched if the processing file format is EXT872, data is saved to [etoro].[Trades] table" |

---

*Generated: 2026-04-11 | Enriched: - | Quality: 9.0/10 (Elements: 9.4/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: etoro.Trades | Type: Table | Source: Sodreconciliation/Sodreconciliation/etoro/Tables/etoro.Trades.sql*
