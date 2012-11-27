\name{aqFilterOHLCSD}
\alias{aqFilterOHLCSD}
\title{Trivial stdev filter}
\description{	
  OHLC data could contain outliers. This function uses a simple stdev data evaluation to clear data outliers. Data outliers are overwritten with the open value. 
}
\usage{
	aqFilterOHLCSD(ohlcv, sdFilterAmount = 10)
}

\arguments{
\item{ohlcv}{open/high/low/close input set}
\item{sdFilterAmount}{multiplied by which a data point has to deviate from sd to count as an outlier}
}

\keyword{utilities}
