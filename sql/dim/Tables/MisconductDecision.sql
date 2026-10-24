CREATE TABLE [dim].[MisconductDecision] (

	[DecisionKey] bigint IDENTITY NOT NULL, 
	[DecisionID] int NOT NULL, 
	[DecisionName] varchar(50) NOT NULL
);



GO

ALTER TABLE [dim].[MisconductDecision] ADD CONSTRAINT PK_MisconductDecision primary key NONCLUSTERED ([DecisionKey]);