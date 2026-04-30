# Billing.ProtocolMIDSettings

> Payment protocol MID (Merchant ID) configuration table. Each row defines a specific protocol parameter value for a combination of depot, trading mode (Live/Demo), regulatory jurisdiction, and currency. Drives payment routing in deposit and withdrawal processing. 1,470 routing entries covering live and demo modes across CySEC, FCA, and other regulatory jurisdictions.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (ParameterID, DepotID, DepotModeID, RegulationID, CurrencyID) - NONCLUSTERED PK; CLUSTERED index on ID |
| **Row Count** | 1,470 rows |
| **Partition** | N/A - filegroup PRIMARY; DATA_COMPRESSION = PAGE |
| **Indexes** | 1 CLUSTERED on ID; 1 NONCLUSTERED composite PK |

---

## 1. Business Meaning

`Billing.ProtocolMIDSettings` is the payment routing configuration table. It maps every combination of payment parameter + depot + mode + regulation + currency to a specific `Value` - the MID (Merchant ID) or protocol identifier string used to route transactions through a specific payment processor endpoint.

When a deposit is processed via `Billing.DepositProcess`, the system looks up this table to determine which MID to use for the given regulatory entity and depot. Similarly, `Billing.WithdrawToFundingProcess` uses this table to route withdrawals. The `ProtocolMIDSettingsID` foreign key in `Billing.Deposit` and `Billing.WithdrawToFunding` references this table's `ID`.

**Row composition**:
- 884 Demo mode (60.1%), 544 Live mode (37.0%), 42 General (2.9%)
- 1,374 rows SubTypeID=0 (default), 96 rows SubTypeID=3 (alternate sub-routing)
- 377 rows linked to a MerchantAccountID (25.6%), 1,093 rows with no merchant account override

---

## 2. Business Logic

### 2.1 MID Routing Lookup

**What**: Given a depot (which payment processor gateway) + regulation (which legal entity) + currency + mode (Live vs Demo), retrieve the Value (MID/protocol string) to use for the transaction.

**Primary reader**: `Billing.GetProtocolMIDSettings(@RegulationID, @DepotID, @CurrencyID, @MerchantAccountID)`
- Filters on (RegulationID, DepotID, CurrencyID, MerchantAccountID)
- Returns (ID, ParameterID, DepotModeID, Value, Description, SubTypeID)
- Used to look up applicable MIDs before processing a payment

**Also used in**: `Billing.GetDepotMIDSettings`, `Billing.DepositProcess`, `Billing.WithdrawToFundingProcess`, `Billing.WithdrawToFundingProcess_v2`, `Billing.LoadPayoutProcessData`, `Billing.PSPMatchToEtoro`

### 2.2 Depot Mode Routing (Live vs Demo separation)

**Column**: `DepotModeID TINYINT FK -> Dictionary.DepotMode`

| DepotModeID | DepotModeName | Count |
|-------------|---------------|-------|
| 0 | General | 42 (2.9%) |
| 1 | Live | 544 (37.0%) |
| 2 | Demo | 884 (60.1%) |

Live and Demo accounts use different MIDs to route to different processing environments. The high Demo count reflects that demo account deposits use the same routing infrastructure but with sandbox MIDs.

### 2.3 Regulatory Segmentation

**Column**: `RegulationID INT FK -> Dictionary.Regulation`

Each regulatory entity (CySEC, FCA, ASIC, etc.) has its own set of MIDs, reflecting that eToro operates under different legal entities across jurisdictions.

| RegulationID | Name | Jurisdiction |
|---|---|---|
| 0 | None | - |
| 1 | CySEC | eToro EU |
| 2 | FCA | eToro UK |
| ... | ... | ... |

### 2.4 Currency Override

**Column**: `CurrencyID INT NOT NULL DEFAULT 0`

CurrencyID=0 (default) means "any currency" - the MID applies regardless of transaction currency. Non-zero values restrict the MID to a specific currency. Most rows use CurrencyID=0.

### 2.5 SubTypeID - Alternate Routing

**Column**: `SubTypeID INT NOT NULL DEFAULT 0`

| SubTypeID | Count | Meaning |
|-----------|-------|---------|
| 0 | 1,374 | Default routing |
| 3 | 96 | Alternate sub-routing (specific processor subset) |

### 2.6 MerchantAccountID - Account-Level Override

**Column**: `MerchantAccountID INT NULL`

When set (377 rows, 25.6%), this links to a specific merchant account configuration in `Billing.MerchantAccountValues`, providing finer-grained routing to a specific acquiring account within a depot.

---

