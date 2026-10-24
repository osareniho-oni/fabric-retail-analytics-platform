CREATE TABLE [fact].[Misconduct] (

	[MisconductKey] bigint IDENTITY NOT NULL, 
	[DateKey] int NOT NULL, 
	[EmployeeKey] bigint NOT NULL, 
	[StoreKey] bigint NOT NULL, 
	[MisconductCategoryKey] bigint NOT NULL, 
	[DecisionKey] bigint NOT NULL, 
	[IncidentCount] int NULL
);



GO

ALTER TABLE [fact].[Misconduct] ADD CONSTRAINT PK_Misconduct primary key NONCLUSTERED ([MisconductKey]);

GO

ALTER TABLE [fact].[Misconduct] ADD CONSTRAINT FK_Misconduct_Category FOREIGN KEY ([MisconductCategoryKey]) REFERENCES [dim].[MisconductCategory]([CategoryKey]);

GO

ALTER TABLE [fact].[Misconduct] ADD CONSTRAINT FK_Misconduct_Date FOREIGN KEY ([DateKey]) REFERENCES [dim].[Date]([DateKey]);

GO

ALTER TABLE [fact].[Misconduct] ADD CONSTRAINT FK_Misconduct_Decision FOREIGN KEY ([DecisionKey]) REFERENCES [dim].[MisconductDecision]([DecisionKey]);

GO

ALTER TABLE [fact].[Misconduct] ADD CONSTRAINT FK_Misconduct_Employee FOREIGN KEY ([EmployeeKey]) REFERENCES [dim].[Employee]([EmployeeKey]);

GO

ALTER TABLE [fact].[Misconduct] ADD CONSTRAINT FK_Misconduct_Store FOREIGN KEY ([StoreKey]) REFERENCES [dim].[Store]([StoreKey]);