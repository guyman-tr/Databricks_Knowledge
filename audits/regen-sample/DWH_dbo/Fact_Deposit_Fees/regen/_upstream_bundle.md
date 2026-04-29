# Pre-Resolved Upstream Bundle for `DWH_dbo.Fact_Deposit_Fees`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `DWH_dbo.Fact_Deposit_Fees.sql`

```sql
CREATE TABLE [DWH_dbo].[Fact_Deposit_Fees]
(
	[CID] [int] NULL,
	[DepositStatus] [nvarchar](max) NULL,
	[Threedsresponse] [nvarchar](max) NULL,
	[DepositRiskStatus] [nvarchar](max) NULL,
	[DepositAmount] [decimal](38, 18) NULL,
	[Currency] [nvarchar](max) NULL,
	[StatusModificationTime] [datetime2](7) NULL,
	[ModificationDateID] [int] NULL,
	[DepositTime] [datetime2](7) NULL,
	[FirstApprovedTime] [datetime2](7) NULL,
	[DepositValueDate] [datetime2](7) NULL,
	[DepositCollarAmount] [decimal](38, 18) NULL,
	[FundingMethod] [nvarchar](max) NULL,
	[Depot] [nvarchar](max) NULL,
	[OldPaymentID] [int] NULL,
	[DepositID] [int] NULL,
	[TransactionID_Internal] [nvarchar](max) NULL,
	[CountryByRegIP] [nvarchar](max) NULL,
	[Riskstatus] [nvarchar](max) NULL,
	[FTD] [nvarchar](max) NULL,
	[BaseExchangeRate] [decimal](38, 18) NULL,
	[ExchangeRate] [decimal](38, 18) NULL,
	[FeeinPIPs] [int] NULL,
	[PIPsinUSD] [decimal](38, 18) NULL,
	[CustomerStatus] [nvarchar](max) NULL,
	[Brand] [nvarchar](max) NULL,
	[CardCategory] [nvarchar](max) NULL,
	[PaymentDetails] [nvarchar](max) NULL,
	[FundingID] [int] NULL,
	[ResponseCode] [nvarchar](max) NULL,
	[TransactionResponse] [nvarchar](max) NULL,
	[CustomerLevel] [nvarchar](max) NULL,
	[AccountManager] [nvarchar](max) NULL,
	[TotalRollbackDollarAmount] [decimal](38, 18) NULL,
	[TotalRollbackAmount] [decimal](38, 18) NULL,
	[RollbackReason] [nvarchar](max) NULL,
	[UserName] [nvarchar](max) NULL,
	[AffiliateID] [int] NULL,
	[ExternalTransactionID] [nvarchar](max) NULL,
	[Funnel] [nvarchar](max) NULL,
	[Regulation] [nvarchar](max) NULL,
	[WhiteLabel] [nvarchar](max) NULL,
	[DepositType] [nvarchar](max) NULL,
	[Threedsparameters] [nvarchar](max) NULL,
	[MIDName] [nvarchar](max) NULL,
	[MID] [nvarchar](max) NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[CID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Writer / Source SP Code

These are stored procedures referenced in the lineage. Their source is included verbatim so the writer can ground column transformations and computed values directly without re-reading the SSDT.


### SP `DWH_dbo.SP_Fact_Deposit_Fees_DL_To_Synapse`
- **Path**: `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Fact_Deposit_Fees_DL_To_Synapse.sql`

```sql
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DWH_dbo].[SP_Fact_Deposit_Fees_DL_To_Synapse] @dt [Date] AS
BEGIN
-- EXEC [DWH_dbo].[SP_Fact_Deposit_Fees_DL_To_Synapse] '2023-07-22'
--declare @dt as date = '2020-01-01'
  DECLARE @CurrentDate as DATETIME
  DECLARE @Yesterday as DATETIME

  SET @Yesterday = CAST(@dt as DATETIME);
  SET @CurrentDate = DATEADD(DAY, 1 ,@Yesterday);
  

----------------------------- delete rows --------------------------
	/*DELETE FROM [DWH_dbo].[Fact_Deposit_Fees]
	WHERE ModificationDateID >= convert(INT,convert(varchar, @Yesterday ,112))
	and ModificationDateID < convert(INT,convert(varchar, @CurrentDate ,112))*/

