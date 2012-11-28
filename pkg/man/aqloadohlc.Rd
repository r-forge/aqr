
\name{aqLoadOHLC}
\alias{aqLoadOHLC}
\title{Loads a OHLCV data set from AQMS}
\description{
      This function loads a Open/High/Low/Close/Volume data set from the AQ Master Server. 
      If the master server does not contain data for a specified series Id, it will return an empty xts object. 

}



\usage{
        aqLoadOHLC(seriesId, freq, startDate, endDate, con)
}
\arguments{
\item{seriesId}{the series Id}
\item{freq}{the granularity, must be one of RAW, MINUTES_1, ... EOD, EOM, EOW. }
\item{startDate}{start date in YYYYMMDD format}
\item{endDate}{end date in YYYYMMDD format}
\item{con}{optional - an AQMS configuration - defaults to a call aqInit() if not specified. }
}
\seealso{
        \code{\link{aqInit}}.
}
\examples{
\dontrun{
        # creates a default configuration
        con = aqInit()
        # load data 
        EURUSD = aqLoadOHLC("CNX.MDI.EUR/USD", "HOURS_1",  20120601, 20120901, con)
}
}

\keyword{fetching time series data}

