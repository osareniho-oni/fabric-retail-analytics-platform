CREATE TABLE [dbo].[FactLoadControl] (

	[TargetEntity] varchar(255) NOT NULL, 
	[LastCompletedBusinessDate] date NULL, 
	[LastSuccessfulRunId] varchar(100) NULL, 
	[UpdatedAt] datetime2(0) NOT NULL
);



GO

ALTER TABLE [dbo].[FactLoadControl] ADD CONSTRAINT PK_FactLoadControl primary key NONCLUSTERED ([TargetEntity]);