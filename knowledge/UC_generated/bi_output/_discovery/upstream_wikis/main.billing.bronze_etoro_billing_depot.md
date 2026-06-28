# Billing.Depot

> Master registry of payment gateway endpoints; each row configures one (FundingType + PaymentType + Protocol) combination as a named "depot" through which deposits, cashouts, or refunds are routed.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | DepotID (PRIMARY KEY NONCLUSTERED) |
| **Row Count** | ~163 rows (IDs 1-174, gaps) |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 - PK NONCLUSTERED on DepotID; 1 - UNIQUE NC on Name; 1 - composite NC on (FundingTypeID, PaymentTypeID, ProtocolID); 2 - NC on PaymentTypeID, ProtocolID |

---

## 1. Business Meaning

`Billing.Depot` is the central routing configuration table - each row defines one payment gateway endpoint ("depot") available for routing customer transactions. A depot is the combination of:
- **What payment method** (`FundingTypeID`): Visa, Mastercard, Neteller, PayPal, Wire, etc.
- **What direction** (`PaymentTypeID`): Deposit (1), Cashout (2), or Refund (3)
- **Which gateway/processor** (`ProtocolID`): the specific payment processing protocol/provider

The routing engine selects a depot based on these three dimensions plus customer-specific factors (regulation, BIN, quotas - see `Billing.RoutingReason`). When a transaction is processed, `Billing.Deposit.DepotID` records which depot was used.

With 163 rows and 38 funding types, the depot matrix represents the full scope of eToro's payment provider integrations across all markets. Currently 114 are active (70%) and 49 are inactive (legacy or decommissioned).

`PayoutGeneration` (int, default=0): indicates whether this depot supports automated payout file generation - only a subset (e.g., MoneyBookers USD=1, Neteller=1) have this capability.

`Features` (nvarchar 4000, nullable): JSON or XML-format configuration for depot-specific behavioral flags (e.g., 3DS settings, specific gateway capabilities). Empty for most historic depots.

---

## 2. Business Logic

### 2.1 Depot Routing Selection

**What**: The routing engine selects a depot for an incoming transaction based on FundingTypeID, PaymentTypeID, and routing criteria (regulation, BIN, quota, priority).

**Columns Involved**: `DepotID`, `FundingTypeID`, `PaymentTypeID`, `ProtocolID`, `IsActive`

**Rules**:
- Only depots with `IsActive=1` are eligible for routing
- The composite NC index `BDPT_DEPOT (FundingTypeID, PaymentTypeID, ProtocolID)` supports the routing lookup
- `Billing.ProtocolMIDSettings` references `DepotID` (FK) to store per-depot MID configuration (the actual merchant credentials used by this depot)
- `Billing.DepotValue` stores per-depot parameter values
- `Billing.CreditCardRoutingTransactionsVerification` uses `Billing.Depot WHERE FundingTypeID=1 AND IsActive=1` to validate CC deposit routing

### 2.2 Payout Generation

**What**: Controls whether automated payment file generation is enabled for cashout-side depots.

**Columns Involved**: `PayoutGeneration`, `DepotID`

**Rules**:
- `PayoutGeneration=1`: depot supports automated payout generation (system can batch-generate payment instructions)
- `PayoutGeneration=0` (DEFAULT): manual processing or provider handles batching
- Observed: MoneyBookers USD and Neteller have `PayoutGeneration=1`

### 2.3 Features Configuration

**What**: Per-depot behavioral configuration stored as structured text (JSON/XML).

**Columns Involved**: `Features`

**Rules**:
- NULL or empty string for most historic depots
- Used for newer integrations requiring depot-specific feature flags (e.g., 3DS2 configuration, specific payment flow overrides)
- Maximum 4,000 characters (nvarchar(4000))

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 163 |
| DepotID range | 1-174 (with gaps) |
| Active depots | 114 (70%) |
| Inactive depots | 49 (30%) |
| Distinct FundingTypes | 38 |
| PaymentTypeID=1 (Deposit) | Majority |

**Sample depots** (first 10):

