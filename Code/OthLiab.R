###### function to read data
OthLiab=read.csv("/Users/runliang/Desktop/OthLiab_pos.csv",header=TRUE)
grp.code=unique(OthLiab$GRCODE)
ins.line.data=function(g.code){
  b=subset(OthLiab,OthLiab$GRCODE==g.code)
  name=b$GRNAME
  grpcode=b$GRCODE
  ay=b$AccidentYear
  dev=b$DevelopmentLag
  cum_pdloss=b[,7]
  cum_incloss=b[,6]
  data.out=data.frame(name,grpcode,ay,dev,cum_pdloss,cum_incloss)
  return(data.out)
}
###### my data
which(ins.line.data(grp.code)[,1]=="First Mercury Ins Co")   ##[1] 64
data=ins.line.data(grp.code[64])
###### upper triangle
upper=subset(data,ay+dev<=1998)
###### lower triangle
lower=subset(data,ay+dev>1998)
###### install necessary packages
  ##install.packages("lme4")
  ##install.packages("geepack")
  ##install.packages("ChainLadder")
  ##install.packages("MuMIn")
  ##install.packages("MESS")
library(lme4)
library(geepack)
library(ChainLadder)
library(MuMIn)
library(MESS)
#########################data in triangles
triangle=as.triangle(upper,origin="ay", dev="dev",
                     value="cum_pdloss")
triangle_low=as.triangle(lower,origin="ay", dev="dev",
                         value="cum_pdloss")
###### plot the data
triangle
plot(triangle, xlab="Development Year",
     ylab="Cumulative Claims",lwd="5",font.axis = 4, cex.axis = 1.2,
     cex.lab = 1.5, col.lab = "dark red" )
plot(triangle,lattice=T)  
    ##setting the argument lattice=TRUE produces individual plots for each origin period
                        
##########################################################ChainLadder Model
###### incremental data
inc_triangle=cum2incr(triangle)
inc_triangle[1,]  ##Show first origin period and its incremental developement
raa.cum=incr2cum(inc_triangle)  
raa.cum[1,]  ##Show first origin period and its cumulative developement
inc_triangle
plot(inc_triangle, xlab="Development Year",
     ylab="Cumulative Claims",lwd="5",font.axis = 4, cex.axis = 1.2,
     cex.lab = 1.5, col.lab = "dark red" )
plot(inc_triangle,lattice=T)

###### Basic Idea
## Link ratios are calculated as the volumne weighted average developement
## rations of a cumulative loss developement triangle from one development period to the next

n=10
f=sapply(1:(n-1),
         function(i){
           sum(triangle[c(1:(n-i)),i+1])/sum(triangle[c(1:(n-i)),i])
         })
f ##[1] 5.592638 2.858319 1.624835 1.322425 1.174066 1.076317 1.020656 1.011057 1.049548

## The oldest origin year is not fully developed, approach to extrapolate 
## the developement raions, assuming a log-linear model

dev.period=1:(n-1)
plot(log(f-1)~dev.period, main="Log-linear extrapolation of age-to-age factors")
tail.model=lm(log(f-1)~dev.period)
abline(tail.model)
co=coef(tail.model)
###### extrapolate another 100 dev.period
tail=exp(co[1]+c((n+1):(n+100))*co[2])+1
f.tail=prod(tail)
f.tail##[1] 1.005696
###### plot the expected claims development patterns
plot(100*(rev(1/cumprod(rev(c(f,tail[tail>0.999]))))),t="b",
     main="Expected claims development pattern",
     xlim=c(0,15),
     xlab="Dev.period", ylab="Development % of ultimate loss")

## to forecast the next developemtn period
f=c(f,f.tail)
full_triangle=cbind(triangle,Ult=rep(0,10))
for (k in 1:n){
  full_triangle[(n-k+1):n,k+1]=full_triangle[(n-k+1):n,k]*f[k]
}
full_triangle=round(full_triangle)
full_triangle
sum(full_triangle[,11]-getLatestCumulative(triangle)) ##[1] 29259



##### Mack chain-ladder

mack=MackChainLadder(triangle, est.sigma="Mack")
mack$f
round(mack$FullTriangle)
plot(mack)
plot(mack,lattice=T)

###########################incremental data
pom=upper[5]
pom
for (k in (2:91)){
  if ( is.na(upper[k,3])!=TRUE & upper[k,3]==upper[k-1,3])
    pom[k,1]=upper[k,5]-upper[k-1,5]
  else if (is.na(upper[k,3])!=TRUE) pom[k,1]=upper[k,5]
}
upper[5]=pom

#data preparation
inc_data=cbind(upper[3],upper[4],upper[5])
colnames(inc_data)[3]="inc_loss"

