# Trade.FundMgrSync

> Synchronizes a Smart Portfolio fund definition from the Rankings Fund Manager system, matching external assets to local instruments by ISIN code and creating fund allocations via Trade.CreateNewFundAllocation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundID + @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure imports a Smart Portfolio fund definition from the external Rankings Fund Manager system into the eToro trading platform. The Fund Manager system defines which assets (identified by ISIN codes) should be included in a fund, with what allocation percentages, stop-loss/take-profit levels, and leverage settings.

The procedure exists to bridge the gap between the external fund management system (accessed via synonyms prefixed with `SYN_RankingsFundMgr*`) and the eToro trading system. It resolves external asset ISIN codes to eToro InstrumentIDs via `Trade.InstrumentMetaData`, validates all instruments exist, and then creates fund allocations using `Trade.CreateNewFundAllocation` for each asset in the fund.

If any instrument cannot be matched by ISIN code, the procedure raises an informational error listing the missing instruments and returns without creating any allocations.

---

## 2. Business Logic

### 2.1 ISIN-Based Instrument Resolution

**What**: Maps external fund assets to eToro instruments using ISIN codes.

**Columns/Parameters Involved**: `ISINCode`, `InstrumentID`, `SymbolFull`

**Rules**:
- External assets from SYN_RankingsFundMgrAsset provide ISINCode
- Trade.InstrumentMetaData provides the ISIN-to-InstrumentID mapping
- If ANY asset has no matching InstrumentID after ISIN resolution, the procedure RAISERRORs with severity 10 listing the missing instruments and returns
- Crypto detection: counts instruments with InstrumentTypeID=10 and sets @HasCrypto flag

### 2.2 Fund Allocation Creation

**What**: Creates individual fund allocations by iterating through fund assets.

**Columns/Parameters Involved**: `@InvestmentPct`, `@StopLossPct`, `@TakeProfitPct`, `@IsBuy`, `@Leverage`

**Rules**:
- Each allocation is created via Trade.CreateNewFundAllocation (cursor-based iteration)
- RefreshIntervalMonths calculated as MAX date range across all fund intervals + 1
- Start/end dates formatted as dd/MM/yyyy strings for the allocation procedure
- Each asset gets its own allocation with investment percentage, SL/TP percentages, direction, and leverage

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundID | int | NO | - | CODE-BACKED | Fund identifier in the Rankings Fund Manager system. Used to query fund definition from SYN_RankingsFundMgr* synonyms. |
| 2 | @CID | int | NO | - | CODE-BACKED | Customer ID who owns/manages this Smart Portfolio. Passed to CreateNewFundAllocation for allocation creation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | SYN_RankingsFundMgrFundIntervalType | READER | Reads fund interval definitions (date ranges) |
| SELECT | SYN_RankingsFundMgrFundIntervalAllocation | READER | Reads asset allocation data per interval |
| SELECT | SYN_RankingsFundMgrAsset | READER | Reads external asset metadata (ISIN, name) |
| SELECT | SYN_RankingsFundMgrFund | READER | Reads fund name and minimum amount |
| JOIN | Trade.InstrumentMetaData | READER | Resolves ISIN codes to InstrumentIDs |
| JOIN | Trade.GetInstrument | READER | Checks InstrumentTypeID for crypto detection |
| EXEC | Trade.CreateNewFundAllocation | Caller | Creates each fund allocation record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | Called by fund management workflows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FundMgrSync (procedure)
+-- SYN_RankingsFundMgrFundIntervalType (synonym)
+-- SYN_RankingsFundMgrFundIntervalAllocation (synonym)
+-- SYN_RankingsFundMgrAsset (synonym)
+-- SYN_RankingsFundMgrFund (synonym)
+-- Trade.InstrumentMetaData (table)
+-- Trade.GetInstrument (view)
+-- Trade.CreateNewFundAllocation (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| SYN_RankingsFundMgrFundIntervalType | Synonym | JOIN - fund interval definitions |
| SYN_RankingsFundMgrFundIntervalAllocation | Synonym | JOIN - asset allocations |
| SYN_RankingsFundMgrAsset | Synonym | JOIN - external asset metadata |
| SYN_RankingsFundMgrFund | Synonym | JOIN - fund name and settings |
| Trade.InstrumentMetaData | Table | JOIN - ISIN to InstrumentID resolution |
| Trade.GetInstrument | View | JOIN - instrument type for crypto detection |
| Trade.CreateNewFundAllocation | Stored Procedure | EXEC - creates each allocation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Error Handling**: RAISERROR with severity 10 (informational) when instruments are missing. Does not throw - just returns early.

---

## 8. Sample Queries

### 8.1 Sync a Fund from Fund Manager

```sql
EXEC Trade.FundMgrSync @FundID = 500, @CID = 12345
```

### 8.2 Preview Fund Assets and Their ISIN Matching

```sql
SELECT fa.AssetID,
       fma.ISINCode,
       fma.Name,
       imd.InstrumentID,
       imd.SymbolFull
  FROM SYN_RankingsFundMgrFundIntervalAllocation fa WITH (NOLOCK)
  JOIN SYN_RankingsFundMgrAsset fma WITH (NOLOCK) ON fa.AssetID = fma.AssetID
  JOIN SYN_RankingsFundMgrFundIntervalType fit WITH (NOLOCK) ON fa.FundIntervalID = fit.FundIntervalID
  LEFT JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON fma.ISINCode = imd.ISINCode
 WHERE fit.FundID = 500
```

### 8.3 Find Instruments with ISIN Codes

```sql
SELECT InstrumentID,
       SymbolFull,
       ISINCode,
       InstrumentTypeID
  FROM Trade.InstrumentMetaData WITH (NOLOCK)
 WHERE ISINCode IS NOT NULL
 ORDER BY InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FundMgrSync | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.FundMgrSync.sql*
