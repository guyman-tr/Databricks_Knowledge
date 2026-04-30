# BackOffice.JUNK_CashierHistory

> **DEPRECATED (JUNK prefix)** - Legacy cashier history view joining credit transactions with position details, manager attribution, and championship data. Not referenced by any active BackOffice objects.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | CreditID - from History.Credit |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.JUNK_CashierHistory` is a legacy view (JUNK prefix indicates deprecated, not actively maintained) that joined `History.Credit` transaction records with associated position details, back-office manager attribution, cashout cross-references, and championship date ranges. It was designed to give cashier/finance staff a comprehensive view of all credit events with enriched context.

The view was likely used by the BackOffice cashier module to display a full history of financial events per customer - deposits, withdrawals, position PnL credits, bonuses, and fees - enriched with the position details linked to those events and identifying who (manager or customer) initiated each action.

No active BackOffice stored procedures or views currently reference this view. It exists as an artifact of legacy BackOffice functionality. The `Trade.GetPositionInfoFromAnyTable()` TVF dependency (which scans across open and closed position tables) makes this view expensive to query.

---

## 2. Business Logic

### 2.1 Credit Transaction Enrichment

**What**: Joins each credit transaction to its associated position (if any), the initiating manager, and related cashout/reverse-cashout events.

**Columns/Parameters Involved**: `CreditTypeID`, `BeforeAction`, `Payment`, `Credit`, `InitiatedBy`, `PositionID`

**Rules**:
- `BeforeAction = Credit - Payment`: reconstructs the account balance before the transaction occurred
- `InitiatedBy = ISNULL(Manager.FirstName + ' ' + Manager.LastName, 'Customer')`: if no ManagerID linked, the action was self-initiated by the customer
- RIGHT OUTER JOIN structure: all `History.Credit` rows are preserved; position/instrument data is NULL if no position is linked
- CashoutID cross-references: joins back to `History.Credit` twice - once for the original cashout (CreditTypeID=2) and once for a reverse cashout (CreditTypeID=8) linked by the same CashoutID

### 2.2 Championship Fee Context (TotalLotCount)

**What**: For Championship Winner (CreditTypeID=5) and Bonus (CreditTypeID=7) credit events, retrieves the customer's total lot count at the time of the event to provide commission/fee context.

**Columns/Parameters Involved**: `TotalLotCount`, `CreditTypeID`, `Occurred`

**Rules**:
- `CASE WHEN CreditTypeID IN (5, 7) THEN Trade.GetLotCountTillTime(CID, Occurred) ELSE NULL END`
- CreditTypeID 5 = "Champ Winner" (championship prize payment), 7 = "Bonus"
- `Trade.GetLotCountTillTime` returns the cumulative lot count for the customer up to the given timestamp
- NULL for all other credit types where lot count is not relevant

---

## 3. Data Overview

*View not sampled - legacy status (JUNK), expensive TVF dependency (Trade.GetPositionInfoFromAnyTable), and no active consumers. Data patterns inferred from DDL and Dictionary.CreditType values.*

| CreditID | CreditTypeID | CreditType | BeforeAction | Payment | Credit | InitiatedBy |
|----------|-------------|------------|-------------|---------|--------|-------------|
| (example) | 1 | Deposit | 0.00 | 1000.00 | 1000.00 | Customer |
| (example) | 4 | Close Position | 1000.00 | 150.00 | 1150.00 | Customer |
| (example) | 2 | Cashout | 1150.00 | -500.00 | 650.00 | Avi Sela |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer identifier. From `History.Credit.CID`. Primary grouping key for the customer's transaction history. |
| 2 | CreditID | INT | NO | - | CODE-BACKED | Unique identifier of the credit/debit transaction. PK of `History.Credit`. |
| 3 | CreditTypeID | INT | NO | - | VERIFIED | Transaction type code. FK to `Dictionary.CreditType`. Values: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse Cashout, 9=Cashout Request, 10=IB Synchronization, 11=Chargeback, 12=Refund, 13=Edit Stop Loss, 14=End Of Week Fee, 15=Cashout Fee, 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks, 18-21=Mirror operations, 22-25=Mirror hierarchy/recovery, 26=FixBonusCreditRealizedEquity, 27-28=Detach operations, 29-30=Stock Order, 31=Data Fix, 32=Reverse Deposit, 33=Cashout Rollback. |
| 4 | CreditType | NVARCHAR | NO | - | VERIFIED | Human-readable name of the credit type. Resolved from `Dictionary.CreditType.Name` on CreditTypeID. |
| 5 | BeforeAction | DECIMAL (computed) | YES | - | VERIFIED | Account credit balance immediately before this transaction. Computed as `Credit - Payment`. Reconstructs the pre-transaction state from the post-transaction balance and the transaction amount. |
| 6 | Payment | DECIMAL | YES | - | CODE-BACKED | Transaction amount (positive = credit to account, negative = debit). From `History.Credit.Payment`. |
| 7 | Credit | DECIMAL | YES | - | CODE-BACKED | Account credit balance after this transaction. From `History.Credit.Credit`. |
| 8 | InitiatedBy | NVARCHAR (computed) | NO | - | VERIFIED | Name of the entity that initiated the transaction. Computed as `ISNULL(Manager.FirstName + ' ' + Manager.LastName, 'Customer')`. If no ManagerID is linked to the credit record, returns 'Customer' (the customer self-initiated, e.g., deposited or submitted a cashout request). |
| 9 | Description | NVARCHAR | YES | - | CODE-BACKED | Free-text description of the credit transaction. From `History.Credit.Description`. May contain payment provider references, notes from operations staff, or system-generated text. |
| 10 | Occurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the credit transaction was recorded. From `History.Credit.Occurred`. |
| 11 | PositionID | INT | YES | - | CODE-BACKED | Position associated with this credit event (e.g., for Open/Close Position credit types). From `History.Credit.PositionID`. NULL for non-position credit types (deposits, cashouts, bonuses). |
| 12 | IsOpened | VARCHAR(6) (computed) | YES | - | CODE-BACKED | Whether the linked position was opened or closed at the time of this credit event. `CASE WHEN IsOpened=1 THEN 'Opened' WHEN IsOpened=0 THEN 'Closed' END`. From `Trade.GetPositionInfoFromAnyTable().IsOpened`. NULL if no position is linked. |
| 13 | CloseAction | INT | YES | - | CODE-BACKED | How the position was closed (if applicable). From `Trade.GetPositionInfoFromAnyTable().CloseAction`. NULL if position is still open or no position is linked. |
| 14 | InstrumentName | NVARCHAR | YES | - | CODE-BACKED | Name of the traded instrument for position-linked events. From `Trade.GetInstrument.Name` joined on InstrumentID. NULL if no position is linked to this credit event. |
| 15 | IsBuy | BIT | YES | - | CODE-BACKED | Direction of the linked position: 1=Buy/Long, 0=Sell/Short. From `Trade.GetPositionInfoFromAnyTable().IsBuy`. NULL if no position is linked. |
| 16 | InitForexRate | DECIMAL | YES | - | CODE-BACKED | Entry (opening) price of the linked position. From `Trade.GetPositionInfoFromAnyTable().InitForexRate`. NULL if no position is linked. |
| 17 | EndForexRate | DECIMAL | YES | - | CODE-BACKED | Exit (closing) price of the linked position. From `Trade.GetPositionInfoFromAnyTable().EndForexRate`. NULL if position is still open or no position linked. |
| 18 | NetProfit | DECIMAL | YES | - | CODE-BACKED | Net profit/loss of the linked position. From `Trade.GetPositionInfoFromAnyTable().NetProfit`. NULL if no position is linked. |
| 19 | InitServerTime | DATETIME | YES | - | CODE-BACKED | Timestamp when the linked position was opened. From `Trade.GetPositionInfoFromAnyTable().InitServerTime`. NULL if no position is linked. |
| 20 | CloseServerTime | DATETIME | YES | - | CODE-BACKED | Timestamp when the linked position was closed. From `Trade.GetPositionInfoFromAnyTable().CloseServerTime`. NULL if position is open or no position linked. |
| 21 | TotalLotCount | DECIMAL | YES | NULL | CODE-BACKED | Total lot count for the customer at the time of this credit event. Only populated for Championship Winner (CreditTypeID=5) and Bonus (CreditTypeID=7) events. Computed by `Trade.GetLotCountTillTime(CID, Occurred)`. NULL for all other credit types. |
| 22 | CashoutID | INT | YES | - | CODE-BACKED | Reference to the cashout request linked to this credit event. From `History.Credit.CashoutID`. Used to cross-reference related cashout and reverse-cashout entries. |
| 23 | PaymentID | INT | YES | - | CODE-BACKED | Reference to the payment processor transaction linked to this credit event. From `History.Credit.PaymentID`. |
| 24 | UpdateID | INT | YES | - | CODE-BACKED | Identifier for the update/audit record linked to this credit event. From `History.Credit.UpdateID`. |
| 25 | CashoutOccurred | DATETIME | YES | - | CODE-BACKED | Timestamp of the original cashout transaction linked by CashoutID. From `History.Credit` where CreditTypeID=2 and CashoutID matches. NULL if no cashout is linked. |
| 26 | CashoutDescription | NVARCHAR | YES | - | CODE-BACKED | Description of the original cashout transaction. From `History.Credit` where CreditTypeID=2 and CashoutID matches. NULL if no cashout is linked. |
| 27 | ReverseCashoutOccurred | DATETIME | YES | - | CODE-BACKED | Timestamp of the reverse cashout transaction linked by CashoutID. From `History.Credit` where CreditTypeID=8 and CashoutID matches. NULL if no reverse cashout exists. |
| 28 | ReverseCashoutDescription | NVARCHAR | YES | - | CODE-BACKED | Description of the reverse cashout transaction. From `History.Credit` where CreditTypeID=8 and CashoutID matches. NULL if no reverse cashout exists. |
| 29 | ChampionshipStartDateTime | DATETIME | YES | - | CODE-BACKED | Start date of the championship linked to this credit event. From `History.Championship` joined on ChampionshipID. NULL if no championship is associated with this credit. |
| 30 | ChampionshipEndDateTime | DATETIME | YES | - | CODE-BACKED | End date of the championship linked to this credit event. From `History.Championship` joined on ChampionshipID. NULL if no championship is associated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditID, CreditTypeID, CID, Payment, Credit, PositionID, CashoutID, PaymentID, UpdateID, Description, Occurred | History.Credit | Source (cross-schema, NOLOCK) | Primary data source - all credit/debit transaction records. Referenced three times (main, cashout cross-ref, reverse-cashout cross-ref). |
| PositionID, IsOpened, CloseAction, IsBuy, InitForexRate, EndForexRate, NetProfit, InitServerTime, CloseServerTime | Trade.GetPositionInfoFromAnyTable() | Source TVF (cross-schema) | Table-valued function returning position details from both open and closed position tables. RIGHT OUTER JOINed so all Credit rows are preserved. |
| InstrumentName | Trade.GetInstrument | Lookup (cross-schema) | Resolves InstrumentID to instrument name. RIGHT OUTER JOINed. |
| InitiatedBy | BackOffice.Manager | Lookup (LEFT OUTER JOIN) | Resolves ManagerID to full name. NULL when customer self-initiated. |
| CreditTypeID -> CreditType | Dictionary.CreditType | Lookup (implicit INNER JOIN) | Resolves credit type code to human-readable name. |
| ChampionshipStartDateTime, ChampionshipEndDateTime | History.Championship | Lookup (cross-schema, LEFT OUTER, NOLOCK) | Provides championship date range for credit events tied to championships. |
| TotalLotCount | Trade.GetLotCountTillTime | Function call (cross-schema) | Returns cumulative lot count at a given timestamp. Called only for CreditTypeID IN (5,7). |

### 5.2 Referenced By (other objects point to this)

No active dependents found. Legacy view with JUNK prefix.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_CashierHistory (view) [DEPRECATED]
├── History.Credit (cross-schema table) [x3: main, cashout ref, reverse-cashout ref]
├── Trade.GetPositionInfoFromAnyTable() (cross-schema TVF)
├── Trade.GetInstrument (cross-schema view)
├── BackOffice.Manager (table)
├── History.Championship (cross-schema table)
├── Dictionary.CreditType (table)
└── Trade.GetLotCountTillTime (cross-schema function) [conditional]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Cross-schema Table | FROM clause (NOLOCK) - primary source; also joined twice for cashout/reverse-cashout cross-references |
| Trade.GetPositionInfoFromAnyTable() | Cross-schema TVF | RIGHT OUTER JOIN - position details for credit-linked positions |
| Trade.GetInstrument | Cross-schema View | RIGHT OUTER JOIN - instrument name resolution |
| BackOffice.Manager | Table | LEFT OUTER JOIN - manager name for InitiatedBy |
| History.Championship | Cross-schema Table | LEFT OUTER JOIN (NOLOCK) - championship date range |
| Dictionary.CreditType | Table | Implicit INNER JOIN - credit type name resolution |
| Trade.GetLotCountTillTime | Cross-schema Function | Conditional call in SELECT - lot count for Champ Winner/Bonus events |

### 6.2 Objects That Depend On This

No active dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: Complex mix of RIGHT OUTER, LEFT OUTER, and implicit INNER JOINs. The RIGHT OUTER JOIN chain (Instrument -> PositionInfo -> Credit) ensures all Credit rows appear. The implicit INNER JOIN to Dictionary.CreditType means Credit rows with an unrecognized CreditTypeID are excluded.

---

## 8. Sample Queries

### 8.1 Get cashier history for a specific customer (deposits and cashouts)

```sql
SELECT CreditID, CreditType, BeforeAction, Payment, Credit, InitiatedBy, Occurred
FROM BackOffice.JUNK_CashierHistory WITH (NOLOCK)
WHERE CID = 123456
  AND CreditTypeID IN (1, 2, 8)
ORDER BY Occurred DESC
```

### 8.2 Find all championship prize payments with lot count context

```sql
SELECT CID, CreditID, Payment, TotalLotCount, Occurred, ChampionshipStartDateTime, ChampionshipEndDateTime
FROM BackOffice.JUNK_CashierHistory WITH (NOLOCK)
WHERE CreditTypeID = 5
ORDER BY Occurred DESC
```

### 8.3 Find credit events that had a reverse cashout

```sql
SELECT CID, CreditID, CreditType, Payment, Occurred,
       CashoutOccurred, ReverseCashoutOccurred, ReverseCashoutDescription
FROM BackOffice.JUNK_CashierHistory WITH (NOLOCK)
WHERE ReverseCashoutOccurred IS NOT NULL
ORDER BY ReverseCashoutOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7 (Phase 2 skipped - JUNK/legacy)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_CashierHistory | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.JUNK_CashierHistory.sql*
