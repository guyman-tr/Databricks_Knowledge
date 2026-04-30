# Wallet.InsertScreeningValidation

> Records a compliance screening result for a crypto transaction, capturing the screening provider's decision, person details, and transaction context for AML/KYT audit.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.ScreeningValidations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a compliance screening (KYT/AML) validation result for a crypto transaction. When the wallet platform screens a transaction (send or receive) against compliance providers, the result is persisted here. The eligibility and wallet middleware services call this to maintain an audit trail of all screening decisions - including positive (approved), negative (flagged), and error cases.

Each record captures: the screening provider's case ID and result, whether it's a positive decision, whether it's a final status, transaction correlation, customer Gcid, direction (send/receive), person information, blockchain hash, and any error message.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct INSERT into ScreeningValidations with all parameters. Default @Created to GETUTCDATE() if not provided. TRY/CATCH with THROW for error propagation.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ScreeningCaseId | nvarchar(255) | YES | NULL | CODE-BACKED | Screening provider's case reference ID. |
| 2 | @ScreeningResult | nvarchar(50) | YES | NULL | CODE-BACKED | Provider's result classification (e.g., 'Pass', 'Flag', 'Block'). |
| 3 | @IsPositiveDecision | bit | NO | - | VERIFIED | 1=approved/positive, 0=flagged/negative. |
| 4 | @FinalStatus | bit | YES | 0 | CODE-BACKED | Whether this is the final screening decision. 0=interim. |
| 5 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Business correlation ID linking to the transaction request. |
| 6 | @Gcid | bigint | NO | - | VERIFIED | Customer screened. |
| 7 | @IsSend | bit | YES | 1 | CODE-BACKED | Transaction direction: 1=send (outbound), 0=receive (inbound). |
| 8 | @Created | datetime2 | YES | GETUTCDATE() | CODE-BACKED | Screening timestamp. Defaults to current UTC time. |
| 9 | @FirstName | nvarchar(255) | YES | NULL | CODE-BACKED | Screened person's first name. |
| 10 | @LastName | nvarchar(255) | YES | NULL | CODE-BACKED | Screened person's last name. |
| 11 | @BlockchainTransactionId | nvarchar(500) | YES | NULL | CODE-BACKED | On-chain hash of the screened transaction. |
| 12 | @ErrorMessage | nvarchar(max) | YES | NULL | CODE-BACKED | Error details if the screening itself failed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.ScreeningValidations | INSERT | Screening audit record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| EligibilityUser | - | EXECUTE | Eligibility screening results |
| WalletMiddlewareUser | - | EXECUTE | Middleware screening results |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertScreeningValidation (procedure)
+-- Wallet.ScreeningValidations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ScreeningValidations | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| EligibilityUser, WalletMiddlewareUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a positive screening
```sql
EXEC Wallet.InsertScreeningValidation @IsPositiveDecision=1, @CorrelationId='GUID', @Gcid=30351701, @ScreeningCaseId='CASE-123', @ScreeningResult='Pass', @FinalStatus=1;
```

### 8.2 Record a flagged screening
```sql
EXEC Wallet.InsertScreeningValidation @IsPositiveDecision=0, @CorrelationId='GUID', @Gcid=30351701, @ScreeningResult='Flag', @BlockchainTransactionId='0xabc...';
```

### 8.3 Check screening history for a customer
```sql
SELECT * FROM Wallet.ScreeningValidations WITH (NOLOCK) WHERE Gcid = 30351701 ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertScreeningValidation | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertScreeningValidation.sql*
