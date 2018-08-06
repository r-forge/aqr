#### backtesting functions ... 



#' method to generate a pnl curve from a running position. 
#' bids, asks and running position must have the same length. 
#' Can compute the pnl from one price to the other, but only for one asset! 
#' Does not take time into account - if you need signal delays, lag 
#' all input data on your own.  
#' 
#' @param bidPrices an array of bid prices
#' @param askPrices an array of ask prices
#' @param runningPosition an array that contains a vector of the position
#' @param messages specifies whether you want to have debug messages or not, defaults to FALSE
#' 
#' @return This function returns a plain double array with pnl changes (uncumulated) and not an XTS series, aligned to your input bid/ask series
#' 
#' @note all input arrays must have the same length. 
#' @export
generatePnlCurve <- function(bidPrices, askPrices, runningPosition, messages=FALSE)
{
        # checks if the length of bid, ask and running position are equally long.
        if(messages)message("Generating PNL curve.")
        if(length(bidPrices) == length(askPrices) && length(askPrices) == length(runningPosition))
        {       
                .C("c_generatePnlCurve", as.double(bidPrices), as.double(askPrices), as.double(runningPosition), as.integer(length(bidPrices)), pnl = double(length(bidPrices)), PACKAGE="aqr")$pnl
        }
        else
        {
                # throw an error.
                simpleError("Arrays must be of same length", "generatePnlCurve")
        }
}

#' Applies an approximated StopLoss/TakeProfit strategy on an incoming pnl series. 
#' 
#' @return the rewritten pnl series. 
#' @export
approximateSLTP <- function(high, low, close, takeProfit, stopLoss, runningPosition, messages=FALSE)
{
        # checks if the length of bid, ask and running position are equally long.
        if(messages){
      	  message("Generating PNL curve, v. 05")
      	  message(high, "/", low, "/", close, "/", takeProfit, "/" , stopLoss, "/", runningPosition)
      	}
      	
        if(length(high) == length(runningPosition))
        {       
            x = .C("c_approximateStopLossTakeProfit", as.double(high), as.double(low), as.double(close), as.double(runningPosition),as.integer(length(runningPosition)),  stopLoss, takeProfit, 
		            pnl = double(length(high)), position = double(length(high)), stopIndication = double(length(high)), PACKAGE="aqr")		
		        return(cbind(x$pnl, x$position, x$stopIndication))
        }
        else
        {
                # throw an error.
                simpleError("Arrays must have the same length", "approximateSLTP")
        }
}
