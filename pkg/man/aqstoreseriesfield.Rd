\name{aqStoreSeriesField}
\alias{aqStoreSeriesField}
\title{Stores a single column time series}
\description{
	Stores a single column time series to the master server. 
}



\usage{
	aqStoreSeriesField(seriesId, fieldId,freq, data, con = aqInit(), silent=FALSE) 
}
\arguments{
\item{seriesId}{the name of the series}
\item{fieldId}{the name of the field within the series}
\item{freq}{the frequency}
\item{data}{a data object, preferrably a zoo object}
\item{con}{an optional connectivity object}
\item{silent}{whether the function should print the server's status message or not}
}
\examples{
\dontrun{

con = aqInit()
aqStoreSeriesField("EURUSD", "SMA14","HOURS_1", sma, con=con) 

}
}
\keyword{storing time series data}
