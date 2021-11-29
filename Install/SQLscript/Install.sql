USE [test]
GO

/****** Object:  UserDefinedTableType [dbo].[StockType]    Script Date: 29/11/2021 01:09:06 ******/
DROP TYPE [dbo].[StockType]
GO

/****** Object:  UserDefinedTableType [dbo].[StockType]    Script Date: 29/11/2021 01:09:06 ******/
CREATE TYPE [dbo].[StockType] AS TABLE(
	[ID] [int] NOT NULL,
	[ProductCode] [char](3) NOT NULL,
	[Level] [int] NOT NULL
)
GO

USE [test]
GO

/****** Object:  StoredProcedure [dbo].[Updatestock]    Script Date: 29/11/2021 01:09:24 ******/
DROP PROCEDURE [dbo].[Updatestock]
GO

/****** Object:  StoredProcedure [dbo].[Updatestock]    Script Date: 29/11/2021 01:09:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Updatestock] 
@vwarehouse as int ,
@vStockinfo as dbo.[Stocktype] readonly,  
@vResponseXML  as varchar(max) OUTPUT
AS
SET NOCOUNT ON;
BEGIN
    Declare @vQty Int;
	Declare @vProductId int;
	DECLARE @vCnt int = 1;
	DECLARE @vMax int;
	Declare @vMessage nvarchar (max);
	Declare @vEmailadr nvarchar(50);
	Declare @vSourceWarehouse int;
	SET NOCOUNT ON;
	SET @vResponseXML = '<UpdateResults>';
	select @vMax = count(*) from @vStockinfo;
	WHILE @vCnt <= @vMax
	
	Begin
         select @vQty = S.Level ,@vProductId = isnull ((select p.ProductId from Products P where P.ProductCode = S.ProductCode),0) from @vStockinfo S
		 where S.ID = @vCnt;
		 if @vQty > -1
		   Begin
			 Update Stock set Level = @Vqty where WarehouseId = @vwarehouse and ProductId = @vProductId;
			 IF @@ROWCOUNT = 0
			   Begin
			      SET @vResponseXML = @vResponseXML + 
				  '<UpdateResult>'
				  + '<ID>' 
      			  +  Convert(Varchar(10),@vCnt)        
				  + '</ID>'
				  + '<Status>' 
				  +  'Failure'      
				  + '</Status>'

				  + '<Message>' 
				  +  'Warehouse or Product not set up'      
				  + '</Message>'
				  +
		          '</UpdateResult>';
			    End	
			  else 
			    Begin
			      SET @vResponseXML = @vResponseXML + 
				  '<UpdateResult>'
				  + '<ID>' 
				  +  Convert(Varchar(10),@vCnt)        
				  + '</ID>'
				  + '<Status>' 
				  +  'Pass'      
				  + '</Status>'
				  + '<Message>' 
				  +  'OK'      
				  + '</Message>'
				  +
		          '</UpdateResult>';
			  End	
			  
		   End
		   else

		   Begin
		   Select top (1) 
		   @vEmailadr =CASE
			when s.WarehouseId = 1 then  'Malawi@Beltway.com'
			when s.WarehouseId = 2 then 'Malawi@Beltway.com'
			END  , @vMessage = concat('Please move ',cast( 0-@vQty as  char(10)),P.ProductCode,'-', p.ProductDescription,' from ' ,W.WarehouseName,' to ',w1.WarehouseName) from stock S 
		   join warehouses W on S.WarehouseId = w.WarehouseId
		   Join warehouses W1 on @vwarehouse = w1.WarehouseId
		   join Products p  on S.ProductId = P.ProductId
		   
            where s.productid = @vProductId and s.Level > 0-@vQty and s.WarehouseId != @vwarehouse
			order by level desc
			
	    	IF @@ROWCOUNT = 0
			begin
			      SET @vResponseXML = @vResponseXML + 
				  '<UpdateResult>'
				  + '<ID>' 
      			  +  Convert(Varchar(10),@vCnt)        
				  + '</ID>'
				  + '<Status>' 
				  +  'Mail Sent Error'      
				  + '</Status>'
				  + '<Message>' 
				  +  'No warehouse available to transfer stock'     
				  + '</Message>'
				  +'<emailto>'
				  +'Error@Beltway.com'
				  +'</emailto>' 

				  + '</UpdateResult>';
end
else
			      Begin
				  SET @vResponseXML = @vResponseXML + 
				  '<UpdateResult>'
				  + '<ID>' 
      			  +  Convert(Varchar(10),@vCnt)        
				  + '</ID>'
				  + '<Status>' 
				  +  'Mail Sent'      
				  + '</Status>'

				  + '<Message>' 
				  +  @vMessage      
				  + '</Message>'
				  +'<emailto>'
				  +@vEmailadr
				  +'</emailto>' 

				  +'</UpdateResult>';
				  End;

		   End;	

 	     set @vCnt = @vCnt+1; 
    End
	SET @vResponseXML = @vResponseXML + 
		'</UpdateResults>'; 
END
GO

