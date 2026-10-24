CREATE TABLE [dim].[AbsentCategory] (

	[CategoryKey] bigint IDENTITY NOT NULL, 
	[CategoryID] int NOT NULL, 
	[CategoryName] varchar(50) NOT NULL
);



GO

ALTER TABLE [dim].[AbsentCategory] ADD CONSTRAINT PK_AbsentCategory primary key NONCLUSTERED ([CategoryKey]);