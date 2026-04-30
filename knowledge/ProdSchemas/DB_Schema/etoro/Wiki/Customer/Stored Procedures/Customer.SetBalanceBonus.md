# Customer.SetBalanceBonus

> Awards a bonus credit to a customer account: updates CustomerMoney balances, logs to ActiveCredit history, sends payment notifications, and queues affiliate/piggybank tracking events.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @BonusInCents MONEY; no return value (raises on error via THROW) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When eToro awards a promotional or operational bonus to a customer, `SetBalanceBonus` is the entry point. It is called by the bonus management system (BackOffice) with the bonus amount in cents (the application-layer unit convention: all amounts sent to database procedures are in cents and divided by 100 for storage as dollars).

The procedure performs four actions in a single transaction: (1) updates all four balance fields in `Customer.CustomerMoney` by the bonus amount, (2) logs the event as a CreditTypeID=7 (Bonus) record in `History.ActiveCreditRecentMemoryBucket` via `SetBalanceInsertCredit_Native`, (3) sends a Service Broker message to the `svcPayment` queue (downstream payment processing notification), and (4) if the bonus is "real" (production flag on) and not hidden from affiliate tracking, calls `Broker.QueuePiggyBankAdd` and `Broker.QueueAffiliateTraderCreditAdd` to inform affiliate/tracking systems.

Key architectural note: `BSLRealFunds` is intentionally NOT updated on bonus events (FB:46791, 01/08/2017). Bonuses are promotional credits, not real-money deposits, so they should not raise the BSL threshold.

---

## 2. Business Logic

### 2.1 Cent-to-Dollar Conversion

**What**: The @BonusInCents parameter arrives in cents and must be converted to dollars before database storage.

**Columns/Parameters Involved**: `@BonusInCents`, `@BonusInDollars`

**Rules**:
- `@BonusInDollars = @BonusInCents / 100`
- ALL balance updates and credit log entries use @BonusInDollars.
- The application layer sends cents; the DB stores dollars.

### 2.2 Balance Update Logic

**What**: Four CustomerMoney fields are updated atomically.

**Columns/Parameters Involved**: `Credit`, `BonusCredit`, `RealizedEquity`, `TotalCash`

**Rules**:
- `Credit += @BonusInDollars` - available balance increases
- `BonusCredit = MAX(0, BonusCredit + @BonusInDollars)` - bonus credit floored at 0 (cannot go negative via IIF)
- `RealizedEquity += @BonusInDollars` - equity increases (bonus counts as realized)
- `TotalCash += @BonusInDollars`
- BSLRealFunds is NOT updated (FB:46791 - bonuses are not real funds)
- Uses OUTPUT clause to capture new values (NewCredit, TotalCash, RealizedEquity, BonusCredit, OldBonusCredit, BSLRealFunds) for the credit record.

```
Customer.CustomerMoney (CID = @CID):
  Credit          += @BonusInDollars
  BonusCredit     = MAX(0, BonusCredit + @BonusInDollars)
  RealizedEquity  += @BonusInDollars
  TotalCash       += @BonusInDollars
  BSLRealFunds    - UNCHANGED (bonus is not real money)
```

### 2.3 Service Broker Payment Notification

**What**: After the balance update, a Service Broker message is sent to trigger downstream payment processing.

**Columns/Parameters Involved**: `@DataAffected`, `svcPayment`

**Rules**:
- Message format (1st send, template for payment queue): `"{CID};7;{BonusTypeID};{BonusInDollars};{NewCredit};{GETUTCDATE()};{RealizedEquity};{CreditID};{BonusChange}"`
- Message format (2nd send, for notification): Similar format with `;bonus` suffix.
- CustomerMoney notification template ID=6 via Customer.SendMessage.
- If NewCredit <= 0: SendEvent 9 (zero balance alert event).

### 2.4 Affiliate and PiggyBank Tracking

**What**: Real bonus events (not test/hidden) are reported to affiliate tracking and piggybank systems.

**Columns/Parameters Involved**: `@IsReal`, `@BonusTypeID`, `HideFromAffwiz`

