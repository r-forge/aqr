\name{aqDataReady}
\alias{aqDataReady}
\title{Is data ready? }
\description{	
  This message retrieves a list of all messaging channels for which there is data. 
  The result set is a list with channel names. 

  This function is a quick call. Other than the aqWaitForData method, this method will not block until data becomes available. 
}
\usage{
	aqDataReady()
}


\examples{
\dontrun{

> aqDataReady()
     [,1]         
[1,] "/topic/R-PROCESSOR-2"
> 
 
}
}

\keyword{messaging}
