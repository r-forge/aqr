
require(blotter)

# trading system context
#' @export
TradSysContext <- setRefClass("TradSysContext", 
  fields = list(positions = "list"), 
  methods = list(
  	initialize = function() {  			
  		},
	placeOrder = function(order) {	
		if((!isS4(order)) || class(order)[1]!="Order") {
    		stop("Place Order requires object of type >order<")
    	}
    	# we execute automatically taking the limit price for now. to keep it simple. 
    	pos <- position(order$instrumentId)
    	if(pos$quantity == 0){
    		pos$quantity <- order$quantity
    		pos$avgEntryPx <- pos$valuationPx <- order$limitPx
    		pos$pnl <- 0
    	} else {
    		oldQ <- pos$quantity
    		pos$quantity <- pos$quantity + order$quantity
    		if(abs(pos$quantity) > abs(oldQ)){
    			# need to change the avg entry price ... 
    			pos$avgEntryPx <- (oldQ * pos$avgEntryPx + order$quantity * order$limitPx) / pos$quantity
    		}
    		else if(sign(pos$quantity)!=sign(oldQ)){
    			pos$avgEntryPx <- order$limitPx
    		}    		
    	}
	},  
	valuation = function(quote) {
		# 
	},
	position = function(instrumentId_){
		# set a 0 position in case of need. 
		if(is.null(positions[[instrumentId_]])) 
			positions[[instrumentId_]] <<- Position$new(instrumentId_)
		# return the current position 
		return(positions[[instrumentId_]])
	}
  )
)

# contains a bar / ohlcv 
#' @export
Bar <- setRefClass("Bar", 
	fields = list(timestamp = "numeric", 
		instrumentId = "character", duration = "character",
		open = "numeric", high = "numeric", low = "numeric", 
		close = "numeric", volume = "numeric", 
		payload = "list"), 
	methods = list(
		initialize = function(timestamp_, instrumentId_, duration_, open_, high_, low_, close_, volume_, payload_) {
			timestamp <<- timestamp_
			instrumentId <<- instrumentId_
			duration <<- duration_
			open <<- open_
			high <<- high_
			low <<- low_
			close <<- close_
			volume <<- volume_
			payload <<- payload_
		}
	)	
)

# contains a market data quote
#' @export
Quote <- setRefClass("Quote", 
	fields = c(timestamp = "numeric", 
		instrumentId = "character",  
		bidPx = "numeric", askPx = "numeric", bidQ = "numeric", 
		askQ = "numeric", payload = "list")
)

# contains an execution
#' @export
Execution <- setRefClass("Execution", 
	fields = c("timestamp", "instrumentId", "price", "quantity")
)

# contains an order object
# ' quantity: positive is a BUY, negative is a SELL
#' @export
Order <- setRefClass("Order", 
	fields = list(timestamp = "numeric", 
		instrumentId = "character", 
		quantity = "numeric", 
		limitPx = "numeric", 
		stopPx = "numeric"), 
	methods = list(
		initialize = function(timestamp_, instrumentId_, quantity_, limitPx_, stopPx_) {
			timestamp <<- timestamp_
			instrumentId <<- instrumentId_
			quantity <<- quantity_
			limitPx <<- limitPx_
			stopPx <<- stopPx_
		}
	)
)

# contains a position entry in our portfolio 
#' @export
Position <- setRefClass("Position", 
	fields = list(instrumentId = "character", 
		quantity = "numeric", 
		avgEntryPx = "numeric", 
		valuationPx = "numeric", 
		pnl = "numeric"), 
	methods = list(
		valuation = function(valPx_){
			valuationPx <<- valPx_
			pnl <<- (valuationPx - avgEntryPx) * quantity
		}, 
		initialize = function(instrumentId_){
			valuationPx <<- 0
			avgEntryPx <<- 0
			quantity <<- 0
			instrumentId <<- instrumentId_
		}
	)
)


