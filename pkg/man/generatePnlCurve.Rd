\name{generatePnlCurve}
\alias{generatePnlCurve}
\title{method to generate a pnl curve from a running position.
bids, asks and running position must have the same length.
Can compute the pnl from one price to the other, but only for one asset!
Does not take time into account - if you need signal delays, lag
all input data on your own.}
\usage{
generatePnlCurve(bidPrices, askPrices, runningPosition, messages = FALSE)
}
\arguments{
  \item{bidPrices}{an array of bid prices}

  \item{askPrices}{an array of ask prices}

  \item{runningPosition}{an array that contains a vector of
  the position}
}
\value{
This function returns a plain double array with pnl changes
(uncumulated) and not an XTS series.
}
\description{
method to generate a pnl curve from a running position.
bids, asks and running position must have the same length.
Can compute the pnl from one price to the other, but only
for one asset! Does not take time into account - if you
need signal delays, lag all input data on your own.
}
\note{
all input arrays must have the same length.
}

