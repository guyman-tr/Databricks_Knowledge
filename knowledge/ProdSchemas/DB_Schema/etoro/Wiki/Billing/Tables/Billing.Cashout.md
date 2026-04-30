# Billing.Cashout

> Legacy cashout request table from eToro's early payment system (2007-~2011); records customer withdrawal requests with status lifecycle and exchange rate tracking. Superseded by `Billing.Withdraw` for all modern withdrawal flows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | CashoutID (PRIMARY KEY NONCLUSTERED, IDENTITY) |
| **Row Count** | ~5,931 rows |
| **Partition** | N/A - filegroup MAIN |
| **Indexes** | 1 - PK NONCLUSTERED on CashoutID; 5 NC indexes (CashoutStatusID, CurrencyID, CID, FundingTypeID, ProcessCurrencyID) |

---

## 1. Business Meaning

`Billing.Cashout` is the original withdrawal request table from eToro's early payment platform, active from approximately 2007 to 2011. It recorded customer cash-out requests - requests to withdraw funds from their eToro trading account to an external payment method.

The table is functionally superseded by `Billing.Withdraw` (which holds 1.66M records vs. Cashout's 5,931) and no longer receives new records in normal operation. It is retained for historical audit purposes and because a small number of stored procedures still reference it for legacy processing and reporting.

Key lifecycle: a customer submits a cashout request (`Billing.CashoutRequestAdd`), which creates the row with an initial `CashoutStatusID` and calls `Customer.SetBalance` to reserve the funds. When an operations manager processes the cashout (`Billing.CashoutProcess`), the status is updated to 3 (Processed), the final exchange rate and process currency are recorded, and `Customer.SetBalance` is called again with the actual amount.

---

## 2. Business Logic

### 2.1 Cashout Request Lifecycle

**What**: A cashout request moves through status transitions from initial request to processed or cancelled.

**Columns Involved**: `CashoutStatusID`, `CashoutID`, `Amount`, `CID`

**Observed Status Values** (from Dictionary.CashoutStatus):
| CashoutStatusID | Meaning | Count in table |
|----------------|---------|---------------|
| 1 | Pending (new request) | Rare |
| 2 | InProcess | Rare |
| 3 | Processed (completed) | ~1 of top 5 |
| 4 | Cancelled | Majority (~71%) |

**Process flow**:
```
CashoutRequestAdd(@CashoutStatusID, @Amount...)
  -> INSERT Billing.Cashout (initial status)
  -> INSERT History.Cashout (status change log)
  -> INSERT History.CashoutAction (action=1 New)
  -> Customer.SetBalance(@Amount negated, UpdateType=9 cashout_request)

CashoutProcess(@CashoutID, @ProcessCurrencyID, @ExchangeRate...)
  -> UPDATE Billing.Cashout SET CashoutStatusID=3, ProcessCurrencyID, FundingTypeID, ExchangeRate
  -> INSERT History.Cashout (status 3)
  -> INSERT History.CashoutAction (action=2 Processed)
  -> Customer.SetBalance(@Amount, UpdateType=2 Cashout)
```

### 2.2 Currency Conversion

**What**: The cashout may be requested in one currency but processed (paid out) in another, with the exchange rate captured at processing time.

**Columns Involved**: `CurrencyID`, `ProcessCurrencyID`, `ExchangeRate`

**Rules**:
- `CurrencyID`: the customer's account currency (the currency from which funds are debited)
- `ProcessCurrencyID` (nullable): the currency in which the payment was actually issued (may differ if the payment provider uses a different currency)
- `ExchangeRate` (dtPrice type): the exchange rate applied at processing time; NULL if no conversion needed

### 2.3 Fraud/Attention Flag

- `Attention` (bit, nullable): a manual flag that operations staff can set to mark a cashout for closer review or exception handling. Not used in automated flows.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Total rows | ~5,931 |
| CashoutID range | 76 to 6,029 (gaps from deletions) |
| Date range | 2007-08-27 to ~2011 (legacy period) |
| Primary FundingTypeID | 4 (Neteller) in oldest records |
| Dominant status | 4 (Cancelled) - ~71% of records |
| Processed records | ~26% (status=3) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CashoutID | int | NO | IDENTITY(1,1) | CODE-BACKED | Internal primary key. Auto-generated. Referenced by `History.Cashout`, `History.CashoutAction`, `Billing.CreditCardToCashout`, `Billing.NetellerToCashout`. NOT FOR REPLICATION. |
| 2 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method used for this cashout (e.g., 1=CreditCard, 4=Neteller). References `Dictionary.FundingType` implicitly (no FK constraint). May be updated during processing if the manager assigns a different method. |
| 3 | CashoutStatusID | int | NO | - | CODE-BACKED | Current status of the cashout request. FK to `Dictionary.CashoutStatus`: observed values 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled. `CashoutProcess` sets this to 3; `CashoutReverse` handles rollbacks. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Customer's account currency - the currency from which funds are debited. FK to `Dictionary.Currency`. |
| 5 | CID | int | NO | - | CODE-BACKED | Customer ID. FK to `Customer.CustomerStatic`. The customer who submitted the cashout request. Indexed (BCSH_CUSTOMER) for customer-level queries. |
| 6 | ProcessCurrencyID | int | YES | NULL | CODE-BACKED | Currency in which the payment was actually issued to the customer. NULL until `CashoutProcess` sets it. May differ from `CurrencyID` when the payment provider requires a different currency. FK to `Dictionary.Currency`. |
| 7 | RequestDate | datetime | NO | - | CODE-BACKED | Timestamp when the customer submitted the cashout request. Oldest record: 2007-08-27. |
| 8 | Amount | int | NO | - | CODE-BACKED | Cashout amount in the smallest currency unit (cents/pips). Stored as integer. Passed to `Customer.SetBalance` negated at request time (reservation) and again at processing time (settlement). |
| 9 | ExchangeRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Exchange rate applied when converting between `CurrencyID` and `ProcessCurrencyID`. Uses the `dbo.dtPrice` user-defined type (decimal for price precision). NULL if no currency conversion was needed. Set by `CashoutProcess`. |
| 10 | IPAddress | numeric(18, 0) | YES | NULL | CODE-BACKED | Customer's IP address at the time of request, stored as a numeric integer (IPv4 converted to decimal). Used for fraud detection and audit trail. |
| 11 | Attention | bit | YES | NULL | CODE-BACKED | Manual flag set by operations staff to mark a cashout for special review (e.g., suspicious activity, exception processing). Not used in automated flows. |
| 12 | Remark | varchar(500) | YES | NULL | CODE-BACKED | Free-text note added by the processing manager or system. Stored in `History.Cashout` at each status transition for audit purposes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_CCST_BSCH) | Customer who submitted the cashout |
| CashoutStatusID | Dictionary.CashoutStatus | FK (FK_DCSS_BCSH) | Current cashout status |
| CurrencyID | Dictionary.Currency | FK (FK_DCUR_BCSH) | Account currency |
| ProcessCurrencyID | Dictionary.Currency | FK (FK_DCUR_BCSP) | Processing currency (nullable) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Cashout | CashoutID | FK (implicit) | Status change audit log |
| History.CashoutAction | CashoutID | FK (implicit) | Action-level audit log (New/Processed) |
| Billing.CreditCardToCashout | CashoutID | FK (implicit) | Links credit card account to this cashout |
| Billing.NetellerToCashout | CashoutID | FK (implicit) | Links Neteller account to this cashout |
| Billing.CashoutProcess | CashoutID | Read/Write | Processes cashout - sets status=3, records exchange rate |
| Billing.CashoutRequestAdd | CashoutID (OUTPUT) | Write | Creates new cashout request |
| Billing.CashoutReverse | CashoutID | Read/Write | Reverses a processed cashout |
| Billing.GetCashoutsHistory | CashoutID | Read | Reporting - cashout history |
| Billing.GetPendingCashouts | CashoutID | Read | Reporting - pending cashouts for operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Cashout
  -> Dictionary.CashoutStatus (status catalog)
  -> Dictionary.Currency (x2: account and process currency)
  -> Customer.CustomerStatic (customer FK)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CashoutStatus | Table | FK on CashoutStatusID |
