# BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution — Column Lineage

## Summary

Performance-optimized partial derivative of DWH_dbo.Fact_CustomerAction for fee/compensation/detach actions, enriched with position attributes from Dim_Position (COALESCE preferring DP over FCA) and point-in-time customer attributes from Fact_SnapshotCustomer via Dim_Range SCD resolution. HASH(PositionID) distribution enables co-located JOINs with position-distributed tables.

## Source Objects

| # | Source Object | Schema | Role |
|---|--------------|--------|------|
| 1 | DWH_dbo.Fact_CustomerAction | DWH_dbo | Primary — fee/compensation/detach action rows filtered by ActionTypeID |
| 2 | DWH_dbo.Dim_Position | DWH_dbo | Enrichment — position attributes (IsBuy, IsSettled, Leverage, etc.) via COALESCE |
| 3 | DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Enrichment — SCD customer attributes at action date via Dim_Range |
| 4 | DWH_dbo.Dim_Range | DWH_dbo | SCD resolution — date range lookup for SnapshotCustomer |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| DateID | Fact_CustomerAction | DateID | Passthrough |
| RealCID | Fact_CustomerAction | RealCID | Passthrough |
| PositionID | Fact_CustomerAction / Dim_Position | PositionID | COALESCE(dp.PositionID, fca.PositionID); for ActionTypeID=36+CompensationReasonID IN (117,118): extracted from Description field via reverse string parsing with TRY_CAST fallback |
| IsSettled | Dim_Position | IsSettled | COALESCE(dp.IsSettled, fca.IsSettled) — prefers Dim_Position |
| MirrorID | Dim_Position | MirrorID | COALESCE(dp.MirrorID, fca.MirrorID); set to 0 if action occurred after detach-from-mirror event |
| Leverage | Dim_Position | Leverage | COALESCE(dp.Leverage, fca.Leverage) — prefers Dim_Position |
| InstrumentID | Dim_Position | InstrumentID | COALESCE(dp.InstrumentID, fca.InstrumentID) — prefers Dim_Position |
| IsBuy | Dim_Position | IsBuy | COALESCE(dp.IsBuy, NULL) — FCA value always NULL, resolved from Dim_Position |
| IsAirDrop | Dim_Position | IsAirDrop | ISNULL(COALESCE(dp.IsAirDrop, fca.IsAirDrop), 0) — defaults to 0 |
| Amount | Fact_CustomerAction | Amount | Passthrough |
| ActionTypeID | Fact_CustomerAction | ActionTypeID | Passthrough — filtered to 35, 36(+CompReasonID 56/117/118), 32, 19 |
| CompensationReasonID | Fact_CustomerAction | CompensationReasonID | Passthrough |
| IsFeeDividend | Fact_CustomerAction | IsFeeDividend | Passthrough |
| Occurred | Fact_CustomerAction | Occurred | Passthrough |
| TicketFeeAction | Fact_CustomerAction | Description | ETL-computed — CASE: 'OpenTotalFees'→'Open', 'CloseTotalFees'→'Close', else NULL |
| Description | Fact_CustomerAction | Description | Passthrough |
| GCID | Fact_SnapshotCustomer | GCID | Passthrough via SCD JOIN |
| CountryID | Fact_SnapshotCustomer | CountryID | Passthrough via SCD JOIN |
| LabelID | Fact_SnapshotCustomer | LabelID | Passthrough via SCD JOIN |
| VerificationLevelID | Fact_SnapshotCustomer | VerificationLevelID | Passthrough via SCD JOIN |
| PlayerStatusID | Fact_SnapshotCustomer | PlayerStatusID | Passthrough via SCD JOIN |
| RiskStatusID | Fact_SnapshotCustomer | RiskStatusID | Passthrough via SCD JOIN |
| RiskClassificationID | Fact_SnapshotCustomer | RiskClassificationID | Passthrough via SCD JOIN |
| GuruStatusID | Fact_SnapshotCustomer | GuruStatusID | Passthrough via SCD JOIN |
| RegulationID | Fact_SnapshotCustomer | RegulationID | Passthrough via SCD JOIN |
| AccountStatusID | Fact_SnapshotCustomer | AccountStatusID | Passthrough via SCD JOIN |
| AccountManagerID | Fact_SnapshotCustomer | AccountManagerID | Passthrough via SCD JOIN |
| PlayerLevelID | Fact_SnapshotCustomer | PlayerLevelID | Passthrough via SCD JOIN |
| AccountTypeID | Fact_SnapshotCustomer | AccountTypeID | Passthrough via SCD JOIN |
| IsDepositor | Fact_SnapshotCustomer | IsDepositor | Passthrough via SCD JOIN |
| SuitabilityTestStatusID | Fact_SnapshotCustomer | SuitabilityTestStatusID | Passthrough via SCD JOIN |
| MifidCategorizationID | Fact_SnapshotCustomer | MifidCategorizationID | Passthrough via SCD JOIN |
| IsValidCustomer | Fact_SnapshotCustomer | IsValidCustomer | Passthrough via SCD JOIN |
| IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough via SCD JOIN |
| AffiliateID | Fact_SnapshotCustomer | AffiliateID | Passthrough via SCD JOIN |
| UpdateDate | ETL metadata | GETDATE() | ETL timestamp |
| SettlementTypeID | Dim_Position | SettlementTypeID | Passthrough — switched from FCA to DP (2025-10-15) because FCA shows NULL on overnights |

## Lineage Notes

- The SP filters Fact_CustomerAction to 4 ActionTypeIDs: 35 (ticket fees, ~97%), 36 (compensations with specific reasons), 32, 19 (detach from mirror).
- For compensation actions (36) with CompensationReasonID IN (117,118), the PositionID is extracted from the Description field via reverse string parsing because the compensation mechanism occasionally loses the direct PositionID reference.
- Position attributes are resolved via COALESCE preferring Dim_Position over Fact_CustomerAction values, because FCA position data can be incomplete.
- IsBuy is always NULL from FCA (hardcoded to NULL in the first query) and resolved entirely from Dim_Position.
- MirrorID is zeroed when the action's Occurred timestamp is after a detach-from-mirror event (ActionTypeID=19) for the same PositionID.
- Post-insert integrity check: row count and SUM(Amount) must match between this table and the filtered Fact_CustomerAction source. Mismatch throws error 50000.