| DepotID | Name | FundingTypeID | ProtocolID | Active |
|---------|------|--------------|-----------|--------|
| 1 | MoneyBookers USD | 8 | 8 | Yes |
| 2 | MoneyGram | 9 | 9 | No |
| 3 | WebMoney | 10 | 10 | Yes |
| 4 | Giropay | 11 | 13 | Yes |
| 5 | ELV | 12 | 14 | No |
| 6 | Direct24 | 13 | 15 | No |
| 7 | Neteller | 6 | 7 | Yes |
| 8 | Neteller (1-Pay) | 7 | 7 | No |
| 9 | Sofort | 15 | 19 | No |
| 10 | Wire | 2 | 6 | Yes |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepotID | int | NO | - | CODE-BACKED | Primary key. Manually assigned (no IDENTITY). Stable identifier referenced by deposits, MID settings, and routing tables. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type (e.g., 1=CreditCard, 2=Wire, 6=Neteller, 8=MoneyBookers/Skrill). References `Dictionary.FundingType` implicitly (no FK constraint in DDL). 38 distinct values across 163 depots. |
| 3 | PaymentTypeID | int | NO | - | CODE-BACKED | Direction of payment flow. FK to `Dictionary.PaymentType` (FK_DPMT_BDPT): 1=Deposit, 2=Cashout, 3=Refund. Indexed (BDPT_PAYMENTTYPE). |
| 4 | ProtocolID | int | NO | - | CODE-BACKED | Payment processing protocol/gateway. FK to `Dictionary.Protocol` (FK_DPRT_BDPT). Identifies the specific API or connection used (e.g., Protocol 7=Neteller, Protocol 6=Wire, Protocol 8=MoneyBookers). Indexed (BDPT_PROTOCOL). |
| 5 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable depot name (e.g., 'MoneyBookers USD', 'Neteller', 'Wire'). UNIQUE (BDPT_NAME index). Used in admin dashboards, routing logs, and discrepancy reports. |
| 6 | IsActive | bit | YES | NULL | CODE-BACKED | Whether this depot is currently accepting transactions. 1=Active (eligible for routing); 0 or NULL=Inactive (excluded from routing). 114 of 163 rows are active. Queried as `IsActive = 1` in routing logic. |
| 7 | PayoutGeneration | int | NO | 0 | CODE-BACKED | Controls automated payout file generation capability: 1=enabled (system can generate payment batch files for this depot); 0=disabled (manual or provider-managed). Default=0. |
| 8 | Features | nvarchar(4000) | YES | NULL | CODE-BACKED | Depot-specific configuration features in structured text (JSON or XML format). Used for newer integrations requiring behavioral flags (e.g., 3DS2 settings, specific API options). NULL or empty for most legacy depots. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentTypeID | Dictionary.PaymentType | FK (FK_DPMT_BDPT) | Deposit/Cashout/Refund direction |
| ProtocolID | Dictionary.Protocol | FK (FK_DPRT_BDPT) | Payment processing protocol |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.ProtocolMIDSettings | DepotID | FK (FK_BPMIDS_DepotID) | Per-depot merchant ID and parameter settings |
| Billing.Deposit | DepotID | FK (implicit) | Records which depot processed each deposit |
| Billing.DepotValue | DepotID | FK (implicit) | Per-depot parameter value configuration |
| Billing.BankToDepot | DepotID | FK (implicit) | Bank routing to depot associations |
| Billing.CreditCardRoutingTransactionsVerification | DepotID | Read | Validates CC routing against active depots |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Depot
  -> Dictionary.PaymentType (1=Deposit, 2=Cashout, 3=Refund)
  -> Dictionary.Protocol (49 payment processing protocols)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.PaymentType | Table | FK on PaymentTypeID |
| Dictionary.Protocol | Table | FK on ProtocolID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.ProtocolMIDSettings | Table | FK on DepotID - MID configuration per depot |
| Billing.Deposit | Table | FK on DepotID - transaction routing record |
| Billing.DepotValue | Table | FK on DepotID - depot parameter values |
| Billing.Terminal | Table | FK on DepotID (implied through protocol) |
| Billing.CreditCardRoutingTransactionsVerification | Stored Procedure | Reads IsActive CC depots for routing validation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_BDPT | NONCLUSTERED PK | DepotID ASC | - | - | Active; FILLFACTOR=90; heap table |
| BDPT_NAME | UNIQUE NC | Name ASC | - | - | Active; FILLFACTOR=90; prevents duplicate depot names |
| BDPT_DEPOT | NC | FundingTypeID, PaymentTypeID, ProtocolID ASC | - | - | Active; FILLFACTOR=90; routing lookup index |
| BDPT_PAYMENTTYPE | NC | PaymentTypeID ASC | - | - | Active |
| BDPT_PROTOCOL | NC | ProtocolID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BDPT | PRIMARY KEY NONCLUSTERED (DepotID) | One row per depot |
| FK_DPMT_BDPT | FOREIGN KEY PaymentTypeID -> Dictionary.PaymentType | Payment direction must be valid |
| FK_DPRT_BDPT | FOREIGN KEY ProtocolID -> Dictionary.Protocol | Protocol must be valid |
| BDPT_NAME (index) | UNIQUE | Depot name must be unique |
| DF PayoutGeneration | DEFAULT (0) | PayoutGeneration defaults to 0 if not specified |

---

## 8. Sample Queries

### 8.1 View active depots by funding type

```sql
SELECT
    d.DepotID,
    d.Name,
    d.FundingTypeID,
    pt.Name AS PaymentType,
    p.Name AS Protocol,
    d.PayoutGeneration
FROM Billing.Depot d WITH (NOLOCK)
JOIN Dictionary.PaymentType pt WITH (NOLOCK) ON pt.PaymentTypeID = d.PaymentTypeID
JOIN Dictionary.Protocol p WITH (NOLOCK) ON p.ProtocolID = d.ProtocolID
WHERE d.IsActive = 1
ORDER BY d.FundingTypeID, d.PaymentTypeID
```

### 8.2 Find depots with MID configuration for a specific regulation/currency

```sql
SELECT
    d.DepotID,
    d.Name,
    pms.RegulationID,
    pms.CurrencyID,
    pms.Value AS MerchantID
FROM Billing.Depot d WITH (NOLOCK)
JOIN Billing.ProtocolMIDSettings pms WITH (NOLOCK) ON pms.DepotID = d.DepotID
WHERE pms.ParameterID = 52  -- merchantID
  AND d.IsActive = 1
ORDER BY d.DepotID, pms.RegulationID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Depot | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Depot.sql*
