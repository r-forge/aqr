library(aqr)

o=h=l=c=c(1,2,3,4,5,6)
pos = c(1,1,1,1,1,1)
message("length: ", as.integer(length(pos)))
x = approximateSLTP(h,l,c,2.5,-100,pos, messages=TRUE)
message(x[,1])
message(x[,2])

message("--------")

o=h=l=c=c(2,4,2,2,2,2)
pos = c(1,0,0,0,0,0)
message("length: ", as.integer(length(pos)))
x = approximateSLTP(h,l,c,2.5,-1.5,pos, messages=TRUE)
message(x[,1])
message(x[,2])

message("--------")

o=h=l=c=c(2,3,3,3,4,5)
pos = c(1,0,0,-1,-1,0)
message("length: ", as.integer(length(pos)))
x = approximateSLTP(h,l,c,2.5,-1.5,pos, messages=TRUE)
message(x[,1])
message(x[,2])