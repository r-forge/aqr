\name{aqPoll}
\alias{aqPoll}
\title{Poll data from the messaging bridge}
\description{	
  Used to poll data from the messaging bridge. 
  As the time of this writing (0.2), individual messages are separated by "\\n".
  In a future version, this function will return a list object. 
}
\usage{
	aqPoll()
}




\examples{
\dontrun{
> aqPoll()
     [,1]
[1,] "/topic/TEXT"
     [,2]
[1,] "TEST1\nTEST2\nTEST3\n"
> 
}
}


\keyword{messaging}
