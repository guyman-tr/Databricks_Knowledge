# Billing.Terminal

> Payment terminal configuration table extending `Billing.Depot` with a currency dimension; each row defines a (Protocol + PaymentType + Currency + FundingType) combination with a default flag and cumulative processed amount counter.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | TerminalID (PRIMARY KEY NONCLUSTERED, IDENTITY) |
| **Row Count** | 48 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 - PK NONCLUSTERED on TerminalID; 4 NC indexes (CurrencyID, FundingTypeID, PaymentTypeID, ProtocolID) |

---

## 1. Business Meaning

`Billing.Terminal` defines payment terminal slots at a finer granularity than `Billing.Depot` - adding a `CurrencyID` dimension to specify which currency each terminal handles. Where a Depot configures a payment gateway for a funding type + payment direction, a Terminal further specifies the currency, enabling multi-currency routing (e.g., PayPal Express Checkout in USD, EUR, and GBP are three separate terminals sharing the same protocol).

Each terminal tracks:
- **Configuration**: Protocol + PaymentType + Currency + FundingType tuple
- **Default flag** (`IsDefault`): which terminal is the preferred selection for its combination (22 of 48 are defaults)
- **Volume tracking** (`ProcessedAmount`): cumulative processed amount through this terminal (in the smallest currency unit), used for quota management and reporting

With 48 rows and CurrencyID values including 0 (currency-agnostic), 1 (USD), 2 (EUR), 3 (GBP), and others, the terminal matrix covers the major currency variants of each payment method.

---

## 2. Business Logic

### 2.1 Terminal Selection

**What**: When processing a payment, the system selects the terminal for the matching (Protocol, PaymentType, Currency, FundingType) combination, preferring the `IsDefault=1` terminal when multiple matches exist.

**Columns Involved**: `ProtocolID`, `PaymentTypeID`, `CurrencyID`, `FundingTypeID`, `IsDefault`

**Rules**:
- `IsDefault=1`: preferred terminal for this combination (22 terminals)
- `IsDefault=0`: alternate or legacy terminal for the same combination
- `CurrencyID=0`: currency-agnostic terminal (used when the protocol handles any currency, e.g., PayPal Direct)
- `CurrencyID=1,2,3,...`: currency-specific terminal (USD, EUR, GBP, etc.)
- Multiple terminals can share the same (Protocol, PaymentType, FundingType) if they differ by currency

### 2.2 Volume Tracking

**What**: `ProcessedAmount` accumulates the total amount processed through this terminal for quota and reporting purposes.

**Columns Involved**: `ProcessedAmount`, `LastTransactionDate`

**Rules**:
- `ProcessedAmount` (int): cumulative total in smallest currency unit (cents); starts at 0, incremented with each processed transaction
- `LastTransactionDate`: timestamp of the most recent transaction through this terminal; updated on each processing event
- Observed: PayPal Express Checkout USD=20,000 cents ($200), PayPal Express EURO=100,000 cents (100 EUR), PayPal Express GBP=8,000 pence (80 GBP) - low values suggest this counter may have been reset or reflects a subset of transactions

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | 48 |
| IsDefault=1 | 22 terminals (46%) |
| IsDefault=0 | 26 terminals (54%) |
| TerminalID range | 1-48+ |

**Sample terminals** (first 10):

