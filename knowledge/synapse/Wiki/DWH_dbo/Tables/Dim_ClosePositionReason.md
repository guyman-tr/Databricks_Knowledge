# DWH_dbo.Dim_ClosePositionReason

> Lookup of reasons why trading positions are closed — covers customer-initiated, automated (Stop Loss/Take Profit), operational, and system actions.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | ClosePositionReasonID (int NOT NULL, CLUSTERED INDEX) |
| **Row Count** | 27 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on ClosePositionReasonID ASC |

---

## 1. Business Meaning

`Dim_ClosePositionReason` classifies why a trading position was closed. This is critical for understanding trading behavior, risk management triggers, and operational actions.

**Category groups**:
- **Customer-initiated**: Customer (0), Close All (12), Manual Unregister (17), Redeem (19)
- **Automated risk controls**: Stop Loss (1), Stop Loss via trade server (3), Take Profit (5), Take Profit via trade server (6), BSL (16), Close by rate (25)
- **Copy trading**: Copy Stop Loss (13), Mirror position manual close (14), Hierarchical Close (9), Hierarchical close by recovery (10)
- **Operational**: BackOffice User (8), BackOffice Unregister (18), Operational position adjustment (20), Orphaned position (21), Manual Liquidation (15), Alignment (23)
- **Market events**: End of Week (2), Return to Market (4), Contact Rollover (7), Delist (24), Expiry (26)
- **Transfers**: Transferred Out (22)

---

## 2. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.Dictionary.ClosePositionActionType` (etoroDB-REAL) |
| **Staging Table** | `DWH_staging.etoro_Dictionary_ClosePositionActionType` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |
| **Column Mapping** | 2 renamed (`ID` → `ClosePositionReasonID`, `ClosePositionActionName` → `Name`), 1 hardcoded (`StatusID = 1`), 2 ETL-generated (`UpdateDate`, `InsertDate`) |

---

## 3. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | ClosePositionReasonID | int | NO | Tier 2 | Position close reason identifier (0–26). Renamed from source `ID`. |
| 2 | Name | varchar(50) | NO | Tier 2 | Reason description. Renamed from source `ClosePositionActionName`. |
| 3 | StatusID | int | YES | Tier 2b | Hardcoded to `1` for all rows. DWH-internal flag. |
| 4 | UpdateDate | datetime | YES | Tier 2 | ETL load timestamp — `GETDATE()`. |
| 5 | InsertDate | datetime | YES | Tier 2 | ETL load timestamp — `GETDATE()`. |

---

*Generated: 2026-03-18 | Quality: 7.8/10 | Confidence: 0 Tier 1, 4 Tier 2, 1 Tier 2b | Phases: 1,2,8,9b,11*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_ClosePositionReason.sql*
