# DWH_dbo.Dim_BillingDepot

> Payment gateway endpoint lookup; each row represents one (FundingType × PaymentType × Protocol) combination through which deposits, cashouts, or refunds are routed.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table (Dimension) |
| **Key Identifier** | DepotID (int NOT NULL, CLUSTERED INDEX) |
| **Row Count** | ~163 rows |
| **Distribution** | REPLICATE |
| **Index** | CLUSTERED INDEX on DepotID ASC |

---

## 1. Business Meaning

`Dim_BillingDepot` is a DWH replica of the production `Billing.Depot` table — the central routing configuration that maps every payment gateway endpoint. A "depot" is the intersection of three dimensions:

- **FundingTypeID** — the payment method (Visa, Neteller, Wire, PayPal, etc.)
- **PaymentTypeID** — the direction of money flow (1 = Deposit, 2 = Cashout, 3 = Refund)
- **ProtocolID** — the specific payment processing gateway/API

When a financial transaction is processed, the routing engine selects the appropriate depot based on these three dimensions plus customer-specific factors (regulation, BIN, quotas). The selected DepotID is stamped on the resulting transaction record.

With ~163 rows covering 38 funding types, the depot matrix represents the full scope of eToro's payment provider integrations across all markets. Approximately 114 (70%) are active and 49 (30%) are decommissioned.

**Column Pruning**: The DWH copy omits two columns from production: `PayoutGeneration` (automated payout file generation flag) and `Features` (depot-specific JSON/XML configuration). These operational columns are irrelevant for analytics.

---

## 2. Business Logic

### 2.1 Depot Routing Classification

**What**: Each depot is uniquely identified by the (FundingType, PaymentType, Protocol) triple.

**Columns Involved**: `DepotID`, `FundingTypeID`, `PaymentTypeID`, `ProtocolID`, `Name`

**Rules**:
- Only depots with `IsActive = 1` are eligible for transaction routing
- `Name` is unique in production (enforced by UNIQUE index on source) — e.g., "MoneyBookers USD", "Neteller", "Wire"
- FKs in production: PaymentTypeID → Dictionary.PaymentType, ProtocolID → Dictionary.Protocol

### 2.2 Active/Inactive Status

**What**: `IsActive` controls whether the depot is available for routing.

**Columns Involved**: `IsActive`

**Rules**:
- `1` = Active, eligible for routing
- `0` or `NULL` = Inactive, excluded from routing (legacy or decommissioned)
- ~70% of depots are currently active

---

## 3. ETL Source & Refresh

| Property | Value |
|----------|-------|
| **Production Source** | `etoro.Billing.Depot` (etoroDB-REAL) |
| **Generic Pipeline ID** | 634 |
| **Copy Strategy** | Override (hourly, every 60 min) |
| **Staging Table** | `DWH_staging.etoro_Billing_Depot` |
| **Load SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Load Pattern** | TRUNCATE + INSERT (daily full reload) |
| **Column Mapping** | 6 columns passthrough, 1 ETL-generated (`UpdateDate`) |

---

## 4. Query Advisory

| Aspect | Detail |
|--------|--------|
| **Distribution** | REPLICATE — broadcast to all compute nodes, optimal for small dimension JOINs |
| **Clustered Index** | DepotID ASC — efficient single-row lookups |
| **Typical JOINs** | `Fact_*.DepotID = Dim_BillingDepot.DepotID` |
| **Best Practice** | Join on DepotID; filter `IsActive = 1` for current-state queries |

---

## 5. Elements

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | DepotID | int | NO | Tier 1 | Primary key. Manually assigned identifier for the payment gateway endpoint (no IDENTITY). Stable identifier referenced by deposit, MID settings, and routing tables. IDs range 1–174 with gaps. |
| 2 | FundingTypeID | int | NO | Tier 1 | Payment method type (e.g., 1 = CreditCard, 2 = Wire, 6 = Neteller, 8 = MoneyBookers/Skrill). References production `Dictionary.FundingType`. 38 distinct values across ~163 depots. |
| 3 | PaymentTypeID | int | NO | Tier 1 | Direction of payment flow. 1 = Deposit, 2 = Cashout, 3 = Refund. References production `Dictionary.PaymentType`. |
| 4 | ProtocolID | int | NO | Tier 1 | Payment processing protocol/gateway identifier. References production `Dictionary.Protocol`. Identifies the specific API or connection (e.g., Protocol 7 = Neteller, Protocol 6 = Wire). |
| 5 | Name | varchar(50) | NO | Tier 1 | Human-readable depot name (e.g., "MoneyBookers USD", "Neteller", "Wire"). Unique in production. Used in admin dashboards and routing logs. |
| 6 | IsActive | bit | YES | Tier 1 | Whether this depot is currently accepting transactions. 1 = Active (eligible for routing); 0 or NULL = Inactive (excluded from routing). ~114 of 163 rows are active. |
| 7 | UpdateDate | datetime | NO | Tier 2 | ETL load timestamp — set to `GETDATE()` by SP_Dictionaries_DL_To_Synapse on each reload. Does not reflect the source record's modification time. |

---

## 6. Sample Data

| DepotID | Name | FundingTypeID | PaymentTypeID | ProtocolID | IsActive |
|---------|------|---------------|---------------|------------|----------|
| 1 | MoneyBookers USD | 8 | 1 | 8 | 1 |
| 2 | MoneyGram | 9 | 1 | 9 | 0 |
| 3 | WebMoney | 10 | 1 | 10 | 1 |
| 7 | Neteller | 6 | 1 | 7 | 1 |
| 10 | Wire | 2 | 1 | 6 | 1 |

---

## 7. Known Consumers

Fact tables and views that JOIN to `Dim_BillingDepot` on `DepotID` for payment method context in deposit/cashout analytics.

---

*Generated: 2026-03-18 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 6 Tier 1, 1 Tier 2, 0 Tier 4 [UNVERIFIED] | Phases: 1,2,4,8,9b,10.5,11*
*Upstream Wiki: Billing.Depot (9.2/10) — 6 of 6 passthrough columns inherited*
*Source: DataPlatform / DWH_dbo / Tables / DWH_dbo.Dim_BillingDepot.sql*
