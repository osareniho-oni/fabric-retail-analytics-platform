CREATE TABLE [fact].[Absence] (

	[AbsenceKey] bigint IDENTITY NOT NULL, 
	[DateKey] int NOT NULL, 
	[EmployeeKey] bigint NOT NULL, 
	[StoreKey] bigint NOT NULL, 
	[AbsenceCategoryKey] bigint NOT NULL, 
	[AbsentHours] int NOT NULL, 
	[AbsenceCount] int NULL
);



GO

ALTER TABLE [fact].[Absence] ADD CONSTRAINT PK_Absence primary key NONCLUSTERED ([AbsenceKey]);

GO

ALTER TABLE [fact].[Absence] ADD CONSTRAINT FK_Absence_Category FOREIGN KEY ([AbsenceCategoryKey]) REFERENCES [dim].[AbsentCategory]([CategoryKey]);

GO

ALTER TABLE [fact].[Absence] ADD CONSTRAINT FK_Absence_Date FOREIGN KEY ([DateKey]) REFERENCES [dim].[Date]([DateKey]);

GO

ALTER TABLE [fact].[Absence] ADD CONSTRAINT FK_Absence_Employee FOREIGN KEY ([EmployeeKey]) REFERENCES [dim].[Employee]([EmployeeKey]);

GO

ALTER TABLE [fact].[Absence] ADD CONSTRAINT FK_Absence_Store FOREIGN KEY ([StoreKey]) REFERENCES [dim].[Store]([StoreKey]);