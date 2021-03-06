% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cst.R
\name{bd2gcj}
\alias{bd2gcj}
\title{Convert coordinates}
\usage{
bd2gcj(bdLat, bdLon)
}
\arguments{
\item{bdLat}{a numeric latitude in BD-09}

\item{bdLon}{a numeric longitude in BD-09}
}
\value{
a data.frame with variables lat/lng
}
\description{
converts lat/lon coordintes from BD-09 to GCJ-02
}
\details{
BD-09 coordinate system is used by Baidu Maps and further encrypted based on 
GCJ-02 coordinates.
}
\examples{
\dontrun{
# latitude/longitude coordinates of Beijing railway station
# GCJ-02: (39.90245, 116.42703)
# BD-09:  (39.90851, 116.43351)
bd2gcj(39.90851, 116.43351) # correct
# convert multiple coordinates
bd2gcj(c(40.00541, 39.99299), c(116.3330, 116.3124))
}
}
\author{
Jun Cai (\email{cai-j12@mails.tsinghua.edu.cn}), PhD candidate from 
Department of Earth System Science, Tsinghua University
}
\seealso{
\code{\link{gcj2bd}}, \code{\link{conv}}.

\url{http://blog.csdn.net/coolypf/article/details/8569813} for C version 
source code.
}

