\name{aqInit}
\alias{aqInit}
\title{Creates an AQ Master Server configuration}
\description{
	Creates an AQ Master Server (AQMS) configuration list. This configuration list object can be passed on to all aqr functions that connect to the AQMS.
}


\usage{
	aqInit()
}
\examples{
\dontrun{
	# creates a default configuration
	con = aqInit()
	
	# set the the tshost to a specific AQMS
	con$tsHost = "127.0.0.1"
	con$tsHost = 21231

	
}
}
\keyword{initialization}
