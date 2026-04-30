# Wallet.VerifyAddressNotKnownBadAML

> Checks if a blockchain address has any previous negative AML screening decisions, returning 1 if flagged or 0 if clean, used by the AML service as a quick historical risk check before processing transactions.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1/0 based on AmlValidations.IsPositiveDecision history |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs a quick historical AML risk check for a blockchain address. The AML service calls this before processing a transaction to check if the address has ever had a negative screening decision (IsPositiveDecision=0) in the AmlValidations table. Returns 1 if any negative decisions exist (address is known-bad), 0 if the address has no negative history. This is distinct from the blacklist checks (IsAddressInReciverBlackList/SenderBlackList) which check a separate curated blacklist.

---

## 2. Business Logic

### 2.1 Historical Negative Decision Check

**What**: Checks if an address has ANY previous negative AML screening result.

**Rules**:
- COUNT(*) FROM AmlValidations WHERE Address = @Address AND IsPositiveDecision = 0
- If count > 0: returns 1 (known-bad, has been flagged before)
- If count = 0: returns 0 (no negative history)
- Checks ALL historical validations, not just the most recent

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Address | nvarchar(512) | NO | - | VERIFIED | Blockchain address to check against AML history. |
| 2 | (result) | int | NO | - | CODE-BACKED | 1 = address has previous negative AML decisions, 0 = clean history. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Address | Wallet.AmlValidations.Address | COUNT | Historical negative check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser | - | EXECUTE | Pre-transaction AML risk check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.VerifyAddressNotKnownBadAML (procedure)
+-- Wallet.AmlValidations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AmlValidations | Table | Historical negative decision check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if address is known-bad
```sql
EXEC Wallet.VerifyAddressNotKnownBadAML @Address = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';
-- Returns 1 if any negative AML decision exists, 0 if clean
```

### 8.2 Full AML check suite
```sql
-- Blacklist checks (curated list):
EXEC Wallet.IsAddressInSenderBlackList @Address = '1A1zP1eP5...';
EXEC Wallet.IsAddressInReciverBlackList @Address = '1A1zP1eP5...';
-- Historical AML check (this SP):
EXEC Wallet.VerifyAddressNotKnownBadAML @Address = '1A1zP1eP5...';
```

### 8.3 Direct equivalent
```sql
DECLARE @Result INT;
SELECT @Result = COUNT(*) FROM Wallet.AmlValidations WHERE Address = '1A1zP1eP5...' AND IsPositiveDecision = 0;
IF @Result > 0 SELECT 1 ELSE SELECT 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.VerifyAddressNotKnownBadAML | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.VerifyAddressNotKnownBadAML.sql*
