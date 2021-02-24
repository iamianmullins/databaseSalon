use jenssalon;

/**********PRIVILEGES AND USERS************/
create user AreaManager identified by 'secret';
create user Finance identified by 'secret';
create user GenUser identified by 'secret';


GRANT ALL on jenssalon.* to AreaManager with grant option;
GRANT insert, select on jenssalon.* to Finance;
GRANT update, delete on fulltimeemployee to Finance;
GRANT update, delete on parttimeemployee to Finance;
GRANT update, delete on product to Finance;
GRANT select on appointment to GenUser;
GRANT select on appointmentuses to GenUser;
GRANT select on branch to GenUser;
GRANT select on customer to GenUser;
GRANT select on product to GenUser;
GRANT select on productpricechangelog to GenUser;
GRANT select on supplier to GenUser;
GRANT select on workson to GenUser;

GRANT select on customerappointmentvw to GenUser;
GRANT select on empfamilyvw to GenUser;
GRANT insert(appointmentTime, appointmentDate,service), 
update(appointmentTime, appointmentDate,service) on appointment to GenUser;
GRANT insert(appointmentTime, appointmentDate,service),update(appointmentTime, appointmentDate,service) on appointment to GenUser;
/************************************/

/***************USEFUL SCRIPTS******************/
-- Search for specific Column in DB
SELECT DISTINCT COLUMN_NAME, TABLE_NAME 
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE COLUMN_NAME like ('%app%')
    and TABLE_SCHEMA = 'jenssalon'
    order by COLUMN_NAME asc;
/***********************************************/


/***************SELECT SCRIPTS******************/
-- Returns part time employee hours, rate of pay and gross earnings Month to date
SELECT employeeId as'Employee Id',  concat(fname," ",lName) as 'Employee Name',
contactNumber as'Employee phone', position as'Position', hourlyRate as'Hourly Rate',
(sum(duration)/60) as 'Hours worked', (hourlyRate*(sum(duration)/60)) as 'Gross Earnings MTD'
from ptEmpHoursVw;

-- View all full time employees and related pay data with constraints for position and salary
select employeeId as'Employee Id', concat(fname," ",lName) as 'Employee Name',
contactNumber as 'Employee Phone', position as 'Position', salary as 'Salary'
from employeeVw
where position in ('Stylist', 'Manager')
Having salary <22000
order by fname;

-- Returns all employees with a salary greater than the average employee salary
SELECT concat(fname," ",lName) as 'Employee Name', salary as 'Salary', position as 'Position'
FROM employee 
natural join fulltimeemployee 
WHERE salary > ALL 
                  (SELECT avg(salary) 
                   FROM fulltimeemployee);

-- Family members and discount rate allowed                  
Select employeeId as 'Employee Id', concat(fname," ",lName) as 'Employee Name', 
contactNumber as 'Employee Phone', position as 'Position', 
concat(cusfName," ",cuslName) as 'Family Member Name', 
cuslContact  as 'Family Member Phone', relationship as 'Relationship', 
discountRate as 'Discount Rate'
from empfamilyvw;

--  Return all appointments with customer data, service, employee and branch related to each appointment at a specific branch
Select appointmentDate as 'Appointment Date', appointmentTime as 'Appointment Time', 
service as 'Service', concat(customerFName," ",customerLName) as 'Customer Name', 
contactNumber as'Customer Phone', duration as 'Duration', 
concat(employeeFName," ",employeeLName) as 'Customer Name',town as 'Branch'
from customerAppointmentVw
where town ='Ferrybank'
-- and appointmentDate <= CURDATE()
and appointmentDate >= CURDATE()
order by appointmentDate asc,appointmentDate asc;

