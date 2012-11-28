\name{aqSubscribeChannel}
\alias{aqSubscribeChannel}
\title{Subscribe to a messaging channel}
\description{	
  Subscribes to a messaging channel. Data will flow into the bridge and it will accumulate that data. 
}
\usage{
	aqSubscribeChannel(channel)
}
\arguments{
\item{channel}{one channel name}
}


\examples{
\dontrun{

>aqSubscribeChannel("R-PROCESSOR-2")
[1] "Subscribed."
>
 
}
}

\keyword{messaging}



