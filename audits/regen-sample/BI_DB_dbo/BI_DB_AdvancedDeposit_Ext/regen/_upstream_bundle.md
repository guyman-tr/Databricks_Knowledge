# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_AdvancedDeposit_Ext`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_AdvancedDeposit_Ext.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_AdvancedDeposit_Ext]
(
	[DepositID] [bigint] NULL,
	[CID] [int] NULL,
	[FundingID] [bigint] NULL,
	[FundingType] [varchar](50) NULL,
	[CurrencyID] [bigint] NULL,
	[PaymentStatusID] [bigint] NULL,
	[ManagerID] [bigint] NULL,
	[RiskManagementStatusID] [bigint] NULL,
	[Amount] [money] NULL,
	[ExchangeRate] [numeric](16, 8) NULL,
	[ModificationDate] [datetime] NULL,
	[TransactionID] [varchar](6) NULL,
	[IPAddress] [numeric](18, 0) NULL,
	[Approved] [bit] NULL,
	[Commission] [money] NULL,
	[PaymentDate] [datetime] NULL,
	[ClearingHouseEffectiveDate] [datetime] NULL,
	[OldPaymentID] [bigint] NULL,
	[IsFTD] [bit] NULL,
	[ProcessorValueDate] [datetime] NULL,
	[RefundVerificationCode] [varchar](50) NULL,
	[DepotID] [bigint] NULL,
	[MatchStatusID] [bigint] NULL,
	[FunnelID] [bigint] NULL,
	[Code] [varchar](50) NULL,
	[ExTransactionID] [varchar](50) NULL,
	[PaymentStatus_PaymentStatusID] [bigint] NULL,
	[PaymentStatus_Name] [varchar](50) NULL,
	[RiskManagementStatus_RiskManagementStatusID] [bigint] NULL,
	[RiskManagementStatus_Name] [varchar](50) NULL,
	[Channel] [nvarchar](50) NULL,
	[SubChannel] [varchar](100) NULL,
	[Region] [varchar](50) NULL,
	[Country] [varchar](50) NULL,
	[FirstDepositAttempt] [datetime] NULL,
	[FirstDepositDate] [datetime] NULL,
	[Registered] [datetime] NULL,
	[SerialID] [bigint] NULL,
	[Funnel] [varchar](50) NULL,
	[FunnelFrom] [varchar](50) NULL,
	[AcquisitionFunnel] [varchar](50) NULL,
	[BinCode] [bigint] NULL,
	[CreditCardType] [varchar](50) NULL,
	[CardSubType] [varchar](50) NULL,
	[BINCountry] [varchar](50) NULL,
	[DepoName] [varchar](50) NULL,
	[CardCategory] [varchar](50) NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	HEAP
)

GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
