# Census Participation - Proposal
Jesse Zlotoff<br>

## Research Goal
Census results are used to determine how federal money is allocated.  Although<br>
responding to the Census is required by law, not everyone participates.  The<br>
goal is to determine which demographic and geographic factors influence <br>
responsiveness.

I plan to build a model that predicts response rates at the county level for the<br>
2010 decennial Census.  That model could then be applied to recent demographic<br>
data in order to predict responses to the upcoming 2020 Census (ignoring the <br>
change to conducting some surveys online and complications due to the novel <br>
coronavirus).

## Data
The Census Bureau publishes participation rates for the 2010 Census.  The rate<br>
is defined as the percentage of questionnaires mailed back by households that<br>
received them ([overview](https://www.census.gov/data/datasets/2010/dec/2010-participation-rates.html) and [direct data link](https://www2.census.gov/programs-surveys/decennial/2010/data/participation-rates-states/participationrates2010.txt?#)).

The 2009 American Community Survey (ACS) 5-year estimates ([list of variables](https://api.census.gov/data/2009/acs5/variables.html)<br>
and [raw data](https://www2.census.gov/acs2005_2009_5yr/summaryfile/)) provide demographic, geographic and other information at the<br>
county level.  I will use a subset of these variables, accounting for <br>
differences in county population.  I will limit the variables to those also<br>
present in the 2018 ACS so that the model can be applied as is for 2020.

Additionally, I will use 2006 county level urban-rural classifications from the <br>
National Center for Health Statistics (NCHS) ([overview](https://www.cdc.gov/nchs/data_access/urban_rural.htm#2006_Urban-Rural_Classification_Scheme_for_Counties) and [data direct link](https://www.cdc.gov/nchs/data/data_acces_files/NCHSURCodes2013.xlsx)).
