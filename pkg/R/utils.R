# Utility functions from AQ-R

#' Returns for an XTS input list the hour index per element. 
#' @param xtsSeries the input object of type XTS. 
#' @return a vector of the same length as xtsSeries, containing the hour 
aqHourIndex <- function(xtsSeries){
  ret <- cbind(xtsSeries, as.POSIXlt(index(xtsSeries))$hour);
  colnames(ret) = c("A", "hour");
  return(ret[,2]);
}

#' applies a function across hour slots. Internally, it iterates over 0:23 and selects all rows which fit into this hour. 
#'
#' @param x the input xts object
#' @param f the function to apply  
#' @return a matrix that contains hourly data 
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



#' applies a function to all values per weekday. 
#' 
#' @param x the input xts object
#' @param f the function to apply  
#' @return a matrix that contains weekly figures  
aqDayOfWeekStat <- function(x, f = mean){
    dowIndex = as.POSIXlt(index(x))$wday
    dows = c(0:6)
    dailyMatrix = c()
    for(i in dows){
      dataSlot = x[dowIndex==i]
      val = NA
      if(nrow(dataSlot)>0){
	val = apply(dataSlot, 2, f)	
      }
      dailyMatrix = rbind(dailyMatrix, c(i, val))
    }
    return(dailyMatrix)
}

#' Removes outliers based on standard deviation filters. Overwrites these with the open value. 
#' 
#' @param ohlcv an input Open/High/Low/Close/Volume dataset
#' @param sdFilterAmount the amount of standard deviations a value has to be off, to be considered errenuous data 
#' 
#' @return retuns a filtered ohlcv object
aqFilterOHLCSD <- function(ohlcv, sdFilterAmount = 10){
  sdLowToOpen = apply(ohlcv[,1] - ohlcv[,2], 2, sd) * sdFilterAmount
  sdHighToOpen = apply(ohlcv[,1] - ohlcv[,3], 2, sd) * sdFilterAmount 
  ohlcv[ abs(ohlcv[,1] - ohlcv[,3]) > sdHighToOpen,3] = ohlcv[abs(ohlcv[,1] - ohlcv[,3]) > sdHighToOpen,1]
  ohlcv[ abs(ohlcv[,1] - ohlcv[,2]) > sdLowToOpen,2] = ohlcv[abs(ohlcv[,1] - ohlcv[,2]) > sdLowToOpen,1]
  return(ohlcv)
}

#' removes all data that belongs to a specific hour from an input data set. 
#' 
#' @param hour the hour to remove from this data set, e.g. 8 or 15, etc.
#' @param x an input  xts object
#' 
#' @return a dataset in which all information for this hour has been dropped. 
aqDropHour <- function(x, hour){
  hourIndex = as.POSIXlt(index(x))$hour
  return(x[hourIndex != hour])
}

#' Drops data of several hours, delegates on to aqDropHour
#' @param x the input xts data set
#' @param hours the vector of hours to drop
#' @return the resulting data set
aqDropHours <- function(x, hours){
  ret = x
  for(hour in hours){
    ret = aqDropHour(ret, hour)
  }
  return(ret)
}




#' returns today
#' @return a POSIXlt object of now. 
today <- function(){
  z <- as.POSIXlt(Sys.time())
  return(z)
}

#' returns the date one month (30 days by default) 
#' @return a POSIXlt object 
#' @param d amount of days to shift, default: 30
daysAgo <- function(d=30){
  z <- as.POSIXlt(Sys.time())
  z <- as.POSIXlt(z - (3600 * 24 * d))
  return(z)
}

#' Formats an input POSIX date to Date8 format (YYYYMMDD). This function is a convenience function. 
#' @param dateObj a POSIX date object
#' @return an integer YYYYMMDD representation 
d8 <- function(dateObj) {
	as.integer(strftime(dateObj, format="%Y%d%m"))
}

#' Backadjusts data, expects yahoo xts structure: 
#' column 1-4: ohlc, 5: vol, 6: backadjusted close price
backadjust <- function(yahooOhlc) {
  
}

