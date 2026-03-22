---
object: Dealing_SuspiciousActivityTrading_24H
schema: Dealing_dbo
type: Table
description: Daily alert list of potential price-abuse traders: CIDs who opened and closed the same tree within 3 minutes, with ≥5 trades and >$3,000 net profit on a single day. Includes regulation, PI status, account seniority, and copy-tree context.
etl_sp: Dealing_dbo.SP_SuspiciousActivityTrading_24H
frequency: Daily
status: Active (last: 2026-03-10)
row_count: ~2,132
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 9.0
---

# Dealing_SuspiciousActivityTrading_24H

Daily surveillance table flagging potential price-abusers: clients (or their copiers) who profited from positions opened and closed within a 3-minute window on the same day, meeting volume and profit thresholds. Designed to detect "latency arbitrage" or rapid-scalping behavior that exploits price delays. Also used to generate email alerts.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Position` | Open + closed positions on DateID |
| Dimension | `DWH_dbo.Dim_Customer` | CID → RegulationID, FirstDepositDate |
| Dimension | `DWH_dbo.Dim_Regulation` | RegulationID → Name |
| Dimension | `DWH_dbo.Dim_Mirror` | Active copiers per PI (for IsImportantPI) |
| Writer | `Dealing_dbo.SP_SuspiciousActivityTrading_24H` | Daily, OpsDB Priority 0 |

**Author**: Assaf Tal (2020-03-26), migrated to Synapse 2024-03-26 (SR-243679), moved from hourly to daily process.

**Detection criteria** (hardcoded thresholds):
1. Root position opened AND closed within 3 minutes (`DATEDIFF(MINUTE, OpenOccurred, CloseOccurred) ≤ 3`)
2. Both root and sub-positions opened on @DateID
3. **HAVING**: `COUNT(*) >= 5 AND SUM(NetProfit) > 3000` (at least 5 trades, >$3K profit per CID)
4. For copy trades (IsCopy='Copy'): only included if the entire tree's NetProfit > $10,000

**NULL sentinel rows**: The SP always includes a LEFT JOIN to `Dim_Date` on @DateID — on days with no suspicious activity, the table contains one NULL row for that date (not zero rows). This preserves the daily continuity for reporting.

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | datetime | NULL | Report date. Note: datetime (not date) — time portion is always 00:00:00. |
| `CID` | int | NULL | The individual client's CID who made the trades. NULL on no-activity sentinel rows. |
| `RootCID` | int | NULL | The PI/root CID of the tree. Equals CID if the trader is the root (not a copier). For copy trades, RootCID is the PI being followed. |
| `Regulation` | varchar(30) | NULL | Regulation entity name for the RootCID (e.g., 'FCA', 'CySEC', 'NFA'). |
| `IsCopy` | varchar(10) | NULL | 'Manual' = trader placed their own orders; 'Copy' = trader is copying a PI's positions. |
| `IsPI` | tinyint | NULL | 1 if the RootCID is an "Important PI" (has >10 active copiers in Dim_Mirror); 0 otherwise. Flags cases where a PI's behavior affects a large follower base. |
| `Is3Month` | int | NULL | 1 if the RootCID's FirstDepositDate is within the last 3 months (new account); 0 = established account. New accounts flagged as higher-risk. |
| `NumberOfTrades` | int | NULL | Count of individual positions opened by this CID in 3-minute trees on this date. Minimum 5 (from HAVING clause). |
| `NetProfit` | money | NULL | Total net profit across all flagged positions for this CID on this date. Minimum $3,000 (from HAVING clause for manual; tree-level $10K for copies). |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: 2024-03-25 → 2026-03-10 (daily), 2,132 rows — intentionally small (alert list)
- Sample (2026-03-10): FCA and CySEC regulations, manual traders, 6-8 trades, $3,006–$3,862 profit
- NULL sentinel rows: if querying WHERE CID IS NOT NULL, you get only actual alerts; full SELECT returns one NULL row per no-activity day
- The table was migrated from an hourly process to daily in March 2024 (SR-243679) — data before 2024-03-25 not available in this table
- Email alert: same SP also writes to `Dealing_SuspiciousActivityTrading_24H_Email` (TRUNCATE+INSERT pattern for email trigger)

## Business Context

Primary daily fraud alert for the Dealing team's price-abuse monitoring program. The 3-minute window is chosen to capture positions that exploit short-lived price feed delays — traders who open and close before eToro's price server fully updates the mid-market price. CIDs appearing here are reviewed by the Trading team; repeat offenders may be rate-limited, flagged for compliance, or have accounts suspended.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_SuspiciousActivityTrading_24H_Email` | Email buffer (skipped — 1K-row staging buffer) |
| `Dealing_PreviouslyIdentifiedAbusers` | Companion table — known re-registrants of confirmed abusers |
| `Dealing_SelfCopyingPI` | Companion table — PI self-copy abuse pattern (decommissioned) |
| `DWH_dbo.Dim_Mirror` | Source for IsImportantPI flag |

## Quality Score: 9.0/10
*Excellent: detection logic fully traced (3-min window, thresholds, copy filter), NULL sentinel behavior documented, migration history noted. Sample data confirms active status.*
