###### function to read data
OthLiab=read.csv("/Users/JennyLiang/Desktop/othliab_pos.csv",header=TRUE)
GRCODE=unique(OthLiab$GRCODE)
data=function(g.code){
  set=subset(OthLiab,OthLiab$GRCODE==g.code)
  name=set$GRNAME
  grpcode=set$GRCODE
  ay=set$AccidentYear
  dev=set$DevelopmentLag
  cum_pdloss=set[,7]
  data.out=data.frame(name,grpcode,ay,dev,cum_pdloss)
  return(data.out)
}

###### data
which(data(GRCODE)=="First Mercury Ins Co")   ##[1] 64
data=data(GRCODE[64])
top_data=subset(data,ay+dev<=1998)
low_data=subset(data,ay+dev>1998)

###### install packages
#install.packages("upper.tri")
#install.packages("geepack")
#install.packages("ChainLadder")
#install.packages("MuMIn")
#install.packages("MESS")
#install.packages("moments")
library(lme4)
library(geepack)
library(ChainLadder)
library(MuMIn)
library(MESS)
library(moments)

#########################data in triangles
top_tri=as.triangle(top_data,origin="ay", dev="dev",
                     value="cum_pdloss")  ## top cumulative losses triangle
low_tri=as.triangle(low_data,origin="ay", dev="dev",
                    value="cum_pdloss")  ## lower cumulative losses triangle
inc_triangle=cum2incr(top_tri)
low_inc_triangle=cum2incr(low_tri)


inc_low_data <- expand.grid(origin=as.numeric(dimnames(low_inc_triangle)
                                      $ay), dev=as.numeric(dimnames(low_inc_triangle)$dev))
inc_low_data$value <- as.vector(low_inc_triangle)
inc_low_data$value[is.na(inc_low_data$value)] <- 0
inc_low_data$value[inc_low_data$value<=0] <- 0
sum(inc_low_data[3])+sum(getLatestCumulative(inc_triangle))  ###[1] 20,194

###### incremental data
inc=top_data[5]
inc
for (k in (2:91)){
  if ( is.na(top_data[k,3])!=TRUE & top_data[k,3]==top_data[k-1,3])
    inc[k,1]=top_data[k,5]-top_data[k-1,5]
  else if (is.na(top_data[k,3])!=TRUE) inc[k,1]=top_data[k,5]
}
top_data[5]=inc

inc_data=cbind(top_data[3],top_data[4],top_data[5])
colnames(inc_data)[3]="inc_loss"

inc_triangle=cum2incr(top_tri)
inc_triangle[1,]  ##Show first origin period and its incremental developement
inc_triangle        ## incremental triangle 
head(inc_data)            ## incrmental trianlge data in data frame format
###### plot the data
top_tri   ## top cumulative losses triangle
plot(top_tri, xlab="Development Year",
     ylab="Cumulative Claims",lwd="5",font.axis = 4, cex.axis = 1.2,
     cex.lab = 1.5, col.lab = "dark red" )
plot(top_tri,lattice=T)  
    ##setting the argument lattice=TRUE produces individual plots for each origin period

                        
##########################################################ChainLadder Model
plot(inc_triangle, xlab="Development Year",
     ylab="Increment Claims",lwd="5",font.axis = 4, cex.axis = 1.2,
     cex.lab = 1.5, col.lab = "dark red" )
plot(inc_triangle,lattice=T)

###### Basic Idea
## Link ratios are calculated as the volumne weighted average developement
## rations of a cumulative loss developement triangle from one development period to the next

year=10
f=sapply(1:(year-1),
         function(i){
           sum(top_tri[c(1:(year-i)),i+1])/sum(top_tri[c(1:(year-i)),i])
         })
f ##[1] 5.592638 2.858319 1.624835 1.322425 1.174066 1.076317 1.020656 1.011057 1.049548

## The oldest origin year is not fully developed, approach to extrapolate 
## the developement raions, assuming a log-linear model

dev.lag=1:(year-1)
plot(log(f-1)~dev.lag, main="Log-linear extrapolation of link ratios")
NewModel=lm(log(f-1)~dev.lag)
abline(NewModel)
co=coef(NewModel)
###### extrapolate another 100 development period
tail=exp(co[1]+c((year+1):(year+100))*co[2])+1
f.tail=prod(tail)
f.tail##[1] 1.005696
###### plot the expected claims development patterns
plot(100*(rev(1/cumprod(rev(c(f,tail[tail>0.999]))))),t="b",
     main="Expected claims development pattern",
     xlim=c(0,15),
     xlab="Development Period", ylab="Development % of ultimate loss")

## to forecast the next developemtn period
f=c(f,f.tail)
full_triangle=cbind(top_tri,Ult=rep(0,10))
for (k in 1:year){
  full_triangle[(year-k+1):year,k+1]=full_triangle[(year-k+1):year,k]*f[k]
}
full_triangle=round(full_triangle)
full_triangle

sum(full_triangle[,10]-getLatestCumulative(top_tri)) ##[1]  28778
full_inc_triangle=cum2incr(full_triangle)
plot(full_inc_triangle, xlab="Development Year",
     ylab="Increment Claims",
     main="Dataset with Predictions under LDF method",lwd="5",font.axis = 4, cex.axis = 1.2,
     cex.lab = 1.5, col.lab = "dark red")

