# Dictionary.CorporateAction

> Lookup table defining all types of corporate actions that affect stock and instrument positions — dividends, splits, mergers, promotions, and platform-specific events. Links to compensation accounting and order-cancel rules.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CorporateActionTypeID (int, PK CLUSTERED, IDENTITY) |
| **Partition** | DICTIONARY filegroup, FILLFACTOR 95 |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.CorporateAction catalogs every type of corporate action the platform supports. Corporate actions are events that affect positions — dividends, stock splits, reverse splits, mergers, spinoffs, cash-in-lieu, rights offerings, ADR fees, staking, and promotional credits. Each action type links to a CompensationReasonID (from Dictionary.CreditType) that determines how the financial compensation is recorded in the client's account.

The table supports both traditional market corporate actions (e.g., Dividend, Stock Split, Merger) and platform-specific promotional events (Staking, Promotion, Promo - CustomerService, Promo - Leads, Promo - Automation, Promo - Churn, Promo - FirstAction, Promo - Crypto Holders, Promo - Club). The CancelOrders flag indicates whether pending orders should be cancelled when the corporate action occurs — for example, stock splits may require order cancellation and rebooking.

Data flows when Trade.CorporateInstrumentActions records a specific corporate action event per instrument. Trade.GetCorporateInstrumentActions, Trade.GetCorporateActionType, Trade.PayCashDividendByPayDate, Trade.PayCashAirdropByPayDateAndTerminalID, Trade.ExecuteCashPayment, and Trade.PositionAirdrop use this table to determine the correct handling. Trade.CashingOperationMonitor and Trade.TerminalIDToCorporateAction support monitoring and mapping.

---

## 2. Business Logic

### 2.1 Compensation Reason Mapping

**What**: Each corporate action type maps to a CompensationReasonID that determines how credits/debits are posted to client accounts.

**Columns/Parameters Involved**: `CorporateActionTypeID`, `CompensationReasonID`, `Description`

**Rules**:
- **CompensationReasonID**: FK to Dictionary.CreditType (compensation reason). Defines the accounting treatment — e.g., Dividend (45), Cash in Lieu (60), Cash Dividend (61), Reverse split (68), Spinoff (75), Stock Dividend (76), Stock Split (77), ADR fee (83), Merger (89), Staking (91), Promotion (92).
- **Description**: Human-readable label for the action type. Used in reporting and UI.

**Diagram**:
```
Corporate Action Flow:

  Corporate Event (e.g., dividend, split) ──► Trade.CorporateInstrumentActions
                                                    (CorporateActionTypeID)
                                                    │
                                                    ▼
  Dictionary.CorporateAction ──► CompensationReasonID ──► CreditType (accounting)
  Dictionary.CorporateAction ──► CancelOrders ──► Order cancellation if needed
```

### 2.2 Order Cancellation

**What**: CancelOrders = 1 indicates that pending orders should be cancelled when this corporate action is processed.

**Columns/Parameters Involved**: `CancelOrders`

**Rules**:
- **CancelOrders = 0 or NULL**: Orders typically remain; action may not affect them.
- **CancelOrders = 1**: Pending orders for affected instruments should be cancelled (e.g., stock split changes price/shares; orders may be invalid).

### 2.3 Action Type Categories

**What**: Representative categories — dividends (1, 3, 8, 20, 28), splits/reorg (10, 21, 22, 23), mergers/spinoffs (19, 33), fees (9, 27), promotions (36–43), and traditional corporate actions (2, 4, 5, 6, 7, 11–17, 24–26, 29–35).

---

## 3. Data Overview

