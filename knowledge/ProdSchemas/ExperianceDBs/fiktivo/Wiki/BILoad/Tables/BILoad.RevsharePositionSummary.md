# BILoad.RevsharePositionSummary

> ADF staging table that holds customer-level aggregated revenue-share position data - combining closed position commissions, open position commissions, trading metrics, and affiliate attribution - before being loaded into the commission system.

| Property | Value |
|----------|-------|
| **Schema** | BILoad |
| **Object Type** | Table |
| **Key Identifier** | No PK - staging table with no unique constraint |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

BILoad.RevsharePositionSummary is the primary ADF staging table for the revenue-share commission pipeline. Each row represents a customer-level aggregate of trading position data - summarizing commission fees, net profit, lot volumes, and affiliate attribution for a given customer (CID) as calculated by the upstream revenue-share process on the eToro platform. This table provides the financial substance of the commission calculation, while BILoad.HistoryClosedPosition provides the position-level detail.

This table exists because the ADF pipeline performs revenue-share calculations externally (on the eToro platform side) and lands the results here for consumption by the affiliate commission system. Without it, the commission system would need direct access to the eToro trading database to compute revenue-share metrics - the old linked-server approach that this ADF pipeline replaces.

Data flows in from Azure Data Factory (external), is consumed by AffiliateCommission.LoadClosedPositionsAndAggregates_ADF in two phases: Phase 1 inserts rows with LastClosedPosition IS NOT NULL into ClosedPositionFromEtoro_ADF (with commission converted from dollars to cents: `(Commission + CP_CloseTotalFees) * 100`), and Phase 3 upserts customer aggregated data via MERGE into CustomerAggregatedData_ADF (incrementally summing commission totals and updating position dates). After processing, BILoad.TruncateLoadTable clears this table for the next batch.

---

## 2. Business Logic

### 2.1 Commission Calculation and Unit Conversion

**What**: The downstream load procedure transforms raw dollar amounts from this staging table into cents for the commission system.

**Columns/Parameters Involved**: `Commission`, `CP_CloseTotalFees`, `CP_CommissionOnClose`, `CP_OpenTotalFees`, `OP_Commission`, `OP_OpenTotalFees`, `OP_Current_Commission`, `OP_Current_OpenTotalFees`

**Rules**:
- Commission for ClosedPositionFromEtoro_ADF = CAST(ISNULL(Commission, 0) + ISNULL(CP_CloseTotalFees, 0) AS MONEY) * 100
- The *100 converts dollars to cents format used by the downstream commission tables
- TotalCommissionOnOpen (for aggregation) = ISNULL(OP_Commission, 0) + ISNULL(OP_OpenTotalFees, 0)
- TotalCommissionOnClose (for aggregation) = ISNULL(CP_CommissionOnClose, 0) + ISNULL(CP_CloseTotalFees, 0)
- OpenedPositionsCommissionOnOpen = ISNULL(OP_Current_Commission, 0) + ISNULL(OP_Current_OpenTotalFees, 0)
- All ISNULL wrappers handle NULL values as zero - NULL means "no data for this component"

### 2.2 Column Group Architecture

**What**: Columns are organized by position lifecycle stage using a prefix convention.

**Columns/Parameters Involved**: `CP_*`, `OP_*`, `OP_Current_*`

**Rules**:
- **CP_ prefix** (Closed Position): Fees and commissions calculated at position close time. These are finalized/historical values.
- **OP_ prefix** (Open Position): Fees and commissions accumulated while positions were open. These represent the open-period contribution.
- **OP_Current_ prefix** (Open Position Current): Snapshot of currently-open position commission data at the time of the revenue-share run. Used for the "current open positions" aggregation separately from historical totals.
- Each prefix group has Commission and OpenTotalFees subcomponents

### 2.3 MERGE Aggregation Pattern

**What**: Customer aggregated data is incrementally summed (not replaced) with each pipeline run.

