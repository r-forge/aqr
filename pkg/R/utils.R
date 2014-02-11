# Utility functions from AQ-R
aqHourIndex <- function(xtsSeries){
  ret <- cbind(xtsSeries, as.POSIXlt(index(xtsSeries))$hour);
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



# applies a function to all values per weekday. 
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

#' 
#' @param hour the hour to remove from this data set, e.g. 8 or 15, etc.
#' @param x an input  xts object
#' 
#' @return a dataset in which all information for this hour has been dropped. 
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



#' method to generate a pnl curve from a running position. 
#' bids, asks and running position must have the same length. 
#' Can compute the pnl from one price to the other, but only for one asset! 
#' Does not take time into account - if you need signal delays, lag 
#' all input data on your own.  
#' 
#' @param bidPrices an array of bid prices
#' @param askPrices an array of ask prices
#' @param runningPosition an array that contains a vector of the position
#' 
#' @return This function returns a plain double array with pnl changes (uncumulated) and not an XTS series.
#' 
#' @note all input arrays must have the same length. 
generatePnlCurve <- function(bidPrices, askPrices, runningPosition, messages=FALSE)
{
        # checks if the length of bid, ask and running position are equally long.
        if(messages)message("Generating PNL curve.")
        if(length(bidPrices) == length(askPrices) && length(askPrices) == length(runningPosition))
        {       
                .C("c_generatePnlCurve", as.double(bidPrices), as.double(askPrices), as.double(runningPosition), as.integer(length(bidPrices)), pnl = double(length(bidPrices)))$pnl
        }
        else
        {
                # throw an error.
                simpleError("Arrays must have the same length", "generatePnlCurve")
        }
}

approximateSLTP <- function(high, low, close, takeProfit, stopLoss, runningPosition, messages=FALSE)
{
        # checks if the length of bid, ask and running position are equally long.
        if(messages){
	  message("Generating PNL curve.")
	  message(high, "/", low, "/", close, "/", takeProfit, "/" , stopLoss, "/", runningPosition)
	}
	
        if(length(high) == length(runningPosition))
        {       
                x = .C("c_approximateStopLossTakeProfit", as.double(high), as.double(low), as.double(close), as.double(runningPosition),as.integer(length(runningPosition)),  stopLoss, takeProfit, 
		    pnl = double(length(high)), position = double(length(high)))		
		return(cbind(x$pnl, x$position))
        }
        else
        {
                # throw an error.
                simpleError("Arrays must have the same length", "approximateSLTP")
        }
}


