# Billing.TerminalEdit

> Creates a new payment terminal record or updates an existing one in Billing.Terminal, using @TerminalID=0 as the sentinel to distinguish insert from update.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TerminalID - 0 means INSERT, non-zero means UPDATE |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.TerminalEdit` is the upsert procedure for payment terminal configuration. It manages rows in `Billing.Terminal`, which defines the (Protocol + PaymentType + Currency + FundingType) routing matrix for payment processing. When a new currency variant or protocol combination needs to be added to the terminal matrix, this procedure creates it; when an existing terminal's routing attributes or volume counters need updating, it modifies it.

This procedure exists because `Billing.Terminal` is a small configuration table (48 rows) managed by billing operations and back-office tooling. Direct SQL edits are avoided in favor of this procedure to ensure consistent validation and an auditable code path.

The procedure implements a sentinel-based upsert: `@TerminalID = 0` means "create new terminal" (INSERT), any non-zero value means "update terminal with this ID" (UPDATE). Additionally, it validates that all key parameters are set (not at their sentinel/empty values) before performing any DML, silently doing nothing if validation fails.

---

## 2. Business Logic

### 2.1 Sentinel-Based Upsert Pattern

**What**: A single procedure handles both creation and modification of terminals, using @TerminalID=0 as the "no-ID-yet" sentinel to differentiate the two operations.

**Columns/Parameters Involved**: `@TerminalID`, all other parameters

**Rules**:
- `@TerminalID = 0`: INSERT path - a new row is created in Billing.Terminal and assigned the next IDENTITY value
- `@TerminalID != 0`: UPDATE path - the existing row with matching TerminalID is updated
- The returned `@@ROWCOUNT` tells the caller whether any row was affected

**Diagram**:
```
EXEC Billing.TerminalEdit @TerminalID=0, ...
  -> All validation checks pass?
       YES -> INSERT INTO Billing.Terminal -> new TerminalID assigned
       NO  -> silent no-op, RETURN 0

EXEC Billing.TerminalEdit @TerminalID=7, ...
  -> All validation checks pass?
       YES -> UPDATE Billing.Terminal WHERE TerminalID=7
       NO  -> silent no-op, RETURN 0
