\name{aqFilterOHLCSD}
\alias{aqFilterOHLCSD}
\title{Removes outliers based on standard deviation filters. Overwrites these with the open value.}
\usage{
aqFilterOHLCSD(ohlcv, sdFilterAmount = 10)
}
\arguments{
  \item{ohlcv}{an input Open/High/Low/Close/Volume dataset}

  \item{sdFilterAmount}{the amount of standard deviations a
  value has to be off, to be considered errenuous data}
}
\value{
retuns a filtered ohlcv object
}
\description{
Removes outliers based on standard deviation filters.
Overwrites these with the open value.
}

