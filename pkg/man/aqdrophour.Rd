\name{aqDropHour}
\alias{aqDropHour}
\title{Drop data of one hour}
\description{	
  This function drops all data for one specific hour from an xts data set. 
}
\usage{
	aqDropHour(x, hour)
}
\arguments{
\item{x}{input xts data set}
\item{hour}{which hour to drop}
}


\examples{
\dontrun{

# will drop data all data of 10h
aqDropHour(anXtsObj, 10)
}
}

\keyword{utilities}
