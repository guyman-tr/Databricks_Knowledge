# Customer.SetPrivacyUniqueIdentityNew

> Inserts or refreshes a customer's social network OAuth connection in Customer.PrivacyUniqueIdentity, with token-aware upsert logic that prevents duplicate connections while allowing token renewal.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @PrivacyRecipientID - unique social connection; @Token - OAuth token for deduplication |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SetPrivacyUniqueIdentityNew is the primary write procedure for Customer.PrivacyUniqueIdentity, which stores a customer's linked social network accounts (Facebook, Google, Twitter, etc.). When a customer connects a social account (via OAuth), this procedure records the connection. When an existing OAuth token expires and the social platform issues a new one, this procedure refreshes the stored token without creating a duplicate row.

The procedure exists to maintain exactly one connection record per (GCID, PrivacyRecipientID) pair while handling the realities of OAuth token lifecycle - tokens expire and get replaced, so a simple INSERT would fail on duplicate, and a simple UPDATE would miss new connections. The token-aware upsert logic distinguishes between these cases.

Data flow: called from social login flows (Sign in with Facebook/Google) and social connection flows (Link my Facebook account). After a customer authenticates via OAuth, the application calls this procedure with the GCID, the social platform ID (PrivacyRecipientID), and the returned OAuth token/user ID. Customer.DeletePrivacyUniqueIdentity removes connections (when unlink or GDPR). Customer.GetPrivacyUniqueIdentity and related procedures read this data for identity matching.

---

## 2. Business Logic

### 2.1 Token-Aware Upsert Logic

**What**: The procedure uses a two-stage conditional to distinguish between new connections and token refreshes, preventing duplicates while allowing renewals.

**Columns/Parameters Involved**: `@GCID`, `@PrivacyRecipientID`, `@Token`, `@UserID`, `@IsAuthorized`, `@TokenExpiry`

**Rules**:
- Stage 1 - INSERT path: IF NOT EXISTS (GCID = @GCID OR Token = @Token) -> INSERT a new row (completely new social connection)
- Stage 2 - UPDATE path (within ELSE): IF NOT EXISTS (Token = @Token) -> UPDATE where GCID = @GCID AND PrivacyRecipientID = @PrivacyRecipientID, setting new UserID, Token, TokenExpiry, IsAuthorized = 1
- No-op path: If Token already exists in the table -> neither INSERT nor UPDATE runs (idempotent for duplicate calls with the same token)
- IsAuthorized is explicitly set to 1 on UPDATE, indicating the connection is being reauthorized (was possibly set to 0 to revoke)
- The entire operation is wrapped in an explicit transaction with ROLLBACK on error

**Diagram**:
```
Inputs: @GCID, @PrivacyRecipientID, @UserID, @Token, @TokenExpiry

NOT EXISTS (GCID=@GCID OR Token=@Token)?
  YES -> INSERT new row (new social connection)
  NO  ->
    NOT EXISTS (Token=@Token)?
      YES -> UPDATE row where GCID=@GCID AND PrivacyRecipientID=@PrivacyRecipientID
             SET UserID=@UserID, Token=@Token, TokenExpiry=@TokenExpiry, IsAuthorized=1
      NO  -> No-op (same token, already stored)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer's eToro CID. Stored in the new row on INSERT. Not used in the EXISTS checks or UPDATE WHERE clause (those use GCID). |
| 2 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. Used as the primary deduplication key: if a row with GCID=@GCID exists, the INSERT is skipped. On UPDATE, targets rows by GCID + PrivacyRecipientID. |
| 3 | @PrivacyRecipientID | int | NO | - | CODE-BACKED | Social platform identifier. Identifies which external network this connection is for (e.g., Facebook=2, Google=5, etc. - from Customer.PrivacyUniqueIdentity). Combined with GCID to uniquely identify one social connection. Used in UPDATE WHERE clause. |
| 4 | @UserID | varchar(255) | NO | - | CODE-BACKED | The customer's user ID on the external social platform (e.g., Facebook user ID). Stored on INSERT; updated to the new value on token refresh (UPDATE path). |
| 5 | @Token | varchar(255) | NO | - | CODE-BACKED | OAuth access token issued by the social platform. Used as the second deduplication key: if Token already exists, no INSERT or UPDATE occurs. Updated to the new token value on token refresh. |
| 6 | @TokenExpiry | datetime | YES | NULL | CODE-BACKED | Expiry timestamp of the OAuth token (when the social platform specifies one). NULL if the token does not expire. Updated on token refresh. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID, @GCID | Customer.PrivacyUniqueIdentity | Writer + Modifier | Primary writer: inserts new social connections and updates token data on refresh |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from social login and social connect services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetPrivacyUniqueIdentityNew (procedure)
└── Customer.PrivacyUniqueIdentity (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.PrivacyUniqueIdentity | Table | EXISTS checks for deduplication; INSERT target (new connection); UPDATE target (token refresh) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Explicit transaction | Atomicity | BEGIN TRAN / COMMIT wraps the INSERT or UPDATE; ROLLBACK on error |
| TRY/CATCH + RAISERROR | Error handling | Constructs a descriptive error message with procedure name, error message, number, and line; re-raises after rollback |
| RETURN @error_num | Return value | Returns 0 on success; returns ERROR_NUMBER() on failure |

---

## 8. Sample Queries

### 8.1 Link a new Facebook account for a customer
```sql
EXEC Customer.SetPrivacyUniqueIdentityNew
    @CID = 12345, @GCID = 67890,
    @PrivacyRecipientID = 2,
    @UserID = 'fb_user_9876',
    @Token = 'oauth_token_abc123',
    @TokenExpiry = '2026-06-01';
```

### 8.2 Refresh an expired token for an existing connection
```sql
EXEC Customer.SetPrivacyUniqueIdentityNew
    @CID = 12345, @GCID = 67890,
    @PrivacyRecipientID = 2,
    @UserID = 'fb_user_9876',
    @Token = 'oauth_token_new456',  -- new token from OAuth refresh
    @TokenExpiry = '2026-09-01';
```

### 8.3 View all social connections for a customer
```sql
SELECT pui.CID, pui.GCID, pui.PrivacyRecipientID, pui.UserID,
       pui.Token, pui.TokenExpiry, pui.IsAuthorized
FROM Customer.PrivacyUniqueIdentity pui WITH (NOLOCK)
WHERE pui.CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetPrivacyUniqueIdentityNew | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetPrivacyUniqueIdentityNew.sql*
