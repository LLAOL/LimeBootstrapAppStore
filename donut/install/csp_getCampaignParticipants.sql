/****** Object:  StoredProcedure [dbo].[csp_getParticipants]    Script Date: 6.8.2014 16:58:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<ILE>
-- Create date: <2014-08-06>
-- Description:	<Used to return participant info for donut>
-- =============================================
CREATE PROCEDURE [dbo].[csp_getParticipants]
		@@lang nvarchar(5),
		@@idcampaign INT
AS
BEGIN
	-- FLAG_EXTERNALACCESS --
	
	DECLARE @lang nvarchar(5)
	set @lang = @@lang
	--CORRECT LANGUAGE BUG
	IF @lang = N'en-us'
		SET @lang = N'en_us'
		
	select dbo.lfn_getstring2(p.participantstatus,@lang) as [participantstatus],
	COUNT(p.idparticipant) as [counter] 
	from participant p
	inner join string s on s.idstring = p.participantstatus
	where campaign = @@idcampaign
	group by p.participantstatus
	FOR XML RAW ('value'), TYPE, ROOT ('participants')	
	
	
END