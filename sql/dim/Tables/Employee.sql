CREATE TABLE [dim].[Employee] (

	[EmployeeKey] bigint IDENTITY NOT NULL, 
	[EmployeeID] int NOT NULL, 
	[EmployeeNumber] varchar(50) NOT NULL, 
	[EmployeeName] varchar(100) NOT NULL, 
	[DateOfBirth] date NOT NULL, 
	[MaritalStatus] varchar(50) NOT NULL, 
	[ValidFrom] datetime2(0) NOT NULL, 
	[ValidTo] datetime2(0) NULL, 
	[IsCurrent] bit NOT NULL
);



GO

ALTER TABLE [dim].[Employee] ADD CONSTRAINT PK_Employee primary key NONCLUSTERED ([EmployeeKey]);