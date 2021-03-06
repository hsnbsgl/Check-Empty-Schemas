SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- List and drop empty schemas  
-- @argDBName = NULL List all Databases
-- @argDropSchemas = 1 Drop Schema 
-- @argDropSchemas = 0 Just List
-- EXEC dbo.[spCheck_Empty_Schemas] NULL,0
-- =============================================

ALTER PROCEDURE [dbo].[spCheck_Empty_Schemas]
(@argDBName VARCHAR(128)=NULL,@argDropSchemas TINYINT=0)
AS
BEGIN
		
	SET NOCOUNT ON
  
	DECLARE @tblSchemas TABLE (DBName VARCHAR(128),SchemaName VARCHAR(128))

	DECLARE @lcSQL VARCHAR(MAX)
	DECLARE @lcDB_Name VARCHAR(128)
	DECLARE @lcSchemaName VARCHAR(128)

	DECLARE curDBs CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT name FROM sys.databases WHERE name=ISNULL(@argDBName,name) ORDER BY name

	OPEN curDBs 
	FETCH NEXT FROM curDBs INTO @lcDB_Name
	WHILE @@FETCH_STATUS=0
	BEGIN
		
		SET @lcSQL='USE ' + QUOTENAME(@lcDB_Name) + '; 
					SELECT DISTINCT ' + '''' + @lcDB_Name + '''' + ',S.name FROM sys.schemas S
					LEFT JOIN sys.database_principals P ON P.principal_id=s.principal_id
					WHERE S.schema_id NOT IN ( SELECT schema_id FROM sys.objects )AND ISNULL(p.type,'''')<>''R''
					AND S.Name NOT IN (''dbo'',''guest'',''INFORMATION_SCHEMA'',''sys'')
					'


		INSERT INTO @tblSchemas
		EXEC (@lcSQL)

		FETCH NEXT FROM curDBs INTO @lcDB_Name
	END
	CLOSE curDBs
	DEALLOCATE curDBs

	-- DROP ?
	IF ISNULL(@argDropSchemas,0)=1 
	BEGIN  		
		DECLARE curSchemas CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
		SELECT DBName,SchemaName FROM @tblSchemas ORDER BY DBName,SchemaName

		OPEN curSchemas 
		FETCH NEXT FROM curSchemas INTO @lcDB_Name,@lcSchemaName
		WHILE @@FETCH_STATUS=0
		BEGIN
							
			SET @lcSQL='USE ' + QUOTENAME(@lcDB_Name) + ';' +
					   'DROP SCHEMA ' + QUOTENAME(@lcSchemaName) 
			 
			EXEC (@lcSQL)			

			PRINT 'Schema Dropped: '+ QUOTENAME(@lcDB_Name) + ' - ' + QUOTENAME(@lcSchemaName)

			FETCH NEXT FROM curSchemas INTO @lcDB_Name,@lcSchemaName
		END
		CLOSE curSchemas
		DEALLOCATE curSchemas
	END

	SELECT * FROM @tblSchemas

END



