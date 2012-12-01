\name{aqDailyStat}
\alias{aqDailyStat}
\title{Applies a function to a group of data per week day}
\description{
	This function groups data by week day and applies a function to it. 
}
\usage{
	aqDailyStat(x, f = mean)
}
\arguments{
\item{x}{an xts data set}
\item{f}{a function which should be applied week day wise}
}
\keyword{utilities}
