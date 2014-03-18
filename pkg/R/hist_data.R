
#' Builds an archive URL, based on connection parameters, seriesId, field, frequency and start and end date.  
#' @param con connection parameters, will be initialized with aqInit() if void
#' @param seriesId the series name
#' @param field the field to load 
#' @param freq a frequency string, such as HOURS_1
#' @param startDate the start date
#' @param endDate the end date 
#' @return the complete archive URL as character 
buildArchiveURL <- function(con=aqInit(), seriesId, field, freq, startDate, endDate, adders=NULL){
  url = paste("http://", con$tsHost, ":", con$tsPort,"/csv/?SERIESID=",seriesId,"&FREQ=",freq,"&FIELD=",field,"&STARTDATE=", startDate, "&ENDDATE=",endDate, sep="")
  if(!is.null(adders)){
    url=paste(url, adders, sep="")
  }
  return(url)
}

#' Saves an XTS object to csv file. 
#' 
#' @param filename where to save data to 
#' @param historyXts the input xts object
aqSaveXtsToCsv <- function(filename, historyXts){
	write.csv2(as.data.frame(historyXts), file=filename)
}

#' Loads a XTS object from CSV, to be used with our aqSaveXtsToCsv function. This method 
#' assumes that the fie's first column contains an interpretable timestmap. 
#'   
#' Implementation in progress (16 Feb 2014)
#' 
#' @param filename the csv file which to load as XTS. 
#' @return an XTS object
aqLoadXtsFromCsv <- function(filename){
	read.csv2(file=filename)
}

#' Loads EOD data from Yahoo and returns an XTS object. 
#' 
#' @param instrument a Yahoo Instrument ID
#' @param start a POSIXlt start date
#' @param end a POSIXlt end date
#' @return instrument prices as XTS object
aqLoadYahooEOD <-function(instrument,start=oneMonthAgo(), end=today()){
  if(is.null(instrument))
    stop("No instrument given to load. ")
    url <- paste("http://ichart.finance.yahoo.com/table.csv?s=", instrument, "&a=",start$mon,"&b=",start$mday,"&c=",(1900+start$year),"&d=",end$mon,"&e=",end$mday,"&f=",(1900+end$year),"&g=d&ignore=.csv", sep="")
    cat("Loading data from ", url, "\n")
    rawData <-read.csv(url)
    dataTable <- cbind(rawData[,2],rawData[,3],rawData[,4], rawData[,5],rawData[,6], rawData[,7])
    ret <- xts(x=dataTable, order.by=strptime(rawData[,1], format="%Y-%m-%d"))
    colnames(ret) <- c("OPEN", "HIGH", "LOW", "CLOSE", "VOLUME", "ADJUSTED_CLOSE")
    return(ret)  
}

aqLoadSeries <- function(seriesId, field, freq, startDate, endDate, con = aqInit(), useCache = FALSE, cacheDir = getwd(), useGZIP=TRUE) {
  cacheKey = paste(seriesId, "_", field,  "_", freq, "_", startDate,"_", endDate, ".history", sep="") 
  if(useCache){ 
    # let's check if the cacheDir exists. 
    if (!file.exists(paste(cacheDir, "/", sep = "/", collapse = "/"))) {
      message("Cache directory doesn't exist, creating it.")
      dir.create(file.path(cacheDir), recursive=TRUE)
    }
    message("Using cache key ", cacheKey, " in directory ", cacheDir)
    # ok, let's create the final cache key. 
    cacheKey = paste(cacheDir, "/", cacheKey, sep="")
  }
  if(useCache && file.exists(cacheKey)){
    message("Loading history from cache.")
    # let's return the file from cache. 
    load(cacheKey)
    # we know that the object was called xtsOhlcv
    return(xtsData)
  }
  data <- NULL
  if(useGZIP) {
    con <- gzcon(buildArchiveURL(con, seriesId, field, freq, startDate, endDate, adders="&GZIP=1"))
    txt <- readLines(con)
    data <- read.csv(textConnection(txt))
  }
  else{
    data <- read.csv(buildArchiveURL(con, seriesId, field, freq, startDate, endDate))
  }
  if(!is.null(data)){
    if(nrow(data[,3])>0){
      xtsData <- xts(data[,3], order.by=as.POSIXct(data[,1]/1000000000, origin="1970/01/01"))
      colnames(xtsData) <- c(field)
      
      if(useCache){
        message("Storing field history to cache.")
        save(xtsData, file=cacheKey)
      }
      # 
      return(xtsData)
    }			
  }
  return(xts())
  
  
}

#' Loads OHLC from an AQ Master Server
#' @param seriesId a series ID 
#' @param freq frequency in enumeration form, f.e. HOURS_1, MINUTES_1 
#' @param startDate a Date8 
#' @param endDate a Date8
#' @param con a fully initialized connection definition 
#' @param useCache a boolean that says whether you want use and cache data
#' @param cacheDir a directory name that will be used for caching if enabled
#' @return a XTS object
aqLoadOHLC <- function(seriesId, freq, startDate, endDate, con = aqInit(), useCache = FALSE, cacheDir = getwd(), useGZIP=TRUE){  
	if(is.null(con) || (is.null(con$tsHost)) || (is.null(con$tsHost))){
		# throw a fatal error. 
		stop("AQConfig list not configured properly.")
	}

	# load the individual columns.table  
	open <- read.csv(buildArchiveURL(con, seriesId, con$openField, freq, startDate, endDate))
	high <- read.csv(buildArchiveURL(con, seriesId, con$highField, freq, startDate, endDate))
	low <- read.csv(buildArchiveURL(con, seriesId, con$lowField, freq, startDate, endDate))
	close <- read.csv(buildArchiveURL(con, seriesId, con$closeField, freq, startDate, endDate))
	volume <- read.csv(buildArchiveURL(con, seriesId, con$volField, freq, startDate, endDate))
  
  olhcv <- merge(open,high,low,close,volume)
	return(ohlcv)
}

#' stores a matrix onto an AQ Master Server
#' 
#' @param seriesId a series ID to store
#' @param freq the frequency, must be one of AQ's enums
#' @param data the data as XTS object
#' @param con a connection object, will be initialized by aqInit by default
#' @param silent whether  it should print storage diagnostics. 
aqStoreMatrix <- function(seriesId, freq, data, con=aqInit(), silent=FALSE){
  for(i in colnames(data)){
    aqStoreSeriesField(seriesId, i, freq, data[,i], con, silent);
  }
}

#' Loads one series field from an AQ Master Server
#' @param seriesId the series name
#' @param fieldId the field name
#' @param freq the frequency, must be one of ActiveQuant's enums
#' @param startDate a start date in date8 format (yyyyMMdd)
#' @param endDate an end date in date8 format (yyyyMMdd)
#' @param con a connection object
#' @return the loaded series as XTS object
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

#' Stores one series field to an AQ Master Server, typicall called from aqStoreSeries. 
#' This function assumes that data is either a zoo object, or that is a matrix with two columns where the first column contains a time series index in NANOSECONDS(!!!)
#' @param seriesId a series name
#' @param fieldId the field ID of this data series
#' @param freq a frequency string, must be one of AQ's suported enum names
#' @param data the data as XTS object
#' @param con a connection object, will be initialized by aqInit by default
#' @param silent whether  it should print storage diagnostics. 
aqStoreSeriesField <- function(seriesId, fieldId, freq, data, con = aqInit(), silent=FALSE){

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


