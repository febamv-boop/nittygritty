Select * from dbo.DIM_CUSTOMER
Select * from dbo.DIM_DATE
Select * from dbo.DIM_LOCATION 
Select * from dbo.DIM_MODEL
Select * from DIM_MANUFACTURER
Select * from FACT_TRANSACTIONS

--1.	List all the states in which we have customers who have bought cellphones from 2005 till today

Select distinct l.[State] from  DIM_DATE d inner join FACT_TRANSACTIONS f on d.Date=f.Date 
                inner join DIM_LOCATION l on f.IDLocation=l.IDLocation
Where d.YEAR >='2005'
 
 --2. What state in the US is buying the most 'Samsung' cell phones?

 Select top 1 [state] from DIM_LOCATION l 
 inner join FACT_TRANSACTIONS f on l.IDLocation=f.IDLocation
 inner join DIM_MODEL mo on f.IDModel=mo.IDModel 
 inner join DIM_MANUFACTURER m on mo.IDManufacturer=m.IDManufacturer
 where Country='US' and Manufacturer_Name='Samsung'
 Group by [State]
 order by sum(Quantity)desc

--3. Show the number of transactions for each model per zip code per state.

 Select [State],zipcode,Model_Name,count( f.IDModel)[No.of transactions] from FACT_TRANSACTIONS f inner join DIM_LOCATION l on
        f.IDLocation=l.IDLocation inner join DIM_MODEL mo on f.IDModel=mo.IDModel
 group by [State],ZipCode,Model_Name

 --4.Show the cheapest cellphone (Output should contain the price also)

 Select top 1 Model_name,Unit_price from DIM_MODEL
 order by Unit_price 

 --5.	Find out the average price for each model in the top5 manufacturers in terms of sales quantity
 --     and order by average price.
  
  create view tab_manuf as
 (Select top 5  Manufacturer_Name,sum(Quantity)[Qty] from DIM_MODEL mo inner join  FACT_TRANSACTIONS f on
  mo.IDModel=f.IDModel inner join DIM_MANUFACTURER m on mo.IDManufacturer=m.IDManufacturer                  
  Group by Manufacturer_Name
  order by [Qty] desc)
  Select  mo.Model_Name,avg(totalprice)[Avg] from tab_manuf t inner join DIM_MANUFACTURER m on t.Manufacturer_Name=m.Manufacturer_Name
  inner join DIM_MODEL mo on m.IDManufacturer=mo.IDManufacturer inner join FACT_TRANSACTIONS f on mo.IDModel=f.IDModel
  group by t.Manufacturer_Name,mo.Model_Name
  order by [avg] desc

 --6.List the names of the customers and the average amount spent in 2009, where the average is higher than 500

 Select Customer_Name,avg(totalprice)[Average] from DIM_DATE d inner join FACT_TRANSACTIONS f on d.DATE=f.Date 
        inner join  DIM_CUSTOMER c on f.IDCustomer=c.IDCustomer
 where  d.YEAR='2009' 
 Group by Customer_Name
 having   avg(totalprice)>500

 --7.List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010
 
 Select Model_Name from DIM_MODEL mo inner join FACT_TRANSACTIONS f on mo.IDModel=f.IDModel
 where year(date)='2008'
 group by Model_Name
 having sum(Quantity) in(Select top 5 sum(Quantity) from FACT_TRANSACTIONS where year(date)='2008'  group by IDModel order by sum(Quantity) desc)
 intersect
 Select Model_Name from DIM_MODEL mo inner join FACT_TRANSACTIONS f on mo.IDModel=f.IDModel
 where year(date)='2009'
 group by Model_Name
 having sum(Quantity) in(Select top 5 sum(Quantity) from FACT_TRANSACTIONS where year(date)='2009' group by IDModel order by sum(Quantity) desc)
 intersect
 Select Model_Name from DIM_MODEL mo inner join FACT_TRANSACTIONS f on mo.IDModel=f.IDModel
 where year(date)='2010'
 group by Model_Name
 having sum(Quantity) in(Select top 5 sum(Quantity) from FACT_TRANSACTIONS where year(date)='2010' group by IDModel order by sum(Quantity) desc)
 
--8.Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer 
 -- with the 2nd top sales in the year of 2010.
  
  with rnk as
 (Select year(date)[Year],m.IDManufacturer,Manufacturer_Name ,rank() over( order by sum(TotalPrice) desc) as [Rank]
 from FACT_TRANSACTIONS f inner join DIM_MODEL m on f.IDModel=m.IDModel 
 inner join DIM_MANUFACTURER ma on m.IDManufacturer=ma.IDManufacturer
 where year(date) ='2009' 
 group by year(date),m.IDManufacturer,Manufacturer_Name
 union all
 Select year(date)[Year], m.IDManufacturer,Manufacturer_Name ,rank() over( order by sum(TotalPrice) desc) as [Rank]
 from FACT_TRANSACTIONS f inner join DIM_MODEL m on f.IDModel=m.IDModel 
 inner join DIM_MANUFACTURER ma on m.IDManufacturer=ma.IDManufacturer
 where year(date) ='2010' 
 group by year(date), m.IDManufacturer,Manufacturer_Name)
 Select year[Year],Manufacturer_Name from rnk
 where [Rank]=2

 --9.Show the manufacturers that sold cellphones in 2010 but did not in 2009.

 Select distinct mo.IDManufacturer,Manufacturer_Name from DIM_MANUFACTURER m inner join DIM_MODEL mo  on m.IDManufacturer=mo.IDManufacturer
 inner join FACT_TRANSACTIONS f on mo.IDModel=f.IDModel inner join DIM_DATE d on d.DATE=f.Date
 where [YEAR] in ('2009','2010')
 except
 (Select distinct mo.IDManufacturer,Manufacturer_Name from DIM_MANUFACTURER m inner join DIM_MODEL mo  on m.IDManufacturer=mo.IDManufacturer
 inner join FACT_TRANSACTIONS f on mo.IDModel=f.IDModel inner join DIM_DATE d on d.DATE=f.Date
 where [YEAR] ='2009')

 --10.Find top 100 customers and their average spend, average quantity by each year. 
 ---Also find the percentage of change in their spend.

 create view t as
 (Select top 100 f.IDCustomer, Customer_Name from DIM_CUSTOMER c inner join FACT_TRANSACTIONS f on c.IDCustomer=f.IDCustomer
 group by f.IDCustomer,Customer_Name
 order by sum(TotalPrice) desc)

 create view t1 as
 (Select Customer_Name,avg(TotalPrice)[Average spend],avg(Quantity)[Average quantity], sum(TotalPrice)[Total Spend],
 lag(sum (TotalPrice)) over(Partition by t.Customer_Name order by year(date))[lag]from FACT_TRANSACTIONS f inner join t
 on f.IDCustomer=t.IDCustomer
 Group by t.Customer_Name,year([date]))

 Select t.Customer_Name, [Average spend],[Average quantity],([Total Spend] - [lag])*100/[lag]
 [Percent change of spend] from t inner join t1 on   t.Customer_Name=t1.Customer_Name  

 

 