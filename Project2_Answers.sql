--Project 2


use AdventureWorks2019

--1 
-- Search the products that are not sold in the order list


select p.ProductID, p.Name, p.Color, p.ListPrice, p.Size
from Production.Product as p
LEFT JOIN sales.SalesOrderDetail as sod
ON sod.ProductID = p.ProductID
where sod.ProductID is null

--2 
-- List down the customers with number ID and their fullnames.

select c.CustomerID,
iif(p.LastName is not null,p.LastName,'unknown') as lastName,
iif(p.FirstName is not null,p.FirstName,'unknown') as FirstName
from Sales.Customer as c
LEFT JOIN sales.SalesOrderHeader as soh
on c.CustomerID = soh.CustomerID
LEFT JOIN Person.Person as p
on c.CustomerID = p.BusinessEntityID
where soh.SalesOrderID is null
order by c.CustomerID


--3
--Search the top 10 customers in maximum order numbers

select TOP 10 c.CustomerID, p.FirstName, p.LastName,
count(soh.SalesOrderID) as CountOfOrders
from Sales.SalesOrderHeader as soh
inner join Sales.Customer as c
on soh.CustomerID = c.CustomerID
inner join Person.Person as p
on c.PersonID = p.BusinessEntityID
group by c.CustomerID, p.FirstName, p.LastName
order by CountOfOrders desc

--4
--List down the information about the workers and their occupations

select p.FirstName, p.LastName, e.JobTitle, e.HireDate,
count(e.JobTitle) over(partition by e.JobTitle) as CountOfTitle
from Person.Person as p
inner join HumanResources.Employee as e
on p.BusinessEntityID = e.BusinessEntityID
group by p.FirstName, p.LastName, e.JobTitle, e.HireDate

--5
--Search all customers that have the last and the previous orders according to dates

WITH CTE_A 
as
(
select soh.SalesOrderID,soh.CustomerID,p.LastName,p.FirstName,
lead(soh.OrderDate,1)OVER(PARTITION BY soh.CustomerID ORDER BY soh.OrderDate desc) as PreviousOrder,
soh.OrderDate as LastOrder,
RANK()OVER(PARTITION BY soh.CustomerID Order By soh.OrderDate desc) as daterank
from Sales.SalesOrderHeader as soh
inner join Sales.Customer as c
on soh.CustomerID = c.CustomerID
inner join Person.Person as p
on c.PersonID = p.BusinessEntityID
)

SELECT ct.SalesOrderID,ct.CustomerID,ct.LastName,ct.FirstName, ct.LastOrder, ct.PreviousOrder
FROM CTE_A as ct
WHERE ct.daterank = 1

--6
-- Write down the customers that in total have the most expensive orders for each year 

WITH CTE_2011
AS
(
select TOP 1 YEAR(soh.OrderDate) as Year,soh.SalesOrderID, p.LastName, p.FirstName,
sum(sod.UnitPrice*(1-sod.UnitPriceDiscount)*sod.OrderQty)OVER(PARTITION BY soh.SalesOrderID) as Total
from sales.SalesOrderDetail as sod
inner join sales.SalesOrderHeader as soh
on sod.SalesOrderID=soh.SalesOrderID
inner join Sales.Customer as c
on soh.CustomerID = c.CustomerID
inner join Person.Person as p
on c.PersonID = p.BusinessEntityID
where YEAR(soh.OrderDate) = 2011
order by Total desc
),

CTE_2012
AS
(
select TOP 1 YEAR(soh.OrderDate) as Year,soh.SalesOrderID, p.LastName, p.FirstName,
sum(sod.UnitPrice*(1-sod.UnitPriceDiscount)*sod.OrderQty)OVER(PARTITION BY soh.SalesOrderID) as Total
from sales.SalesOrderDetail as sod
inner join sales.SalesOrderHeader as soh
on sod.SalesOrderID=soh.SalesOrderID
inner join Sales.Customer as c
on soh.CustomerID = c.CustomerID
inner join Person.Person as p
on c.PersonID = p.BusinessEntityID
where YEAR(soh.OrderDate) = 2012
order by Total desc
),

CTE_2013
AS
(
select TOP 1 YEAR(soh.OrderDate) as Year,soh.SalesOrderID, p.LastName, p.FirstName,
sum(sod.UnitPrice*(1-sod.UnitPriceDiscount)*sod.OrderQty)OVER(PARTITION BY soh.SalesOrderID) as Total
from sales.SalesOrderDetail as sod
inner join sales.SalesOrderHeader as soh
on sod.SalesOrderID=soh.SalesOrderID
inner join Sales.Customer as c
on soh.CustomerID = c.CustomerID
inner join Person.Person as p
on c.PersonID = p.BusinessEntityID
where YEAR(soh.OrderDate) = 2013
order by Total desc
),

