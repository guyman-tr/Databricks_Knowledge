# BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution

> 3.4B-row performance-optimized derivative of Fact_CustomerAction for fee, compensation, and detach-from-mirror actions (ActionTypeIDs 35/36/32/19), enriched with position attributes from Dim_Position and point-in-time customer attributes from Fact_SnapshotCustomer. Covers April 2008 to present (6,356 days). HASH(PositionID) distribution enables co-located JOINs with position-distributed tables. Populated daily by SP_Fact_Customer_Action_Position_Distribution with post-insert integrity validation.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction + DWH_dbo.Dim_Position + DWH_dbo.Fact_SnapshotCustomer via SP_Fact_Customer_Action_Position_Distribution |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE WHERE DateID=@dateID + INSERT with integrity check |
| **Synapse Distribution** | HASH(PositionID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_Fact_Customer_Action_Position_Distribution is a performance-optimized partial derivative of DWH_dbo.Fact_CustomerAction. It exists because the JOIN from Fact_CustomerAction to Dim_Position hampers performance in views and table-valued functions (TVFs) where well-aligned distributions in temp tables are not possible. By pre-computing this JOIN and distributing on HASH(PositionID), downstream consumers get co-located access to position-enriched fee data.

The table contains 3.4 billion rows spanning April 2008 to April 2026 (6,356 distinct dates). Each row represents one customer action of a specific type — predominantly ticket fees (ActionTypeID=35, ~97% of rows), with compensations (ActionTypeID=36 with specific reason codes), edit stop-loss events (ActionTypeID=32), and detach-from-mirror events (ActionTypeID=19).

Each action row is enriched with:
- **Position attributes** from Dim_Position (IsBuy, IsSettled, Leverage, SettlementTypeID, MirrorID, IsAirDrop) — resolved via COALESCE preferring Dim_Position over Fact_CustomerAction
- **Customer snapshot attributes** from Fact_SnapshotCustomer at the action date — resolved via Dim_Range SCD JOIN (19 customer dimension columns)

The SP was authored by Guy Manova (2024-09-05) with subsequent fixes for compensation PositionID extraction (2025-01-04), SettlementTypeID addition for stocks margin (2025-09-10), and SettlementTypeID source switch from FCA to Dim_Position (2025-10-15).

After each daily load, the SP validates data integrity: row count and SUM(Amount) between this table and the filtered source must match exactly or the SP throws error 50000.

---

## 2. Business Logic

### 2.1 Action Type Filtering

**What**: Only specific action types from Fact_CustomerAction are included.

**Columns Involved**: `ActionTypeID`, `CompensationReasonID`

**Rules**:
- ActionTypeID=35: Ticket fees (overnight, dividend, SDRT, open/close total fees) — ~97% of rows
- ActionTypeID=36 + CompensationReasonID IN (56, 117, 118): Specific compensation types
- ActionTypeID=32: Edit stop-loss by customer
- ActionTypeID=19: Detach from mirror

### 2.2 Compensation PositionID Extraction

**What**: For compensations with CompensationReasonID IN (117, 118), the PositionID is sometimes missing from Fact_CustomerAction and must be extracted from the Description field.

**Columns Involved**: `PositionID`, `Description`, `CompensationReasonID`

**Rules**:
- When ActionTypeID=36 AND CompensationReasonID IN (117, 118): extract the last word from Description via REVERSE+SUBSTRING and TRY_CAST to BIGINT
- If TRY_CAST fails (non-numeric last word): PositionID = NULL
- For all other action types: PositionID passes through from Fact_CustomerAction
- Added 2025-01-04 to handle compensation mechanism errors that lost PositionID

### 2.3 Position Attribute COALESCE

**What**: Position attributes are resolved preferring Dim_Position over Fact_CustomerAction because FCA position data can be incomplete.

**Columns Involved**: `IsSettled`, `MirrorID`, `Leverage`, `InstrumentID`, `IsBuy`, `IsAirDrop`, `SettlementTypeID`

**Rules**:
- COALESCE(dp.X, fca.X) for IsSettled, MirrorID, Leverage, InstrumentID
- IsBuy: always NULL from FCA (hardcoded), resolved entirely from Dim_Position
- IsAirDrop: ISNULL(COALESCE(dp.IsAirDrop, fca.IsAirDrop), 0) — defaults to 0
- SettlementTypeID: from Dim_Position only (switched from FCA 2025-10-15 because FCA shows NULL on overnights)

### 2.4 Detach-from-Mirror Logic

**What**: MirrorID is zeroed when the action occurred after a detach-from-mirror event for the same position.

**Columns Involved**: `MirrorID`

**Rules**:
- If action Occurred > detach Occurred (ActionTypeID=19) for same PositionID: MirrorID = 0
- Otherwise: MirrorID retains the COALESCE'd value from Dim_Position/FCA
- This prevents attributing post-detach fees to the original mirror relationship

### 2.5 Ticket Fee Action Classification

**What**: Maps Description values to a simplified Open/Close ticket fee classification.

**Columns Involved**: `TicketFeeAction`, `Description`

**Rules**:
- Description = 'OpenTotalFees' → TicketFeeAction = 'Open'
- Description = 'CloseTotalFees' → TicketFeeAction = 'Close'
- All other descriptions → TicketFeeAction = NULL

### 2.6 Post-Insert Integrity Validation

**What**: After inserting data, the SP validates that row count and SUM(Amount) match the source.

**Rules**:
- Compares COUNT(*) and SUM(Amount) between this table (for @dateID) and the filtered Fact_CustomerAction source
- If either differs (CountRowDiff != 0 OR AmountDiff != 0): THROW 50000 error
- Ensures no data loss or duplication during the ETL process

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(PositionID) distribution with CLUSTERED COLUMNSTORE INDEX. This design enables co-located JOINs with other PositionID-distributed tables (e.g., BI_DB_PositionPnL). Always filter on DateID first — the CCI provides excellent compression and segment elimination on DateID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get all fees for a specific date | `WHERE DateID = @dateID` |
| Ticket fees only (no compensations) | `WHERE ActionTypeID = 35` |
| Open vs Close ticket fees | `WHERE TicketFeeAction IN ('Open', 'Close')` |
| Overnight fees only | `WHERE ActionTypeID = 35 AND IsFeeDividend = 1` |
| Dividend payments | `WHERE ActionTypeID = 35 AND IsFeeDividend = 2` |
| SDRT charges | `WHERE ActionTypeID = 35 AND IsFeeDividend = 3` |
| Ticket fees (open/close total) | `WHERE ActionTypeID = 35 AND IsFeeDividend = 4` |
| Copy-trade fees | `WHERE MirrorID > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON f.InstrumentID = di.InstrumentID | Resolve instrument name, type, asset class |
| DWH_dbo.Dim_Customer | ON f.RealCID = dc.RealCID | Customer demographic details |
| DWH_dbo.Dim_ActionType | ON f.ActionTypeID = dat.ActionTypeID | Action type name and category |
| DWH_dbo.Dim_Country | ON f.CountryID = dc.CountryID | Country name resolution |
| DWH_dbo.Dim_Regulation | ON f.RegulationID = dr.RegulationID | Regulatory jurisdiction name |

### 3.4 Gotchas

- **IsBuy is always from Dim_Position**: The SP sets IsBuy=NULL from Fact_CustomerAction and resolves it via COALESCE from Dim_Position. If a PositionID has no Dim_Position match (orphaned), IsBuy will be NULL.
- **MirrorID=0 after detach**: A position that was once a copy-trade (MirrorID>0) will show MirrorID=0 for actions that occurred after the detach-from-mirror event. This is by design.
- **PositionID extraction from Description**: For CompensationReasonID 117/118, PositionID comes from the last word in the Description string. If Description is malformed, PositionID = NULL.
- **SettlementTypeID can be NULL**: For actions on positions not in Dim_Position, or for legacy data before the column was added (pre-2025-09-10).
- **Amount sign**: Amount can be negative (e.g., overnight fees are typically negative values like -0.01, -0.44).
- **MASSIVE TABLE**: 3.4B rows. Always filter on DateID. Never run unfiltered SELECT COUNT(*) or GROUP BY without a date range.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (DWH_dbo documentation) | Highest — verified against source wiki docs |
| Tier 2 | SP code analysis | High — traced from ETL stored procedure logic |
| Tier 5 | ETL metadata / Expert Review | Standard — system-generated or expert-assigned |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Integer date key in YYYYMMDD format. DELETE+INSERT keyed on this column. 6,356 distinct dates from April 2008 to present. Passthrough from Fact_CustomerAction.DateID. (Tier 1 — DWH_dbo.Fact_CustomerAction) |
| 2 | RealCID | bigint | YES | Real-account Customer ID. References Dim_Customer.RealCID. Each customer has one real CID. Passthrough from Fact_CustomerAction.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 3 | PositionID | bigint | YES | Position identifier. Allocated by Internal.GetPositionID_Bigint. Unique per position. HASH distribution key. DWH note: for ActionTypeID=36 + CompensationReasonID IN (117,118), extracted from Description field via reverse string parsing with TRY_CAST fallback. COALESCE prefers Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 4 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 5 — Expert Review) |
| 5 | MirrorID | bigint | YES | FK to Trade.Mirror. 0/NULL = manual trade. Positive = copy-trade position. DWH note: set to 0 if action Occurred after a detach-from-mirror event (ActionTypeID=19) for the same PositionID. COALESCE from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 6 | Leverage | int | YES | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 1 — Trade.PositionTbl) |
| 7 | InstrumentID | int | YES | Tradeable instrument pair identifier. FK to Dim_Instrument. COALESCE from Dim_Position over Fact_CustomerAction. (Tier 1 — Trade.Instrument) |
| 8 | IsBuy | int | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. Always NULL from Fact_CustomerAction, resolved entirely from Dim_Position. NULL if no Dim_Position match. (Tier 1 — Trade.PositionTbl) |
| 9 | IsAirDrop | int | YES | 1 = position was created via an airdrop event (crypto). ISNULL(COALESCE(dp, fca), 0) — defaults to 0. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 10 | Amount | decimal(16,6) | YES | Action amount in dollars. Passthrough from Fact_CustomerAction. Can be negative (e.g., overnight fee = -0.01). (Tier 1 — Trade.PositionTbl) |
| 11 | ActionTypeID | int | YES | Event type classifier. Filtered to 4 values: 35 (ticket fees, ~97%), 36 (compensations with reason 56/117/118), 32 (edit stop-loss), 19 (detach from mirror). FK to Dim_ActionType. (Tier 1 — DWH_dbo.Fact_CustomerAction) |
| 12 | CompensationReasonID | int | YES | Compensation reason for compensation events (ActionTypeID=36). References BackOffice.CompensationReason. 0 for non-compensation events. Filtered to IN (56, 117, 118) when ActionTypeID=36. (Tier 1 — History.Credit) |
| 13 | IsFeeDividend | int | YES | Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. (Tier 2 — ETL-derived from Description) |
| 14 | Occurred | datetime | YES | UTC timestamp when the action occurred. Passthrough from Fact_CustomerAction. (Tier 1 — source-dependent) |
| 15 | TicketFeeAction | varchar(10) | YES | Simplified ticket fee classification. 'Open' = OpenTotalFees, 'Close' = CloseTotalFees. NULL for all other action types. 3 values: Open (8%), Close (8%), NULL (84%). (Tier 2 — SP_Fact_Customer_Action_Position_Distribution) |
| 16 | Description | varchar(255) | YES | Human-readable description. For ActionTypeID=35: "Over night fee", "Payment caused by dividend", "Weekend fee", "OpenTotalFees", "CloseTotalFees", "SDRT Charge". For ActionTypeID=32: "edit stop loss by customer". Passthrough from Fact_CustomerAction. (Tier 1 — History.Credit) |
| 17 | GCID | bigint | YES | Global Customer ID — cross-platform identifier linking RealCID to demo and external systems. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 18 | CountryID | int | YES | Customer's registered country. DEFAULT 0. FK to Dim_Country. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 19 | LabelID | int | YES | Brand/label associated with the customer (e.g., eToro UK, eToro Australia). DEFAULT 0. FK to Dim_Label. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 20 | VerificationLevelID | int | YES | KYC verification level. DEFAULT -1. FK to Dim_VerificationLevel. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 21 | PlayerStatusID | int | YES | Customer lifecycle status (e.g., Active, Blocked, Pending). DEFAULT 0. FK to Dim_PlayerStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 22 | RiskStatusID | int | YES | Customer risk assessment status. DEFAULT 0. FK to Dim_RiskStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 23 | RiskClassificationID | int | YES | Risk classification tier for compliance. DEFAULT 0. FK to Dim_RiskClassification. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 24 | GuruStatusID | int | YES | Popular Investor (Guru) program status. DEFAULT 0. FK to Dim_GuruStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 25 | RegulationID | int | YES | Customer's assigned regulatory jurisdiction. DEFAULT 0. FK to Dim_Regulation. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 26 | AccountStatusID | int | YES | Account enabled/suspended status. DEFAULT 0. FK to Dim_AccountStatus. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 27 | AccountManagerID | int | YES | Assigned account manager (sales/retention). DEFAULT 0. FK to Dim_Manager. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 28 | PlayerLevelID | int | YES | Account tier: 4=demo, other values=real tiers. DEFAULT 0. FK to Dim_PlayerLevel. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 29 | AccountTypeID | int | YES | Account type (e.g., 7=Employee, 9=excluded type, 2=real account). DEFAULT 0. FK to Dim_AccountType. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 30 | IsDepositor | int | YES | 1 if the customer has made at least one real-money deposit (FTD detected). Never reverted to 0 once set. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 31 | SuitabilityTestStatusID | int | YES | MiFID suitability test completion status. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 32 | MifidCategorizationID | int | YES | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. FK to Dim_MifidCategorization. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 33 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID in Fact_SnapshotCustomer. Passthrough via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 34 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed in Fact_SnapshotCustomer. Passthrough via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 35 | AffiliateID | int | YES | Affiliate/partner who referred this customer. DEFAULT 0. Passthrough from Fact_SnapshotCustomer at action date via SCD JOIN. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 36 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |
| 37 | SettlementTypeID | int | YES | Modern settlement classification from Dim_Position. 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. DWH note: switched from FCA to Dim_Position source (2025-10-15) because FCA shows NULL on overnights. (Tier 1 — Trade.PositionTbl) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| DateID | DWH_dbo.Fact_CustomerAction | DateID | Passthrough |
| RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough |
| PositionID | DWH_dbo.Fact_CustomerAction + Dim_Position | PositionID | COALESCE; extracted from Description for comp 117/118 |
| IsSettled–IsAirDrop | DWH_dbo.Dim_Position | Various | COALESCE(dp, fca) — prefers Dim_Position |
| Amount–Description | DWH_dbo.Fact_CustomerAction | Various | Passthrough |
| TicketFeeAction | DWH_dbo.Fact_CustomerAction | Description | CASE mapping |
| GCID–AffiliateID | DWH_dbo.Fact_SnapshotCustomer | Various | SCD passthrough via Dim_Range |
| SettlementTypeID | DWH_dbo.Dim_Position | SettlementTypeID | Passthrough |
| UpdateDate | ETL metadata | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (filtered: ActionTypeID IN (35,36,32,19))
  |-- Extract PositionID from Description for comp 117/118 ---|
  v
#fca (fee/comp/detach rows with parsed PositionID)
  + DWH_dbo.Dim_Position (LEFT JOIN on PositionID)
  |-- COALESCE(dp.X, fca.X) for position attributes ---|
  v
#fca2 (position-enriched actions)
  + DWH_dbo.Fact_SnapshotCustomer (JOIN on RealCID)
  + DWH_dbo.Dim_Range (SCD resolution: DateRangeID WHERE DateID BETWEEN From/To)
  + #detachFromMirror (LEFT JOIN for MirrorID zeroing)
  |-- Enrich with point-in-time customer attributes ---|
  v
#final
  |-- DELETE WHERE DateID=@dateID + INSERT ---|
  v
BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution (3.4B rows)
  |-- Integrity check: COUNT + SUM(Amount) must match source ---|
  Daily via SP_Fact_Customer_Action_Position_Distribution (SB_Daily, Priority 0)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | FK — customer identification |
| PositionID | DWH_dbo.Dim_Position | FK — position details |
| InstrumentID | DWH_dbo.Dim_Instrument | FK — instrument name, type |
| ActionTypeID | DWH_dbo.Dim_ActionType | FK — action type name, category |
| CountryID | DWH_dbo.Dim_Country | FK — country name |
| RegulationID | DWH_dbo.Dim_Regulation | FK — regulatory jurisdiction |
| PlayerLevelID | DWH_dbo.Dim_PlayerLevel | FK — account tier |
| AccountTypeID | DWH_dbo.Dim_AccountType | FK — account type |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship | Description |
|-------------------|--------------|-------------|
| SP_M_Finance_Audit_Auxillary_Datapoints | Reader | Uses for TicketFee and StockMarginOvernightFee metric calculations |
| SP_Client_Balance_New | Reader | Uses for client balance distribution analysis |

---

## 7. Sample Queries

### 7.1 Get Overnight Fees for a Date by Regulation

```sql
SELECT RegulationID,
       COUNT(*) AS fee_count,
       SUM(Amount) AS total_overnight_fees
FROM BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution
WHERE DateID = 20260412
  AND ActionTypeID = 35
  AND IsFeeDividend = 1
GROUP BY RegulationID
ORDER BY total_overnight_fees
```

### 7.2 Get Ticket Fee Open vs Close Breakdown

```sql
SELECT TicketFeeAction,
       IsSettled,
       COUNT(*) AS cnt,
       SUM(Amount) AS total_amount
FROM BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution
WHERE DateID = 20260412
  AND TicketFeeAction IS NOT NULL
GROUP BY TicketFeeAction, IsSettled
```

### 7.3 Find Copy-Trade Fees Detached from Mirror

```sql
SELECT DateID, RealCID, PositionID, MirrorID, Amount, Description
FROM BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution
WHERE DateID >= 20260401
  AND ActionTypeID = 35
  AND MirrorID = 0
  AND PositionID IN (
    SELECT PositionID FROM DWH_dbo.Dim_Position WHERE MirrorID > 0
  )
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 29 T1, 4 T2, 0 T3, 0 T4, 2 T5 | Elements: 37/37, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Fact_Customer_Action_Position_Distribution | Type: Table | Production Source: Fact_CustomerAction + Dim_Position + Fact_SnapshotCustomer via SP_Fact_Customer_Action_Position_Distribution*