```

### 2.2 Input Validation via Sentinel Values

**What**: All parameters use sentinel values (-1 for integers, '' for strings, NULL for dates) to signal "not provided". The procedure silently does nothing if any sentinel is detected.

**Columns/Parameters Involved**: `@ProtocolID`, `@PaymentTypeID`, `@TerminalName`, `@FundingTypeID`, `@ProcessedAmount`, `@LastTransactionDate`

**Rules**:
- `@ProtocolID = -1`: skip execution (protocol not specified)
- `@TerminalName = ''`: skip execution (name not provided)
- `@PaymentTypeID = -1`: skip execution (payment type not specified)
- `@FundingTypeID = -1`: skip execution (funding type not specified)
- `@ProcessedAmount = -1`: skip execution (amount not specified)
- `@LastTransactionDate IS NULL`: skip execution (transaction date not provided)
- `@CurrencyID` has no sentinel check - it is always applied as-is (including 0 = currency-agnostic)
- If validation fails, the procedure returns 0 without any error; the caller does not receive an error message

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TerminalID | INTEGER | NO | - | CODE-BACKED | Terminal ID to update, or 0 to create a new terminal. Maps to `Billing.Terminal.TerminalID`. When 0, INSERT path is taken; any non-zero value triggers UPDATE on the matching row. |
| 2 | @ProtocolID | INTEGER | NO | - | CODE-BACKED | Payment protocol identifier. Sentinel value -1 causes the procedure to abort. Maps to `Billing.Terminal.ProtocolID` -> references `Billing.Protocol` (e.g., PayPal, Credit Card, Wire Transfer). |
| 3 | @PaymentTypeID | INTEGER | NO | - | CODE-BACKED | Payment type (deposit=1 / withdrawal=2 direction). Sentinel value -1 causes abort. Maps to `Billing.Terminal.PaymentTypeID`. |
| 4 | @TerminalName | VARCHAR(50) | NO | - | CODE-BACKED | Human-readable name for the terminal configuration (e.g., "PayPal Express USD"). Empty string '' causes abort. Maps to `Billing.Terminal.TerminalName`. |
| 5 | @FundingTypeID | INTEGER | NO | - | CODE-BACKED | Funding method type identifier (credit card, bank wire, PayPal, etc.). Sentinel value -1 causes abort. Maps to `Billing.Terminal.FundingTypeID`. |
| 6 | @ProcessedAmount | INTEGER | NO | - | CODE-BACKED | Cumulative amount processed through this terminal, in smallest currency unit (cents/pence). Sentinel value -1 causes abort. Maps to `Billing.Terminal.ProcessedAmount`. Used in quota tracking. |
| 7 | @LastTransactionDate | DATETIME | NO | - | CODE-BACKED | Timestamp of the most recent transaction through this terminal. NULL causes abort. Maps to `Billing.Terminal.LastTransactionDate`. |
| 8 | @CurrencyID | INTEGER | NO | - | CODE-BACKED | Currency for this terminal: 0=currency-agnostic, 1=USD, 2=EUR, 3=GBP, others for other currencies. No sentinel check - always applied. Maps to `Billing.Terminal.CurrencyID`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TerminalID / all params | Billing.Terminal | Direct DML (INSERT/UPDATE) | Creates or modifies terminal configuration rows |
| @ProtocolID | Billing.Protocol | Lookup (implicit) | Protocol used by the terminal (PayPal, CC, etc.) |
| @FundingTypeID | Dictionary.FundingType | Lookup (cross-schema) | Funding method type for this terminal |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back-office tooling / BILLING_MANAGER role | - | EXEC | Called by billing operations to maintain the terminal routing matrix |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.TerminalEdit (procedure)
├── Billing.Terminal (table) - UPDATE path
└── Billing.Terminal (table) - INSERT path
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Terminal | Table | INSERT (new terminal) or UPDATE (existing terminal) depending on @TerminalID sentinel |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called externally by back-office application via BILLING_MANAGER role. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: The sentinel-based validation (-1, '', NULL checks) is the only input validation. No unique constraint is enforced at the procedure level - the caller must ensure they are not creating duplicate (Protocol + PaymentType + Currency + FundingType) combinations.

---

## 8. Sample Queries

### 8.1 Create a new currency variant terminal
```sql
-- Add a new EUR terminal for an existing protocol
EXEC Billing.TerminalEdit
  @TerminalID = 0,
  @ProtocolID = 3,
  @PaymentTypeID = 1,
  @TerminalName = 'PayPal Express EUR',
  @FundingTypeID = 2,
  @ProcessedAmount = 0,
  @LastTransactionDate = GETDATE(),
  @CurrencyID = 2;
```

### 8.2 Update processed amount and last transaction date for an existing terminal
```sql
-- Reset/update volume tracker for terminal 7
EXEC Billing.TerminalEdit
  @TerminalID = 7,
  @ProtocolID = 3,
  @PaymentTypeID = 1,
  @TerminalName = 'PayPal Express USD',
  @FundingTypeID = 2,
  @ProcessedAmount = 0,
  @LastTransactionDate = GETDATE(),
  @CurrencyID = 1;
```

### 8.3 Query current terminal matrix
```sql
SELECT t.TerminalID,
       t.TerminalName,
       t.ProtocolID,
       t.PaymentTypeID,
       t.CurrencyID,
       t.FundingTypeID,
       t.ProcessedAmount,
       t.LastTransactionDate
FROM Billing.Terminal t WITH (NOLOCK)
ORDER BY t.ProtocolID, t.FundingTypeID, t.CurrencyID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.TerminalEdit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.TerminalEdit.sql*
