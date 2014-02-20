\name{aqLoadYahooEOD}
\alias{aqLoadYahooEOD}
\title{Loads EOD data from Yahoo and returns an XTS object.}
\usage{
aqLoadYahooEOD(instrument, start = oneMonthAgo(), end = today())
}
\arguments{
  \item{instrument}{a Yahoo Instrument ID}

  \item{start}{a POSIXlt start date}

  \item{end}{a POSIXlt end date}
}
\value{
instrument prices as XTS object
}
\description{
Loads EOD data from Yahoo and returns an XTS object.
}

