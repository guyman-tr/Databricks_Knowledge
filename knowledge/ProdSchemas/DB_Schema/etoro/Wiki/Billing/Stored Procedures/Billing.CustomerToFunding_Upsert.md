# Billing.CustomerToFunding_Upsert

> MERGE-based upsert for `Billing.CustomerToFunding`: inserts a new customer-funding link (inheriting block state from `Billing.Funding`) or updates `LastUsedDate` if already linked; returns @IsNew OUTPUT flag and archives UPDATE history.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FundingID (MERGE key) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CustomerToFunding_Upsert` is the primary entry point for creating or refreshing a customer-payment-instrument association. It is called each time a customer initiates or uses a payment method - if the link doesn't exist, it's created; if it does, the last-used date is refreshed.

A key design detail: on INSERT, the new row inherits the blocking state (`IsBlocked`, `IsRefundExcluded`, `ManagerID`, `BlockedAt`, `BlockedDescription`) from the `Billing.Funding` record, ensuring that a blocked payment instrument cannot be silently re-linked to a customer in an unblocked state.

The `@IsNew OUTPUT` parameter allows the caller to distinguish between a first-time link (INSERT) and a re-use (UPDATE), enabling conditional downstream logic (e.g., sending a "new payment method added" notification only once).

History is archived only for UPDATE paths (not INSERT), since the DELETED pseudo-table is empty for INSERTs.

Originally referenced as "ROLLED BACK FROM PAYIL-2869" before being reformatted with UPSERT command and @IsNew parameter in January 2023 (PAYIL-5588, Shay Oren). IsVerified added to history in January 2023 (PAYIL-5743).

---

## 2. Business Logic

### 2.1 MERGE: Insert-or-Update-LastUsedDate

**MERGE key**: `CTF.CID = @CID AND CTF.FundingID = @FundingID`

**USING source**: Single row from `Billing.Funding WHERE FundingID = @FundingID` - this brings in the current block state from the Funding record.

**WHEN NOT MATCHED (INSERT)**:
- Inserts new row with: CID, FundingID, @DepositTypeID, @ReasonID, LastUsedDate=GETUTCDATE(), IsBlocked (from Funding), IsRefundExcluded (from Funding), ManagerID (from Funding), BlockedAt (from Funding), BlockedDescription (from Funding), @CustomerFundingStatusID
- Block state comes directly from `Billing.Funding` - a blocked instrument creates a blocked CustomerToFunding link

**WHEN MATCHED (UPDATE)**:
- Updates only `LastUsedDate = GETUTCDATE()`
- All other columns (status, type, reason, blocks) remain unchanged

### 2.2 History Archival (UPDATE path only)

**What**: The MERGE OUTPUT goes to an intermediate `@res` table variable, then only the 'UPDATE' rows are inserted into `History.ActiveCustomerToFunding`.

**Rules**:
- `OUTPUT $action, DELETED.*` -> `@res` table (captures both INSERT and UPDATE MERGE results)
- `INSERT History.ActiveCustomerToFunding ... SELECT ... FROM @res WHERE r.Act = 'UPDATE'`
- INSERT rows are NOT archived to history (DELETED.* is NULL/empty on INSERT)
- History also includes `ModificationDate = GETUTCDATE()` (this column is in History but not in the live table)

### 2.3 @IsNew OUTPUT: New Link Detection

**What**: Signals whether the MERGE resulted in an INSERT (new customer-funding link).

**Rules**:
- `SET @IsNew = (SELECT TOP 1 CASE Act WHEN 'INSERT' THEN 1 ELSE 0 END FROM @res)`
- 1 = new link (INSERT path); 0 = existing link (UPDATE path)
- If @res is empty (no MERGE output) -> @IsNew = NULL -> `RAISERROR(60000, ...)` and RETURN 60000
- Empty @res means `Billing.Funding WHERE FundingID=@FundingID` returned no rows (Funding doesn't exist) - the MERGE USING source had no rows, so neither INSERT nor UPDATE fired

### 2.4 Default Parameter Values

| Parameter | Default | Meaning |
|-----------|---------|---------|
| @DepositTypeID | 1 | Regular deposit |
| @ReasonID | 6 | By user (customer-initiated) |
| @CustomerFundingStatusID | 0 | Deactivated (requires explicit activation via UpdateStatus) |

**Status default note**: New links start as Deactivated (0). Contrast with `CustomerToFunding_Add` which relies on the table DEFAULT of 1 (Active). Callers of `_Upsert` must call `CustomerToFunding_UpdateStatus` to activate the link.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID for the funding link. MERGE key component. |
| 2 | @FundingID | INT | NO | - | VERIFIED | Payment instrument to link. MERGE key component and USING source. Must exist in Billing.Funding or RAISERROR fires. |
| 3 | @DepositTypeID | INT | YES | 1 (Regular) | CODE-BACKED | Deposit type for new links. Only used on INSERT path. Values: 1=Regular, 2=Instant, 3=RecurringDeposit. |
| 4 | @ReasonID | INT | YES | 6 (ByUser) | CODE-BACKED | Reason for new links. Only used on INSERT path. Values: 6=ByUser. |
| 5 | @CustomerFundingStatusID | INT | YES | 0 (Deactivated) | VERIFIED | Status for new links. Only used on INSERT path. Default=0 (Deactivated) - requires explicit activation after upsert. |
| 6 | @IsNew | BIT OUTPUT | YES | NULL | VERIFIED | Output flag: 1 if new link was created (INSERT), 0 if existing link was updated (UPDATE). NULL + RAISERROR if FundingID not found in Billing.Funding. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| USING source | Billing.Funding | Read | Block state inheritance for new links; validates FundingID exists |
| MERGE target | Billing.CustomerToFunding | Write (UPSERT) | Creates or refreshes customer-funding link |
| UPDATE history | History.ActiveCustomerToFunding | Write | Archives prior state on update path only |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment service | @CID, @FundingID | Caller | Primary entry point for creating or refreshing customer-funding associations (PAYIL-5588) |

---

## 6. Dependencies

```
Billing.CustomerToFunding_Upsert (procedure)
+-- Billing.Funding (table) [USING source - block state inheritance + existence validation]
+-- Billing.CustomerToFunding (table) [MERGE target]
+-- History.ActiveCustomerToFunding (table) [INSERT target for UPDATE history]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Funding | Table | USING source: block state for INSERT; FundingID existence check |
| Billing.CustomerToFunding | Table | MERGE target |
| History.ActiveCustomerToFunding | Table | History INSERT (UPDATE path only) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment registration service | External | Primary upsert for customer-funding links (PAYIL-5588) |

