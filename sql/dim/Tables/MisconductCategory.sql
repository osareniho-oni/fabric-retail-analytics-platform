CREATE TABLE [dim].[MisconductCategory] (

	[CategoryKey] bigint IDENTITY NOT NULL, 
	[CategoryID] int NOT NULL, 
	[CategoryName] varchar(50) NOT NULL
);



GO

ALTER TABLE [dim].[MisconductCategory] ADD CONSTRAINT PK_MisconductCategory primary key NONCLUSTERED ([CategoryKey]);