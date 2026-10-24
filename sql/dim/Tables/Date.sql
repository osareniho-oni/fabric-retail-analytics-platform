CREATE TABLE [dim].[Date] (

	[DateKey] int NOT NULL, 
	[FullDate] date NOT NULL, 
	[Year] int NOT NULL, 
	[Quarter] int NOT NULL, 
	[Month] int NOT NULL, 
	[MonthName] varchar(10) NOT NULL, 
	[Day] int NOT NULL, 
	[DayOfWeek] int NOT NULL, 
	[DayName] varchar(10) NOT NULL, 
	[QuarterName] varchar(2) NOT NULL, 
	[YearQuarter] varchar(7) NOT NULL, 
	[DayType] varchar(20) NULL
);



GO

ALTER TABLE [dim].[Date] ADD CONSTRAINT PK_Date primary key NONCLUSTERED ([DateKey]);