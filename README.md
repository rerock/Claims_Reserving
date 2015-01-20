### Claim Paid Losses (Mercury Insurance Group)
###### _Jenny Liang (Wen Liang)_


----
#### Introduction

[Glenn Meyers and Peng Shi](http://www.casact.org/research/index.cfm?fa=loss_reserves_data) provide databases that include major personal and commercial lines of business from U.S. property casualty insurers. For the purpose of this project, only
the data involving Mercury Insurance Group will be used. Unfortunately, the datasets that contain information for Mercury Insurance Group are only the Workers’ Compensation and Other Liability datasets. I choose Other Liability line of business dataset because Mercury’s information from Workers’ Compensation mostly is zero. 

The Claim Paid Losses in Other Liability Insurance for accident years in 1988-1997 form a development triangle as below. Presenting the data in a triangle structure is because (1) It shows the development of claims over time for each origin period; (2) “ChainLadder” package in R expect triangles as input data sets with development periods along the columns and the origin period in rows

![](https://raw.githubusercontent.com/wliang88/ClaimsLossAnalysis/master/Rplot_CumClaim.png)


Objective: Using the “ChainLadder” Package in R, I aim to forecast the future claims development for the bottom right half of the triangle. In other words, I am estimating unobserved values and quantify the outstanding loss liabilities for each origin year. 



Data Overview
 
The cumulative claims development is visualized in the below Figure. Most of the insured incidents take 3-6 years to settle down and close. The growth rate is the highest after 2 - 3 years from the claims origin point but it does slow down with the increasing development period. 

The R package ChainLadder comes with two helper functions, cum2incr and incr2cum. They can transform cumulative triangles into incremental triangles and vice versa. Incremental claims for the development years are displayed in the figure below. For this data set, the highest incremental claims come from the third, fourth and fifth development years. In general, the decreasing trend in claims development is visible.

 

For a better illustration, the development of the incremental claims is shown in below figure individually for each origin period.
 

Chain-Ladder Methods

Chain-Ladder is a deterministic algorithm to forecast claims based on historical data. It assumes that the proportional developments of claims from one development period to the next are the same for all origin years.

Loss Development Factor method
Loss Development Factor method uses the basic chain ladder function, which link ratios are calculated as the volume weighted average development ratios of a cumulative loss development triangle from one development period to the next.
			 

Since the oldest origin year is not fully developed, I extrapolate anther 100 development periods assuming a log-linear model. The link ratios then allow me to plot the expected claims development patterns. 
 
The link ratios are then applied to the latest known cumulative claims amount to forecast the next development period. An ultimate column is appended to the right to accommodate the expected development beyond the oldest year (10) of the triangle due to the tail factor (1.005696) being greater than unity. 

Accident
Year	Development Year
	1	2	3	4	5	6	7	8	9	10	Ult
1988	233	887	2548	4353	6210	7542	8133	8177	8295	8706	8756
1989	142	828	2758	4412	6060	7448	8208	8555	8622	9049	9101
1990	189	927	3304	6019	7463	8942	9366	9506	9611	10087	10145
1991	142	1043	2299	3764	4799	5380	5842	5963	6029	6327	6363
1992	98	1284	3813	5995	7117	7846	8445	8619	8715	9146	9198
1993	164	824	2723	1090	6216	7298	7855	8017	8106	8507	8556
1994	164	1238	3010	4603	6087	7147	7692	7851	7938	8331	8379
1995	285	1227	3149	5117	6766	7944	8550	8727	8823	9251	9313
1996	213	858	2452	3985	5270	6187	6659	6797	6872	7212	7253
1997	163	912	2606	4234	5599	6573	7075	7221	7301	7663	7706


Based on the estimated unobserved values, I can then draw the complete graph of Incremental claims for each origin year. The total estimated outstanding loss under this method is about 29259. 
 

Mack-chain-ladder Method

The Mack-chain-ladder model can be regarded as a weighted linear regression through the origin for each development period: lm(y ~ x + 0, weights=w/x^(2-
alpha)), where y is the vector of claims at development period k + 1 and x is the
vector of claims at development period k.

The Mack method is implemented in the ChainLadder package via the function
MackChainLadder. I can then access the loss development factors and the full triangle. 
	   
Accident 
Year	Development Year
	1	2	3	4	5	6	7	8	9	10
1988	233	887	2548	4353	6210	7542	8133	8177	8295	8706
1989	142	828	2758	4412	6060	7448	8208	8555	8622	9049
1990	189	927	3304	6019	7463	8942	9366	9506	9611	10087
1991	142	1043	2299	3764	4799	5380	5842	5963	6029	6327
1992	98	1284	3813	5995	7117	7846	8445	8619	8715	9146
1993	164	824	2723	1090	6216	7298	7855	8017	8106	8507
1994	164	1238	3010	4603	6087	7147	7692	7851	7938	8331
1995	285	1227	3149	5117	6766	7944	8550	8727	8823	9261
1996	213	858	2452	3985	5270	6187	6659	6797	6872	7212
1997	163	912	2606	4234	5599	6573	7075	7221	7301	7663


To check whether Mack chain-ladder method is valid for the dataset, we can see that there are no trends in all the residual plots. 


 

I then plot the development, including the forecast and estimated standard errors by origin period by setting the argument lattice=TRUE.
 
Further question
Forecast future claims development beyond development age 10? 

Bibliography
Glenn Meyers and Peng Shi,            
	http://www.casact.org/research/index.cfm?fa=loss_reserves_data

Package ‘ChainLadder’
http://cran.r-project.org/web/packages/ChainLadder/ChainLadder.pdf


