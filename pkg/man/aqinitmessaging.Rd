\name{aqInitMessaging}
\alias{aqInitMessaging}
\title{Initializes the messaging layer}
\description{	
  This function can be used to specify a host and a port different from localhost and 61618. It is recommended practice to call this function before using AQ-R's messaging functionality. 
}
\usage{
	aqInitMessaging(host = "localhost", port = 61618)
}

\arguments{
\item{host}{the STOMP host}
\item{port}{the STOMP port}
}
\keyword{messaging}
\keyword{initialization}
