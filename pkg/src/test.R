dyn.load(paste("am", .Platform$dynlib.ext, sep=""))
# .Call("aqSubscribe", 20)
.Call("aqSubscribe", "/topic/TEXT")
#.Call("aqSubscribe", "/topic/MARK")
#.Call("aqSubscribe", "abcd56")
#.Call("aqSubscribe", "abcd56")
Sys.sleep(15)





