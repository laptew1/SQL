USE [EVM]
GO
/****** Object:  StoredProcedure [dbo].[reader_AsyncExecQueue]    Script Date: 10.03.2022 16:52:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   procedure [dbo].[reader_AsyncExecQueue]
as
begin

	SET DATEFORMAT ymd;

    set nocount on;
    declare @h uniqueidentifier
        , @messageTypeName sysname
        , @messageBody varbinary(max)
        , @xactState smallint
		, @trancount int;
	
    begin try;
	WAITFOR( 
        receive top(1) 
            @h = [conversation_handle]
            , @messageTypeName = [message_type_name]
            , @messageBody = [message_body]
            from AsyncExecQueue),TIMEOUT 180000;


        if (@h is not null)
			exec [dbo].[async_reliser] @h,@messageTypeName, @messageBody

      --  commit;

    end try
    begin catch

        declare @error int
            , @message nvarchar(2048);
        select @error = ERROR_NUMBER()
            , @message = ERROR_MESSAGE()
            , @xactState = XACT_STATE();
        if (@xactState <> 0)
        begin
            rollback;
        end;

       raiserror(N'Error: %i, %s', 1, 60,  @error, @message);
    end catch
end

