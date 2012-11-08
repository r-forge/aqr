\name{buildArchiveURL}
\alias{buildArchiveURL}
\title{Utility function to generate the archive access url.}
\description{
	As access to the AQ Master Server (AQMS) is essentially an HTTP GET call, this method constructs the corresponding URL to fetch data. Under certain circumstances, the user might want to reimplement this function, for example when the AQMS archive access has been deployed into a servlet container. 
}




\usage{
	buildArchiveURL(con, seriesId, field, freq, startDate, endDate)
}
\arguments{
\item{con}{Connection object which contains tsHost and tsPort}
\item{seriesId}{The series ID that is to be loaded}
\item{field}{the field that is to be loaded}
\item{freq}{The frequency}
\item{startDate}{from when...}
\item{endDate}{to when ...}
}
\keyword{initialization}
