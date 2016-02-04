-- Written by: Fredrik Eriksson
-- Created: 2015-11-05

-- Returns xml with information needed to draw a board.
ALTER PROCEDURE [dbo].[csp_embrello_getboard]
	@@tablename NVARCHAR(64)
	, @@lanefieldname NVARCHAR(64)
	, @@titlefieldname NVARCHAR(64)
	, @@additionalinfofieldname NVARCHAR(64) = N''
	, @@completionfieldname NVARCHAR(64) = N''
	, @@sumfieldname NVARCHAR(64) = N''
	, @@valuefieldname NVARCHAR(64) = N''
	, @@sortfieldname NVARCHAR(64) = N''
	, @@ownerrelationfieldname NVARCHAR(64)
	, @@ownerrelatedtablename NVARCHAR(64)
	, @@ownerdescriptivefieldname NVARCHAR(64)
	, @@idrecords NVARCHAR(MAX)
	, @@lang NVARCHAR(5)
	, @@limeservername NVARCHAR(64)
	, @@limedbname NVARCHAR(64)
AS
BEGIN

	-- FLAG_EXTERNALACCESS --
	
	-- Fix en-us, make it en_us
	SET @@lang = REPLACE(@@lang, N'-', N'_')
	
	-- Get idcategory for option field for lanes
	DECLARE @idcategory INT
	SELECT @idcategory = ad.value
	FROM field f
	INNER JOIN [table] t
		ON t.idtable = f.idtable
	INNER JOIN attributedata ad
		ON ad.idrecord = f.idfield
	WHERE t.name = @@tablename
		AND f.name = @@lanefieldname
		AND ad.[owner] = N'field'
		AND ad.name = N'idcategory'
	
	IF @idcategory IS NULL
	BEGIN
		RETURN
	END
	
	-- Build string with dynamic SQL
	DECLARE @sql NVARCHAR(MAX)
	
	SET @sql = N'SELECT *' + CHAR(10)
	SET @sql = @sql + N'FROM' + CHAR(10)
	SET @sql = @sql + N'(' + CHAR(10)
	
	-- Get lanes
	SET @sql = @sql + N'	SELECT 1 AS Tag' + CHAR(10)
	SET @sql = @sql + N'		, NULL AS Parent' + CHAR(10)
	SET @sql = @sql + N'		, s.[stringorder] AS [Lanes!1!order]' + CHAR(10)
	SET @sql = @sql + N'		, s.[idstring] AS [Lanes!1!id]' + CHAR(10)
	SET @sql = @sql + N'		, s.[key] AS [Lanes!1!key]' + CHAR(10)
	SET @sql = @sql + N'		, s.[' + @@lang + N'] AS [Lanes!1!name]' + CHAR(10)
	SET @sql = @sql + N'		, NULL AS [Cards!2!title]' + CHAR(10)
	
	IF @@additionalinfofieldname <> N''
	BEGIN
		SET @sql = @sql + N'		, NULL AS [Cards!2!additionalInfo]' + CHAR(10)
	END
	
	IF @@completionfieldname <> N''
	BEGIN
		SET @sql = @sql + N'		, NULL AS [Cards!2!completionRate]' + CHAR(10)
	END
	
	IF @@sumfieldname <> N''
	BEGIN
		SET @sql = @sql + N'		, NULL AS [Cards!2!sumValue]' + CHAR(10)
	END
	
	IF @@valuefieldname <> N''
	BEGIN
		SET @sql = @sql + N'		, NULL AS [Cards!2!value]' + CHAR(10)
	END
	
	IF @@sortfieldname <> N''
	BEGIN
		SET @sql = @sql + N'		, NULL AS [Cards!2!sortValue]' + CHAR(10)
	END
	
	SET @sql = @sql + N'		, NULL AS [Cards!2!owner]' + CHAR(10)
	SET @sql = @sql + N'		, NULL AS [Cards!2!link]' + CHAR(10)
	SET @sql = @sql + N'	FROM string s' + CHAR(10)
	SET @sql = @sql + N'	WHERE idcategory = ' + CONVERT(NVARCHAR(20), @idcategory) + CHAR(10)
	SET @sql = @sql + N'		AND s.[' + @@lang + N'] <> N''''' + CHAR(10)

	-- Get cards
	SET @sql = @sql + N'	UNION ALL' + CHAR(10)
	SET @sql = @sql + N'	SELECT 2 AS Tag' + CHAR(10)
	SET @sql = @sql + N'		, 1 AS Parent' + CHAR(10)
	SET @sql = @sql + N'		, s.stringorder AS [Lanes!1!order]' + CHAR(10)
	SET @sql = @sql + N'		, NULL AS [Lanes!1!id]' + CHAR(10)
	SET @sql = @sql + N'		, NULL AS [Lanes!1!key]' + CHAR(10)
	SET @sql = @sql + N'		, NULL AS [Lanes!1!name]' + CHAR(10)
	SET @sql = @sql + N'		, A1.[' + @@titlefieldname + N'] AS [Cards!2!title]' + CHAR(10)
	
	IF @@additionalinfofieldname <> N''
	BEGIN
		SET @sql = @sql + N'		, A1.[' + @@additionalinfofieldname + N'] AS [Cards!2!additionalInfo]' + CHAR(10)
	END
	
	IF @@completionfieldname <> N''
	BEGIN
		SET @sql = @sql + N'		, CONVERT(NVARCHAR(32), A1.[' + @@completionfieldname + N']) AS [Cards!2!completionRate]' + CHAR(10)
	END
	
	IF @@sumfieldname <> N''
	BEGIN
		SET @sql = @sql + N'		, A1.[' + @@sumfieldname + N'] AS [Cards!2!sumValue]' + CHAR(10)
	END
	
	IF @@valuefieldname <> N''
	BEGIN
		SET @sql = @sql + N'		, A1.[' + @@valuefieldname + N'] AS [Cards!2!value]' + CHAR(10)
	END
	
	IF @@sortfieldname <> N''
	BEGIN
		SET @sql = @sql + N'		, A1.[' + @@sortfieldname + N'] AS [Cards!2!sortValue]' + CHAR(10)
	END
	
	SET @sql = @sql + N'		, A2.[' + @@ownerdescriptivefieldname + '] AS [Cards!2!owner]' + CHAR(10)
	SET @sql = @sql + N'		, N''limecrm:' + @@tablename + N'.' + @@limedbname + '.' + @@limeservername + '?'' + CONVERT(NVARCHAR(20), A1.[id' + @@tablename + N']) AS [Cards!2!link]' + CHAR(10)
	SET @sql = @sql + N'	FROM [' + @@tablename + N'] A1' + CHAR(10)
	SET @sql = @sql + N'	INNER JOIN [dbo].[cfn_gettablefromstring](@@idrecords, N'';'') ids' + CHAR(10)
	SET @sql = @sql + N'		ON ids.value = A1.[id' + @@tablename + N']' + CHAR(10)
	SET @sql = @sql + N'	INNER JOIN string s' + CHAR(10)
	SET @sql = @sql + N'		ON s.idstring = A1.[' + @@lanefieldname + N']' + CHAR(10)
	SET @sql = @sql + N'	LEFT JOIN [' + @@ownerrelatedtablename + N'] A2' + CHAR(10)
	SET @sql = @sql + N'		ON A2.[id' + @@ownerrelatedtablename + N'] = A1.[' + @@ownerrelationfieldname + N']' + CHAR(10)
	SET @sql = @sql + N'	WHERE s.[' + @@lang + N'] <> N''''' + CHAR(10)
	SET @sql = @sql + N') t' + CHAR(10)
	SET @sql = @sql + N'ORDER BY t.[Lanes!1!order] ASC, t.Tag ASC' + CHAR(10)
	SET @sql = @sql + N'FOR XML EXPLICIT' + CHAR(10)
	
	-- Run SQL code to get XML that will be returned to LIME Pro VBA.
	EXEC sp_executesql
		@sql
		, N'@@idrecords NVARCHAR(MAX)'
		, @@idrecords
END