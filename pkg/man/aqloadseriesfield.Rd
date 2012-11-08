\name{aqLoadSeriesField}
\alias{aqLoadSeriesField}
\title{Load a single column time series}
\description{
	Loads a single column time series from the master server. 
}



\usage{
	aqLoadSeriesField(...)
}
\arguments{
\item{seriesId}{the name of the series}
\item{fieldId}{the name of the field within the series}
\item{freq}{the frequency}
\item{startDate}{the start date in date8 format}
\item{endDate}{the end date in date8 format}
\item{con}{an optional connectivity object}
}
\examples{
\dontrun{

con = aqInit()
aqLoadSeriesField("EURUSD", "SMA14", "HOURS_1", 20120101, 20130101, con = con)
}
}
\keyword{fetching time series data}
