buildArchiveURL <- function(con, seriesId, field, freq, startDate, endDate){
  url = paste("http://", con$tsHost, ":", con$tsPort,"/csv/?SERIESID=",seriesId,"&FREQ=",freq,"&FIELD=",field,"&STARTDATE=", startDate, "&ENDDATE=",endDate, sep="")
  return(url)
}

aqLoadOHLC <- function(seriesId, freq, startDate, endDate, con = aqInit(), useCache = false){  
	if(is.null(con) || (is.null(con$tsHost)) || (is.null(con$tsHost))){
		# throw a fatal error. 
		stop("AQConfig list not configured properly.")
	}

  cacheKey = paste(seriesId, "_", freq, "_", startDate,"_", endDate, ".cache")
  if(useCache && file.exists(cacheKey)){
    # let's return the file from cache. 
    load(cacheKey)
    return(xtsOhlcv)
  }
  
	# load the individual columns.table 
	open = read.csv(buildArchiveURL(con, seriesId, con$openField, freq, startDate, endDate))
	high = read.csv(buildArchiveURL(con, seriesId, con$highField, freq, startDate, endDate))
	low = read.csv(buildArchiveURL(con, seriesId, con$lowField, freq, startDate, endDate))
	close = read.csv(buildArchiveURL(con, seriesId, con$closeField, freq, startDate, endDate))
	volume = read.csv(buildArchiveURL(con, seriesId, con$volField, freq, startDate, endDate))
	if(nrow(high)==nrow(open) && nrow(low) == nrow(open) && nrow(close) == nrow(open) && nrow(open)>0 ){
	  # convert everything to XTS. 
	  if(nrow(volume)==0)
		  volume = NA 
	  else 
		  volume = volume[,3]
	  ohlcv = cbind(open[,3], high[,3], low[,3], close[,3], volume)
	  if(nrow(ohlcv)>0){
		  xtsOhlcv= xts(ohlcv, order.by=as.POSIXct(open[,1]/1000000000, origin="1970/01/01"))
		  colnames(xtsOhlcv) <- c("OPEN", "HIGH", "LOW", "CLOSE", "VOLUME")

      if(useCache){
        save(xtsOhlcv, file=cacheKey)
      }
		  # 
		  return(xtsOhlcv)
	  }			
	}
  
	# still here. 
	return(xts())
}

aqStoreMatrix <- function(seriesId, freq, data, con=aqInit(), silent=FALSE){
  for(i in colnames(data)){
    aqStoreSeriesField(seriesId, i, freq, data[,i], con, silent);
  }
}

aqLoadSeriesField <- function(seriesId, fieldId, freq, startDate, endDate, con = aqInit()){
	if(is.null(con) || (is.null(con$tsHost)) || (is.null(con$tsHost))){
		# throw a fatal error. 
		stop("AQConfig list not configured properly.")
	}

	data <- read.csv(buildArchiveURL(con, seriesId, fieldId, freq, startDate, endDate))
	if(nrow(data)>0){
		dataXts = xts(data[,3], order.by=as.POSIXct(data[,1]/1000000000, origin="1970/01/01"))
		return(dataXts)
	}
	else{
		return(xts())
	}

}

# this function assumes that data is either a zoo object, or that is a matrix with two columns where the first column contains a time series index in NANOSECONDS(!!!)
aqStoreSeriesField <- function(seriesId, fieldId, freq, data, con = aqInit(), silent=FALSE){
	require(RCurl)	

	if(ncol(data)>2){
	  warning("Only the first data column will be stored.")
	}
  
	toBeStored <- c()
	# let's check if we have a zoo object. 
	if(sum(class(data)=="zoo")>0){
	  # convert it to nano seconds. 
	  toBeStored <- cbind(as.numeric(as.POSIXct(index(data))) * 1000000000, data[,1])
	}
	else{
	  # 
	  warning("No zoo object. First column assumed to be timestamp in nanoseconds and second column assumed to contain data series.") 
	  toBeStored = data[,1:2]
	}
	

	convertedData <- capture.output(write.table(format(toBeStored, scientific=FALSE), row.names=FALSE,  col.names=FALSE,quote=FALSE, sep=","))
	response <- postForm(paste("http://", con$tsHost, ":", con$tsPort, "/csv/", sep=""), 
		SERIESID=seriesId,
		FIELD = fieldId, 
		FREQ = freq, 
		DATA = convertedData, style="httppost")
	if(!silent){
	  cat(rawToChar(response))
	}
	return(rawToChar(response))
}