## 3. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **ID** | int IDENTITY(1,1) | NOT NULL | Auto | - | [CODE-BACKED] Surrogate PK (physical clustered key). Referenced as `ProtocolMIDSettingsID` in Billing.Deposit and Billing.WithdrawToFunding to record which routing config was used. NOT FOR REPLICATION. |
| **ParameterID** | int | NOT NULL | - | Billing.Parameter(ParameterID) | [CODE-BACKED] Protocol parameter type. Part of logical PK. References Billing.Parameter which defines the parameter name/type (e.g., "MID", "SecretKey", etc.). |
| **DepotID** | int | NOT NULL | - | Billing.Depot(DepotID) | [CODE-BACKED] Payment gateway/depot. Part of logical PK. Identifies the payment processor this MID belongs to. |
| **DepotModeID** | tinyint | NOT NULL | - | Dictionary.DepotMode(DepotModeID) | [CODE-BACKED] Trading mode. Part of logical PK. 0=General, 1=Live, 2=Demo. Separates Live and Demo processing environments. 60% Demo, 37% Live. |
| **Value** | nvarchar(250) | NULL | - | - | [CODE-BACKED] The protocol identifier string (MID, merchant ID, API key, etc.). This is the actual routing value passed to the payment processor. Examples: "18989693", "18986763". |
| **RegulationID** | int | NOT NULL | - | Dictionary.Regulation(ID) | [CODE-BACKED] Regulatory entity. Part of logical PK. Segments MIDs by legal jurisdiction (CySEC=1, FCA=2, etc.). Ensures transactions route through the correct legal entity's acquiring relationship. |
| **CurrencyID** | int | NOT NULL | (0) | - | [CODE-BACKED] Currency restriction. Part of logical PK. 0=any currency. Most rows are 0. Non-zero restricts this MID to a specific currency. |
| **Description** | nvarchar(250) | NULL | - | - | [NAME-INFERRED] Human-readable description of this MID entry (e.g., which processor, account name). |
| **SubTypeID** | int | NOT NULL | (0) | - | [CODE-BACKED] Sub-routing type. 0=default (93.5%), 3=alternate (6.5%). Allows multiple routing paths within the same (depot, mode, regulation, currency). |
| **MerchantAccountID** | int | NULL | - | Billing.MerchantAccountValues(MerchantAccountID) [implicit] | [CODE-BACKED] Optional link to a specific merchant account configuration. 377 rows (25.6%) have this set for finer-grained routing. |

---

## 4. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| IDX_BillingProtocolMIDSettingsClustered_ID | CLUSTERED | ID ASC | FILLFACTOR=95; DATA_COMPRESSION=PAGE. Physical row ordering by identity. |
| PK_BillingProtocolMIDSettings | NONCLUSTERED | (ParameterID, DepotID, DepotModeID, RegulationID, CurrencyID) ASC | FILLFACTOR=95. Logical uniqueness constraint; routing lookup key. |

---

## 5. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.GetProtocolMIDSettings` | Lookup by (RegulationID, DepotID, CurrencyID, MerchantAccountID) |
| `Billing.GetDepotMIDSettings` | Alternative lookup path |
| `Billing.DepositProcess` | Reads during deposit approval to select MID |
| `Billing.WithdrawToFundingProcess` / `_v2` | Reads during withdrawal processing for routing |
| `Billing.LoadPayoutProcessData` / `_v2` | Reads for payout routing |
| `Billing.ProtocolEdit` | Writes/updates entries |
| `Billing.WithdrawToFundingUpdateProtocolMidSettingsID` | Updates Billing.WithdrawToFunding.ProtocolMIDSettingsID references |

---

## 6. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.Depot | Many-to-one | ProtocolMIDSettings.DepotID = Depot.DepotID | Explicit FK. The payment gateway this MID is configured for. |
| Billing.Parameter | Many-to-one | ProtocolMIDSettings.ParameterID = Parameter.ParameterID | Explicit FK. The parameter type (MID, key, etc.). |
| Dictionary.DepotMode | Many-to-one | ProtocolMIDSettings.DepotModeID = DepotMode.DepotModeID | Explicit FK. 0=General, 1=Live, 2=Demo. |
| Dictionary.Regulation | Many-to-one | ProtocolMIDSettings.RegulationID = Regulation.ID | Explicit FK. Legal jurisdiction. |
| Billing.Deposit | Reverse | Deposit.ProtocolMIDSettingsID = ProtocolMIDSettings.ID | Implicit (no FK in Deposit). Records which MID was used for each deposit. |
| Billing.WithdrawToFunding | Reverse | WithdrawToFunding.ProtocolMIDSettingsID = ProtocolMIDSettings.ID | Implicit. Records which MID was used for each withdrawal processing. |

---

*Quality: 9.1/10 | 9 CODE-BACKED, 1 NAME-INFERRED | Phases: 1,2,3,4,5,6,8,9,11*