**Rules**:
- Only runs if `Maintenance.Feature.FeatureID = 22` has Value=1 (production environment flag).
- Skipped if `BackOffice.BonusType.HideFromAffwiz = 1` for the given BonusTypeID.
- Reads customer tracking data from Customer.CustomerStatic (@OriginalCID, @ProviderID, @SerialID, etc.).
- Calls `Broker.QueuePiggyBankAdd` with Type=2, IsFirstDeposit=0 (bonus, not deposit).
- Calls `Broker.QueueAffiliateTraderCreditAdd` with Type=2, CreditID=@Identity (for affiliate commission tracking).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the account receiving the bonus. |
| 2 | @BonusInCents | MONEY | NO | - | VERIFIED | Bonus amount in CENTS (application convention). Divided by 100 internally to get dollars. Example: 5000 = $50.00 bonus. |
| 3 | @BonusTypeID | INT | NO | - | CODE-BACKED | Category of bonus (BackOffice.BonusType lookup). Controls whether the bonus is hidden from affiliate tracking (HideFromAffwiz flag). |
| 4 | @Description | VARCHAR(200) | NO | - | CODE-BACKED | Human-readable description of the bonus event, stored in the credit history record. |
| 5 | @DepositID | INT | NO | - | CODE-BACKED | Deposit ID linked to this bonus event (if bonus is tied to a specific deposit). Passed to SetBalanceInsertCredit_Native as DepositID. |
| 6 | @ManagerID | INT | NO | - | CODE-BACKED | ID of the manager/admin who initiated the bonus award. Stored in the credit record for traceability. |
| 7 | @CampaignID | INT | NO | - | CODE-BACKED | Marketing campaign ID that triggered this bonus. Used to look up the CampaignCode (BackOffice.Campaign) for affiliate reporting. |
| 8 | @MoveMoneyReasonID | INT | NO | - | CODE-BACKED | Reason code for internal money movement classification. Added FB 33991 (03/02/2016). Passed to SetBalanceInsertCredit_Native. |
| 9 | @ErrOut | NVARCHAR(4000) | YES | '' (OUTPUT) | CODE-BACKED | OUTPUT parameter that receives detailed error message if the procedure fails. Format: "SP - Schema.ProcName | ERROR_NUMBER: ... ERROR_LINE: ... ERROR_MESSAGE: ...". |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | Updates Credit, BonusCredit, RealizedEquity, TotalCash |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs CreditTypeID=7 bonus credit record |
| @CID | Customer.SendMessage | Caller (EXEC) | Sends template-6 message notification |
| @CID | Customer.SendEvent | Caller (EXEC) | Sends event-9 (zero balance) if NewCredit <= 0 |
| @CID | Customer.CustomerStatic | READ | Gets tracking data for affiliate reporting |
| @BonusTypeID | BackOffice.BonusType | READ | Checks HideFromAffwiz flag |
| @CampaignID | BackOffice.Campaign | READ | Gets CampaignCode for affiliate tracking |
| - | Maintenance.Feature | READ | Checks FeatureID=22 (production flag) |
| - | Broker.QueuePiggyBankAdd | Caller (EXEC) | Queues piggybank event for tracking |
| - | Broker.QueueAffiliateTraderCreditAdd | Caller (EXEC) | Queues affiliate credit tracking event |
| - | svcPayment (Service Broker) | SEND | Notifies payment queue of bonus event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central balance router delegates CreditTypeID=7 to this procedure |
| BackOffice bonus management | External | Caller | Called when awarding bonuses to customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceBonus (procedure)
+-- Customer.CustomerMoney (table) [UPDATE Credit, BonusCredit, RealizedEquity, TotalCash]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit record CreditTypeID=7]
|     +-- History.ActiveCreditRecentMemoryBucket (table)
+-- Customer.SendMessage (procedure) [template-6 notification]
+-- Customer.SendEvent (procedure) [event-9 zero-balance alert, conditional]
+-- Customer.CustomerStatic (table) [READ tracking data for affiliate reporting]
+-- BackOffice.BonusType (table) [READ HideFromAffwiz flag]
+-- BackOffice.Campaign (table) [READ CampaignCode]
+-- Maintenance.Feature (table) [READ FeatureID=22 production flag]
+-- Broker.QueuePiggyBankAdd (procedure) [conditional affiliate tracking]
+-- Broker.QueueAffiliateTraderCreditAdd (procedure) [conditional affiliate tracking]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - adds bonus to Credit, BonusCredit, RealizedEquity, TotalCash |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts CreditTypeID=7 history record |
| Customer.SendMessage | Procedure | EXEC - sends customer notification (template 6) |
| Customer.SendEvent | Procedure | EXEC - sends zero-balance event if NewCredit <= 0 |
| Customer.CustomerStatic | Table | SELECT - reads affiliate tracking fields |
| BackOffice.BonusType | Table | SELECT - checks HideFromAffwiz |
| BackOffice.Campaign | Table | SELECT - gets CampaignCode by CampaignID |
| Maintenance.Feature | Table | SELECT - checks production flag (FeatureID=22) |
| Broker.QueuePiggyBankAdd | Procedure | EXEC - piggybank event queue |
| Broker.QueueAffiliateTraderCreditAdd | Procedure | EXEC - affiliate credit tracking queue |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for CreditTypeID=7 (Bonus) events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BonusCredit floor at 0 | Business rule | IIF(BonusCredit + bonus < 0, 0, BonusCredit + bonus) - bonus credit cannot go negative |
| BSLRealFunds not updated | Design decision | FB:46791 (01/08/2017) - bonuses are promotional credits, not real funds; should not raise BSL threshold |
| @BonusInCents / 100 | Unit conversion | Application sends cents, DB stores dollars |
| BEGIN TRAN / COMMIT | Transaction | Balance update + credit insert are atomic |

