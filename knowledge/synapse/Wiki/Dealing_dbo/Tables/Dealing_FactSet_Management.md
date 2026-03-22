# Dealing_dbo.Dealing_FactSet_Management

## 1. Overview
Control table tracking which People Investors (PIs) and Copy Portfolios (CPs) are active in the FactSet data feed, when their history was sent, and the date range of daily sends. One row per CID. **STALE** — last updated 2024-06-04.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (CID ASC) |
| **Row Count** | ~4K |
| **Date Range** | Control table — no time-series grain |
| **Grain** | One row per CID |
| **Refresh** | None since 2024-06-04 — FactSet integration appears decommissioned |

## 2. Business Context
This is the orchestration control table for the FactSet PI data feed. `SP_FactSet_Management` runs before `SP_FactSet_Daily` (based on OpsDB Priority 0 ordering) to keep this table current: new PIs are inserted, deregistered PIs have IsActive set to 0 and PI_To date filled, and never-sent active rows are cleaned up. `SP_FactSet_Daily` then reads from this table (`IsActive=1 AND DailyLastSentDate<@Date`) to determine which CIDs need their portfolio snapshot sent to FactSet that day. The HistorySendFlag/HistorySentDate columns track the separate historical portfolio send (handled by `SP_FactSet_NewPIs_History`) for newly onboarded PIs. The integration was last active in June 2024.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| CID | int | Yes | Customer ID — PI or CP (distribution key) | T2 | DWH_dbo.Fact_SnapshotCustomer |
| CopyType | varchar(100) | Yes | 'PI' or 'CP' classification | T2 | DWH_dbo.Dim_Range |
| RegistrationDate | date | Yes | Customer account registration date | T2 | DWH_dbo.Dim_Customer |
| PI_From | date | Yes | First date when CID had GuruStatusID>=2 (became active PI/CP) | T2 | SP_FactSet_Management: derived from Fact_SnapshotCustomer |
| PI_To | date | Yes | Date when CID stopped being PI/CP (GuruStatusID dropped to <2); NULL if still active | T2 | SP_FactSet_Management: updated on deregistration |
| IsActive | int | Yes | 1 if currently active PI/CP in FactSet feed; 0 if deregistered | T2 | SP_FactSet_Management |
| HistorySendFlag | int | Yes | Flag controlling history send to FactSet: 1=history needs to be sent, 0=already sent | T2 | Manual / SP_FactSet_NewPIs_History |
| HistorySentDate | date | Yes | Date when historical portfolio was last sent to FactSet | T2 | SP_FactSet_NewPIs_History |
| DailyFirstSentDate | date | Yes | Date when daily sends first started for this CID | T2 | SP_FactSet_Management: set on first successful daily send |
| DailyLastSentDate | date | Yes | Most recent date successfully sent to FactSet. SP_FactSet_Daily uses `DailyLastSentDate<@Date` to select CIDs needing send | T2 | SP_FactSet_Daily: updated after each send |
| UpdateDate | datetime | Yes | ETL metadata: timestamp of last SP run affecting this row | T2 | SP_FactSet_Management: `GETDATE()` |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| Dealing_dbo.Dealing_FactSet_Daily | Downstream consumer | IsActive=1 AND DailyLastSentDate<@Date |
| Dealing_dbo.Dealing_FactSet_NewPIs_History | History send consumer | HistorySendFlag=1 |
| DWH_dbo.Fact_SnapshotCustomer | PI detection | GuruStatusID>=2 |
| DWH_dbo.Dim_Range | CopyType | CID |
| DWH_dbo.Dim_Customer | RegistrationDate | CID |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_FactSet_Management` |
| **Parameters** | `@Date DATE` |
| **Load Pattern** | UPSERT (INSERT new PIs, UPDATE deregistered PIs, DELETE cleanup) |
| **Key Logic** | 1) INSERT: New CIDs where first date GuruStatusID>=2 = @Date. 2) UPDATE IsActive=0 + PI_To=@Date−1: CIDs where GuruStatusID<2 on @Date−1. 3) DELETE: rows where DailyFirstSentDate IS NULL AND IsActive=1 (cleanup of never-sent active rows). |
| **Note** | Runs before SP_FactSet_Daily to ensure control table is current |

## 6. Data Lifecycle
- **Retention**: Persistent lookup — rows are updated, not appended by date
- **Status**: STALE since 2024-06-04
- **Volume**: ~4K rows — one per PI/CP ever registered in FactSet feed

## 7. Known Gaps
- STALE — integration appears discontinued as of June 2024
- HistorySendFlag appears to be manually managed for initial history loads
- DELETE rule (DailyFirstSentDate IS NULL) could remove newly created rows if SP_FactSet_Daily doesn't run after SP_FactSet_Management on the same day

## 8. Quality Score
**7.5/10** — Clean control table with clear UPSERT semantics. IsActive + date range fields are well-traced. Stale status limits immediate utility.
