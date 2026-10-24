CREATE TABLE [fact].[Overtime] (

	[OvertimeKey] bigint IDENTITY NOT NULL, 
	[OvertimeID] int NOT NULL, 
	[StartDateKey] int NOT NULL, 
	[StartHourKey] int NOT NULL, 
	[EndDateKey] int NOT NULL, 
	[EndHourKey] int NOT NULL, 
	[EmployeeKey] bigint NOT NULL, 
	[OvertimeHours] decimal(10,2) NULL
);



GO

ALTER TABLE [fact].[Overtime] ADD CONSTRAINT PK_Overtime primary key NONCLUSTERED ([OvertimeKey]);

GO

ALTER TABLE [fact].[Overtime] ADD CONSTRAINT FK_Overtime_Employee FOREIGN KEY ([EmployeeKey]) REFERENCES [dim].[Employee]([EmployeeKey]);

GO

ALTER TABLE [fact].[Overtime] ADD CONSTRAINT FK_Overtime_EndDate FOREIGN KEY ([EndDateKey]) REFERENCES [dim].[Date]([DateKey]);

GO

ALTER TABLE [fact].[Overtime] ADD CONSTRAINT FK_Overtime_EndHour FOREIGN KEY ([EndHourKey]) REFERENCES [dim].[Time]([TimeKey]);

GO

ALTER TABLE [fact].[Overtime] ADD CONSTRAINT FK_Overtime_StartDate FOREIGN KEY ([StartDateKey]) REFERENCES [dim].[Date]([DateKey]);

GO

ALTER TABLE [fact].[Overtime] ADD CONSTRAINT FK_Overtime_StartHour FOREIGN KEY ([StartHourKey]) REFERENCES [dim].[Time]([TimeKey]);