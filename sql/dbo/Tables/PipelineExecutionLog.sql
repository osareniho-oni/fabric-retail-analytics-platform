CREATE TABLE [dbo].[PipelineExecutionLog] (

	[AuditId] bigint IDENTITY NOT NULL, 
	[MasterRunId] varchar(100) NOT NULL, 
	[ChildRunId] varchar(100) NULL, 
	[Layer] varchar(20) NOT NULL, 
	[SourceEntity] varchar(128) NOT NULL, 
	[TargetEntity] varchar(128) NOT NULL, 
	[RowsRead] bigint NULL, 
	[RowsWritten] bigint NULL, 
	[Status] varchar(20) NOT NULL, 
	[ErrorMessage] varchar(max) NULL, 
	[LogTime] datetime2(6) NOT NULL
);



GO

ALTER TABLE [dbo].[PipelineExecutionLog] ADD CONSTRAINT PK_PipelineExecutionLog primary key NONCLUSTERED ([AuditId]);