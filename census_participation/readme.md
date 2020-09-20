# Census Participation
Jesse Zlotoff<br>

## Proposal
proposal.md

## Data Gathering
Data was manually downloaded from the links below, unzipped as necessary, and
moved to the **data > raw** subfolder of this project.
1. 2009 ACS 5-Year Estimates
    * [Raw data zip](https://www2.census.gov/acs2005_2009_5yr/summaryfile/2005-2009_ACSSF_All_In_2_Giant_Files(Experienced-Users-Only)/All_Geographies_Not_Tracts_Block_Groups.zip)
    * [Sequence Number](https://www2.census.gov/acs2005_2009_5yr/summaryfile/Sequence_Number_and_Table_Number_Lookup.xls)
    * [Table shells](https://www2.census.gov/acs2005_2009_5yr/summaryfile/ACS2009_5-Year_TableShells.xls)
    * [Additional metadata](https://www2.census.gov/acs2005_2009_5yr/summaryfile/ACS_2005-2009_SF_Tech_Doc.pdf) (i.e. header for geographic lookup files)
2. [NHCS Urabnity Classification](https://www.cdc.gov/nchs/data/data_acces_files/NCHSURCodes2013.xlsx)
3. [2010 Census Participation Rates](https://www2.census.gov/programs-surveys/decennial/2010/data/participation-rates-states/participationrates2010.txt?#)

## Exploratory Data Analysis
The ACS data requires extensive cleaning before use.  The `prep_acs_data.ipynb` file extracts the raw data from the various ACS files and builds features.  The `eda.ipynb` builds a combined dataset and does exploratory analysis.
1. prep_acs_data.ipynb
    * Inputs: `data/acs_variables.txt`, raw ACS files in `data/raw/`
    * Ouputs: `data/sequence_info.csv`, `data/table_names.csv`, `data/acs_raw.csv`, `data/acs_features.csv`
2. eda.ipynb
    * Inputs: `data/acs_features.csv`, `data/raw/NCHSURCodes2013.xlsx`, `data/raw/participationrates2010.txt`
    * Outputs: `data/combined_data.csv`

## Modeling
1. modeling.ipynb<br>
    * Inputs: `data/comb_data.csv`
    * Outputs: `data/initial_feature_importance.csv`, `data/objects/*`, `data/imgs/*`

## Presentation
presentation.pptx