-- Returns busiest times of day YTD up to TODAY to allow for more efficient staffing
select distinct
	CASE 
		WHEN DAYOFWEEK(appointmentDate) = 1 THEN "SUN"
		WHEN DAYOFWEEK(appointmentDate) = 2 THEN "MON"
		WHEN DAYOFWEEK(appointmentDate) = 3 THEN "TUE"    
		WHEN DAYOFWEEK(appointmentDate) = 4 THEN "WED"
		WHEN DAYOFWEEK(appointmentDate) = 5 THEN "THU"
		WHEN DAYOFWEEK(appointmentDate) = 6 THEN "FRI"    
		WHEN DAYOFWEEK(appointmentDate) = 7 THEN "SAT"
    END as'Day',
    appointmentTime as 'Appointment Time',
    count(appointmentTime) as Count
 from customerAppointmentVw
	 where (appointmentDate between  DATE_FORMAT(NOW() ,'%Y-%01-01') AND LAST_DAY(NOW()))
	 group by appointmentTime
	 order by Count desc
     limit 5;
 
 -- Returns latest booked appointment date
SELECT distinct appointmentDate as 'Next Appointment Date', 
appointmentTime as 'Appointment time', concat(fname," ",lName) as 'Customer Name', contactNumber as 'Customer Phone'
FROM appointment natural join customer
	WHERE appointmentDate = 
		(SELECT max(appointmentDate) 
		FROM appointment)
        order by appointmentDate asc, appointmentTime asc;
        
-- Returns booked appointments date and time and customer details
SELECT distinct appointmentDate as 'Next Appointment Date', 
appointmentTime as 'Appointment time', concat(fname," ",lName) as 'Customer Name', contactNumber as 'Customer Phone'
FROM appointment natural join customer
	WHERE appointmentDate = 
		(SELECT min(appointmentDate) 
		FROM appointment)
        order by appointmentDate asc, appointmentTime asc;
        

-- Search for a customer by name
Select customerId as 'Customer Id', concat(fname," ",lName) as 'Customer Name', 
contactNumber as 'Customer Phone' 
from customer 
	where fName like ('am%');


-- Returns amount of product scheduled for usage in appointments in the coming month
-- also the amount in stock and supplier info to order more
Select count(prod.productid) as 'Scheduled Product Usage', description as 'Product Description', 
stockQuantity as 'Quantity in Stock', unitcost as 'Unit cost', 
companyName as 'Supplier Name', contactNumber as 'Supplier Phone', 
emailAddress as 'Supplier Email'
from product prod
	left join appointmentuses aptuse on aptuse.productid = prod.productid
	left join supplier supl on supl.supplierId = prod.supplierId
	left join appointment apt on apt.appointmentId = aptuse.appointmentId
	WHERE appointmentDate >= date_add(CURDATE(), INTERVAL +1 MONTH)
	group by description
	order by stockQuantity asc;

/***********************************************/




/***************UPDATE SCRIPTS******************/
--  !!!!!!!!!!!!!STORED PROCEDURES!!!!!!!!!!! -- Queries can be found in salon DDL File

-- Change in ALL product prices use 1.1 for 10% INSCREASE. 0.9 for 10% DECREASE
CAll productPriceChangeSp(0.9);

-- Change an employee hourly rate using employee id (employeeId, newRate)
CAll ptEmpRateChangeSp(14, 12.50);

-- Change an employee salary using employee id (employeeId, newSalary)
CALL ftEmpSalChangeSp(1, 31900.00);

/***********************************************/



/***************UPDATE LOGS******************/
-- Part time employee hourly rate changes Log
select id as 'Log Id', employeeId as 'Employee Id', previoushourlyrate as 'Previous Rate', 
changeDate as 'Change Date', action as 'Action' 
from PTEmpRateChangeLog
order by changeDate desc, previousHourlyRate asc;

-- Full time employee salary changes Log
select  id as 'Log Id', employeeId as 'Employee Id', previousSalary as 'Previous Rate', 
changeDate as 'Change Date', action as 'Action' 
from FTEmpSalaryChangeLog
order by changeDate desc, previousSalary asc;

-- Product price change log
select id as 'Log Id', productId as 'Product Id', lastpricechange as 'Previous Price',
changeDate as 'Change Date', action as 'Action'
from productPriceChangeLOG
order by changeDate desc, lastPriceChange desc, unitCostOld desc;
/***********************************************/



























