\name{aqInit}
\alias{aqInit}
\title{Creates an AQ Master Server configuration}
\description{
	Creates an AQ Master Server (AQMS) configuration list. This configuration list object can be passed on to all aqr functions that connect to the AQMS.
}



\usage{
	aqInit()
}
\arguments{
\item{tsHost}{optional - the AQMS timeseries server host address}
\item{envir}{optional - the AQMS timeseries server port}
}
\examples{
	# creates a default configuration
	con = aqInit()
	
	# creates a con object to a specific AQMS
	con = aqInit(tsHost = "127.0.0.1", tsPort = 44444)

	

}
\keyword{initialization}
