create database energy_company1;
use energy_company1;
show tables;

Select * from customers;
select * from energy_consumption;
select * from energy_production;
select * from production_plants;
select * from sustainability_initiatives;

----Carbon Emission Plant

select pp.plant_name, pp.location, (sum(ep.carbon_emission_kg)/sum(ep.amount_kwh)) as avg_carbon_emission_per_kwh
from production_plants pp
join energy_production ep on pp.plant_id=ep.production_plant_id
group by pp.plant_name, pp.location
order by avg_carbon_emission_per_kwh desc
limit 5;

----Top 3 Performing Initiative

select initiative_name, start_date, end_date, 
sum(energy_savings_kwh) as energy_savings_kwh
from sustainability_initiatives
group by initiative_name, start_date, end_date
order by energy_savings_kwh desc
limit 3;

----consumption trend

select production_id, production_plant_id, date, energy_type, amount_kwh,
sum(amount_kwh) over(partition by energy_type) as total_energy_by_type
from energy_production;

---Ranking Production Amounts

select production_id, production_plant_id, date, energy_type, amount_kwh,
rank() over (order by amount_kwh desc) as rank_within_type
from energy_production;

---Cumulative Consumption

select consumption_id, customer_id, date, energy_type, amount_kwh,
sum(amount_kwh) over (partition by customer_id order by date) as cumulative_consumption
from energy_consumption;

----Monthly Energy Changes

with cte as
(
    select production_plant_id, 
    date_format(date, '%Y-%m-01') as month, 
    sum(amount_kwh) as current_month_production
    from energy_production
    group by production_plant_id, month
)
select production_plant_id, month, current_month_production,
lag(current_month_production) over (partition by production_plant_id order by month) as previous_month_production,
lead(current_month_production) over (partition by production_plant_id order by month) next_month_production
from cte
order by production_plant_id, month;

----Highest 3  Production

select * from energy_production;

with cte as
(
    select production_plant_id, energy_type, date, amount_kwh,
    row_number() over (partition by energy_type order by amount_kwh desc) as ranking
    from energy_production
)

select production_plant_id, energy_type, date, amount_kwh
from cte
where ranking<=3
order by energy_type, ranking;

----Average Monthly Production 

with cte as
(
    select production_plant_id, date_format(date, '%Y-%m') as month,
    avg(amount_kwh)as avg_monthly_production
    from energy_production
    group by production_plant_id, month
    )

select production_plant_id, month, avg_monthly_production,
rank() over (partition by month order by avg_monthly_production desc) as ranking
from cte
order by month, ranking ;

---High Performing Initiatives

select initiative_name, start_date, end_date, energy_savings_kwh,
dense_rank() over (order by energy_savings_kwh desc) as initiative_rank
from sustainability_initiatives
order by initiative_rank;


---Monthly Changes 

with cte as 
(
    select production_plant_id, date_format(date,'%Y-%m') as month,
    sum(amount_kwh) as current_month_production
    from energy_production
    group by production_plant_id, month
)
select production_plant_id, month, current_month_production,
lag(current_month_production) over (partition by production_plant_id order by month asc) as previous_month_production,
lead(current_month_production) over (partition by production_plant_id order by month asc) as next_month_production
from cte;   

----Energy Consumption

with monthlyconsumption as 
(
  select ec.customer_id, 
  date_format(ec.date,'%Y-%m') as month, 
  sum(ec.amount_kwh) as monthly_consumption
  from energy_consumption ec
  group by ec.customer_id, month
)
select mc.customer_id, c.name, sum(mc.monthly_consumption) as total_consumption, 
avg(mc.monthly_consumption) as avg_monthly_consumption
from monthlyconsumption mc
join customers c  on c.customer_id=mc.customer_id
group by mc.customer_id, c.name
order by mc.customer_id;

----Energy Savings

with monthlysavings as
(
    select initiative_id, initiative_name, date_format(start_date,'%Y-%m') as month,
    energy_savings_kwh/ timestampdiff(month, start_date, end_date) as monthly_savings
    from sustainability_initiatives
    where end_date is not null
)
select initiative_id, initiative_name, 
sum(monthly_savings) as total_savings,
avg(monthly_savings) as avg_monthly_savings
from monthlysavings
group by initiative_id, initiative_name
order by initiative_id;
