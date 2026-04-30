# History.OpenBookLoginWithCID

> CID-based OpenBook login variant that retrieves the customer profile and checks first-login status without password validation - for pre-authenticated callers. The History.LoginOpenBook INSERT is currently commented out so no login record is written.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer ID (caller has already authenticated the user) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.OpenBookLoginWithCID` is the CID-based (pre-authenticated) variant of `History.OpenBookLogin`. Instead of receiving a username and password and calling the STS security service for validation, this procedure accepts a CID directly - the assumption is that the caller has already performed authentication through another mechanism (e.g., SSO, token validation, or a prior successful authentication step). The procedure then retrieves the customer profile from `Customer.Customer` and performs the same first-login detection and lead-tracking logic as the username-password variant.

A critical behavioral difference from `History.OpenBookLogin`: the INSERT into `History.LoginOpenBook` is commented out. This means `OpenBookLoginWithCID` does NOT create a login audit record in `History.LoginOpenBook` - it only reads data and (when conditions are met) sends lead tracking data. As a result, this procedure cannot affect the first-login detection for future calls (since it writes nothing to History.LoginOpenBook or History.Login).

Data flow: (1) SELECT customer profile WHERE CID=@CID from Customer.Customer; (2) RETURN -1 if not found; (3) check first-login status (NOT EXISTS in History.Login AND NOT EXISTS in History.LoginOpenBook); (4) if LeadMode=2 AND first login AND not test user: send lead XML via Service Broker; (5) SELECT result set (CID, PrivacyPolicyID, UserName, IsFirstLogin, AffiliateID, GCID); (6) INSERT into History.LoginOpenBook is commented out; (7) RETURN 0.

---

## 2. Business Logic

### 2.1 Trust-Based Authentication (No Password Validation)

**What**: No credential validation occurs. The caller is trusted to have already authenticated the user.

**Columns/Parameters Involved**: `@CID`

**Rules**:
- SELECT directly from Customer.Customer WHERE CID=@CID (no STS call, no password check)
- If @@ROWCOUNT != 1 (CID not found): RETURN -1 (same error code as credential failure in OpenBookLogin)
- This variant is appropriate for scenarios where the platform has already established the user's identity via a separate auth flow (e.g., mobile SSO, trusted internal service)

### 2.2 First-Login Detection and Lead Tracking

**What**: Identical to History.OpenBookLogin - checks if this is the customer's first-ever login and sends lead XML when conditions are met.

**Columns/Parameters Involved**: `@IsFirstLogin`, `@LeadMode`, `@CID`, `@PlayerLevelID`

**Rules**:
- Same first-login check: NOT EXISTS in History.Login WHERE CID=@CID AND NOT EXISTS in History.LoginOpenBook WHERE CID=@CID
- Same LeadMode logic: Maintenance.Feature FeatureID=3 must equal 2
- Same exclusion: PlayerLevelID=4 (test users) are skipped
- Lead XML built via direct SELECT FROM Customer.Customer WHERE CID=@CID (unlike OpenBookLogin which uses local variables); note FunnelID and LabelID fields are NOT included in this variant's lead XML
- IsFirstLogin returned in result set

### 2.3 Commented-Out Login Insert

**What**: The INSERT into History.LoginOpenBook is commented out, making this procedure a read-only operation from a data perspective.

**Rules**:
- The INSERT block (lines 128-140 in DDL) is wrapped in a `/* ... */` comment block
- This means successful calls to this procedure are NOT recorded in History.LoginOpenBook
- Consequence: if a customer's first-ever platform login is via this procedure, the IsFirstLogin=1 state will persist on future calls until History.Login or History.LoginOpenBook gets a record through another path
- The INSERT code matches what History.OpenBookLogin does - it appears intentionally disabled for this variant, possibly because the caller handles login recording differently

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the pre-authenticated user. Used directly to look up Customer.Customer (no password validation). If no Customer row exists for this CID, RETURN -1. |
| 2 | @ClientVersion | VARCHAR(20) | YES | NULL | CODE-BACKED | Client application version. Declared and accepted but currently unused since the INSERT into History.LoginOpenBook is commented out. Retained for interface compatibility with History.OpenBookLogin callers. |
| 3 | @ClientTypeID | TINYINT | YES | 0 | CODE-BACKED | Client platform type. Same as @ClientVersion - declared, accepted, but not persisted since the INSERT is commented out. |

**Result Set Columns Returned:**

| # | Column | Description |
|---|--------|-------------|
| R1 | CID | Customer ID. |
| R2 | PrivacyPolicyID | Privacy policy version last accepted by this customer. |
| R3 | UserName | Stored username from Customer.Customer. |
| R4 | IsFirstLogin | 1 = first-ever login across History.Login + History.LoginOpenBook. 0 = returning user. |
| R5 | AffiliateID | SerialID from Customer.Customer - affiliate/tracking serial. |
| R6 | GCID | Global Customer ID from Customer.Customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Lookup | Reads customer profile (all fields: CID, PrivacyPolicyID, UserName, PlayerLevelID, OriginalCID, ProviderID, IsReal, IP, SerialID, etc.) WHERE CID=@CID; also re-queried in lead XML SELECT |
| @CID | History.Login | EXISTS check | Checks for prior login records for first-login detection |
| @CID | History.LoginOpenBook | EXISTS check | Checks for prior OpenBook login records for first-login detection (INSERT is commented out) |
| FeatureID=3 | Maintenance.Feature | Lookup | Reads LeadMode for first-login lead tracking |
| - | Internal.GetCountryIDByIP | Function call | Used in lead XML to resolve Customer.Customer.IP to CountryID |
| - | Internal.CallRaiseError | Procedure call | CATCH block error handler |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. Called externally by the OpenBook platform.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.OpenBookLoginWithCID (procedure)
+-- Customer.Customer (table)
+-- History.Login (table)
+-- History.LoginOpenBook (table)
+-- Maintenance.Feature (table)
+-- Internal.GetCountryIDByIP (function)
+-- Internal.CallRaiseError (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | SELECT profile WHERE CID=@CID; also re-read in lead XML |
| History.Login | Table | EXISTS check for first-login status |
| History.LoginOpenBook | Table | EXISTS check for first-login status (INSERT commented out) |
| Maintenance.Feature | Table | SELECT Value WHERE FeatureID=3 for LeadMode |
| Internal.GetCountryIDByIP | Function | Resolves IP to CountryID in lead XML |
| Internal.CallRaiseError | Procedure | CATCH block error propagation |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READ UNCOMMITTED isolation | Session | Same as OpenBookLogin - all reads are dirty reads |
| No login audit record | Behavioral | INSERT into History.LoginOpenBook is commented out; no login event is persisted |
| @Password declared but unused | Code smell | @Password is declared but set to itself (@Password = @Password in SELECT) and never used for validation |

---

## 8. Sample Queries

### 8.1 Check customer profile that would be returned by this procedure

```sql
SELECT CID, PrivacyPolicyID, UserName, PlayerLevelID, SerialID AS AffiliateID, GCID,
       IsReal, IP, OriginalCID, ProviderID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678
```

### 8.2 Determine first-login status for a CID

```sql
SELECT
    CASE WHEN NOT EXISTS (SELECT 1 FROM History.Login WITH (NOLOCK) WHERE CID = 12345678)
              AND NOT EXISTS (SELECT 1 FROM History.LoginOpenBook WITH (NOLOCK) WHERE CID = 12345678)
         THEN 1 ELSE 0 END AS IsFirstLogin
```

### 8.3 Check recent OpenBook logins (from History.OpenBookLogin path, since this proc does not write)

```sql
SELECT TOP 5 CID, LoggedIn, IP, ClientVersion, ClientTypeID
FROM History.LoginOpenBook WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY LoggedIn DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.7/10 (Elements: 8.5/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (OpenBookLogin for comparison) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OpenBookLoginWithCID | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.OpenBookLoginWithCID.sql*
