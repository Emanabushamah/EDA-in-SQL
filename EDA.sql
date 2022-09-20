SELECT location, date, CAST(population AS float),total_cases, CAST(total_deaths AS float)
FROM coviddeaths 

--lets start with global numbers: 1.6% is the AVG death pct globally
SELECT SUM(CAST(total_cases AS float)) as totalcases, sum(CAST(total_deaths AS float)) as totaldeaths, 
(SUM(CAST(total_deaths AS float))/SUM(CAST(total_cases AS float)))*100 AS Gdeathpct
from coviddeaths 
WHERE continent is not null 
order by Gdeathpct DESC

--lets look at the continent level:
--I deleted these rwos because they are not continents and i don't want it in my analysis
DELETE FROM coviddeaths 
WHERE location IN ('Upper middle income', 'High income', 'Lower middle income', 'Low income', 'International', 'European Union')

SELECT location, SUM(total_cases) as casescount, SUM(CAST(total_deaths AS float)) as deathcount 
FROM coviddeaths 
WHERE continent is null 
group by location
order by deathcount DESC

--lets look at the infection rate in the population: Vatican
SELECT location, date, CAST(population AS float) as population, total_cases, 
(total_cases/cast(population as float))*100 as covidinfectionrate
FROM coviddeaths 
where continent is not null 
group by location
order by covidinfectionrate DESC

--Lets look at the death rate from covid cases in each country:
SELECT location, date, population, sum(CAST(total_deaths AS float)) as total_deaths,
AVG((CAST(total_deaths AS float)/population))*100 as coviddeathrate
from coviddeaths 
where continent is not null 
group by location
order by coviddeathrate DESC