# A base class for a simple trading system
#' @export
TradingSystem <- setRefClass("TradingSystem", 
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
		if(rowCount>100 && currentPos==0){
			x1 <- which.max(as.numeric(barHist[(rowCount-maxFlDur):rowCount,4])) +1
			x2 <- x1 + 1
			#if(x2 == -1)
			#browser()
			#message("RowCount: ", rowCount, " - X1: " , x1, " - X2: ", x2)
			lf <- min(barHist[(rowCount-x2):rowCount,4])
			top <- max(barHist[(rowCount-x2):rowCount,4])
			 # browser()
			# message("X1 : ", x1)
			slope1 <- coef(lm(barHist[(rowCount - x1 ):rowCount,4] ~ c(1:(x1+1))))[2]
			lastAtr <- as.numeric(last(ATR(barHist[rowCount-40:rowCount, 2:4], n=40))[,2])
			x2 <- ifelse(slope1 < 0 && (top-lf) < (flagMin * lastAtr), (x1+1),100)
			# message("S1: ", slope1, " -TLF ",  (top-lf), " - Flag ", flagMin *lastAtr, " - X2 ", x2, " - x1 ", x1)
			if(x2>2 && x2<maxFlDur){

				y23 <- which.min(as.numeric(barHist[(rowCount-(maxPoleDur+x2)):rowCount,4]))
				bottom <- min(as.numeric(barHist[(rowCount-(maxPoleDur+x2)):rowCount,4]))
				pole <- top - bottom
				if((top-bottom)>(poleMin*lastAtr) && y23>x2){
					top <- max(as.numeric(barHist[(rowCount-x2):rowCount,4]))
					flagBot<- min(as.numeric(barHist[(rowCount-x2):rowCount,4]))
					upt1 <- bottom-min(as.numeric(barHist[(rowCount- upt1Bars):rowCount,4]))
					lrsx1 <- coef(lm(barHist[(rowCount - x1 + 1):rowCount,4] ~ c(1:x1)))[2] * 100
					lrsx2 <- coef(lm(barHist[(rowCount - x1):(rowCount-1),4] ~ c(1:x1)))[2] * 100
					condition1 <- (top-lf)<(flagMin*lastAtr) && (lrsx1 <0 || lrsx2 < 0)
					condition2 <- (pole>(poleMin*lastAtr))
					condition3 <- upt1 > 0
					#condition4 <- barsSinceExit
					message("Y23: ", y23)
					# browser()
					atrY23 <- as.numeric(last(ATR(barHist[(rowCount-40-y23-1):(rowCount-y23), 2:4], n=40))[,2])
					message("atr: ", atrY23)
					condition5 <-(((lastAtr / atrY23)-1)*100) > atrMin
					if(condition1 && condition2 && condition3 && condition5){
						addTxn("p1",bar$instrumentId, ts, 100, limitPrice, TxnFees = 0)						
					}
				}
			}

			#	browser()
		}

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
				if(abs(pnl)>50){
					addTxn("p1",bar$instrumentId, ts, -currentPos, limitPrice, TxnFees = 0)		
				}
				else if(abs(pnl)< -100){
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

Replayer <- setRefClass("Replayer", 
   fields = c("pnlMatrix"), 
  methods=list(
    initialize = function(){    	
    }, 
    replayCsv = function(context, symbol, tradingSysList_) {

    	# creating an instrument stub
    	currency("EUR")
		stock(symbol, currency="EUR", multiplier=1)
    	message("Replaying file ", symbol, " with ", length(tradingSysList_), " trading systems.")    	

		# getSymbols(symbol, from='2017-01-01', to='2020-03-01', src='yahoo', index.class=c("POSIXt","POSIXct"))
    	
    	# initialize the pnl matrix .. 
    	iid <- symbol

		initPortf('p1', symbols=c(symbol), currency = "EUR")
		initAcct('a1', portfolios='p1',initEq=10000, currency="EUR")		
		d1 <- get(symbol)	
    	for(i in 1:nrow(d1)){
    		q <- Quote$new()
    		q$askPx <- q$bidPx <- as.numeric(d1[i, 1])
    		q$instrumentId <- iid
    		context$valuation(q)
    		bar <- Bar$new(as.numeric(index(d1[i,1])), iid, "EOD", 
    			 as.numeric(d1[i, 1]), 
    			 as.numeric(d1[i, 2]), 
    			 as.numeric(d1[i, 3]), 
    			 as.numeric(d1[i, 4]), 
    			 as.numeric(d1[i, 5]), list())
    		bar$payload[[1]] <- d1[i,]
    		for(j in 1:length(tradingSysList_)){
    			ts <- tradingSysList_[[j]]
    			ts$handleOHLC(list(bar))
    		}
			q$askPx <- q$bidPx <- as.numeric(d1[i, 4])
			context$valuation(q)
    	}
		updatePortf(Portfolio="p1")
		updateAcct("a1")
		updateEndEq("a1")
		chart.Posn(Portfolio="p1")
		# let's get the summary statistics ...
		stats <- tradeStats(Portfolios=c("p1"), Symbols=c(symbol))
		return(stats)
		#browser()
    }
   )
)
