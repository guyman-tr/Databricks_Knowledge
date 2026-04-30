# BackOffice.Bonus

> Ledger of bonus credit adjustments issued to customer accounts, recording each bonus grant with its type, campaign association, amount, and reason for the money movement.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | BonusID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 3 active (1 clustered PK + NC on CID + NC on CampaignID) |

---

## 1. Business Meaning

BackOffice.Bonus is the operational log of bonus credit adjustments issued to customer trading accounts. Each row represents a single bonus grant or debit, recording who received it (CID), how much (Amount), when (Occurred), what type it was (BonusTypeID), and why it was moved (MoveMoneyReasonID). The table covers all manual and automated bonus transactions processed through the BackOffice system.

The table exists as a BackOffice-layer record of bonus activity, distinct from History.Credit which is the authoritative financial ledger. BackOffice.Bonus captures the operational context (campaign code used, deposit triggering the bonus, BackOffice notes/description) that the lower-level credit history does not. It is the table BackOffice agents query when reviewing a customer's bonus history through the BackOffice UI.

Rows are primarily written directly by application code (no single SSDT stored procedure manages the full insert lifecycle for this table). All 7,786 rows have BonusStatusID=1 (Approved), indicating bonus grants go directly to approved state - the workflow states (New, Declined, Reverted) exist in the dictionary but are either managed by an external system or not used in current operations. The dominant bonus type is BonusTypeID=59 (Share and Copy Bonus, 74.6% of all rows), followed by BonusTypeID=22 (NWA Adjustment, 17.9%).

---

## 2. Business Logic

### 2.1 Bonus Status Workflow

**What**: BonusStatusID tracks the lifecycle state of a bonus grant.

**Columns Involved**: `BonusStatusID`, `BonusID`

**Rules**:
- Dictionary.BonusStatus defines four states: 0=New, 1=Approved, 2=Declined, 3=Reverted.
- In current data, all 7,786 rows have BonusStatusID=1 (Approved). The New, Declined, and Reverted states are defined but not seen in production - grants go directly to Approved.
- FK (WITH CHECK) to Dictionary.BonusStatus enforces only valid status codes.

**Diagram**:
```
BonusStatus lifecycle (as defined):
  0=New -> 1=Approved (normal path)
         -> 2=Declined (rejected)
  1=Approved -> 3=Reverted (clawback)

In practice: all rows are 1=Approved.
```

### 2.2 Bonus Type and Campaign Association

**What**: Each bonus is classified by type (BonusTypeID) and optionally linked to a marketing campaign (CampaignID/UsedCampaignCode).

**Columns Involved**: `BonusTypeID`, `CampaignID`, `UsedCampaignCode`

**Rules**:
- BonusTypeID: implicit FK to BackOffice.BonusType (no constraint enforced - BonusTypeID=999999 exists for 3 rows, likely a test/fallback value).
- The dominant type is BonusTypeID=59 (Share and Copy Bonus, 5,809 of 7,786). See BackOffice.BonusType for the full hierarchy.
- CampaignID: implicit FK to BackOffice.Campaign. NULL for 99.7% of rows - most bonuses are not campaign-driven.
- UsedCampaignCode: the text code the customer entered at registration. NULL for 99.7% of rows (correlated with CampaignID being NULL).
- When a campaign bonus is issued, both CampaignID and UsedCampaignCode should be set; standalone bonuses leave both NULL.

### 2.3 Negative Amounts and Reversals

**What**: Amount can be negative, representing a bonus debit (clawback or reversal) rather than a credit.

**Columns Involved**: `Amount`, `MoveMoneyReasonID`

**Rules**:
- Amount is stored as MONEY type (4-decimal precision, USD assumed).
- Negative amounts indicate a bonus reversal or debit adjustment (e.g., BonusID=1: Amount=-500).
- MoveMoneyReasonID: implicit FK to Dictionary.MoveMoneyReason. 98.1% of rows have 1=Adjustment, indicating standard manual credit. 2=Bonus Abuser suggests clawback of improperly obtained bonus. 999999 is a non-standard sentinel value (42 rows).

---

## 3. Data Overview