**Columns/Parameters Involved**: `CID`, `LastClosedPosition`, `LastOpenedPosition`

**Rules**:
- MERGE uses CID as the match key
- WHEN MATCHED: commission totals are ADDED to existing values (target + source), not replaced
- Last position dates use CASE WHEN to keep the more recent date (MAX logic)
- OpenedPositionsCommissionOnOpen is NOT incremented if the new value is 0 (preserves prior value)
- WHEN NOT MATCHED: new customer row is inserted with initial values

---

## 3. Data Overview

Table is currently empty (0 rows). This is expected for a staging table that is truncated between ADF runs. Data is transient: populated by ADF, consumed by LoadClosedPositionsAndAggregates_ADF, then cleared by TruncateLoadTable.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | bigint | YES | - | CODE-BACKED | Customer identifier on the eToro platform. Primary join key for all downstream operations: Phase 1 INSERT into ClosedPositionFromEtoro_ADF, Phase 2 JOIN to HistoryClosedPosition for bridge mapping, and Phase 3 MERGE key for CustomerAggregatedData_ADF. One row per CID per pipeline run. |
| 2 | CP_CommissionOnClose | money | YES | - | CODE-BACKED | Closed Position - commission earned at position close. Component of TotalCommissionOnClose aggregation: ISNULL(CP_CommissionOnClose, 0) + ISNULL(CP_CloseTotalFees, 0). In dollar units (not cents). |
| 3 | CP_OpenTotalFees | money | YES | - | CODE-BACKED | Closed Position - total fees incurred during the open period of now-closed positions. Historically included in TotalCommissionOnClose formula but currently commented out in the procedure (preceded by "New version" comment). |
| 4 | CP_CloseTotalFees | money | YES | - | CODE-BACKED | Closed Position - total fees incurred at close time. Added to Commission in the dollars-to-cents formula: (Commission + CP_CloseTotalFees) * 100. Also component of TotalCommissionOnClose aggregation. |
| 5 | LastClosedPosition | datetime | YES | - | CODE-BACKED | Timestamp of the most recent closed position for this customer. Used as CloseOccurred in ClosedPositionFromEtoro_ADF (Phase 1 WHERE LastClosedPosition IS NOT NULL filters out customers with no closed positions). Also used in MERGE to track the latest close date via MAX logic. |
| 6 | LastOpenedPosition | datetime | YES | - | CODE-BACKED | Timestamp of the most recent opened position for this customer. Used in MERGE to track the latest open date via MAX logic. Not used in the closed-position INSERT (Phase 1). |
| 7 | OP_Commission | money | YES | - | CODE-BACKED | Open Position - commission accumulated while positions were open. Component of TotalCommissionOnOpen aggregation: ISNULL(OP_Commission, 0) + ISNULL(OP_OpenTotalFees, 0). In dollar units. |
| 8 | OP_OpenTotalFees | money | YES | - | CODE-BACKED | Open Position - total fees incurred during the open period. Component of TotalCommissionOnOpen aggregation alongside OP_Commission. In dollar units. |
| 9 | OP_Current_Commission | money | YES | - | CODE-BACKED | Open Position Current - snapshot of commission for currently-open positions at the time of the revenue-share run. Component of OpenedPositionsCommissionOnOpen: ISNULL(OP_Current_Commission, 0) + ISNULL(OP_Current_OpenTotalFees, 0). Only overwrites the prior value if non-zero. |
| 10 | OP_Current_OpenTotalFees | money | YES | - | CODE-BACKED | Open Position Current - snapshot of open fees for currently-open positions. Component of OpenedPositionsCommissionOnOpen alongside OP_Current_Commission. |
| 11 | Commission | decimal(16,6) | YES | - | CODE-BACKED | Aggregate commission amount in dollar units. Combined with CP_CloseTotalFees and multiplied by 100 for the downstream cents-based commission: CAST(ISNULL(Commission, 0) + ISNULL(CP_CloseTotalFees, 0) AS MONEY) * 100. Higher precision (decimal(16,6)) than the money-type fee columns to avoid rounding during aggregation. |
| 12 | NetProfit | money | YES | - | CODE-BACKED | Customer's net profit (or loss) from closed positions. Passed directly to ClosedPositionFromEtoro_ADF without transformation. Represents the total PnL for the revenue-share period. |
| 13 | LotsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Total trading volume in lots (decimal precision). Passed directly to ClosedPositionFromEtoro_ADF as the Lots column. Higher precision than money type to accurately represent fractional lots. |
| 14 | OriginalCID | bigint | YES | - | CODE-BACKED | Original customer ID for copy-trade attribution. When a customer copies another trader, OriginalCID identifies the original account. Passed to ClosedPositionFromEtoro_ADF for affiliate tracking chain resolution. |
| 15 | OriginalProviderID | bigint | YES | - | CODE-BACKED | Original provider ID for copy-trade attribution. Paired with OriginalCID to trace the copy-trade source. Passed to ClosedPositionFromEtoro_ADF. |
| 16 | AffiliateID | int | YES | - | CODE-BACKED | Affiliate who referred this customer. Determines which affiliate receives commission for this customer's trading activity. Passed to ClosedPositionFromEtoro_ADF for commission allocation. |
| 17 | AffiliateCampaign | nvarchar(1024) | YES | - | CODE-BACKED | Affiliate marketing campaign identifier (free-text tracking tag). Associates the customer's activity with a specific campaign for commission reporting. Passed to ClosedPositionFromEtoro_ADF. |
| 18 | BannerID | int | YES | - | CODE-BACKED | Marketing banner/creative identifier that the customer clicked to register. Part of the affiliate attribution chain for conversion tracking. Passed to ClosedPositionFromEtoro_ADF. |
| 19 | DownloadID | bigint | YES | - | CODE-BACKED | Download/install tracking identifier linking the customer to a specific app download event. Part of the affiliate attribution chain. Passed to ClosedPositionFromEtoro_ADF. |
| 20 | CountryID | bigint | YES | - | CODE-BACKED | Country identifier of the customer. Used for regional commission reporting and regulatory segmentation. Passed to ClosedPositionFromEtoro_ADF. |
| 21 | ProviderID | bigint | YES | - | CODE-BACKED | Provider identifier - the copy-trade leader being copied (if applicable). Passed to ClosedPositionFromEtoro_ADF for provider-level commission attribution. |
| 22 | RealProviderID | bigint | YES | - | CODE-BACKED | Underlying/real provider ID. When copy-trade chains involve intermediaries, this identifies the ultimate source provider. Passed to ClosedPositionFromEtoro_ADF. |
| 23 | FunnelID | int | YES | - | CODE-BACKED | Marketing funnel identifier. Tracks which registration/onboarding funnel the customer went through. Part of the affiliate attribution chain. Passed to ClosedPositionFromEtoro_ADF. |
| 24 | LabelID | int | YES | - | CODE-BACKED | Label identifier for customer segmentation. Used for categorizing customers in commission reporting. Passed to ClosedPositionFromEtoro_ADF. |
| 25 | PlayerLevelID | int | YES | - | CODE-BACKED | Customer loyalty tier: 1=Bronze, 5=Silver, 3=Gold, 2=V.I.P, 4=Test. See [Player Level](../../_glossary.md#player-level). Determines cashout processing speed and VIP benefits. Passed to ClosedPositionFromEtoro_ADF. (Dictionary.PlayerLevel) |
| 26 | ProcessingDate | datetime | YES | - | CODE-BACKED | Date when the revenue-share calculation was processed. Passed to ClosedPositionFromEtoro_ADF as a processing timestamp. Distinct from LastClosedPosition (which is the last trade date). |
| 27 | GCID | bigint | YES | - | CODE-BACKED | Global Customer ID - cross-platform customer identifier used when the same person has accounts across multiple eToro entities. Passed to ClosedPositionFromEtoro_ADF for global-level aggregation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer (cross-database) | Implicit | Customer identifier from the eToro platform |
| AffiliateID | AffiliateAdmin.Affiliates (cross-schema) | Implicit | References the affiliate who referred this customer |
| PlayerLevelID | Dictionary.PlayerLevel | Implicit | Customer loyalty tier (1=Bronze, 5=Silver, 3=Gold, 2=VIP, 4=Test) |
| CountryID | Dictionary.Country (cross-schema) | Implicit | Customer's country |
| BannerID | AffiliateAdmin.Banners (cross-schema) | Implicit | Marketing banner clicked by customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | - | READ (SELECT) | Phase 1: inserts into ClosedPositionFromEtoro_ADF; Phase 3: MERGE source for CustomerAggregatedData_ADF |
| BILoad.HistoryClosedPosition | CID | Co-staged | Both tables are consumed together - HistoryClosedPosition joins on CID to this table's aggregated records |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.LoadClosedPositionsAndAggregates_ADF | Stored Procedure | READER - Phase 1 SELECT for ClosedPositionFromEtoro_ADF INSERT + Phase 3 SELECT for CustomerAggregatedData_ADF MERGE |
| BILoad.TruncateLoadTable | Stored Procedure | DELETER - dynamic TRUNCATE TABLE clears staging data between ADF runs |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. As a staging table that is truncated between runs, indexes are unnecessary.

### 7.2 Constraints

None. No PK, no FKs, no CHECK constraints. All columns are nullable to accommodate partial data from the ADF pipeline. This is a minimal staging table designed for fast bulk INSERT and sequential read.

---

## 8. Sample Queries

### 8.1 Preview staged customer aggregates
```sql
SELECT TOP 10 CID, AffiliateID, Commission, NetProfit, LotsDecimal,
       LastClosedPosition, LastOpenedPosition, ProcessingDate
FROM BILoad.RevsharePositionSummary WITH (NOLOCK)
ORDER BY Commission DESC
```

### 8.2 Simulate the commission conversion formula
```sql
SELECT CID,
       Commission AS RawCommission_Dollars,
       CP_CloseTotalFees AS CloseFees_Dollars,
       CAST(ISNULL(Commission, 0) + ISNULL(CP_CloseTotalFees, 0) AS MONEY) * 100 AS FinalCommission_Cents,
       ISNULL(OP_Commission, 0) + ISNULL(OP_OpenTotalFees, 0) AS TotalCommissionOnOpen,
       ISNULL(CP_CommissionOnClose, 0) + ISNULL(CP_CloseTotalFees, 0) AS TotalCommissionOnClose
FROM BILoad.RevsharePositionSummary WITH (NOLOCK)
```

### 8.3 Cross-reference with HistoryClosedPosition for position counts per customer
```sql
SELECT r.CID,
       r.AffiliateID,
       r.Commission,
       r.PlayerLevelID,
       COUNT(h.PositionID) AS ClosedPositionCount
FROM BILoad.RevsharePositionSummary r WITH (NOLOCK)
LEFT JOIN BILoad.HistoryClosedPosition h WITH (NOLOCK) ON r.CID = h.CID
GROUP BY r.CID, r.AffiliateID, r.Commission, r.PlayerLevelID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PART-5265 (referenced in SQL comments) | Jira | Original ticket for ADF pipeline implementation by Noga (Feb 2026). Created BILoad schema including this staging table. |

No direct Confluence pages found for this object. Business context derived from the LoadClosedPositionsAndAggregates_ADF procedure logic and existing wiki docs.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.1/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 27 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 1 Jira (ref only) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BILoad.RevsharePositionSummary | Type: Table | Source: fiktivo/BILoad/Tables/BILoad.RevsharePositionSummary.sql*