--let's look at the suvival rate from covid:
--SELECT location, date, population, sum(total_cases), sum(CAST(total_deaths AS float)) as total_deaths, 
--round(((SUM(total_cases) - SUM(cast(total_deaths as float))/SUM(total_cases))*100,2)
--from coviddeaths
--where continent is not null 
--group by location

--let's look at how much countries were strict on AVG: Ireland, Lebanon, Venzuela
SELECT location, sum(total_cases), sum(total_deaths), ROUND(AVG(stringency_index),2)
from coviddeaths
where continent is not null
group by location
order by AVG(stringency_index) desc

--let's look at the highest infection rate: ANDORRA, Montenegro, Luxemborg//// highestinfectioncount: USA, India, Brazil

SELECT location, CAST(population AS float) as population, MAX(total_cases) as highestinfectioncount, MAX((total_cases/cast(population as float)))*100 as highestinfectionrate
FROM coviddeaths 
WHERE continent is not null and date not like "%/22"
group by location
order by 1,2



--lets look at the highest death rate from covid: (north korea is outlier) YEMEN,Vanuatu, Peru/// highestdeathcount: USA, Brazil, India

SELECT location, SUM(CAST(total_deaths AS float)) as highestdeathcount, (AVG(CAST(total_deaths AS float)/total_cases))*100 as deathpct
from coviddeaths
WHERE continent is not null and date not like "%/22"
group by location
order by 1,2


--deeper look in USA COVID cases:
SELECT location, date, CAST(population AS float),total_cases, CAST(total_deaths AS float)
FROM coviddeaths
where location = "United States"


--Avg cases:6.2% and AVG deaths:0.112%
SELECT location, population, MAX(total_cases), MAX(cast(total_deaths as float)), 
AVG(total_cases/cast(population as float))*100, AVG(cast(total_deaths as float)/cast(population as float))*100
FROM coviddeaths c 
WHERE location = "United States" and date not like "%/22"


SELECT location, date, MAX(total_cases), MAX(CAST(hosp_patients AS float)), AVG((cast(hosp_patients as float)/total_cases))*100
from coviddeaths
where location = "United States" and date not like "%/22"


SELECT location, date, MAX(total_cases), MAX(CAST(icu_patients AS float)), AVG((cast(icu_patients as float)/total_cases))*100
from coviddeaths
where location = "United States" and date not like "%/22"


--looking at the vaccine in the USA: people started getting vaccinated in mid-December 2020 and the boosters started the beggning of next year
select location, date, people_vaccinated, people_fully_vaccinated, total_boosters 
from covidvaccinations  
where location ="United States"

--let's join the two tables:

SELECT * 
FROM coviddeaths dea
Join covidvaccinations vac 
on dea.location = vac.location
and dea.date = vac.date

--66.5% of the USA population is fully-vaccinated
SELECT dea.location, dea.date, dea.population, (cast(vac.people_vaccinated as float)/dea.population)*100 as usavacpoprate,
(CAST(vac.people_fully_vaccinated AS float)/dea.population)*100 as usafullvacpoprate,
(cast(vac.total_boosters as float)/dea.population)*100 as usaboosterpoprate
FROM coviddeaths dea
Join covidvaccinations vac 
on dea.location = vac.location
and dea.date = vac.date
WHERE dea.location = "United States"

--running total in usa for vaccine:
SELECT dea.location, dea.date, dea.population, cast(vac.people_vaccinated as float) as usavacpop, 
sum(cast(vac.people_vaccinated as float)) over (partition by dea.location order by dea.date) as vacrunningtotal,
CAST(vac.people_fully_vaccinated AS float) as usafullvacpop, 
sum(CAST(vac.people_fully_vaccinated AS float)) over (partition by dea.location order by dea.date) as fullvacrunningtotal,
cast(vac.total_boosters as float) as usaboosterpop,
sum(cast(vac.total_boosters as float)) over (partition by dea.location order by dea.date)
FROM coviddeaths dea
Join covidvaccinations vac 
on dea.location = vac.location
and dea.date = vac.date
WHERE dea.location = "United States"


use CTE:

with rateofrunningtotal as
(
SELECT dea.location, dea.date, dea.population, cast(vac.people_vaccinated as float) as usavacpop, 
sum(cast(vac.people_vaccinated as float)) over (partition by dea.location order by dea.date) as vacrunningtotal,
CAST(vac.people_fully_vaccinated AS float) as usafullvacpop, 
sum(CAST(vac.people_fully_vaccinated AS float)) over (partition by dea.location order by dea.date ASC) as fullvacrunningtotal,
cast(vac.total_boosters as float) as usaboosterpop,
sum(cast(vac.total_boosters as float)) over (partition by dea.location order by dea.date ASC) as boosterrunningtotal
FROM coviddeaths dea
Join covidvaccinations vac 
on dea.location = vac.location
and dea.date = vac.date
WHERE dea.location = "United States"
)
SELECT *, (vacrunningtotal/population)*100, (fullvacrunningtotal/population)*100, (boosterrunningtotal/population)*100
from rateofrunningtotal
order by date ASC
-- runnig total of fully vaccinated people by country:
SELECT dea.location, dea.date, dea.population, CAST(vac.people_fully_vaccinated as float) as peoplefullyvaccinated, 
sum (CAST(vac.people_fully_vaccinated as float)) OVER (partition by dea.location order by dea.date) as runningtotal
FROM coviddeaths dea
Join covidvaccinations vac 
on dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null 


--USE CTE to calculate runningtotal over population:
with vacvspop AS
(
SELECT dea.location, dea.date, dea.population, CAST(vac.people_fully_vaccinated as float) as peoplefullyvaccinated, 
sum (CAST(vac.people_fully_vaccinated as float)) OVER (partition by dea.location order by dea.date) as runningtotal
FROM coviddeaths dea
Join covidvaccinations vac 
on dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null 
)

select *, (runningtotal/population)*100 from vacvspop





select distinct(state) from usa_covid_data ucd 

select * from usa_covid_data ucd 

select state, submission_date, tot_cases, tot_death 
from usa_covid_data ucd 
group by submission_date
order by tot_cases Desc

select state, submission_date, tot_cases, tot_death 
from usa_covid_data ucd 
group by submission_date
order by tot_death Desc

select state, submission_date, tot_cases, tot_death, (CAST(tot_death as float)/cast(tot_cases as float))*100
from usa_covid_data ucd 
group by submission_date
order by tot_cases Desc











select * from us_state_vaccinations usv 

select location, date, total_vaccinations, people_vaccinated ,
(cast(people_vaccinated as float)/(cast(total_vaccinations as float)))*100 as rateofvacfromtotalvac
from us_state_vaccinations usv 
group by location, date 
order by rateofvacfromtotalvac DESC


select location, date, total_vaccinations, people_fully_vaccinated ,
(cast(people_fully_vaccinated as float)/(cast(total_vaccinations as float)))*100 as rateoffvacfromtotalvac
from us_state_vaccinations usv 
group by location, date 
order by rateoffvacfromtotalvac desc

select location, date, cast(total_vaccinations as float), cast(total_boosters as float),
(cast(total_boosters as float)/(cast(total_vaccinations as float)))*100 as rateoffvacfromtotalvac
from us_state_vaccinations usv 
group by location, date 
order by rateoffvacfromtotalvac desc






