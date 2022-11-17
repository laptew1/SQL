/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
SELECT TOP (1000) [id]
      ,[dadd]
      ,[name]
      ,[queue]
      ,[service]
      ,[a]
  FROM [EVM].[dbo].[event]