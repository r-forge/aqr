aqLoadOHLC <- function(seriesId, freq, startDate, endDate, con = aqInit()){  
	if(is.null(con) || (is.null(con$tsHost)) || (is.null(con$tsHost))){
		# throw a fatal error. 
		stop("AQConfig list not configured properly.")
	}
	 
	# load the individual columns.table 
	open = read.csv(paste("http://", con$tsHost, ":", con$tsPort,"/?SERIESID=",seriesId,"&FREQ=",freq,"&FIELD=OPEN&STARTDATE=", startDate, "&ENDDATE=",endDate, sep=""))
	high = read.csv(paste("http://", con$tsHost, ":", con$tsPort,"/?SERIESID=",seriesId,"&FREQ=",freq,"&FIELD=HIGH&STARTDATE=", startDate, "&ENDDATE=",endDate, sep=""))
	low = read.csv(paste("http://", con$tsHost, ":", con$tsPort,"/?SERIESID=",seriesId,"&FREQ=",freq,"&FIELD=LOW&STARTDATE=", startDate, "&ENDDATE=",endDate, sep=""))
	close = read.csv(paste("http://", con$tsHost, ":", con$tsPort,"/?SERIESID=",seriesId,"&FREQ=",freq,"&FIELD=CLOSE&STARTDATE=", startDate, "&ENDDATE=",endDate, sep=""))
	volume = read.csv(paste("http://", con$tsHost, ":", con$tsPort,"/?SERIESID=",seriesId,"&FREQ=",freq,"&FIELD=VOLUME&STARTDATE=", startDate, "&ENDDATE=",endDate, sep=""))
	# convert everything to XTS. 
	if(nrow(volume)==0)
		volume = NA 
	else 
		volume = volume[,3]
	ohlcv = cbind(open[,3], high[,3], low[,3], close[,3], volume)
 	if(nrow(ohlcv)>0){
	  	xtsOhlcv= xts(ohlcv, order.by=as.POSIXct(open[,1]/1000000000, origin="1970/01/01"))
	  	colnames(xtsOhlcv) <- c("OPEN", "HIGH", "LOW", "CLOSE", "VOLUME")

	  	# 
		return(xtsOhlcv)
	}
	else{	
		return(NA)
	}
}


aqLoadSeriesField <- function(seriesId, fieldId, freq, startDate, endDate, con = aqInit()){
	if(is.null(con) || (is.null(con$tsHost)) || (is.null(con$tsHost))){
		# throw a fatal error. 
		stop("AQConfig list not configured properly.")
	}

	data = read.csv(paste("http://", con$tsHost, ":", con$tsPort,"/?SERIESID=",seriesId,"&FREQ=",freq,"&FIELD=",fieldId,"&STARTDATE=", startDate, "&ENDDATE=",endDate, sep=""))
	if(nrow(data)>0){
		dataXts = xts(data, order.by=as.POSIXct(data[,1]/1000000000, origin="1970/01/01"))
		return(dataXts)
	}
	else{
		return(NA)
	}
}

