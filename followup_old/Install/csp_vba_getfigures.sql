
/****** Object:  StoredProcedure [dbo].[csp_vba_getfigures]    Script Date: 2015-04-21 10:27:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		MOL (Lundalogik)
-- Create date: 2015-03-11
-- Description:	Used to return XML to client for LBS-app
-- Updated by AOL(Lundalogik)
-- =============================================
create PROCEDURE [dbo].[csp_vba_getfigures]
    @@targettype nvarchar(40) ,
    @@historytype nvarchar(40) ,
    @@idcoworker INT = NULL,
	@@lang NVARCHAR(5)
AS
    BEGIN
	-- FLAG_EXTERNALACCESS --
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;


        DECLARE @start DATETIME
        DECLARE @end DATETIME
        DECLARE @now DATETIME
        DECLARE @networkingdays INT
        DECLARE @monthnetworkingdays INT
        DECLARE @outcomecoworker BIGINT
        DECLARE @outcometotal BIGINT
        DECLARE @budgetcoworker BIGINT
        DECLARE @budgettotal BIGINT
		DECLARE @historytext NVARCHAR(20)
		DECLARE @idhistory INT
		DECLARE @idtarget INT
		
 
 -- SET MONDAY AS FIRST DAY (Saturday & Sunday is 6 & 7)
        SET DATEFIRST 1
 
        SELECT  @now = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0) ,   -- GET TODAY
                @start = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) -- GET THE FIRST DAY IN CURRENT MONTH
        SELECT  @end = DATEADD(DAY, -1, DATEADD(MONTH, 1, @start)) -- GET THE LAST DAY IN CURRENT MONTH
	
-- GET IDSTRING FROM KEY	
	SET @idhistory =	(SELECT [idstring]
						FROM [string] WHERE [key] = @@historytype AND idcategory = (SELECT [value] FROM [attributedata] WHERE [name] = 'idcategory' AND [idrecord] 
						IN (SELECT [idfield] FROM [field] WHERE [name] = 'type' AND [idtable] = (SELECT [idtable] FROM [table] WHERE [name] = 'history'))))
	
	SET @idtarget =		(SELECT [idstring]
						FROM [string] WHERE [key] = @@targettype AND idcategory = (SELECT [value] FROM [attributedata] WHERE [name] = 'idcategory' AND [idrecord] 
						IN (SELECT [idfield] FROM [field] WHERE [name] = 'targettype' AND [idtable] = (SELECT [idtable] FROM [table] WHERE [name] = 'target'))))


-- GET TEXT FROM HISTORY
	IF(@@lang = 'sv')
		SET @historytext = (SELECT s.sv from string s where s.idstring = @idhistory)
	ELSE IF(@@lang = 'en_us')
		SET @historytext = (SELECT s.en_us from string s where s.idstring = @idhistory)
	ELSE IF(@@lang = 'fi')
		SET @historytext = (SELECT s.fi from string s where s.idstring = @idhistory)
	ELSE IF(@@lang = 'no')
		SET @historytext = (SELECT s.[no] from string s where s.idstring = @idhistory)
	ELSE
		SET @historytext = (SELECT s.en_us from string s where s.idstring = @idhistory)


-- GET ALL COWORKERS WITH TARGET
        DECLARE @coworkerwithtarget TABLE
            (
              [idcoworker] INT ,
              [targetvalue] BIGINT
            )
        INSERT  INTO @coworkerwithtarget
                ( idcoworker ,
                  targetvalue
                )
                SELECT  c.[idcoworker] ,
                        SUM(ISNULL(t.[targetvalue], 0))
                FROM    [dbo].[target] t
                        INNER JOIN [dbo].[coworker] c ON t.[coworker] = c.[idcoworker]
                                                         AND c.[status] = 0
                WHERE   t.[status] = 0
                        AND t.[targettype] = @idtarget
                        AND t.[targetdate] >= @start
                        AND t.[targetdate] <= @end
                        AND t.[coworker] IS NOT NULL
                GROUP BY c.[idcoworker]
							
-- GET OUTCOME            
        SELECT  @outcometotal = COUNT(h.[idhistory]) ,
                @outcomecoworker = SUM(CASE WHEN h.[coworker] = @@idcoworker
                                            THEN 1
                                            ELSE 0
                                       END)
        FROM    [dbo].[history] h
                INNER JOIN @coworkerwithtarget t ON t.[idcoworker] = h.[coworker]
        WHERE   h.[status] = 0
                AND h.[date] >= @start
                AND h.[date] <= @end
                AND h.[type] = @idhistory
                AND h.[coworker] IS NOT NULL
					 
-- GET TARGET					 
        SELECT  @budgettotal = SUM(t.targetvalue) ,
                @budgetcoworker = SUM(CASE WHEN t.[idcoworker] = @@idcoworker
                                           THEN t.targetvalue
                                           ELSE 0
                                      END)
        FROM    @coworkerwithtarget t
-- GET NETWORKINGDAYS		
		;WITH    CTE_DateRange ( [date], [dayno] )
                      AS ( SELECT   @start ,
                                    DATEPART(DW, @start)
                           UNION ALL
                           SELECT   DATEADD(DAY, 1, [date]) ,
                                    DATEPART(DW, DATEADD(DAY, 1, [date]))
                           FROM     CTE_DateRange
                           WHERE    [date] < @end
                         )
            

                    SELECT  @networkingdays = SUM(CASE WHEN DATEDIFF(DAY,
                                                              [date], @now) >= 0
                                                       THEN 1
                                                       ELSE 0
                                                  END) ,
                            @monthnetworkingdays = COUNT(1)
                    FROM    CTE_DateRange
                    WHERE   [dayno] < 6
                    	
	-- RETURN XML RESULT
        SELECT  ( SELECT    ISNULL(@outcometotal, 0) AS [outcome] ,
                            ISNULL(CAST(ROUND(CAST(@budgettotal AS FLOAT)
                                              * CAST(@networkingdays AS FLOAT)
                                              / CAST(@monthnetworkingdays AS FLOAT),
                                              0) AS BIGINT), 0) AS [targetnow] ,
                            ISNULL(@budgettotal, 0) AS [target]
                FOR
                  XML RAW('value') ,
                      TYPE ,
                      ROOT('all')
                ) ,
                ( SELECT    ISNULL(@outcomecoworker, 0) AS [outcome] ,
                            ISNULL(CAST(ROUND(CAST(@budgetcoworker AS FLOAT)
                                              * CAST(@networkingdays AS FLOAT)
                                              / CAST(@monthnetworkingdays AS FLOAT),
                                              0) AS BIGINT), 0) AS [targetnow] ,
                            ISNULL(@budgetcoworker, 0) AS [target]
                FOR
                  XML RAW('value') ,
                      TYPE ,
                      ROOT('coworker')
                ),
				(SELECT @historytext as displaytext
				FOR
					XML RAW('value'),
					TYPE,
					ROOT('displaytext')
				)
        FOR     XML PATH('') ,
                    TYPE ,
                    ROOT('followup');	

    END