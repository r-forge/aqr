\name{aqLoadSeriesField}
\alias{aqLoadSeriesField}
\title{Loads one series field from an AQ Master Server}
\usage{
aqLoadSeriesField(seriesId, fieldId, freq, startDate, endDate, con = aqInit())
}
\arguments{
  \item{seriesId}{the series name}

  \item{fieldId}{the field name}

  \item{freq}{the frequency, must be one of ActiveQuant's
  enums}

  \item{startDate}{a start date in date8 format (yyyyMMdd)}

  \item{endDate}{an end date in date8 format (yyyyMMdd)}
}
\description{
Loads one series field from an AQ Master Server
}

