# BI_DB_dbo.BI_DB_CopyBlockedAUMHistory

| Property | Value |
|----------|-------|
| Schema | BI_DB_dbo |
| Object | BI_DB_CopyBlockedAUMHistory |
| Type | Table |
| Rows | Varies (historical block events for currently-blocked PIs only) |
| Distribution | HASH(CID) |
| Index | CLUSTERED INDEX(CID ASC) |
| Production Source | etoro.Customer.History_BlockedCustomerOperations (OperationTypeID=2) |
| Writer SP | BI_DB_dbo.SP_CopyBlockedAUM |
| Refresh Cadence | Daily TRUNCATE+INSERT (written in same SP run as BI_DB_CopyBlockedAUM) |
| UC Target | _Not_Migrated |
| Batch | 74 |
| Documented | 2026-04-23 |

---

## 1. Business Meaning

Historical block event log for **Popular Investors whose copy portfolio is currently blocked**. Each row represents one block event (one `BlockStart`/`BlockEnd` pair) from the etoro production history table, filtered to the CIDs that appear in today's active blocked list.

Unlike `BI_DB_CopyBlockedAUM` (which shows the *current state* of each blocked PI), this table shows the *event history* — multiple rows per PI if they were blocked, unblocked, and re-blocked. It supports trend analysis: how many times has a PI been blocked, for how long, and what changed between blocks.

**Key behavioral constraint:** The table is TRUNCATE+INSERT daily using a JOIN to the current blocked population (`#blockedusers`). When a PI is unblocked, all their history rows are dropped from this table on the next daily refresh. This is a point-in-time view of history for *currently blocked* PIs, not a permanent historical archive.

Authored by Dan (2021-11-22); PII columns (FirstName, LastName) removed 2022-03-13 (Inbal BML); migrated to Synapse by Tom Boksenbojm (2023-12-18).

---

## 2. Business Logic & Derivation Rules

### Scope Filter
The SP builds `#blockedusers` (currently blocked PIs with `OperationTypeID=2`, `IsDepositor=1`, `IsValidCustomer=1`, active `GuruStatusID` or AUM>0 with BlockReasonID=13). The history query then JOINs this temp table, so only CIDs in today's blocked population are included.

### Block Event Pairs
`BlockStart` and `BlockEnd` come from `etoro.Customer.History_BlockedCustomerOperations`. A NULL `BlockEnd` indicates an ongoing block that has not yet been resolved. Multiple rows per CID represent distinct historical block/unblock cycles.

### DaysBlocked Derivation
`DaysBlocked = DATEDIFF(DAY, BlockStart, BlockEnd)`. Returns NULL when `BlockEnd` IS NULL (currently active block).

### Enrichment from Current State
`UserName`, `Country`, and `GuruStatusID` are sourced from `#blockedusers` — i.e., the customer's **current** dimension values at load time, not their values at the time of the historical block event. If a PI changed username or country since an old block, the historical rows will reflect today's values, not the original.

### OperationTypeID
Always 2 (PI copy block) — filtered by `WHERE bdbcoh.OperationTypeID=2` in the SP.

---

## 3. Query Advisory

- **HASH(CID) distributed** — `WHERE CID = ?` queries are efficient.
- **Multiple rows per CID** — this is an event table, not a snapshot. Always aggregate by CID if you want per-PI summaries.
- **`DaysBlocked` is NULL for ongoing blocks** — `BlockEnd` IS NULL means the PI is still blocked in that event record.
- **UserName/Country/GuruStatusID reflect current state**, not historical state at the time of the block. Do not use for historical attribute analysis.
- **TRUNCATE+INSERT daily** — no point-in-time recovery once a PI is unblocked. For permanent audit trails, query `etoro.Customer.History_BlockedCustomerOperations` directly.
- **OperationTypeID is always 2** — filtering on it is redundant.

---

## 4. Elements