--------------------------------------------------------------------
	
	INSERT INTO [DWH_dbo].[Fact_Deposit_Fees]
           ([CID], 
			[DepositStatus], 
			[Threedsresponse], 
			[DepositRiskStatus], 
			[DepositAmount], 
			[Currency], 
			[StatusModificationTime], 
			[DepositTime], 
			[FirstApprovedTime], 
			[DepositValueDate], 
			[DepositCollarAmount], 
			[FundingMethod], 
			[Depot], 
			[OldPaymentID], 
			[DepositID], 
			[TransactionID_Internal], 
			[CountryByRegIP], 
			[Riskstatus], 
			[FTD], 
			[BaseExchangeRate], 
			[ExchangeRate], 
			[FeeinPIPs], 
			[PIPsinUSD], 
			[CustomerStatus], 
			[Brand], 
			[CardCategory], 
			[PaymentDetails], 
			[FundingID], 
			[ResponseCode], 
			[TransactionResponse], 
			[CustomerLevel], 
			[AccountManager], 
			[TotalRollbackDollarAmount], 
			[TotalRollbackAmount], 
			[RollbackReason], 
			[UserName], 
			[AffiliateID], 
			[ExternalTransactionID], 
			[Funnel], 
			[Regulation], 
			[WhiteLabel], 
			[DepositType], 
			[Threedsparameters], 
			[MIDName], 
			[MID],
            [ModificationDateID],
			[UpdateDate]
		   )
     SELECT 
		    [CID], 
			[DepositStatus], 
			[Threedsresponse], 
			[DepositRiskStatus], 
			[DepositAmount], 
			[Currency], 
			[StatusModificationTime], 
			[DepositTime], 
			[FirstApprovedTime], 
			[DepositValueDate], 
			[DepositCollarAmount], 
			[FundingMethod], 
			[Depot], 
			[OldPaymentID], 
			[DepositID], 
			[TransactionID_Internal], 
			[CountryByRegIP], 
			[Riskstatus], 
			[FTD], 
			[BaseExchangeRate], 
			[ExchangeRate], 
			[FeeinPIPs], 
			[PIPsinUSD], 
			[CustomerStatus], 
			[Brand], 
			[CardCategory], 
			[PaymentDetails], 
			[FundingID], 
			[ResponseCode], 
			[TransactionResponse], 
			[CustomerLevel], 
			[AccountManager], 
			[TotalRollbackDollarAmount], 
			[TotalRollbackAmount], 
			[RollbackReason], 
			[UserName], 
			[AffiliateID], 
			[ExternalTransactionID], 
			[Funnel], 
			[Regulation], 
			[WhiteLabel], 
			[DepositType], 
			[Threedsparameters], 
			[MIDName], 
			[MID],
			convert(int,convert(varchar,dateadd(day,datediff(day,0,StatusModificationTime),0),112)) as ModificationDateID,
			getdate() as UpdateDate
FROM [DWH_staging].[etoro_BackOffice_BillingDepositsPCIVersion]
--WHERE StatusModificationTime >= @Yesterday AND StatusModificationTime < dateadd(day,1, @CurrentDate)
--------------------------------------------------------------------
/*
select *
from [DWH_staging].[etoro_BackOffice_BillingDepositsPCIVersion]

select *
from [DWH_dbo].[Fact_Deposit_Fees]
WHERE ModificationDateID = 20230721

*/
--------------------------------------------------------------------
END

GO

```

---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
| `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees` | unresolved | dwh | gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees | `—` |
| `BackOffice.BillingDepositsPCIVersion` | unresolved | BackOffice | BillingDepositsPCIVersion | `—` |
| `DWH_dbo.SP_Fact_Deposit_Fees_DL_To_Synapse` | synapse_sp | DWH_dbo | SP_Fact_Deposit_Fees_DL_To_Synapse | `c:\Users\guyman\Documents\github\DataPlatform\SynapseSQLPool1\sql_dp_prod_we\DWH_dbo\Stored Procedures\DWH_dbo.SP_Fact_Deposit_Fees_DL_To_Synapse.sql` |
| `DWH_staging.etoro_BackOffice_BillingDepositsPCIVersion` | unresolved | DWH_staging | etoro_BackOffice_BillingDepositsPCIVersion | `—` |
