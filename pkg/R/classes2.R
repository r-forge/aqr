



# A base class for a simple trading system
#' @export
SMITradingSystem <- setRefClass("SMITradingSystem", 
  # contains="com.fxbot.AbstractStrategy", # inheritance ..
  fields = c("context", "name", "formerClose", "barHist", "params"), 
  methods=list(
    initialize = function(parameterList, tradSysContext){
    	if(typeof(parameterList)!="list") {    		
    		stop("Parameter list needs to be of type >list<")
    	}
    	params <<- parameterList
      	name <<- "TradingSystem"
      	context <<- tradSysContext
      	formerClose <<- 0
      	barHist <<- xts()
    },    
    handleOHLC = function(barList){     	
#     	message("Handling bar list of ", length(barList), " bars.")
		# single instrument system ..

		maxFlDur <- 15
		flagMin <- 2.5
		maxPoleDur <- 23
		upt1Bars <- 70
		poleMin <- 5.5
		lbf <- 50
		atrMin <- 5
		k <- 1.2
		TimeExit <- 100
		atrLL <- 3
		bseMin <- 5
		atrTrail <- 3
		trailbars <- 5
		bseInact <- 70
		atrInact <- 4


		

		
		bar <- barList[[1]]
		xtsRow <- bar$payload[[1]]
		
		if(length(barHist)==0)
			barHist <<- xtsRow
		else 
			barHist <<- rbind(barHist, xtsRow)



		quantity <- 0
		limitPrice <- bar$close
		
		ts <- as.POSIXct(bar$timestamp, origin="1970-01-01")
		currentPos <- getPosQty("p1", Symbol=bar$instrumentId, Date = ts)

		rowCount = nrow(barHist)		
		if(rowCount>50 && currentPos==0){
			# browser()
			s1 <- SMI(barHist[,2:4])
			dVec2 <- (s1[,1]>s1[,2]) * 2 - 1			
			condition1 = as.numeric(last(dVec2))==1
			if(condition1){
				addTxn("p1",bar$instrumentId, ts, 100, limitPrice, TxnFees = 0)						
			}
		}
			

			#	browser()
		

#		if(rowCount > 50 
#			&& 	as.numeric(EMA(barHist[,4], n=20)[rowCount]) < (bar$close) 
#			&& currentPos < 100){
#			addTxn("p1",bar$instrumentId, ts, 100, limitPrice, TxnFees = 0)
#		}
#		else{
			# check if we have an position 
			#message("Current pos ", currentPos)

			if(currentPos>0){
				entryPrice <- as.numeric(getPos("p1", Symbol=bar$instrumentId, Date = ts)[,2])
				pnl <- (limitPrice - entryPrice) * currentPos
				maxPnl <- (bar$high - entryPrice) * currentPos
				if(pnl > 200){
					addTxn("p1",bar$instrumentId, ts, -currentPos, limitPrice, TxnFees = 0)		
				}
				else if(pnl< -500){
					addTxn("p1",bar$instrumentId, ts, -currentPos, limitPrice, TxnFees = 0)		
				}
			}
#		}
		
		#context$placeOrder(Order$new(0, "I0", 100, limitPrice, 0.0))
		#message(context$position("I0")$quantity)
		formerClose <<- bar$close
		return(0)
    }, 
    setTarget = function(instrumentId, quantity, limitPx){

   	},
    handleQuote = function(quote) {
    	return(0)
    }, 
    handleExecution = function(execution){
    	return(0)
    }
  )
)



# A base class for a simple trading system
#' @export
SMISlopeTradingSystem <- setRefClass("SMISlopeTradingSystem", 
  # contains="com.fxbot.AbstractStrategy", # inheritance ..
  fields = c("context", "name", "formerClose", "barHist", "params"), 
  methods=list(
    initialize = function(parameterList, tradSysContext){
    	if(typeof(parameterList)!="list") {    		
    		stop("Parameter list needs to be of type >list<")
    	}
    	params <<- parameterList
      	name <<- "TradingSystem"
      	context <<- tradSysContext
      	formerClose <<- 0
      	barHist <<- xts()
    },    
    handleOHLC = function(barList){     	
	  	bar <- barList[[1]]
		xtsRow <- bar$payload[[1]]
		
		if(length(barHist)==0)
			barHist <<- xtsRow
		else 
			barHist <<- rbind(barHist, xtsRow)

		quantity <- 0
		limitPrice <- bar$close
		
		ts <- as.POSIXct(bar$timestamp, origin="1970-01-01")
		currentPos <- getPosQty("p1", Symbol=bar$instrumentId, Date = ts)
		regSlopeFrameSize <- 5
		rowCount <- nrow(barHist)		
		if(rowCount>50 && currentPos==0){
			s1 <- RSI(barHist[,4], n=2)
			slope1 <- coef(lm(barHist[(rowCount - (regSlopeFrameSize-1)):rowCount,4] ~ c(1:regSlopeFrameSize)))[2]			
			condition1 <- as.numeric(last(s1))>70 && slope1 > 0
			if(condition1){
				addTxn("p1",bar$instrumentId, ts, 100, limitPrice, TxnFees = 0)						
			}
		}
			

		
		if(currentPos>0){
			entryPrice <- as.numeric(getPos("p1", Symbol=bar$instrumentId, Date = ts)[,2])
			pnl <- (limitPrice - entryPrice) * currentPos
			maxPnl <- (bar$high - entryPrice) * currentPos
			if(pnl > 100){
				addTxn("p1",bar$instrumentId, ts, -currentPos, limitPrice, TxnFees = 0)		
			}
			else if(pnl< -400){
				addTxn("p1",bar$instrumentId, ts, -currentPos, limitPrice, TxnFees = 0)		
			}
		}
#		}
		
		formerClose <<- bar$close
		return(0)
    }, 
    setTarget = function(instrumentId, quantity, limitPx){

   	},
    handleQuote = function(quote) {
    	return(0)
    }, 
    handleExecution = function(execution){
    	return(0)
    }
  )
)