| Column | Nullable | Type | Description |
|--------|----------|------|-------------|
| CID | NOT NULL | int | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic via #blockedusers) |
| UserName | NULL | varchar(20) | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Reflects current value at load time, not value at time of block. (Tier 1 — DWH_dbo.Dim_Customer via #blockedusers) |
| Country | NULL | varchar(50) | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Reflects current country at load time. (Tier 1 — DWH_dbo.Dim_Country via #blockedusers) |
| GuruStatusID | NULL | smallint | eToro Popular Investor/Guru program status — whether the customer is an active copy trading strategy provider. FK to Dictionary.GuruStatus. Values: 0=No, 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro, 7=Removed, 8=Rejected. Reflects current status at load time. (Tier 1 — DWH_dbo.Dim_Customer via BackOffice.Customer, via #blockedusers) |
| OperationTypeID | NULL | int | Block operation type code. Always 2 in this table (PI copy block). Source: etoro.Customer.History_BlockedCustomerOperations. (Tier 2 — etoro.Customer.History_BlockedCustomerOperations) |
| Reason | NULL | nvarchar(50) | Human-readable label for the block reason. Source: etoro.Dictionary.BlockUnBlockReason. (Tier 2 — etoro.Dictionary.BlockUnBlockReason) |
| BlockStart | NULL | datetime | UTC timestamp when this block event began. From etoro.Customer.History_BlockedCustomerOperations. (Tier 2 — etoro.Customer.History_BlockedCustomerOperations) |
| BlockEnd | NULL | datetime | UTC timestamp when this block event ended (PI was unblocked). NULL if the block is still active. From etoro.Customer.History_BlockedCustomerOperations. (Tier 2 — etoro.Customer.History_BlockedCustomerOperations) |
| DaysBlocked | NULL | int | Duration of this block event in days: DATEDIFF(DAY, BlockStart, BlockEnd). NULL when BlockEnd IS NULL (ongoing block). (Tier 2 — derived from BlockStart, BlockEnd) |
| UpdateDate | NOT NULL | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Usage |
|--------|-------|
| etoro.Customer.History_BlockedCustomerOperations | Primary source: BlockStart, BlockEnd, OperationTypeID (all historical events) |
| etoro.Customer.BlockedCustomerOperations | CID population filter via #blockedusers (current blocks only) |
| DWH_dbo.Dim_Customer | UserName, GuruStatusID, CountryID enrichment via #blockedusers |
| DWH_dbo.Dim_Country | Country (Name) enrichment via #blockedusers |
| etoro.Dictionary.BlockUnBlockReason | Reason lookup |

### 5.2 ETL Pipeline

```
etoro.Customer.BlockedCustomerOperations (OperationTypeID=2)
  + DWH_dbo.Dim_Customer + DWH_dbo.Dim_Country
  |
  v
#blockedusers (temp table: currently blocked PI population)
  |
  +---- JOIN ----+
                 |
etoro.Customer.History_BlockedCustomerOperations (OperationTypeID=2, all event history)
  + etoro.Dictionary.BlockUnBlockReason (Reason)
  |
  v
SP_CopyBlockedAUM — TRUNCATE + INSERT daily
  |
  v
BI_DB_dbo.BI_DB_CopyBlockedAUMHistory (HASH(CID))
  |
  v
UC Target: _Not_Migrated (not in Generic Pipeline)
```

---

## 6. Relationships & Cross-References

| Related Object | Relationship |
|----------------|-------------|
| BI_DB_dbo.BI_DB_CopyBlockedAUM | Sibling: written by same SP (SP_CopyBlockedAUM). Shows current state; this table shows event history for the same CID population. |
| BI_DB_dbo.DWH_CIDsDailyRisk | Sibling input: used by the same SP to populate risk score columns in BI_DB_CopyBlockedAUM. Not directly used for this history table. |
| etoro.Customer.History_BlockedCustomerOperations | Primary production source (external table in BI_DB_dbo schema). |

---

## 7. Sample Queries

```sql
-- All historical block events for a specific PI
SELECT CID, UserName, Country, Reason, BlockStart, BlockEnd, DaysBlocked
FROM [BI_DB_dbo].[BI_DB_CopyBlockedAUMHistory]
WHERE CID = 12345
ORDER BY BlockStart;

-- PIs with multiple historical block cycles (repeat offenders)
SELECT CID, UserName, COUNT(*) AS BlockCycles, SUM(DaysBlocked) AS TotalDaysBlocked
FROM [BI_DB_dbo].[BI_DB_CopyBlockedAUMHistory]
WHERE BlockEnd IS NOT NULL
GROUP BY CID, UserName
HAVING COUNT(*) > 1
ORDER BY BlockCycles DESC;

-- Currently active blocks (BlockEnd IS NULL in history)
SELECT CID, UserName, Reason, BlockStart, DATEDIFF(DAY, BlockStart, GETDATE()) AS DaysActiveBlock
FROM [BI_DB_dbo].[BI_DB_CopyBlockedAUMHistory]
WHERE BlockEnd IS NULL
ORDER BY BlockStart;

-- Block reason distribution across history
SELECT Reason, COUNT(*) AS EventCount, COUNT(DISTINCT CID) AS UniquePIs
FROM [BI_DB_dbo].[BI_DB_CopyBlockedAUMHistory]
GROUP BY Reason
ORDER BY EventCount DESC;
```

---

## 8. Atlassian Sources

No Confluence pages identified for this object. Contact the Data Platform team or check the DATA Confluence space for block policy documentation. See also notes for `BI_DB_CopyBlockedAUM` (same SP, same operational context).
