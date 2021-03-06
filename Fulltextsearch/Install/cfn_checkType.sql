USE [limebootstrap_aas]
GO
/****** Object:  UserDefinedFunction [dbo].[cfn_checkType]    Script Date: 2015-04-02 10:15:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
ALTER FUNCTION [dbo].[cfn_checkType]
(
	@searchString  nvarchar(4000)
)
RETURNS nvarchar(10)
AS
BEGIN
	
	declare @and as nvarchar(10)
	declare @or as nvarchar(10)
	declare @and_char as nvarchar(10)	
	declare @return as nvarchar(10)

	set @and = ' AND '
	set @or = ' OR '
	set @and_char = ' && '		

	if charindex(@and,@searchString) != 0 	
	begin 
		SET @return = @and
	end
	
	else if charindex(@or,@searchString) != 0 
	begin
		SET @return = @or
	end
	
	else if charindex(@and_char,@searchString) != 0
	begin 
		SET @return = @and_char
	end 	
	
	RETURN @RETURN
END
