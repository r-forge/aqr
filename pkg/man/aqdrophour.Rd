\name{aqDropHour}
\alias{aqDropHour}
\title{removes all data that belongs to a specific hour from an input data set.}
\usage{
aqDropHour(x, hour)
}
\arguments{
  \item{hour}{the hour to remove from this data set, e.g. 8
  or 15, etc.}

  \item{x}{an input xts object}
}
\value{
a dataset in which all information for this hour has been
dropped.
}
\description{
removes all data that belongs to a specific hour from an
input data set.
}

