# DWH_dbo.Dim_ClosePositionReason

> Lookup dimension defining the 27 triggers for closing a trading position - from user manual close and stop-loss orders to CopyTrading cascades, operational liquidations, and corporate events.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | `etoro.Dictionary.ClosePositionActionType` |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full reload) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (ClosePositionReasonID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason` |
| **UC Format** | Parquet (Override/full load, daily) |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_ClosePositionReason` defines every possible trigger or reason that can cause a trading position to close on the eToro platform. Each of the 27 IDs represents a distinct closure scenario: whether a user manually closes (ID=0), a stop-loss fires (ID=1/3), a CopyTrading leader exits cascading to copiers (ID=9), or operations liquidates an account (ID=15). This classification is permanently written to position records and drives trading analytics, P&L attribution, and regulatory reporting.

Data flows from `etoro.Dictionary.ClosePositionActionType` via the Generic Pipeline, through `DWH_staging.etoro_Dictionary_ClosePositionActionType`, and into DWH via `SP_Dictionaries_DL_To_Synapse`. The ETL applies column renames: `ID` becomes `ClosePositionReasonID` and `ClosePositionActionName` becomes `Name`. `StatusID=1` is hardcoded, and `UpdateDate`/`InsertDate` are set to `GETDATE()`. See upstream wiki: `DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ClosePositionActionType.md`.

`SP_Dictionaries_DL_To_Synapse` refreshes this table daily. As of 2026-03-11 the DWH table has 27 rows (IDs 0-26), matching the production count. The close action type is immutable once set - it records the original trigger event.

---

## 2. Business Logic

### 2.1 Closure Trigger Categories

**What**: The 27 close reasons group into five analytical categories by who or what initiated the closure.

**Columns Involved**: `ClosePositionReasonID`, `Name`

**Rules**:
- **User-Initiated (0, 12, 14, 17)**: User consciously closed - 0=Customer (manual), 12=Close All, 14=Mirror manual close, 17=Manual Unregister
- **System-Automated (1, 3, 5, 6, 16, 2, 26)**: Triggered by price or time conditions - 1/3=Stop Loss, 5/6=Take Profit, 16=BSL (gap stop-loss), 2=End of Week, 26=Expiry
- **CopyTrading (9, 10, 13, 17, 18, 23)**: Related to copy relationship lifecycle - 9=Hierarchical Close (leader closed), 10=Recovery, 13=Copy SL, 23=Alignment
- **Operations (8, 15, 18, 20, 21)**: Internal team actions - 8=BackOffice, 15=Manual Liquidation, 18=BO Unregister, 20=Operational adjustment, 21=Orphaned
- **Business Events (7, 19, 22, 24, 25)**: External business drivers - 7=Contract Rollover, 19=Redeem, 22=Transferred Out, 24=Delist, 25=Close by rate

**Diagram**:
```
Close Position Triggers:
+-- User-Initiated: 0 (Customer), 12 (Close All), 14 (Mirror manual), 17 (Unregister)
+-- System-Automated: 1/3 (Stop Loss), 5/6 (Take Profit), 16 (BSL), 2 (EOW), 26 (Expiry)
+-- CopyTrading: 9 (Hierarchical), 10 (Recovery), 13 (Copy SL), 23 (Alignment)
+-- Operations: 8 (BackOffice), 15 (Liquidation), 20 (Adjustment), 21 (Orphaned)
+-- Business Events: 7 (Rollover), 19 (Redeem), 22 (Transfer Out), 24 (Delist)
```

### 2.2 DWH Column Mapping vs. Production

**What**: The ETL renames both primary columns, requiring awareness when cross-referencing production code.

**Columns Involved**: `ClosePositionReasonID`, `Name`

**Rules**:
- Production column `ID` -> DWH column `ClosePositionReasonID` (logical renaming for clarity)
- Production column `ClosePositionActionName` -> DWH column `Name` (shortened)
- `StatusID=1` is hardcoded for all rows (active record flag, not from production)
- `UpdateDate` and `InsertDate` both set to GETDATE() at load time (not from production)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, REPLICATE-distributed with CLUSTERED INDEX on `ClosePositionReasonID`. 27 rows - zero-cost broadcast JOIN on every node. Always include in the JOIN condition for position analytics.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, stored as Parquet at `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason`. 27 rows, daily Override. No partitioning needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode a close reason ID | `JOIN Dim_ClosePositionReason ON ClosePositionReasonID` |
| Find user-voluntary closures | `WHERE ClosePositionReasonID IN (0, 12)` |
| Find all stop-loss closes | `WHERE ClosePositionReasonID IN (1, 3, 16)` (includes BSL) |
| Find CopyTrading cascade closes | `WHERE ClosePositionReasonID IN (9, 10, 13, 23)` |
| Find operations-forced closes | `WHERE ClosePositionReasonID IN (8, 15, 20, 21)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position (planned) | ON ClosePositionReasonID | Decode close reason for each closed position |
| DWH_dbo.Fact_CustomerAction (planned) | ON ClosePositionReasonID | Close reason in action event stream |

### 3.4 Gotchas

- **Column rename from production**: Production stores this as `ClosePositionActionTypeID` (referencing `Dictionary.ClosePositionActionType.ID`). DWH renaming to `ClosePositionReasonID`/`Name` means cross-references with production code need translation.
- **ID=0 is "Customer"** (user manual close), not a placeholder. This is a real, valid value. Unlike other DWH dimension tables where ID=0 is the N/A sentinel, here ID=0 has full business meaning.
- **IDs 1 and 3 are both Stop Loss**: ID=1 is client-side stop-loss; ID=3 is via trade server. Distinguish when needed for trading system attribution.
- **IDs 5 and 6 are both Take Profit**: Same pattern - client vs. trade server.
- **ID=16 BSL (Below Stop Loss)**: Gap close where market jumped through stop-loss level. Close price may be significantly worse than the stated stop-loss level. Important for P&L calculation variance.
- **StatusID is always 1**: Not meaningful for filtering - all rows are active.
- **UpdateDate/InsertDate are ETL timestamps**: Do not use to determine when action types were added to production.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Meaning |
|-------|------|-----|---------|
| **** | Tier 1 | `(Tier 1 - upstream wiki, ...)` | Verbatim from upstream production wiki |
| *** | Tier 2 | `(Tier 2 - SP code, ...)` | Confirmed from Synapse ETL SP code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ClosePositionReasonID | int | NO | Primary key. DWH rename of production `ID`. Values 0-26. 0=Customer (manual), 1=Stop Loss, 2=End of Week, 3=SL via trade server, 4=Return to Market, 5=Take Profit, 6=TP via trade server, 7=Contact Rollover, 8=BackOffice, 9=Hierarchical Close, 10=Hierarchical close by recovery, 11=Join Demo Challenge, 12=Close All, 13=Copy Stop Loss, 14=Mirror manual, 15=Manual Liquidation, 16=BSL, 17=Manual Unregister, 18=BackOffice Unregister, 19=Redeem, 20=Operational adjustment, 21=Orphaned, 22=Transferred Out, 23=Alignment, 24=Delist, 25=Close by rate, 26=Expiry. Stored permanently with every closed position. (Tier 1 - upstream wiki, Dictionary.ClosePositionActionType) |
| 2 | Name | varchar(50) | NO | DWH rename of production `ClosePositionActionName`. Human-readable closure trigger label. E.g., "Customer", "Stop Loss", "Hierarchical Close", "BSL". Used in account statements, trading reports, and position analytics. (Tier 1 - upstream wiki, Dictionary.ClosePositionActionType) |
| 3 | StatusID | int | YES | Active record flag hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse. Not from production Dictionary.ClosePositionActionType. No filtering value - all rows are active. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 4 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() on each daily reload. Not a business change date. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 5 | InsertDate | datetime | YES | ETL insert timestamp set to GETDATE() on each daily reload (same value as UpdateDate due to TRUNCATE+INSERT). Not the date the action type was originally created. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ClosePositionReasonID | etoro.Dictionary.ClosePositionActionType | ID | Rename (ID -> ClosePositionReasonID) |
| Name | etoro.Dictionary.ClosePositionActionType | ClosePositionActionName | Rename (ClosePositionActionName -> Name) |
| StatusID | (ETL-computed) | - | Hardcoded to 1 |
| UpdateDate | (ETL-computed) | - | GETDATE() at load |
| InsertDate | (ETL-computed) | - | GETDATE() at load |

### 5.2 ETL Pipeline

```
etoro.Dictionary.ClosePositionActionType (production, 27 rows)
  -> Generic Pipeline (daily Override, Bronze: general.bronze_etoro_dictionary_closepositionactiontype)
  -> DWH_staging.etoro_Dictionary_ClosePositionActionType
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ID->ClosePositionReasonID, ClosePositionActionName->Name)
  -> DWH_dbo.Dim_ClosePositionReason
  -> Generic Pipeline (daily Override, Gold: dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Dictionary.ClosePositionActionType | 27-type position closure taxonomy |
| Lake | Bronze/etoro/Dictionary/ClosePositionActionType/ | Daily Override export |
| Staging | DWH_staging.etoro_Dictionary_ClosePositionActionType | Raw import from lake |
| ETL | SP_Dictionaries_DL_To_Synapse (lines 470-484) | TRUNCATE + INSERT; ID->ClosePositionReasonID, ClosePositionActionName->Name |
| Target | DWH_dbo.Dim_ClosePositionReason | 27 rows (IDs 0-26) |

---

## 6. Relationships

### 6.1 References To (this object points to)

This table has no outgoing references.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Dim_Position (planned) | ClosePositionReasonID | Each closed position records the closure trigger |
| DWH_dbo.Fact_CustomerAction (planned) | ClosePositionReasonID | Customer action event stream includes position close events |
| Production: Trade.PositionTbl | ClosePositionActionTypeID | Stores the closure trigger for every closed position |
| Production: Account statement procs | ClosePositionActionTypeID | Display human-readable closure reason in statements |

Note: No DWH_dbo SPs or Views currently JOIN this table (SSDT grep returned no matches).

---

## 7. Sample Queries

### 7.1 List all close position reasons
```sql
SELECT  ClosePositionReasonID,
        Name
FROM    [DWH_dbo].[Dim_ClosePositionReason]
ORDER BY ClosePositionReasonID;
```

### 7.2 Count closed positions by category
```sql
SELECT  r.Name AS CloseReason,
        COUNT(*) AS PositionCount
FROM    [DWH_dbo].[Dim_Position] p
JOIN    [DWH_dbo].[Dim_ClosePositionReason] r
        ON p.ClosePositionReasonID = r.ClosePositionReasonID
GROUP BY r.Name
ORDER BY PositionCount DESC;
```

### 7.3 Find all CopyTrading-triggered closures
```sql
SELECT  p.PositionID,
        p.CID,
        r.Name AS CloseReason
FROM    [DWH_dbo].[Dim_Position] p
JOIN    [DWH_dbo].[Dim_ClosePositionReason] r
        ON p.ClosePositionReasonID = r.ClosePositionReasonID
WHERE   r.ClosePositionReasonID IN (9, 10, 13, 23)
ORDER BY p.PositionID DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from upstream wiki (Dictionary.ClosePositionActionType, quality 8.6/10) and SP_Dictionaries_DL_To_Synapse ETL analysis.

---

*Generated: 2026-03-19 | Quality: 9.0/10 (★★★★★) | Phases: 7/14 (Simple-Dict Fast-Path)*
*Tiers: 2 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 9/10*
*Object: DWH_dbo.Dim_ClosePositionReason | Type: Table | Production Source: etoro.Dictionary.ClosePositionActionType*