---

## 7. Technical Details

**Two-step history write**: MERGE OUTPUT -> `@res` table variable -> filtered INSERT to History. This is necessary because `OUTPUT` with `INTO` can only write to one target; capturing to `@res` allows filtering to UPDATE rows only before writing to History.

**RAISERROR on missing Funding**: If `Billing.Funding` has no row for @FundingID, the MERGE USING source is empty -> no INSERT or UPDATE fires -> @res is empty -> @IsNew is NULL -> `RAISERROR(60000, 16, 1, 'SP:CustomerToFunding_Upsert, ...')`. This validates Funding existence implicitly.

**Block state inheritance**: New CustomerToFunding rows inherit the current Funding block state. This ensures consistency: if a funding is globally blocked, any new CTF link created for it will also start blocked.

---

## 8. Sample Queries

### 8.1 Link a customer to a payment instrument (new or update)

```sql
DECLARE @IsNew BIT
EXEC Billing.CustomerToFunding_Upsert
    @CID = 24186018,
    @FundingID = 12345,
    @IsNew = @IsNew OUTPUT
SELECT @IsNew AS IsNewLink  -- 1=new link created, 0=existing link refreshed
```

### 8.2 Check the initial status after upsert

```sql
-- After _Upsert, new links have CustomerFundingStatusID=0 (Deactivated)
-- Must call _UpdateStatus to activate:
EXEC Billing.CustomerToFunding_UpdateStatus
    @CID = 24186018,
    @FundingID = 12345,
    @StatusID = 1   -- Activate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CustomerToFunding_Upsert | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CustomerToFunding_Upsert.sql*