| TerminalID | TerminalName | Protocol | Currency | FundingType | Default |
|-----------|-------------|---------|---------|------------|---------|
| 1 | Xor Deposit | 1 (Xor) | 1 (USD) | 1 (CC) | No |
| 2 | PayPal Express Checkout | 2 (PayPal) | 1 (USD) | 3 (PayPal) | Yes |
| 3 | PayPal Direct | 2 (PayPal) | 0 (any) | 3 (PayPal) | No |
| 4 | Wire Deposit | 6 (Wire) | 1 (USD) | 2 (Wire) | Yes |
| 5 | Western Union Deposit | 5 (WU) | 1 (USD) | 5 (WU) | Yes |
| 6 | PayPal Express EURO | 2 (PayPal) | 2 (EUR) | 3 (PayPal) | Yes |
| 7 | Xor Deposit EURO | 1 (Xor) | 2 (EUR) | 1 (CC) | No |
| 8 | Wire EURO deposit | 6 (Wire) | 2 (EUR) | 2 (Wire) | Yes |
| 9 | Western EURO Deposit | 5 (WU) | 2 (EUR) | 5 (WU) | Yes |
| 10 | PayPal Express GBP | 2 (PayPal) | 3 (GBP) | 3 (PayPal) | Yes |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TerminalID | int | NO | IDENTITY(1,1) | CODE-BACKED | Internal primary key. Auto-generated. NOT FOR REPLICATION. |
| 2 | ProtocolID | int | NO | - | CODE-BACKED | Payment processing protocol. FK to `Dictionary.Protocol` (FK_DPRT_BTER). Identifies the gateway API used (e.g., 1=Xor, 2=PayPal, 5=WesternUnion, 6=Wire). Indexed (BTER_PROTOCOL). |
| 3 | PaymentTypeID | int | NO | - | CODE-BACKED | Transaction direction. FK to `Dictionary.PaymentType` (FK_DPMT_BTER): 1=Deposit, 2=Cashout, 3=Refund. Indexed (BTER_PAYMENTTYPE). |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Terminal currency. FK to `Dictionary.Currency` (FK_DCUR_BTER). CurrencyID=0 = currency-agnostic (any currency). CurrencyID=1=USD, 2=EUR, 3=GBP, etc. Indexed (BTER_CURRENCY). Enables per-currency terminal routing. |
| 5 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method type. References `Dictionary.FundingType` implicitly (no FK constraint). Indexed (BTER_FUNDINGTYPE). |
| 6 | TerminalName | varchar(50) | NO | - | CODE-BACKED | Human-readable terminal identifier (e.g., 'PayPal Express Checkout', 'Wire Deposit', 'Western Union Deposit'). Not UNIQUE - multiple terminals can share similar names with currency variants. |
| 7 | ProcessedAmount | int | NO | - | CODE-BACKED | Cumulative amount processed through this terminal in smallest currency unit (cents/pence/etc.). Updated on each transaction. Used for quota monitoring and volume reporting. Not nullable. |
| 8 | LastTransactionDate | datetime | NO | - | CODE-BACKED | Timestamp of the most recent transaction processed through this terminal. Updated on each new transaction. Used for activity monitoring and idle terminal detection. |
| 9 | IsDefault | bit | NO | - | CODE-BACKED | Whether this is the preferred/default terminal for its (Protocol, PaymentType, Currency, FundingType) combination: 1=default (22 terminals); 0=alternate or legacy. The routing engine prefers default terminals when selecting among multiple valid options. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProtocolID | Dictionary.Protocol | FK (FK_DPRT_BTER) | Payment gateway protocol |
| PaymentTypeID | Dictionary.PaymentType | FK (FK_DPMT_BTER) | Deposit/Cashout/Refund direction |
| CurrencyID | Dictionary.Currency | FK (FK_DCUR_BTER) | Processing currency |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | TerminalID | FK (implicit) | Records which terminal processed the deposit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Terminal
  -> Dictionary.Protocol
  -> Dictionary.PaymentType (1=Deposit, 2=Cashout, 3=Refund)
  -> Dictionary.Currency
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Protocol | Table | FK on ProtocolID |
| Dictionary.PaymentType | Table | FK on PaymentTypeID |
| Dictionary.Currency | Table | FK on CurrencyID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | FK on TerminalID - records which terminal processed the transaction |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_BTER | NONCLUSTERED PK | TerminalID ASC | - | - | Active; FILLFACTOR=90; heap table |
| BTER_CURRENCY | NC | CurrencyID ASC | - | - | Active; FILLFACTOR=90 |
| BTER_FUNDINGTYPE | NC | FundingTypeID ASC | - | - | Active; FILLFACTOR=90 |
| BTER_PAYMENTTYPE | NC | PaymentTypeID ASC | - | - | Active; FILLFACTOR=90 |
| BTER_PROTOCOL | NC | ProtocolID ASC | - | - | Active; FILLFACTOR=90 |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BTER | PRIMARY KEY NONCLUSTERED (TerminalID) | One row per terminal |
| FK_DCUR_BTER | FOREIGN KEY CurrencyID -> Dictionary.Currency | Currency must be valid |
| FK_DPMT_BTER | FOREIGN KEY PaymentTypeID -> Dictionary.PaymentType | Payment direction must be valid |
| FK_DPRT_BTER | FOREIGN KEY ProtocolID -> Dictionary.Protocol | Protocol must be valid |

---

## 8. Sample Queries

### 8.1 View default terminals by funding type and currency

```sql
SELECT
    t.TerminalID,
    t.TerminalName,
    t.FundingTypeID,
    c.Name AS Currency,
    p.Name AS Protocol,
    t.ProcessedAmount,
    t.LastTransactionDate
FROM Billing.Terminal t WITH (NOLOCK)
JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = t.CurrencyID
JOIN Dictionary.Protocol p WITH (NOLOCK) ON p.ProtocolID = t.ProtocolID
WHERE t.IsDefault = 1
ORDER BY t.FundingTypeID, t.CurrencyID
```

### 8.2 Terminals with highest processed volumes

```sql
SELECT
    t.TerminalName,
    t.FundingTypeID,
    t.CurrencyID,
    t.ProcessedAmount,
    t.LastTransactionDate
FROM Billing.Terminal t WITH (NOLOCK)
WHERE t.ProcessedAmount > 0
ORDER BY t.ProcessedAmount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Terminal | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Terminal.sql*
