-- Create Pipeline Audit Log table for failure logging

-- CREATE TABLE dbo.PipelineExecutionLog (
--     AuditId         BIGINT IDENTITY,
--     MasterRunId     VARCHAR(100) NOT NULL, -- Parent (Master) Pipeline Run ID
--     ChildRunId      VARCHAR(100) NULL,     -- Sub-pipeline or Copy Job Run ID
--     Layer           VARCHAR(20)  NOT NULL, -- 'Bronze', 'Silver', 'Gold'
--     SourceEntity    VARCHAR(128) NOT NULL, -- Source table or file name
--     TargetEntity    VARCHAR(128) NOT NULL, -- Destination table/file name
--     RowsRead        BIGINT NULL,
--     RowsWritten     BIGINT NULL,
--     Status          VARCHAR(20)  NOT NULL, -- 'Success', 'Failed'
--     ErrorMessage    VARCHAR(MAX) NULL,
--     LogTime         DATETIME2(6) NOT NULL
-- );
-- ALTER TABLE dbo.PipelineExecutionLog
--     ADD CONSTRAINT PK_PipelineExecutionLog
--     PRIMARY KEY NONCLUSTERED (AuditId) NOT ENFORCED;
-- GO

CREATE   PROCEDURE dbo.sp_WritePipelineAudit
    @MasterRunId   VARCHAR(100),
    @ChildRunId    VARCHAR(100) = NULL,
    @Layer         VARCHAR(20),
    @SourceEntity  VARCHAR(128),
    @TargetEntity  VARCHAR(128),
    @RowsRead      BIGINT = NULL,
    @RowsWritten   BIGINT = NULL,
    @Status        VARCHAR(20),
    @ErrorMessage  VARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.PipelineExecutionLog (
        MasterRunId,
        ChildRunId,
        Layer,
        SourceEntity,
        TargetEntity,
        RowsRead,
        RowsWritten,
        Status,
        ErrorMessage,
        LogTime
    )
    VALUES (
        @MasterRunId,
        @ChildRunId,
        @Layer,
        @SourceEntity,
        @TargetEntity,
        @RowsRead,
        @RowsWritten,
        @Status,
        @ErrorMessage,
        CAST(SYSDATETIMEOFFSET() AT TIME ZONE 'Mountain Standard Time' AS DATETIME2)
    );
END;