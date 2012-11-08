buildArchiveURL <- function(con, seriesId, field, freq, startDate, endDate){
  url = paste("http://", con$tsHost, ":", con$tsPort,"/csv/?SERIESID=",seriesId,"&FREQ=",freq,"&FIELD=",field,"&STARTDATE=", startDate, "&ENDDATE=",endDate, sep="")
  return(url)
}

aqLoadOHLC <- function(seriesId, freq, startDate, endDate, con = aqInit()){  
	if(is.null(con) || (is.null(con$tsHost)) || (is.null(con$tsHost))){
		# throw a fatal error. 
		stop("AQConfig list not configured properly.")
	}
	 
	# load the individual columns.table 
	open = read.csv(buildArchiveURL(con, seriesId, "OPEN", freq, startDate, endDate))
	high = read.csv(buildArchiveURL(con, seriesId, "HIGH", freq, startDate, endDate))
	low = read.csv(buildArchiveURL(con, seriesId, "LOW", freq, startDate, endDate))
	close = read.csv(buildArchiveURL(con, seriesId, "CLOSE", freq, startDate, endDate))
	volume = read.csv(buildArchiveURL(con, seriesId, "VOLUME", freq, startDate, endDate))
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

	data = read.csv(buildArchiveURL(con, seriesId, fieldId, freq, startDate, endDate))
	if(nrow(data)>0){
		dataXts = xts(data, order.by=as.POSIXct(data[,1]/1000000000, origin="1970/01/01"))
		return(dataXts)
	}
	else{
		return(NA)
	}

}

aqStoreSeriesField <- function(seriesId, fieldId, freq, data, con = aqInit(), silent=FALSE){
	require(RCurl)	
	convertedData =capture.output(write.table(data, row.names=FALSE,  col.names=FALSE,quote=FALSE, sep=","))
	response = postForm(paste("http://", con$tsHost, ":", con$tsPort, "/csv/", sep=""), 
		SERIESID=seriesId,
		FIELD = fieldId, 
		FREQ = freq, 
		DATA = convertedData, style="httppost")
	if(!silent){
	  cat(rawToChar(response))
	}
	
}

