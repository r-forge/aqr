\name{aqHourlyStat}
\alias{aqHourlyStat}
\title{applies a function across hour slots. Internally, it iterates over 0:23 and selects all rows which fit into this hour.}
\usage{
aqHourlyStat(x, f = mean)
}
\arguments{
  \item{x}{the input xts object}

  \item{f}{the function to apply}
}
\value{
a matrix that contains hourly data
}
\description{
applies a function across hour slots. Internally, it
iterates over 0:23 and selects all rows which fit into this
hour.
}

