# Billing.CustomerToFunding_UpdateFundingID

> Migrates a customer-funding link from @FundingID to @NewFundingID in `Billing.CustomerToFunding`, only if @NewFundingID does not already exist for that customer; archives prior state to history.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID (source), @NewFundingID (target) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerToFunding_UpdateFundingID` replaces the `FundingID` in a customer-funding association row without changing any other attributes (status, type, reason, dates). It is used in payment instrument migration scenarios - for example, when a card token or wallet account is re-tokenized and gets a new FundingID, the existing customer link must be remapped to the new FundingID.

Created November 2020 by Shabtai E. (PAYIL-1676). The IsVerified column was added to the history OUTPUT in January 2023 (PAYIL-5743, Shay Oren).

---

## 2. Business Logic

### 2.1 FundingID Migration with Duplicate Guard

**What**: Updates `FundingID` from @FundingID to @NewFundingID only if the customer doesn't already have a link for @NewFundingID.

**Rules**:
- `UPDATE ... WHERE CID=@CID AND FundingID=@FundingID AND NOT EXISTS (SELECT 1 FROM Billing.CustomerToFunding WHERE FundingID=@NewFundingID AND CID=@CID)`
- The `NOT EXISTS` guard prevents a PK collision: if the customer already has a link to @NewFundingID, the UPDATE is a no-op (0 rows affected)
- If the update proceeds: `FundingID` changes to @NewFundingID; all other columns remain unchanged
- `OUTPUT DELETED.*` -> `History.ActiveCustomerToFunding` archives the row with the OLD FundingID before the migration

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer whose funding link is being migrated. Lookup component. |
| 2 | @FundingID | INT | NO | - | VERIFIED | Current (old) FundingID to be replaced. The row to update is identified by (CID, @FundingID). |
| 3 | @NewFundingID | INT | NO | - | VERIFIED | New FundingID to migrate to. FK to Billing.Funding. Not applied if the customer already has a link with this ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID | Billing.CustomerToFunding | Write (UPDATE) | Migrates FundingID on the matched row |
| OUTPUT DELETED | History.ActiveCustomerToFunding | Write | Archives the pre-migration row state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment instrument migration service | All params | Caller | Called when a payment instrument is re-tokenized (PAYIL-1676) |

---

## 6. Dependencies

```
Billing.CustomerToFunding_UpdateFundingID (procedure)
+-- Billing.CustomerToFunding (table) [UPDATE target + NOT EXISTS check]
+-- History.ActiveCustomerToFunding (table) [OUTPUT target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | UPDATE target; NOT EXISTS guard check |
| History.ActiveCustomerToFunding | Table | History OUTPUT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Instrument migration service | External | Re-tokenization flows (PAYIL-1676) |

---

## 7. Technical Details

**No-op on duplicate**: If @NewFundingID already exists for the customer, `NOT EXISTS` is false -> 0 rows updated and 0 rows archived. The caller must check @@ROWCOUNT if it needs to distinguish migration success from the no-op case.

---

## 8. Sample Queries

```sql
EXEC Billing.CustomerToFunding_UpdateFundingID
    @CID = 24186018,
    @FundingID = 12345,      -- old FundingID
    @NewFundingID = 67890    -- new FundingID after re-tokenization
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerToFunding_UpdateFundingID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerToFunding_UpdateFundingID.sql*
