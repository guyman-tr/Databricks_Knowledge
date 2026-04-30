# Billing.CreditCardAuthentication_Update

> Partially updates a credit card authentication session in `Billing.CreditCardAuthentication` using ISNULL-pattern (only non-NULL parameters overwrite existing values); called as the 3DS/Zero Auth flow progresses to record status transitions and provider responses.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID (Billing.CreditCardAuthentication.ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CreditCardAuthentication_Update` is the MODIFIER for `Billing.CreditCardAuthentication`. It is called at each stage of the 3DS / Zero Auth flow to record the outcome of that stage: setting 3DS response data, routing decisions (DepotID, MerchantAccountID), the checkout.com provider response code, risk management status, and ultimately the final `StatusID` transition (e.g., 1=New -> 2=Approved, 3=Decline, etc.).

Because authentication sessions can have multiple intermediate updates (e.g., first routing is resolved, then 3DS completes, then checkout.com responds), the procedure uses an ISNULL partial-update pattern: passing NULL for a parameter leaves that column unchanged. Only the `Modified` timestamp is always forced to `GETUTCDATE()` regardless.

Since `Billing.CreditCardAuthentication` is SYSTEM_VERSIONED (temporal table), every UPDATE call automatically archives the previous row version in `History.BillingCreditCardAuthenticationHistory` - providing a complete audit trail of every status transition without explicit history inserts.

---

## 2. Business Logic

### 2.1 Partial Update Pattern for Multi-Stage Authentication Flow

**What**: Each update call covers only the fields relevant to the current stage of the authentication flow. NULL parameters preserve existing column values.

**Parameters Involved**: All optional parameters

**Rules**:
- Every column except `Modified` uses `ISNULL(@Param, [ColumnName])`: if the parameter is NULL, the DB value is preserved
- `Modified = GETUTCDATE()` is always applied (forced, no ISNULL) - every update advances the modification timestamp
- Only rows matching `ID = @ID` are updated (single-row PK update)
- The system versioning table automatically archives the prior row state on each UPDATE

**Typical update sequence**:
```
Stage 1 - Routing resolved:
  UPDATE: @DepotID=X, @MerchantAccountID=Y (others NULL)

Stage 2 - 3DS completed:
  UPDATE: @ThreeDsData={payload}, @ThreeDsResponseType=1 (others NULL)

Stage 3 - Zero Auth result from checkout.com:
  UPDATE: @SchemeID={id}, @StatusID=2, @StatusReasonID=3,
          @ProviderResponseCode=NULL (others NULL)

Stage 4 - Risk check (if applicable):
  UPDATE: @RiskManagementStatusID=X, @StatusID=35 (if RRE declined)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | VERIFIED | Primary key of the authentication session to update. References `Billing.CreditCardAuthentication.ID`. Required - the only mandatory parameter. |
| 2 | @StatusID | int | YES | NULL | VERIFIED | Updated authentication state. NULL = preserve existing. Values: 1=New, 2=Approved, 3=Decline, 4=Technical, 35=DeclineByRRE. Set to terminal state (2/3/4/35) when the flow concludes. |
| 3 | @StatusReasonID | int | YES | NULL | CODE-BACKED | Updated reason code for the new StatusID. NULL = preserve existing. |
| 4 | @ProcessRegulationID | int | YES | NULL | CODE-BACKED | Updated regulatory context. NULL = preserve existing. Typically set at creation; rarely updated. |
| 5 | @DepotID | int | YES | NULL | CODE-BACKED | Payment depot/terminal assigned by routing. NULL = preserve existing. Set when routing decisions are made after session creation. |
| 6 | @MerchantAccountID | int | YES | NULL | CODE-BACKED | checkout.com merchant account assigned by routing. NULL = preserve existing. Set when merchant routing is resolved. |
| 7 | @SchemeID | nvarchar(100) | YES | NULL | VERIFIED | checkout.com scheme ID returned by successful Zero Auth. NULL = preserve existing. Populated when checkout.com returns success. Enables future MIT charges. |
| 8 | @ThreeDsData | nvarchar(max) | YES | NULL | VERIFIED | Full 3DS response payload from Cardinal SDK. NULL = preserve existing. Populated after 3DS authentication completes. |
| 9 | @ThreeDsResponseType | int | YES | NULL | VERIFIED | Encoded 3DS result code. NULL = preserve existing. Values: Y=Success(1), N=Failed(2), B=Bypassed, U=Unable, A=Attempts, R=Rejected. Set after the 3DS step completes. |
| 10 | @RiskManagementStatusID | int | YES | NULL | NAME-INFERRED | Risk check outcome. NULL = preserve existing. Currently NULL in all rows in production (reserved for future risk integration). |
| 11 | @ProviderResponseCode | nvarchar(100) | YES | NULL | VERIFIED | Raw checkout.com error/response code. NULL = preserve existing. Examples: 20062=Restricted Card, 40205=Gateway Reject BIN Blacklist. Populated from the checkout.com API response. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | Billing.CreditCardAuthentication | Write | Partial UPDATE on the authentication session by PK |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CreditCardAuthentication microservice | @ID + fields | Caller | Called at each stage of the authentication flow to record progress and outcome |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CreditCardAuthentication_Update (procedure)
+-- Billing.CreditCardAuthentication (table) [UPDATE target; temporal - archives to History.BillingCreditCardAuthenticationHistory]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CreditCardAuthentication | Table | UPDATE target - partial update by PK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CreditCardAuthentication microservice | External | Calls to advance authentication session through each flow stage |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Temporal versioning**: Because `Billing.CreditCardAuthentication` has `SYSTEM_VERSIONING = ON`, every UPDATE automatically creates an archived row in `History.BillingCreditCardAuthenticationHistory`. No explicit history INSERT is needed in this procedure.

---

## 8. Sample Queries

### 8.1 Record 3DS completion

```sql
EXEC Billing.CreditCardAuthentication_Update
    @ID = 12345,
    @ThreeDsData = N'{"transStatus":"Y","authenticationValue":"..."}',
    @ThreeDsResponseType = 1  -- Y=Success
-- All other params NULL: StatusID, SchemeID, ProviderResponseCode preserved
```

### 8.2 Record successful Zero Auth (full approval)

```sql
EXEC Billing.CreditCardAuthentication_Update
    @ID = 12345,
    @StatusID = 2,          -- Approved
    @StatusReasonID = 3,
    @SchemeID = N'src_abc123xyz',
    @ProviderResponseCode = NULL  -- No error code on success
```

### 8.3 Check session history (temporal query)

```sql
SELECT
    ha.ID, ha.StatusID, ha.StatusReasonID, ha.SchemeID,
    ha.Modified, ha.ValidFrom, ha.ValidTo
FROM History.BillingCreditCardAuthenticationHistory ha WITH (NOLOCK)
WHERE ha.ID = 12345
ORDER BY ha.ValidFrom ASC
-- Shows every state this session has been in
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD Recurring Payments Zero Auth](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13281656921) | Confluence | Authentication flow stages, SchemeID acquisition from checkout.com, 3DS response types, provider error code meanings (20062, 40205) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CreditCardAuthentication_Update | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CreditCardAuthentication_Update.sql*
