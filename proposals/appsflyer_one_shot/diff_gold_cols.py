"""Diff the alter.sql column coverage against the live UC schema."""
import re, os
from pathlib import Path

ALTER = Path(__file__).resolve().parents[2] / "knowledge" / "synapse" / "Wiki" / "BI_DB_dbo" / "Tables" / "BI_DB_AppFlyer_Reports.alter.sql"

UC_COLS_89 = [
    "AttributedTouchType","AttributedTouchTime","InstallTime","Partner","MediaSource",
    "Channel","Keywords","Campaign","CampaignID","Adset","AdsetID","Ad","AdID","AdType",
    "SiteID","SubSiteID","SubParam1","SubParam2","SubParam3","SubParam4","SubParam5",
    "HTTPReferrer","OriginalURL","UserAgent","CostModel","CostValue","CostCurrency",
    "Contributor1Partner","Contributor1MediaSource","Contributor1Campaign",
    "Contributor1TouchType","Contributor1TouchTime","Contributor2Partner",
    "Contributor2MediaSource","Contributor2Campaign","Contributor2TouchType",
    "Contributor2TouchTime","Contributor3Partner","Contributor3MediaSource",
    "Contributor3Campaign","Contributor3TouchType","Contributor3TouchTime",
    "IsRetargeting","RetargetingConversionType","Region","CountryCode","State","City",
    "PostalCode","DMA","WIFI","Operator","Carrier","Language","AppsFlyerID",
    "AdvertisingID","IDFA","AndroidID","CustomerUserID","IMEI","IDFV","Platform",
    "DeviceType","OSVersion","AppVersion","SDKVersion","AppID","AppName","BundleID",
    "AttributionLookback","ReengagementWindow","IsPrimaryAttribution","EventTime",
    "EventName","EventValue","EventRevenue","EventRevenueCurrency","EventRevenueUSD",
    "EventSource","IsReceiptValidated","DateID","Date","EtoroAppID","EtoroAppName",
    "EtoroReport","UpdateDate","etr_y","etr_ym","etr_ymd",
]
print(f"UC total: {len(UC_COLS_89)} columns")

text = ALTER.read_text("utf-8")
covered = set(re.findall(r"ALTER COLUMN (\w+) COMMENT", text))
print(f"alter.sql covered: {len(covered)} columns")

missing = [c for c in UC_COLS_89 if c not in covered]
print(f"NOT covered ({len(missing)}): {missing}")
