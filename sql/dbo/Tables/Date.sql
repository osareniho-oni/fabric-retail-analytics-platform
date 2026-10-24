CREATE TABLE [dbo].[Date] (

	[DateKey] bigint NULL, 
	[FullDate] date NULL, 
	[Year] bigint NULL, 
	[Quarter] bigint NULL, 
	[Month] bigint NULL, 
	[MonthName] varchar(8000) NULL, 
	[Day] bigint NULL, 
	[DayOfWeek] bigint NULL, 
	[DayName] varchar(8000) NULL, 
	[QuarterName] varchar(8000) NULL, 
	[YearQuarter] varchar(8000) NULL, 
	[DayType] varchar(8000) NULL
);