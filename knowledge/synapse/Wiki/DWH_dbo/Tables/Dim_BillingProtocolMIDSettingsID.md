# DWH_dbo.Dim_BillingProtocolMIDSettingsID

> Payment protocol MID (Merchant ID) routing configuration; each row maps a (depot × parameter × mode × regulation × currency) combination to a specific merchant identifier used to route deposit and withdrawal transactions through payment processors.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | ProtocolMIDSettingsID (int NOT NULL) |
| **Row Count** | ~1,851 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on DepotID ASC |

---

## 1. Business Meaning

`Dim_BillingProtocolMIDSettingsID` is a DWH replica of production `Billing.ProtocolMIDSettings` — the payment routing configuration table that stores MID (Merchant ID) mappings used to process deposits and withdrawals through payment gateways.

Each row defines which MID/protocol string to use for a specific combination of:
- **DepotID** — which payment gateway endpoint (→ `Dim_BillingDepot`)
- **ParameterID** — which protocol parameter (e.g., MerchantID, SecretKey)
- **DepotModeID** — Live (1), Demo (2), or General (0)
- **RegulationID** — regulatory jurisdiction (CySEC, FCA, ASIC, etc.)
- **CurrencyID** — currency restriction (0 = any currency)

When a financial transaction is processed, the Billing system looks up this table to determine the correct MID string (`Value` column) for routing. The selected `ProtocolMIDSettingsID` is stamped on each deposit and withdrawal record.

**Row composition** (from upstream analysis):
- ~60% Demo mode, ~37% Live mode, ~3% General
- ~94% default routing (SubTypeID=0), ~6% alternate (SubTypeID=3)
- ~26% linked to a specific MerchantAccountID

---

## 2. Business Logic

### 2.1 MID Routing Lookup

**What**: For a given (depot, regulation, currency, merchant account) combination, retrieve the MID value to route the transaction through the correct payment processor endpoint.

**Columns Involved**: `DepotID`, `ParameterID`, `RegulationID`, `CurrencyID`, `DepotModeID`, `Value`

**Rules**:
- The composite logical key is (ParameterID, DepotID, DepotModeID, RegulationID, CurrencyID)
- `Value` contains the actual MID/API key string passed to the payment processor (e.g., "18989693")
- CurrencyID = 0 means "any currency" — the MID applies regardless of transaction currency

### 2.2 Depot Mode Separation

**What**: Live and Demo accounts use different MIDs routed to different processing environments.

**Columns Involved**: `DepotModeID`

**Rules**:
- 0 = General (applies to both modes)
- 1 = Live (production payment processing)
- 2 = Demo (sandbox/test processing)

### 2.3 Regulatory Segmentation

**What**: Each regulatory entity has its own MID set, ensuring transactions route through the correct legal entity's acquiring relationship.

**Columns Involved**: `RegulationID`

**Rules**:
- RegulationID segments MIDs by jurisdiction (CySEC=1, FCA=2, etc.)
- Each (depot, regulation) pair may have different MID values

---

## 3. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.Billing.ProtocolMIDSettings` (etoroDB-REAL) |
| **Generic Pipeline ID** | 636 |
| **Copy Strategy** | Override (daily, every 1440 min) |
| **Staging Table** | `DWH_staging.etoro_Billing_ProtocolMIDSettings` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |
| **Column Mapping** | 10 columns (1 renamed: `ID` → `ProtocolMIDSettingsID`), 1 ETL-generated (`UpdateDate`) |

---

## 4. Query Advisory

| Aspect | Detail |
|--------|--------|
| **Distribution** | REPLICATE — broadcast to all compute nodes, optimal for dimension JOINs |
| **Clustered Index** | DepotID ASC — efficient for depot-based lookups and JOINs to `Dim_BillingDepot` |
| **Typical JOINs** | `Fact_*.ProtocolMIDSettingsID = Dim_BillingProtocolMIDSettingsID.ProtocolMIDSettingsID` |
| **Best Practice** | Join on ProtocolMIDSettingsID for transaction-level lookups; filter by DepotModeID = 1 for live-only analysis |

---

## 5. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | ProtocolMIDSettingsID | int | NO | Tier 1 | Surrogate primary key — maps to production `Billing.ProtocolMIDSettings.ID` (IDENTITY). Referenced by deposit and withdrawal records to track which MID routing config was used. |
| 2 | ParameterID | int | NO | Tier 1 | Protocol parameter type. References production `Billing.Parameter`. Identifies what kind of value this row holds (e.g., MerchantID, SecretKey). Part of the logical composite key. |
| 3 | DepotID | int | NO | Tier 1 | Payment gateway/depot identifier. References `Dim_BillingDepot`. Identifies which payment processor endpoint this MID belongs to. Part of the logical composite key. |
| 4 | DepotModeID | tinyint | NO | Tier 1 | Trading mode: 0 = General (both), 1 = Live, 2 = Demo. Separates production and sandbox payment processing environments. ~60% Demo, ~37% Live. |
| 5 | Value | nvarchar(250) | YES | Tier 1 | The actual MID / merchant identifier / API key string routed to the payment processor (e.g., "18989693"). This is the operational routing value. |
| 6 | RegulationID | int | NO | Tier 1 | Regulatory jurisdiction (CySEC=1, FCA=2, etc.). Segments MIDs by legal entity to ensure correct acquiring relationship per jurisdiction. Part of the logical composite key. |
| 7 | CurrencyID | int | NO | Tier 1 | Currency restriction. 0 = any currency (majority). Non-zero restricts this MID to a specific currency. Part of the logical composite key. |
| 8 | Description | nvarchar(250) | YES | Tier 1 | Human-readable description of this MID entry (processor name, account name). Often empty for older entries. |
| 9 | SubTypeID | int | NO | Tier 1 | Sub-routing type. 0 = default routing (~94%), 3 = alternate sub-routing (~6%). Allows multiple routing paths within the same (depot, mode, regulation, currency) combination. |
| 10 | MerchantAccountID | int | YES | Tier 1 | Optional link to a specific merchant account configuration for finer-grained routing. Set for ~26% of rows; NULL means depot-level default routing applies. |
| 11 | UpdateDate | datetime | NO | Tier 2 | ETL load timestamp — set to `GETDATE()` by SP_Dictionaries_DL_To_Synapse on each reload. Does not reflect the source record's modification time. |

---

## 6. Known Consumers

Fact tables storing deposit and withdrawal transactions JOIN to this dimension on `ProtocolMIDSettingsID` to resolve the payment routing configuration used for each transaction.

---

*Generated: 2026-03-18 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10)*
*Confidence: 10 Tier 1, 1 Tier 2, 0 Tier 4 [UNVERIFIED] | Phases: 1,2,4,8,9b,10.5,11*
*Upstream Wiki: Billing.ProtocolMIDSettings (9.1/10) — 10 of 10 source columns inherited*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_BillingProtocolMIDSettingsID.sql*
