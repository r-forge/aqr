require(aqr)
require(blotter)
require(IBrokers)
#tws <- twsConnect(host="192.168.1.44", port=4001, clientId = 10101)

if(exists(".blotter"))rm(.blotter)
  .blotter <- new.env()
source("../R/classes.R")
source("../R/classes2.R")

#ibInst <- twsFUT(conId=384085893, currency="EUR", symbol="DAX", exch="DTB", expiry="20200619", multiplier=5)
#data <- reqHistoricalData(tws, ibInst)

context <- TradSysContext$new()
ts <- SMISlopeTradingSystem$new(list(), context)
symbol="DB1.DE"
getSymbols(symbol, from='2017-01-01', to='2020-03-01', src='yahoo', index.class=c("POSIXt","POSIXct"))
x1 <- get(symbol)
symbol="x1"    
replayer <- Replayer$new()
stats <- replayer$replayCsv(context, symbol, list(ts))
