

select * from PortfolioProject..[CovidDeaths.xlsx - CovidDeaths]
order by 3,4

select * from PortfolioProject..CovidVaccinations
order by 3,4

--rename a table,column,index
Exec sp_rename '[CovidDeaths.xlsx - CovidDeaths]','CovidDeaths'

-- Total case vs Total Deaths displayed as Death_Percentage
--shows likelihood of dying if you contract covid in your country
select location,date,(total_cases),(total_deaths),(cast(total_deaths as float)/cast( total_cases as FLOAT)) * 100  as Death_Percentage
from [CovidDeaths.xlsx - CovidDeaths]
order by 1,2

-- Total case vs Total Deaths displayed as Death_Percentage in India when cases are maximum

select location,date,(total_cases),(total_deaths),(cast(total_deaths as float)/cast( total_cases as FLOAT)) * 100 as Total_percentage
from [CovidDeaths.xlsx - CovidDeaths]
where location = 'India' and total_cases in (select max(total_cases) from [CovidDeaths.xlsx - CovidDeaths] where location='India')
order by 1,2

---percent population died
select location,population, MAX(total_cases) as TotalCases, MAX(total_deaths) as TotalDeaths,
MAX(cast(total_deaths as float)/cast(population as FLOAT) * 100) as PercenPopulationDied
from [CovidDeaths.xlsx - CovidDeaths]

GROUP BY location,population
order by PercenPopulationDied desc

--countries with highest infection rate compared to population
select location,population,MAX(total_cases) as HighestInfectionCount,
MAX((cast(total_cases as float)/cast( population as FLOAT)))* 100 as PercentPopulationInfected
from [CovidDeaths.xlsx - CovidDeaths]
Group by location,population
order by 1,2


--total deaths per country eliminatring the continent redudancy
select location,MAX(total_deaths) as Total_Deaths
from CovidDeaths
where continent is not NULL
group by location
order by Total_Deaths desc


 --global numbers for each date
select date,sum(new_cases) as Total_Cases,sum(new_deaths) as Total_Deaths,
sum(cast(new_deaths as float))/sum(cast(new_cases as float))*100 as DeathPercentage
from CovidDeaths
where new_cases <> 0 and new_deaths <>0
group by date
order by 1,2

--global death percentage for new cases and new deaths
select sum(new_cases) as Total_Cases,sum(new_deaths) as Total_Deaths,
sum(cast(new_deaths as float))/sum(cast(new_cases as float))*100 as DeathPercentage
from CovidDeaths
where new_cases <> 0 and new_deaths <>0

order by 1,2


-- joinig covid deaths and covid vaccinations to display new cases for population of each country
select dea.continent,dea.location,dea.date,population,new_vaccinations
FROM CovidDeaths dea join CovidVaccinations vac
  on dea.location = vac.location
  and dea.date = vac.date
where dea.continent is not null
order by  2,3

--joinig covid deaths and covid vaccinations to display rolling people vaccinated per location and at a given date

select dea.continent,dea.location,dea.date,population,new_vaccinations,
sum (cast(new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinted
FROM CovidDeaths dea join CovidVaccinations vac
  on dea.location = vac.location
  and dea.date = vac.date
where dea.continent is not null
order by  2,3

--using cte to display rollingpeoplevaccinated per population
with popvsvac (continent,location,date,population,new_vaccinations,rollingpeoplevaccinated)
AS
(
select dea.continent,dea.location,dea.date,population,new_vaccinations,
sum (cast(new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinted
FROM CovidDeaths dea join CovidVaccinations vac
  on dea.location = vac.location
  and dea.date = vac.date
where dea.continent is not null 
)
select *,cast(RollingPeopleVaccinated as float)/population *100 as Rollingpeoplevacciated_percentage from popvsvac 

--using temp table  display rollingpeoplevaccinated per population
drop table if exists #populationvaccinated
Create Table #populationvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population NUMERIC,
new_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT into #populationvaccinated
select dea.continent,dea.location,dea.date,population,new_vaccinations,
sum (cast(new_vaccinations as int)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinted
FROM CovidDeaths dea join CovidVaccinations vac
  on dea.location = vac.location
  and dea.date = vac.date
where dea.continent is not null 

select *,cast(RollingPeopleVaccinated as float)/population *100 as Rollingpeoplevacciated_percentage from #populationvaccinated
