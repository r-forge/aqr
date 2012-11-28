\name{aqDataReady}
\alias{aqDataReady}
\title{Is data ready? }
\description{	
  This message retrieves a list of all messaging channels for which there is data. 
  The result set is a list with channel names. 

  This function is a quick call. Unless the aqWaitForData method, this method will not wait for data arrive.  
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
