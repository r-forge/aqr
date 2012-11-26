# Utility functions from AQ-R


aqHourIndex <- function(xtsSeries){
  ret <- cbind(x, as.POSIXlt(index(x))$hour);
  colnames(ret) = c("A", "hour");
  return(ret[,2]);
}

# applies a function across hour slots. 
aqHourlyStat <- function(x, f = mean){
    
    hourIndex = as.POSIXlt(index(x))$hour
    hours = c(0:23)
    hourlyMatrix = c()
    for(i in hours){
      dataSlot = x[hourIndex==i]
      val = NA
      if(nrow(dataSlot)>0){
	val = apply(dataSlot, 2, f)	
      }
      hourlyMatrix = rbind(hourlyMatrix, c(i, val))
    }
    return(hourlyMatrix)
}


aqFilterOHLCSD <- function(ohlcv, sdFilterAmount = 10){
  sdLowToOpen = apply(ohlcv[,1] - ohlcv[,2], 2, sd) * sdFilterAmount
  sdHighToOpen = apply(ohlcv[,1] - ohlcv[,3], 2, sd) * sdFilterAmount 
  ohlcv[ abs(ohlcv[,1] - ohlcv[,3]) > sdHighToOpen,3] = ohlcv[abs(ohlcv[,1] - ohlcv[,3]) > sdHighToOpen,1]
  ohlcv[ abs(ohlcv[,1] - ohlcv[,2]) > sdLowToOpen,2] = ohlcv[abs(ohlcv[,1] - ohlcv[,2]) > sdLowToOpen,1]
  return(ohlcv)
}


aqDropHour <- function(x, hour){
  hourIndex = as.POSIXlt(index(x))$hour
  return(x[hourIndex != hour])
}

aqDropHours <- function(x, hours){
  ret = x
  for(hour in hours){
    ret = aqDropHour(ret, hour)
  }
  return(ret)
}