| BonusID | CID | Amount | BonusTypeID | BonusStatusID | MoveMoneyReasonID | Meaning |
|---------|-----|--------|-------------|---------------|-------------------|---------|
| 1 | 3633274 | -500 | 21 | 1 | NULL | Manual debit adjustment (negative amount) for BonusTypeID=21. Earliest record, June 2014. |
| 2 | 3633274 | 2200 | 21 | 1 | NULL | Positive bonus credit for the same customer, same day as BonusID=1. Both have MoveMoneyReasonID NULL (pre-dates that field being required). |
| 3 | 3634278 | 2000 | 7 | 1 | NULL | Bonus linked to CampaignID=11993. DepositID=0 (deposit-triggered with sentinel deposit ID). |
| 4 | 3635330 | 50000 | 22 | 1 | 1 | BonusTypeID=22 (NWA Adjustment), MoveMoneyReasonID=1 (Adjustment). Large $500.00 credit adjustment (Amount stored as cents * 100? or dollars). |
| 5 | 3635331 | 50000 | 22 | 1 | 1 | Same pattern as BonusID=4: same date, same type, same amount, MoveMoneyReasonID=1=Adjustment. Likely a bulk adjustment run. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BonusID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-generated unique bonus record identifier. NOT FOR REPLICATION. Clustered PK. Range 1-9981 (7,786 rows used, sparse due to identity gaps from failed/rolled back transactions). |
| 2 | CID | int | NO | - | VERIFIED | Customer account ID of the bonus recipient. Implicit FK to Customer.Customer.SerialID (and BackOffice.Customer.CID). NC index IX_BO_Bonus_CID enables fast lookup of all bonuses for a customer. |
| 3 | CampaignID | int | YES | - | VERIFIED | The marketing campaign that originated this bonus. Implicit FK to BackOffice.Campaign.CampaignID. NULL for 99.7% of rows - most bonuses are not linked to a campaign. When populated, UsedCampaignCode should also be set. NC index IX_BO_Bonus_CampaignID. |
| 4 | UsedCampaignCode | varchar(50) | YES | - | VERIFIED | The campaign code text the customer used at registration (e.g., "20coupon", "freecopyref"). Denormalized alongside CampaignID for historical record-keeping. NULL for 99.7% of rows (correlated with CampaignID being NULL). |
| 5 | Amount | money | NO | - | VERIFIED | Bonus amount in USD (money type, 4-decimal precision). Positive = credit to customer. Negative = debit/reversal/clawback. Stored in whole dollar units (not cents). |
| 6 | Description | varchar(255) | YES | - | CODE-BACKED | Free-text note describing the reason for this bonus, entered by the BackOffice agent or system. Populated for 99.4% of rows (7,739 of 7,786). Used in GetUserStatementTransactionList and GetActivityList for display. |
| 7 | Occurred | datetime | NO | GETDATE() | VERIFIED | Server timestamp when this bonus record was inserted. Defaults to GETDATE(). Range: 2014-06-24 to present. |
| 8 | BonusStatusID | int | NO | - | VERIFIED | Bonus lifecycle state. FK (WITH CHECK) to Dictionary.BonusStatus. Values: 0=New, 1=Approved, 2=Declined, 3=Reverted. In production all 7,786 rows are 1=Approved - grants go directly to approved state. |
| 9 | DepositID | int | YES | - | CODE-BACKED | The deposit that triggered this bonus, when the bonus is deposit-related. Implicit FK to a deposits table (likely Billing.Funding or similar). NULL for 97.9% of rows. When 0 (seen in BonusID=3), used as a sentinel "deposit-triggered but no specific deposit ID" value. |
| 10 | BonusTypeID | int | YES | - | VERIFIED | Classification of this bonus. Implicit FK to BackOffice.BonusType.BonusTypeID (no constraint enforced - 3 rows have BonusTypeID=999999, a non-standard sentinel). Top types: 59=Share and Copy Bonus (74.6%), 22=NWA Adjustment (17.9%), 13=Satisfaction Bonus (1.3%), 3=Custom (1.1%). See BackOffice.BonusType for full hierarchy. |
| 11 | MoveMoneyReasonID | int | YES | - | VERIFIED | The reason category for the money movement. Implicit FK to Dictionary.MoveMoneyReason. Values: 1=Adjustment (98.1%), 2=Bonus Abuser (0.24%), 8=Recurring Deposit (0.04%), 999999=non-standard sentinel (0.54%), NULL=1.0% (legacy rows). Drives financial reporting categorization. |
| 12 | WithdrawID | int | YES | NULL | CODE-BACKED | Links this bonus to a withdrawal event when the bonus is issued in connection with a cashout. NULL default; NULL for 99.7% of rows - almost never used. Implicit FK to a withdrawal table (likely Billing.Cashout or similar). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Bonus recipient's trading account |
| CampaignID | BackOffice.Campaign | Implicit | Campaign that generated this bonus |
| BonusStatusID | Dictionary.BonusStatus | FK (WITH CHECK) | Bonus lifecycle state (0=New, 1=Approved, 2=Declined, 3=Reverted) |
| BonusTypeID | BackOffice.BonusType | Implicit | Bonus classification (type hierarchy) |
| MoveMoneyReasonID | Dictionary.MoveMoneyReason | Implicit | Reason for money movement |
| DepositID | Billing.Funding (inferred) | Implicit | Deposit that triggered the bonus |
| WithdrawID | Billing.Cashout (inferred) | Implicit | Withdrawal linked to this bonus |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetActivityList | BonusID | READER | Includes bonus records in customer activity reporting |
| BackOffice.GetUserStatementTransactionList | BonusID | READER | Shows bonus transactions in customer account statements |
| BackOffice.UpsertIntoAggregationTablesAction | BonusID | READER | Aggregates bonus data into summary tables |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.Bonus (table)
- FK targets: Dictionary.BonusStatus
- Implicit references: Customer.Customer (CID), BackOffice.BonusType (BonusTypeID),
  BackOffice.Campaign (CampaignID), Dictionary.MoveMoneyReason (MoveMoneyReasonID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.BonusStatus | Table | FK (WITH CHECK) on BonusStatusID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetActivityList | Procedure | READER - joins Bonus for activity reporting |
| BackOffice.GetUserStatementTransactionList | Procedure | READER - bonus transactions in statements |
| BackOffice.UpsertIntoAggregationTablesAction | Procedure | READER - bonus data for aggregation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BO_Bonus_BonusID | CLUSTERED PK | BonusID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| IX_BO_Bonus_CID | NC | CID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |
| IX_BO_Bonus_CampaignID | NC | CampaignID ASC | - | - | Active (FILLFACTOR=90, ON [MAIN]) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BO_Bonus_BonusID | PK | BonusID uniqueness |
| FK_BO_Bonus_BonusStatusID | FK (WITH CHECK) | BonusStatusID -> Dictionary.BonusStatus(BonusStatusID) |
| DF_BO_Bonus_Occurred | DEFAULT | Occurred = GETDATE() |
| (unnamed) | DEFAULT | WithdrawID = NULL |

---

## 8. Sample Queries

### 8.1 Get all bonuses for a customer with type and status names
```sql
SELECT
    b.BonusID,
    b.Amount,
    b.Occurred,
    bt.Name AS BonusTypeName,
    bs.Name AS StatusName,
    mr.MoveMoneyReason,
    b.Description,
    b.CampaignID
FROM BackOffice.Bonus b WITH (NOLOCK)
JOIN BackOffice.BonusType bt WITH (NOLOCK) ON bt.BonusTypeID = b.BonusTypeID
JOIN Dictionary.BonusStatus bs WITH (NOLOCK) ON bs.BonusStatusID = b.BonusStatusID
LEFT JOIN Dictionary.MoveMoneyReason mr WITH (NOLOCK) ON mr.MoveMoneyReasonID = b.MoveMoneyReasonID
WHERE b.CID = @CID
ORDER BY b.Occurred DESC
```

### 8.2 Summarize bonus amounts by type for a date range
```sql
SELECT
    bt.Name AS BonusTypeName,
    COUNT(*) AS BonusCount,
    SUM(b.Amount) AS TotalAmount
FROM BackOffice.Bonus b WITH (NOLOCK)
JOIN BackOffice.BonusType bt WITH (NOLOCK) ON bt.BonusTypeID = b.BonusTypeID
WHERE b.Occurred >= '2025-01-01' AND b.Occurred < '2026-01-01'
GROUP BY bt.Name
ORDER BY TotalAmount DESC
```

### 8.3 Find campaign-linked bonuses with campaign details
```sql
SELECT
    b.BonusID,
    b.CID,
    b.Amount,
    b.UsedCampaignCode,
    c.Code AS CampaignCode,
    c.Description AS CampaignDescription,
    b.Occurred
FROM BackOffice.Bonus b WITH (NOLOCK)
JOIN BackOffice.Campaign c WITH (NOLOCK) ON c.CampaignID = b.CampaignID
WHERE b.CampaignID IS NOT NULL
ORDER BY b.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Bonus | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.Bonus.sql*