| Dictionary.Currency | Table | FK on CurrencyID and ProcessCurrencyID |
| Customer.CustomerStatic | Table | FK on CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Cashout | Table | Status change log keyed by CashoutID |
| History.CashoutAction | Table | Action log keyed by CashoutID |
| Billing.CreditCardToCashout | Table | Links credit card to cashout |
| Billing.NetellerToCashout | Table | Links Neteller account to cashout |
| Billing.CashoutProcess | Stored Procedure | Processes cashout to completion |
| Billing.CashoutRequestAdd | Stored Procedure | Creates new cashout request |
| Billing.CashoutReverse | Stored Procedure | Reverses processed cashout |
| Billing.GetPendingCashouts | Stored Procedure | Retrieves pending cashouts for processing |
| Billing.GetCashoutsHistory | Stored Procedure | Historical cashout reporting |
| Billing.CalculateCashoutRollbackPIPsUSD | Function | Calculates PnL impact of cashout rollback |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Notes |
|-----------|------|-------------|-----------------|--------|-------|
| PK_BCSH | NONCLUSTERED PK | CashoutID ASC | - | - | Active; FILLFACTOR=90; heap table |
| BCSH_CASHOUTSTATUS | NC | CashoutStatusID ASC | - | - | Active; FILLFACTOR=90 |
| BCSH_CURRENCY | NC | CurrencyID ASC | - | - | Active; FILLFACTOR=90 |
| BCSH_CUSTOMER | NC | CID ASC | - | - | Active; FILLFACTOR=90 |
| BCSH_FUNDINGTYPE | NC | FundingTypeID ASC | - | - | Active; FILLFACTOR=90 |
| BCSH_PROCESSCURRENCY | NC | ProcessCurrencyID ASC | - | - | Active; FILLFACTOR=90 |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BCSH | PRIMARY KEY NONCLUSTERED (CashoutID) | One row per cashout |
| FK_CCST_BSCH | FOREIGN KEY CID -> Customer.CustomerStatic | CID must exist |
| FK_DCSS_BCSH | FOREIGN KEY CashoutStatusID -> Dictionary.CashoutStatus | Status must be valid |
| FK_DCUR_BCSH | FOREIGN KEY CurrencyID -> Dictionary.Currency | Currency must be valid |
| FK_DCUR_BCSP | FOREIGN KEY ProcessCurrencyID -> Dictionary.Currency | Process currency must be valid if set |

---

## 8. Sample Queries

### 8.1 View cashout status distribution

```sql
SELECT cs.Name AS StatusName, COUNT(*) AS Count
FROM Billing.Cashout c WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK) ON cs.CashoutStatusID = c.CashoutStatusID
GROUP BY cs.Name
ORDER BY Count DESC
```

### 8.2 View pending cashouts for processing

```sql
SELECT
    c.CashoutID,
    c.CID,
    c.FundingTypeID,
    c.Amount,
    c.CurrencyID,
    c.RequestDate,
    c.Attention
FROM Billing.Cashout c WITH (NOLOCK)
WHERE c.CashoutStatusID = 1  -- Pending
ORDER BY c.RequestDate
```

### 8.3 View cashout with payment method details

```sql
SELECT TOP 20
    c.CashoutID,
    c.CID,
    c.Amount,
    c.CurrencyID,
    c.RequestDate,
    c.CashoutStatusID,
    c.FundingTypeID,
    c.ExchangeRate
FROM Billing.Cashout c WITH (NOLOCK)
ORDER BY c.CashoutID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Cashout | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Cashout.sql*
