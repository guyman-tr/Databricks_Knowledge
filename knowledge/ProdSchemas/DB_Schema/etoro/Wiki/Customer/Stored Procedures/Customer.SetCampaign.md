# Customer.SetCampaign

> Bulk-assigns a marketing CampaignID to a list of customer accounts; with optional overwrite guard that skips customers who already have a campaign assigned.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CustomerList VARCHAR(MAX), @CampaignID INTEGER, @DoOverwrite BIT; RETURN @@ERROR |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetCampaign` assigns a marketing campaign attribution to one or more customer accounts in a single call. It is used by marketing operations and back-office tooling to associate customers with campaigns after the fact - for example, retroactively attributing a promotional campaign to customers who signed up during a campaign period but whose tracking ID was not captured at registration.

The `@CustomerList` parameter accepts a comma-delimited string of CIDs. The `@DoOverwrite` flag controls whether existing campaign assignments are overwritten:
- `@DoOverwrite = 1`: updates ALL customers in the list, replacing existing CampaignID values.
- `@DoOverwrite = 0`: only sets CampaignID for customers whose CampaignID is currently NULL (first-time assignment only).

---

## 2. Business Logic

### 2.1 Bulk CID List Parsing

**What**: Converts the comma-delimited CID string to a table for the UPDATE join.

**Columns/Parameters Involved**: `@CustomerList`, `Internal.ConvertListToTable`

**Rules**:
- `FROM Internal.ConvertListToTable(@CustomerList) AS T` - TVF returns one row per parsed value.
- Each `T.Parameter` is `CAST`ed to INTEGER for the WHERE join.
- Invalid non-integer entries would cause a cast error.

### 2.2 CampaignID Assignment with Overwrite Guard

**What**: Sets CampaignID on matched customer records.

**Columns/Parameters Involved**: `Customer.Customer.CampaignID`, `@CampaignID`, `@DoOverwrite`

**Rules**:
- `UPDATE Customer.Customer SET CampaignID = @CampaignID WHERE CID = T.Parameter AND (@DoOverwrite = 1 OR CampaignID IS NULL)`
- `@DoOverwrite = 1`: condition is always true for matched CIDs (existing values overwritten).
- `@DoOverwrite = 0`: only rows with NULL CampaignID are updated.
- Returns `@@ERROR` (0 = success, non-zero = failure).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CustomerList | VARCHAR(MAX) | NO | - | CODE-BACKED | Comma-delimited list of CIDs to update. Parsed by Internal.ConvertListToTable into individual integer CIDs. |
| 2 | @CampaignID | INTEGER | NO | - | CODE-BACKED | Marketing campaign ID to assign. FK to BackOffice.Campaign (implicit). NULL would clear existing campaign, but passing NULL is not typical use. |
| 3 | @DoOverwrite | BIT | NO | - | CODE-BACKED | 1=overwrite all existing CampaignID values for listed CIDs; 0=only assign where CampaignID IS NULL (preserve existing assignments). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CustomerList | Internal.ConvertListToTable | Caller (TVF) | Parses comma-delimited CID string into a table |
| @CampaignID | Customer.Customer | MODIFIER | UPDATE CampaignID on matched CID rows |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Marketing / BackOffice campaign tools | External | Callers | Used for bulk campaign attribution assignments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetCampaign (procedure)
+-- Internal.ConvertListToTable (function) [parses comma-delimited CID list]
+-- Customer.Customer (view/table) [UPDATE CampaignID]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.ConvertListToTable | Function (TVF) | Splits @CustomerList string into table of CIDs |
| Customer.Customer | View/Table | UPDATE - sets CampaignID for matched customers |

### 6.2 Objects That Depend On This

No dependents found in Customer schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @DoOverwrite guard | Business rule | `(@DoOverwrite = 1 OR CampaignID IS NULL)` - prevents overwriting existing attributions when @DoOverwrite=0 |
| RETURN @@ERROR | Legacy error handling | Uses @@ERROR (pre-TRY/CATCH style). Returns 0 on success, SQL error code on failure. |
| No transaction | Design | No explicit transaction; UPDATE is implicitly atomic. No rollback on partial failure if list is large. |

---

## 8. Sample Queries

### 8.1 Assign a campaign to specific customers (overwrite)

```sql
EXEC Customer.SetCampaign
    @CustomerList = '12345,67890,11111',
    @CampaignID = 42,
    @DoOverwrite = 1;
```

### 8.2 Assign only to customers with no existing campaign

```sql
EXEC Customer.SetCampaign
    @CustomerList = '12345,67890,11111',
    @CampaignID = 42,
    @DoOverwrite = 0;
-- Only customers with CampaignID IS NULL will be updated
```

### 8.3 Verify campaign assignment

```sql
SELECT CID, CampaignID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID IN (12345, 67890, 11111)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetCampaign | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetCampaign.sql*
