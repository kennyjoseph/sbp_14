df <- expand.grid(n_tweets_in_stream=6000,
                  n_tweets_in_pool=seq(10000,100000,by=10000),
                  n_streams=c(1,2,3,seq(6,60,by=10)))


run_sim <- function(f){
  ##How many total tweets during the interval?
  total_tweets <- f["n_tweets_in_stream"] *100
  
  ##What is the likelihood of any given tweet being captured in any given 
  ##stream?
  t_prob <- f["n_tweets_in_stream"]/f["n_tweets_in_pool"]
  ##Created the sample streams
  streams <- sample.int (2, 
                         as.integer(f["n_tweets_in_pool"]*f["n_streams"]), 
                         TRUE,
                         prob=c(1-t_prob,t_prob))-1L
  dim(streams) <- c(f["n_streams"],f["n_tweets_in_pool"])
  
  if(as.integer(f["n_streams"]) == 1){
    return(sum(streams) / f["n_tweets_in_pool"]);
  } else {
    return(sum(colSums(streams) > 0) / f["n_tweets_in_pool"]);
  }
  
}

n_trials <- 10
require(snowfall)
sfInit(parallel=TRUE,cpus=40)
sfExport("n_trials")
sfExport("run_sim")
z <- parApply(sfGetCluster(),df,1,function(f){
  res <- rep(0,n_trials)
  for(i in 1:n_trials){
    res[i] <- run_sim(f)
  }
  return(data.frame(mean=mean(res),sd=sd(res)))
})
sfStop()

require(plyr)
dat <- rbind.fill(z)
cbind(df,dat)
dat <- cbind(df,dat)
write.csv(dat,"sim2.csv")