CTE_2014
AS
(
select TOP 1 YEAR(soh.OrderDate) as Year,soh.SalesOrderID, p.LastName, p.FirstName,
sum(sod.UnitPrice*(1-sod.UnitPriceDiscount)*sod.OrderQty)OVER(PARTITION BY soh.SalesOrderID) as Total
from sales.SalesOrderDetail as sod
inner join sales.SalesOrderHeader as soh
on sod.SalesOrderID=soh.SalesOrderID
inner join Sales.Customer as c
on soh.CustomerID = c.CustomerID
inner join Person.Person as p
on c.PersonID = p.BusinessEntityID
where YEAR(soh.OrderDate) = 2014
order by Total desc
)

select * from CTE_2011
UNION
select * from CTE_2012
UNION
select * from CTE_2013
UNION
select * from CTE_2014

--7
--Find number of orders that finished according to all months of the years

select mm as Month, [2011] , [2012] , [2013] , [2014]
from (select year(soh.OrderDate) as yy, MONTH(soh.OrderDate) as mm,
 soh.SalesOrderID
 from sales.SalesOrderHeader as soh) as soh
 PIVOT(COUNT(SalesOrderID) for yy IN([2011],[2012],[2013],[2014])) as PVT
order by mm

--8
/* Write down the total price according to months and years, cumulatively add prices at the end of the month
 and calculate the grand total at the end of all years */ 

with order_total 
as 
(
select
cast(year(soh.orderdate) as varchar) as year,
cast(month(soh.orderdate) as varchar) as month,
sum(sod.unitprice * (1 - sod.unitpricediscount)) as Sum_Price
from sales.salesorderheader soh
inner join sales.salesorderdetail sod 
on soh.salesorderid = sod.salesorderid
group by month(soh.orderdate), year(soh.orderdate)
),

month_total 
as 
(
select year,month,sum(Sum_Price) as Sum_Price
from order_total
group by month, year
),

year_total 
as 
(
select year,sum(Sum_Price) as yeartotal
from month_total
group by year
),

cumulative_total 
as 
(
select year,month,Sum_Price,
sum(Sum_Price) over (partition by year order by cast(month as int) 
rows between unbounded preceding and current row) as CumSum
from month_total
),

grand_total 
as 
(
select year,null as month,null as sumtotal,  sum(CumSum) as CumSum
from cumulative_total
group by year
)

select 
 year,case when month is null then 'grand_total' else cast(month as varchar(2)) end as month,
 Sum_Price,CumSum
from ( select year,month,Sum_Price,CumSum
from cumulative_total
 union all
 select year,null as month,null as Sum_Price, sum(cumsum) as CumSum
from grand_total
group by year) as result
order by year, 
case when month = 'grand_total' then 13 else cast(month as int) 
end



--9
-- List down the employees according to the hire date in groups of each department in order to the new employees to the older ones 

select d.Name as DepartmentName, e.BusinessEntityID as EmployeeID, 
CONCAT(p.FirstName, ' ' , p.LastName) as Employee_FullName, e.HireDate,
DATEDIFF(MM,e.HireDate,GETDATE()) as Seniority, 
lead(CONCAT(p.FirstName, ' ' , p.LastName),1)OVER(PARTITION BY d.Name ORDER BY e.HireDate desc) as PreviousEmpName,
lead(e.HireDate,1)OVER(PARTITION BY d.Name ORDER BY e.HireDate desc) as PreviousEmpHireDate,
DATEDIFF(DD,lead(e.HireDate,1)OVER(PARTITION BY d.Name ORDER BY e.HireDate desc),e.HireDate) as DiffDays
from HumanResources.Employee as e
inner join HumanResources.EmployeeDepartmentHistory as edh
on e.BusinessEntityID = edh.BusinessEntityID
inner join HumanResources.Department as d
on edh.DepartmentID = d.DepartmentID
inner join Person.Person as p
on e.BusinessEntityID = p.BusinessEntityID
order by d.Name


--10
/* Write down the employees with the same hire date in one row seperated each one with comma
according to the hire dates in order to the newest to oldest */

select e.HireDate , edh.DepartmentID, 
STRING_AGG(CONCAT(e.BusinessEntityID,' ',p.LastName,' ',p.FirstName),',') as TeamEmployees
from HumanResources.Employee as e
inner join HumanResources.EmployeeDepartmentHistory as edh
on e.BusinessEntityID = edh.BusinessEntityID
inner join HumanResources.Department as d
on edh.DepartmentID = d.DepartmentID
inner join Person.Person as p
on e.BusinessEntityID = p.BusinessEntityID
where edh.EndDate is null
group by e.HireDate, edh.DepartmentID
order by e.HireDate desc












