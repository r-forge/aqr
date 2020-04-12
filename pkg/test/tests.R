# test cases. 
require(aqr)

px <- c(10,10,10,10)
pos <- c(0,1,1,1)

pos2 <- approximateSLTP(px, px, px, 1, -1, pos)

px <- c(10,11,12,13)
pos <- c(0,1,1,1)
approximateSLTP(px, px, px, 10, -1, pos)

px <- c(10,11,12,13)
pos <- c(0,1,1,0)
approximateSLTP(px, px, px, 10, -1, pos)

px <- c(10,11,12,13,14,15,16,17,18,19,20)
pos <- c(0,1,1,1,1,1,-1,-1,-1,-1,0)
approximateSLTP(px, px, px, 2, -1, pos)







