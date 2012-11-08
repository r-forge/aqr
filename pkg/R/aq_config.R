# returns a configuration object. 
aqInit <- function(){
	# used to set default parameters. 
	# all these can be overriden. 

	ret = list()
	ret$tsHost = "127.0.0.1"
	ret$tsPort = 44444

	return(ret)

}


