CREATE TABLE [dim].[Time] (

	[TimeKey] int NOT NULL, 
	[TimeHour] int NOT NULL, 
	[DayPeriodOfDay] varchar(15) NOT NULL, 
	[TimeStatus] varchar(20) NOT NULL
);



GO

ALTER TABLE [dim].[Time] ADD CONSTRAINT PK_Time primary key NONCLUSTERED ([TimeKey]);