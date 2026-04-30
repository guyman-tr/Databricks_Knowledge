# Billing.CustomerToFunding_UpdateDate

> Updates `LastUsedDate` to the current UTC time for a specific customer-funding pair; archives the prior row state to `History.ActiveCustomerToFunding` via OUTPUT clause.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID (composite PK of target row) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerToFunding_UpdateDate` refreshes the `LastUsedDate` timestamp on a customer-funding link to record the most recent activity. It is called whenever a customer uses a payment instrument for a deposit, withdrawal, or other payment action - keeping the "last used" tracking current without modifying any other fields.

Created December 2016 by Geri Reshef (ticket 41987). The IsVerified column was added to the history OUTPUT in January 2023 (PAYIL-5743, Shay Oren).

---

## 2. Business Logic

### 2.1 LastUsedDate Refresh with History Archival

**What**: Updates only `LastUsedDate` to `GETUTCDATE()` and writes the pre-update row state to history.

**Rules**:
- Only `LastUsedDate` changes; all other columns (status, type, reason, blocks) are preserved
- `OUTPUT DELETED.*` -> `History.ActiveCustomerToFunding` archives the PREVIOUS row state before the update
- No return value; no result set
- If CID+FundingID does not exist: 0 rows updated, 0 rows archived (silent no-op)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID of the link to update. Composite PK lookup component. |
| 2 | @FundingID | INT | NO | - | VERIFIED | Payment instrument ID of the link to update. Composite PK lookup component. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID | Billing.CustomerToFunding | Write (UPDATE) | Refreshes LastUsedDate for the customer-funding link |
| OUTPUT DELETED | History.ActiveCustomerToFunding | Write | Archives prior row state before update |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit/withdrawal service | @CID, @FundingID | Caller | Called after each payment action to refresh the last-used timestamp |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CustomerToFunding_UpdateDate (procedure)
+-- Billing.CustomerToFunding (table) [UPDATE target]
+-- History.ActiveCustomerToFunding (table) [OUTPUT target - history archive]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CustomerToFunding | Table | UPDATE target |
| History.ActiveCustomerToFunding | Table | History OUTPUT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment processing service | External | Refreshes LastUsedDate after each use |

---

## 7. Technical Details

**OUTPUT clause**: `OUTPUT DELETED.*` captures the row state BEFORE the update. The archived row in `History.ActiveCustomerToFunding` reflects what the link looked like prior to this date refresh.

---

## 8. Sample Queries

```sql
EXEC Billing.CustomerToFunding_UpdateDate @CID = 24186018, @FundingID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerToFunding_UpdateDate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerToFunding_UpdateDate.sql*
