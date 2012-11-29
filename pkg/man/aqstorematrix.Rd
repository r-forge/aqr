\name{aqStoreMatrix}
\alias{aqStoreMatrix}
\title{Stores an xts matrix}
\description{
	Stores an xts matrix into AQMS. 
}

\usage{
	aqStoreMatrix(seriesId, freq, data, con = aqInit(), silent=FALSE) 
}
\arguments{
\item{seriesId}{the name of the series}
\item{freq}{the frequency}
\item{data}{a data object, preferrably a zoo object}
\item{con}{an optional connectivity object}
\item{silent}{whether the function should print the server's status message or not}
}
\examples{
\dontrun{

con = aqInit()
aqStoreMatrix("EURUSD", "HOURS_1", hourlyData, con = con) 

}
}
\keyword{storing time series data}