---

## 8. Sample Queries

### 8.1 Verify bonus credit was applied correctly

```sql
DECLARE @CID INT = 12345;
DECLARE @ExpectedBonus MONEY = 50.00; -- was sent as 5000 cents

SELECT
    cm.CID,
    cm.Credit,
    cm.BonusCredit,
    cm.RealizedEquity,
    cm.BSLRealFunds,
    acb.CreditID,
    acb.Payment AS BonusAmount,
    acb.Occurred
FROM Customer.CustomerMoney cm WITH (NOLOCK)
JOIN History.ActiveCreditBucket_VW acb WITH (NOLOCK)
    ON acb.CID = cm.CID AND acb.CreditTypeID = 7
WHERE cm.CID = @CID
ORDER BY acb.Occurred DESC
```

### 8.2 Find all bonus events for a customer with campaign info

```sql
SELECT
    acb.CreditID,
    acb.CreditTypeID,
    acb.Payment AS BonusAmountUSD,
    acb.BonusTypeID,
    bt.Name AS BonusTypeName,
    acb.CampaignID,
    camp.Code AS CampaignCode,
    acb.Description,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
JOIN BackOffice.BonusType bt WITH (NOLOCK) ON bt.BonusTypeID = acb.BonusTypeID
LEFT JOIN BackOffice.Campaign camp WITH (NOLOCK) ON camp.CampaignID = acb.CampaignID
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 7
ORDER BY acb.Occurred DESC
```

### 8.3 Check if a bonus type is hidden from affiliate tracking

```sql
SELECT
    BonusTypeID,
    Name,
    HideFromAffwiz,
    CASE HideFromAffwiz WHEN 1 THEN 'Hidden from AffWiz tracking' ELSE 'Tracked by AffWiz' END AS AffWizStatus
FROM BackOffice.BonusType WITH (NOLOCK)
ORDER BY Name
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Multi-Currency Balance API](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14028570661/Multi-Currency+Balance+API) | Confluence | MIMO terminology; bonus credit handling context in multi-currency migration (BonusCredit remains account-level/USD). |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceBonus | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceBonus.sql*
