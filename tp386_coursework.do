pwd // Show current working directory

cd "D:\University of Kent\01. Lectures\AUT - EC821 - Econometric Methods\Coursework\Data and documentation\data"

log using tp386_coursework.log, replace

clear
sysuse apsp_o13s_eul_pwta16_sample, clear

//clear unnecessary variables
keep HOURPAY AGE edageband SMOKEVER CIGNOW LIMITA LIMITK MF5964 PWTA16

//cleaning data
drop if HOURPAY < 0					//clearing "no answer" or "does not apply" cases
drop if MF5964 < 0					//clearing "no answer" or "does not apply" cases
replace MF5964 = 0 if MF5964 !=1	//converting into dummy variable
drop if edageband < 0				//clearing "no answer" or "does not apply" cases
drop if edageband > 70				//clearing "Still in education or never had education" cases
drop if SMOKEVER < 0				//clearing "dl/refusal" or "does not apply" cases
drop if CIGNOW == -8				//clearing "dl/refusal" cases
replace CIGNOW = 0 if CIGNOW !=1	//converting into dummy variable
drop if LIMITA == -8				//clearing "no answer" cases
replace LIMITA = 0 if LIMITA !=1	//converting into dummy variable
drop if LIMITK == -8				//clearing "no answer" cases
replace LIMITK = 0 if LIMITK !=1	//converting into dummy variable

//clearing outliers in person weight
drop if PWTA16 == 0					//clearing person with 0 weight
egen Q1_PWTA16 = pctile(PWTA16), p(25)
egen Q3_PWTA16 = pctile(PWTA16), p(75)
egen IQ_PWTA16 = iqr(PWTA16)
gen outlier1 = 1 if (PWTA16 < Q1_PWTA16 - 1.25*IQ_PWTA16| PWTA16 > Q3_PWTA16 + 1.25*IQ_PWTA16)
drop if outlier1 == 1

//generate log of gross hourly pay
gen lnwage = log(HOURPAY)
label variable lnwage "Log of gross hourly pay"

//clearing outliers in log of gross hourly pay
egen Q1_lw = pctile(lnwage), p(25)
egen Q3_lw = pctile(lnwage), p(75)
egen IQ_lw = iqr(lnwage)
gen outlier2 = 1 if (lnwage < Q1_lw - 1.25*IQ_lw| lnwage > Q3_lw + 1.25*IQ_lw)
drop if outlier2 == 1

//clearing unnecessary variables for outliers
drop Q1_PWTA16 Q3_PWTA16 IQ_PWTA16 outlier1 Q1_lw Q3_lw IQ_lw outlier2

//generate dummy variables for schooling-finish age
gen edageband1 = 0
replace edageband1 = 1 if edageband < 16
label variable edageband1 "Under 16"
gen edageband2 = 0
replace edageband2 = 1 if edageband == 16
label variable edageband2 "16 to 19"
gen edageband3 = 0
replace edageband3 = 1 if edageband == 20
label variable edageband3 "20 to 24"
gen edageband4 = 0
replace edageband4 = 1 if edageband == 25
label variable edageband4 "25 to 29"
gen edageband5 = 0
replace edageband5 = 1 if edageband > 29
label variable edageband5 "30 and over"

//generate Age squared
gen age2 = AGE^2
label variable age2 "Age squared"

//generate Weight squared
gen weight2 = PWTA16^2
label variable weight2 "Weight squared"

su HOURPAY lnwage edageband1 edageband2 edageband3 edageband4 edageband5 AGE MF5964 CIGNOW PWTA16 LIMITA LIMITK

//OLS regression & IV regression
reg lnwage edageband1 edageband3 edageband4 edageband5 AGE age2 MF5964 CIGNOW
estat ovtest					//test for omitted variables
estimates store OLS

ivregress 2sls lnwage edageband1 edageband3 edageband4 edageband5 AGE age2 MF5964 (CIGNOW = PWTA16 weight2 LIMITA LIMITK), first
estat overid					//test for over-identification
estimates store IV

//Hausman test for endogeneity
hausman IV OLS, constant sigmamore

//Boxplot of the first stage of the IV regression
reg CIGNOW edageband1 edageband3 edageband4 edageband5 AGE age2 MF5964	//first stage of IV regression
predict smk	//get fitted value
su smk		//summary of fitted value
graph box smk	//boxplot of fitted value
