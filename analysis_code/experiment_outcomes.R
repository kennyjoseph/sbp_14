require(data.table)
require(stringr)
require(bit64)
require(reshape)
require(ggplot2)
require(scales)
require(boot)
require(snowfall)

source("func.R")
top_dir <- "DATA_DIR"
setwd(top_dir)
theme_set(theme_bw(20))

##First of a few "sorry's"... one day will interface python and R correctly
path_to_python_script <- "PATH_TO/write_out_res.py" 
path_to_python <- "PATH_TO_PYTHON27"

#Check connection statistics
stats <- lapply(Sys.glob("*/*_stats.csv"), function(e){
    z <- fread(e,header=F);z$name <- e;z})
stats <- rbind.fill(stats)
names(stats) <- c("name","n200s","n400s","n500s","nClientEventsDropped",
                  "nConFail","nConnects","nDisconnects","nMessageDropped","nTweets","name")
names(stats)[length(names(stats))] <- "id"
stats$type <- as.vector(sapply(stats$id,function(l){str_split(l,"/")[[1]][1]}))
mean(ddply(stats,.(type),summarise,sd=sd(nTweets))$sd)

#########RUN ANALYSES (but not the bootstrapping for Fig. 2a yet)############

###set up cluster
run_configs <- Sys.glob("*")
sfInit(parallel=TRUE,cpus=15)
sfExport("get_data_from_directory")
sfExport("path_to_python_script")
sfExport("path_to_python")
sfExport("top_dir")
sfLibrary(data.table)
sfLibrary(stringr)
x <- parSapply(sfGetCluster(),run_configs, function(run_to_test){
    result = list()
    captured <- get_data_from_directory(paste0(run_to_test,"/*_captured.csv"))
    names(captured) <- c("Captured","LimitInc","Time","Name")
    captured$FractionCaptured <- with(captured,Captured/(Captured+LimitInc))
    result <- list(total=with(captured,sum(Captured)+sum(LimitInc))/5,
                   collected=sum(captured$Captured)/5)
    
    ###Get list of tweets
    tweets <- data.table(get_data_from_directory(
                            paste0(run_to_test,"/*_tweets.csv")))
    tweets$V1 <- factor(tweets$V1)
    ##Something strange w/ data.table and doing this call within it...made RAM blow up
    ##Will track it down someday, but probably something dumb I'm doing
    ##Not going to do this now, because it takes a while and we didn't have space beyond a sentence 
    ##in the paper
    #df <- data.frame(id=tweets$V1,
    #                time=strptime(tweets$V3,"%a %b %d %H:%M:%S +0000 %Y"))
    #tweets$Date <- df$time
    
    users_per_tweet <- tweets[,list(NUsers=length(unique(name)),
                                    Position=mean(V2) #, Date=Date[1]
                                    ), by=V1]
    setnames(users_per_tweet,"V1","id")
    
    ###Generate tweet_descrip.csv using the python script write_out_res.py
    ####***Because of twitter data sharing policies, you won't be able to reproduce this
    ####step. You'll have to pull down the tweets with the ids provided to do so
    ##(sorry, but python is just easier to use with MongoDB, which is where the tweets are stored)
    #system2(path_to_python,c(path_to_python_script,top_dir,run_to_test))
    
    data_descrip <- fread(paste0("tweet_descrip_",run_to_test,".csv"))
    data_descrip$id <- factor(data_descrip$id)
    bias_checks <- merge(
      data_descrip, 
      users_per_tweet,
      ##Try removing first and last to make sure findings hold
      #users_per_tweet[users_per_tweet$Date > ymd_hms("2013-11-06 05:00:00",tz="EST") &
      #                users_per_tweet$Date < ymd_hms("2013-11-06 06:30:00",tz="EST"),]
      by="id")
    write.csv(bias_checks,paste0("bias_ck_",run_to_test,".csv"))
    
    result <- c(result,Freq=data.frame(table(users_per_tweet$NUsers))$Freq)
})
sfStop()

df <- data.frame(t(x))
rnames <-rownames(df)
df <- data.frame(apply(df, 2, as.integer))
df$name <- rnames
df$percent_collected <-df$collected/df$total
########Calculate some values
#he number of total tweets using the given keywords ranged from X-Y
range(df$total)
mean(df$percent_collected)
mean(df$Freq5/df$collected)
#1,000,000 connections to the Streaming API, we would expect to obtain only approximately XXX\%  of the full data. 
mean(ddply(df, .(name), summarise, val=(collected+sum(total*((Freq1/total)/(2:100000))))/total)$val)

####Plot figure 1
plot_dat <-  df[,3:7]/df$total
names(plot_dat) <- c("1","2","3","4","5")
plot_dat$Type <- "Empirical"
plot_dat_2 <- ddply(df, .(name),function(t){dbinom(1:5,5,t$collected/t$total)})
plot_dat_2$name <- NULL
names(plot_dat_2) <- c("1","2","3","4","5")
plot_dat_2$Type <- "Expected"
plot_dat <- rbind(plot_dat,plot_dat_2)
p1 <- ggplot(melt(plot_dat), aes(variable,value,color=Type)) + geom_boxplot() 
p1 <- p1 + ylab("Percent of all tweets in T\nseen by only Xt samples") 
p1 <- p1 + xlab(expression(X[t]))
p1 <- p1 + scale_y_continuous(labels=percent)


###Now, compute stats for figure 2a #######
##what stats are we checking
to_check <- c("user_followers_count","user_friends_count",
              "hashtags_count","urls_count",
              "user_mentions_count","Position")

bias_checks <- rbindlist(lapply(Sys.glob("bias_ck*.csv"), function(e){
  z <- fread(e)
  z$name <- str_replace(str_replace(e,".csv",""),"bias_ck_","")
  z$user_followers_count <- log(z$user_followers_count)
  z$user_friends_count <- log(z$user_friends_count)
  z[,c(to_check,"NUsers", "name"),with=F]}))


##Figure 2a
fig_2a_dat <- data.table(melt(bias_checks[,
                        c("user_followers_count",
                          "user_friends_count",
                          "hashtags_count",
                          "urls_count",
                          "user_mentions_count",
                          "NUsers"),with=F],id="NUsers"))
fig_2a_dat <- fig_2a_dat[!is.nan(fig_2a_dat$value) & fig_2a_dat$value > -1000000,]
x <- fig_2a_dat[,list(mean=mean(value,na.rm=T),
                      se=sd(value)/sqrt(length(value))),
                by=c("NUsers","variable")]

x$variable <- factor(x$variable, labels=c("Log Num. Follwers","Log Num. Followed By","Num. Hastags","Num URLs","Num. Mentions"))
p2a <- ggplot(x, aes(NUsers,mean,ymin=mean-1.96*se,ymax=mean+1.96*se))
p2a <- p2a + geom_pointrange() + facet_wrap(~variable,scales="free",nrow=1)
p2a <- p2a+ xlab(expression(X[t]))
p2a <- p2a + ylab("value") 
p2a <- p2a + theme(strip.text=element_text(size=12),
                   axis.text.y =element_text(size=12))

##Figure 2b
bias_checks$xt <- paste0("Xt=",bias_checks$NUsers)
p2b <- ggplot(bias_checks, aes(Position)) + geom_histogram() 
p2b <- p2b + xlab("Position in stream after rate limit notice") 
p2b <- p2b + facet_wrap(~xt,scales="free_y",nrow=1) + scale_x_continuous(limits=c(0,50))