| CorporateActionTypeID | Description | CompensationReasonID | CancelOrders | Meaning |
|---|---|---|---|---|
| 1 | Dividend | 45 | NULL | Standard dividend payment; maps to credit type 45. |
| 2 | Cash in Lieu | 60 | NULL | Cash payment instead of fractional shares. |
| 3 | Cash Dividend | 61 | NULL | Cash dividend; distinct from stock dividend. |
| 10 | Reverse split | 68 | NULL | Reverse stock split; share consolidation. |
| 19 | Spinoff | 75 | NULL | Corporate spinoff; new entity distribution. |
| 20 | Stock Dividend | 76 | NULL | Dividend paid in additional shares. |
| 21 | Stock Split | 77 | NULL | Forward split; share multiplier. |
| 33 | Merger | 89 | NULL | Merger/acquisition corporate action. |
| 35 | Staking | 91 | NULL | Crypto staking rewards; platform-specific. |
| 36 | Promotion | 92 | NULL | General promotional credit. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CorporateActionTypeID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Primary key. Auto-generated. Referenced by Trade.CorporateInstrumentActions via FK. Used by GetCorporateActionType, GetCorporateInstrumentActions, PayCashDividendByPayDate, ExecuteCashPayment, PositionAirdrop. |
| 2 | Description | varchar(100) | YES | - | CODE-BACKED | Human-readable description. Values: Dividend, Cash in Lieu, Stock Split, Merger, Staking, Promotion, etc. (41 types). NULL allowed. |
| 3 | CompensationReasonID | int | NO | - | CODE-BACKED | FK to Dictionary.CreditType. Determines how compensation is recorded. NOT NULL. |
| 4 | CancelOrders | bit | YES | 0 | CODE-BACKED | Whether to cancel pending orders when this action is processed. 1 = cancel; 0/NULL = typically no cancellation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Target Object | Target Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Dictionary.CreditType | CompensationReasonID | FK | Compensation reason for accounting treatment |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CorporateInstrumentActions | CorporateActionTypeID | FK | Each corporate action event references type |
| Trade.GetCorporateInstrumentActions | - | JOIN/SELECT | Proc reads corporate actions |
| Trade.GetCorporateActionType | - | SELECT | Proc returns action type |
| Trade.PayCashDividendByPayDate | - | Implicit | Cash dividend payments |
| Trade.PayCashAirdropByPayDateAndTerminalID | - | Implicit | Airdrop payments |
| Trade.ExecuteCashPayment | - | Implicit | Generic cash payment proc |
| Trade.CashingOperationMonitor | Table | Implicit | Monitoring table |
| Trade.TerminalIDToCorporateAction | Table | Implicit | Mapping table |
| Trade.PositionAirdrop | - | Implicit | Airdrop proc |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CorporateAction (table)
    └── Dictionary.CreditType (CompensationReasonID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CreditType | Table | FK — CompensationReasonID references CreditType for compensation accounting |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CorporateInstrumentActions | Table | FK — each event has CorporateActionTypeID |
| Trade.GetCorporateInstrumentActions | Stored Procedure | Reads corporate actions |
| Trade.GetCorporateActionType | Stored Procedure | Returns action type |
| Trade.PayCashDividendByPayDate | Stored Procedure | Cash dividend processing |
| Trade.ExecuteCashPayment | Stored Procedure | Cash payment processing |
| Trade.PositionAirdrop | Stored Procedure | Airdrop processing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_CorporateAction | CLUSTERED PK | CorporateActionTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_CorporateAction | PRIMARY KEY | Unique action type identifier. FILLFACTOR 95, DICTIONARY filegroup. |
| FK (CompensationReasonID) | FOREIGN KEY | References Dictionary.CreditType |

---

## 8. Sample Queries

### 8.1 List all corporate action types with compensation reason
```sql
SELECT  ca.CorporateActionTypeID,
        ca.Description,
        ca.CompensationReasonID,
        ca.CancelOrders
FROM    Dictionary.CorporateAction ca WITH (NOLOCK)
ORDER BY ca.CorporateActionTypeID;
```

### 8.2 Find corporate actions for a specific instrument
```sql
SELECT  cia.InstrumentID,
        ca.Description                 AS CorporateActionType,
        cia.PayDate,
        cia.Amount
FROM    Trade.CorporateInstrumentActions cia WITH (NOLOCK)
JOIN    Dictionary.CorporateAction ca WITH (NOLOCK)
        ON cia.CorporateActionTypeID = ca.CorporateActionTypeID
WHERE   cia.InstrumentID = @InstrumentID
ORDER BY cia.PayDate DESC;
```

### 8.3 List promotional corporate action types (platform-specific)
```sql
SELECT  CorporateActionTypeID,
        Description,
        CompensationReasonID
FROM    Dictionary.CorporateAction WITH (NOLOCK)
WHERE   Description LIKE 'Promo%'
   OR   Description = 'Staking'
   OR   Description = 'Promotion'
ORDER BY CorporateActionTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: DDL + MCP live data + Trade.CorporateInstrumentActions, GetCorporateActionType, PayCashDividendByPayDate, ExecuteCashPayment, CreditType FK | Corrections: 0 applied*
*Object: Dictionary.CorporateAction | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CorporateAction.sql*
