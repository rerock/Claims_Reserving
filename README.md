### Claims Paid Losses (Mercury Insurance Group)
###### _Jenny Liang (Wen Liang)_


----

### Introduction

[Glenn Meyers and Peng Shi](http://www.casact.org/research/index.cfm?fa=loss_reserves_data) provide databases that include major personal and commercial lines of business from U.S. property casualty insurers. For the purpose of this project, only
the data involving Mercury Insurance Group will be used. Unfortunately, the datasets that contain information for Mercury Insurance Group are only the Workers’ Compensation and Other Liability datasets. I choose Other Liability line of business dataset because Mercury’s information from Workers’ Compensation mostly is zero. 

The Claim Paid Losses in Other Liability Insurance for accident years in 1988-1997 form a development triangle as below. Presenting the data in a triangle structure is because (1) It shows the development of claims over time for each origin period; (2) “ChainLadder” package in R expect triangles as input data sets with development periods along the columns and the origin period in rows

![](https://raw.githubusercontent.com/wliang88/ClaimsLossAnalysis/master/Data/Triangle_Data.png)

----

### Objective

Using the “ChainLadder” Package in R, I aim to forecast the future claims development for the bottom right half of the triangle. In other words, I am estimating unobserved values and quantify the outstanding loss liabilities for each origin year. 

----

### Data

The cumulative claims development is visualized in the below Figure. Most of the insured incidents take 3-6 years to settle down and close. The growth rate is the highest after 2 - 3 years from the claims origin point but it does slow down with the increasing development period. 
![](https://raw.githubusercontent.com/wliang88/ClaimsLossAnalysis/master/Data/Rplot_CumClaim.png)

----

###Modeling

### 1. Chain Ladder Packages in R

Chain Ladder methods are deterministic algorithms to forecast outstanding claims on the basis of historical data. They assumes the cumulative claims losses for each business year develop similarly by delay year. Loss Development Factor method uses the most basic chain ladder function, and the ChainLadder package in R has implementations of Mack, Munich, and Boot Strap ChainLadder methods. 

#### (1) [Loss Development Factor method](http://www.riskmanagementblog.com/2011/10/03/understanding-loss-development-factors/)
Loss Development Factor method uses the basic chain ladder function, which development factors are calculated as the ratios of cumulative claims losses from one development period to the next. 

![](https://raw.githubusercontent.com/wliang88/ClaimsLossAnalysis/master/LDFmethod/LaTexFormula_LDFmethod.png)

Since the oldest origin year is not fully developed, I extrapolate anther 100 development periods assuming a log-linear model. The link ratios then allow me to plot the expected claims development patterns. 

![](https://github.com/wliang88/ClaimsLossAnalysis/blob/master/LDFmethod/Rplot_pattern.png)

The link ratios are then applied to the latest known cumulative claims amount to forecast the next development period. An ultimate column is appended to the right to accommodate the expected development beyond the oldest year (10) of the triangle due to the tail factor (1.005696) being greater than unity. 

![](https://raw.githubusercontent.com/wliang88/ClaimsLossAnalysis/master/LDFmethod/FullData_LDFmethod.png)

Based on the estimated unobserved values, I can then draw the complete graph of Incremental claims for each origin year. The total estimated outstanding loss under this method is about 29259. 
![](https://raw.githubusercontent.com/wliang88/ClaimsLossAnalysis/master/LDFmethod/Rplot_LDFmethod_FullDataset.png)

----

#### (2)[Mack Chain Ladder Method](http://www.casact.net/library/astin/vol23no2/213.pdf)

The Mack Chain Ladder model forcecasts IBNR (Incurred But Not Reported) claims based on a historical cumulative claims triangles and calculattes the standard error for the reserves estimates. It can be regarded as a weighted linear regression through the origin for each development period: lm(y ~ x + 0, weights=w/x^(2- alpha)), where y is the vector of claims at development period k + 1 and x is the vector of claims at development period k.


The Mack's method is implemented in the ChainLadder package via the function MackChainLadder._But_ this method will only works if accident years are independent, thus I dont think Mack's Method is applicable for my dataset. To ensure my statement is valid, we can check whether there are trends in the residual plots. 

![](https://raw.githubusercontent.com/wliang88/ClaimsLossAnalysis/master/MCLmethod/Rplot_MCLmethod.png)

The residual plots above show the standarised residuals against fitted values, origin period, calendar periodm and development period. There seems to be trends in the bottom left and top right plots. The patterns in any direction can be result of trends and thus require further investigations. 

#### (3)[Munich Chain Ladder Method](http://www.variancejournal.org/issues/02-02/266.pdf)
Munich-chain-ladder (MCL) is an extension of Mack’s method that reduces the gap between IBNR projections based on paid and incurred losses. MCL adjusts the chain-ladder link-ratios depending if the momentary Paid/Incurred (P/I) ratio is above or below average. MCL also uses the correlation of residuals between P vs. (I/P) and I vs. (P/I) chain-ladder link-ratio to estimate the correction factor. 

![]()
- Top left: MCL method forcasts on Paid Loss and Incurred losses
- Top right: Comparion of Ultimate P/I rations of MCL and Mack
- Bottom Left: I/P link-ratio residuals against P link-ratio residuals
- Bottom right: P/I link-ratio residuals against I link-ratios residuals

Because MCL is an extension of Mack's method, and Mack's method is not applicable to both of the paid and incurred losses triangles, I decide to move onto the next method.

#### (4)[Boot Strap Chain Ladder Method](http://www.variancejournal.org/issues/02-02/266.pdf)
BootChainLadder uses a two-stage approach.
      1.Calculate the scaled Pearson residuals and bootstrap R times to forecast future incremental claims payments via the standard chain-ladder method.
      2.Simulate the process error with the bootstrap value as the mean and using an assumed process distribution.

The set of reserves obtained in this way forms the predictive distribution, from which summary statistics such as mean, prediction error or quantiles can be derived.

![]()
- Top left: .Histogram of simulated total IBNR
- Top right: Empirical distribution of total IBNR
- Bottom Left: Box-whisker plot of simulated ultimate claims cost by origin period
- Bottom right: Box-whisker plot of simulated ultimate claims cost by origin period

### 2. Statistical approaches 
1. Data
The chain ladder methods uses cumulative claims, but statistical approaches uses the incremental claims. The R package ChainLadder comes with two helper functions, cum2incr and incr2cum. They can transform cumulative triangles into incremental triangles and vice versa. Incremental claims for the development years are displayed in the figure below. For this data set, the highest incremental claims come from the third, fourth and fifth development years. In general, the decreasing trend in claims development is visible.
![](https://raw.githubusercontent.com/wliang88/ClaimsLossAnalysis/master/Data/Rplot_IncData.png)
 
For a better illustration, the development of the incremental claims is shown in below figure individually for each origin period.

![](https://raw.githubusercontent.com/wliang88/ClaimsLossAnalysis/master/Data/Rplot_IndivInc.png)





----

### Bibliography
Glenn Meyers and Peng Shi, http://www.casact.org/research/index.cfm?fa=loss_reserves_data

Package ‘ChainLadder’, http://cran.r-project.org/web/packages/ChainLadder/ChainLadder.pdf