##### Mack Chain Ladder
mack=MackChainLadder(top_tri, est.sigma="Mack")
mack
mack$f ## IBNR:      28,779.32
round(mack$FullTriangle)
plot(mack)
plot(mack,lattice=T)

##### Bootstrap Chain-ladde
BootCL=BootChainLadder(top_tri,R=800,process.distr="od.pois")
BootCL ##IBNR:      28,916
plot(BootCL)
quantile(BootCL,c(0.75,0.95,0.99,0.995))
## fit a distribution to the IBNR
library(MASS)
plot(ecdf(BootCL$IBNR.Totals))
## fit a log-normal distribution
fit=fitdistr(BootCL$IBNR.Totals[BootCL$IBNR.Totals>0],"lognormal")
fit
curve(plnorm(x,fit$estimate["meanlog"],fit$estimate["sdlog"]),col="red",add=T,lwd="5")



##GLM chainladder: 
fit=glmReserve(top_tri, var.powe=1, mse.method="bootstrap")
fit$summary   ##IBNR: 28779

###################Multivariate Chain-ladder
fit1=MultiChainLadder(list(top_tri),fit.method="OLS")
fit1   ##IBNR: 28779
lapply(summary(fit1)$report.summary,"[",11,)


fit=lapply(list(top_tri),MackChainLadder,est.sigma="Mack")
lapply(fit, function(x) t(summary(x)$Totals))  ##IBNR: 28779



#####################################################glm




Fit1=lm(log(inc_loss) ~ as.factor(dev) + as.factor(ay),
        data=inc_data)
m=Fit1
res=resid(m)
plot(res,xlab="",ylab="residuals")
abline(h=0,lty=2)
fitm=exp(fitted(m))
plot(fitm~inc_data$inc_loss,xlab="fitted values",
     ylab="observed values")
cor(fitted(m),inc_data$inc_loss)
mse=mean((inc_data$inc_loss-fitted(m))^2)
qqPlot(res)
AIC(m)
BIC(m)

ay=rep(1992:2000,times=1:9)
ay=rep(1989:1997,times=1:9)
dev=NULL
ddev=1:10

for (i in 0:8) dev=c(dev,ddev[10:(10-i)])
future=data.frame(ay,dev)
future

year=10
f=sapply(1:(year-1),
         function(i){
           sum(top_tri[c(1:(year-i)),i+1])/sum(top_tri[c(1:(year-i)),i])
         })

eta=predict(m,future)
yhat=exp(eta)
sum(yhat)     ###[1] 30892.27
















gl=glm(inc_loss ~ factor(ay) + factor(dev), data=inc_data,
       family=poisson("log"))
summary(gl)
coef(gl)
## using the summary statistics, the second payment of 1989 would be
exp(5.22139 + 0.03866 + 1.52445) 

Claims <- data.frame(ay = sort(rep(1988:1997, year)),
                        dev = rep(1:year,year))

Claims <- within(Claims, {
  devf <- factor(dev)
  cal <- ay + dev - 1
  originf <- factor(ay)})

n=10
pred.inc.tri <- t(matrix(predict(gl,type="response",
                                    newdata=Claims), n, n))

sum(predict(gl,type="response", newdata=subset(Claims, cal > 1997)))    #[1] 28779.32


m=gl
res2=resid(m)
plot(res2,xlab="",ylab="residuals",xlim=c(0,60),ylim=c(-40,40))
abline(h=0,lty=2)
plot(fitted(m)~inc_data$inc_loss,xlab="fitted values",
     ylab="observed values")
cor(fitted(m),inc_data$inc_loss)
mse=mean((inc_data$inc_loss-fitted(m))^2)
qqPlot(res2)
mse  ## [1] 52796.72


# diagnostics
res=resid(m)
fitm=cbind(inc_data,fitted(m))
colnames(fitm)[4]="fit_val"
plot(res,xlab="",ylab="residuals")
abline(h=0,lty=2)
plot(fitted(m)~inc_data$inc_loss,xlab="fitted values",
     ylab="observed values")
cor(fitted(m),inc_data$inc_loss)
mse=mean((inc_data$inc_loss-fitted(m))^2)
qqPlot(res)
AIC(m)
BIC(m)




##################################################################################
upper_inc=cum2incr(top_tri)  ## inc_upper triangle
fit.triangle=as.triangle(round(fitm),origin="ay", dev="dev",
                         value="fit_val")                    ## fitted inc_upper triangle 
mat <- matrix(NA, 10,10)
mat[row(mat)+col(mat) >11]=predict(gl,type="response", newdata=subset(Claims, cal > 1997))
reserves.triangle=t(round(mat))  ## estimated future incremental claims

op=par(mfrow=c(3,4))
i=1
for (i in 1:10){
  plot(upper_inc[i,],col="red",type="l",ylim=c(0,3000))
  lines(fit.triangle[i,],col="blue")
  points(reserves.triangle[i,],col="green")
}

par(op)
