sbp_14
=======

This repository holds the code used in the following article:

Joseph, K., Landwehr, P.M. and Carley, K.M. no date. 
Two 1%s don't make a whole: Comparing simultaneous samples from Twitter's Streaming API. 
to *hopefully* appear in SBP '14

Running the experiment
----------

The java code used to run the experiments is in experiment_code.  I used the following libraries as well:

mongo-2.10.1
hbc-core-1.3.0
gson-2.2.3
commons-lang3-3.1
 
Once you put everything together and spit out a runnable jar (i.e. from eclipse), you can run with
java -jar  CONFIG_FILE DATA_DIR TIME_TO_RUN

CONFIG_FILE specifies the set of users you are going to use to connect to the Streaming API.  The file has the form:
```
user_name
consumerKey
consumerSecret
accessToken
accessTokenSecret

user_name2
consumerKey2
consumerSecr2et
accessToken2
accessTokenSecret2

...
```

I'm sorry I didn't piece together a Maven build, but I probably will get there as this code develops.

Note also that you should have a mongodb instance running with no username or password in order to store the tweets.

Analysis Code
------------
The analysis code is run from experiment_outcomes.R.  The file is pretty well commented, but note that top_dir is the same as DATA_DIR from above.

Note that experiment_outcomes.R calls write_out_res.py and func.R.  The file sim_exper.R was a little simulation I ran to make sure the derivations in the paper were correct.



Data
-----
The data was too big to put on github, so you can find it @ http://www.dl.dropboxusercontent.com/u/53207718/data.tgz 

I can only give out part of the data, in particular I can't give out the entire tweets.  Instead, for each configuration run you get a separate directory (14 in all).
Within each, you have fifteen files: {username}\_captured.csv, {username}\_stats.csv, {username}\_tweets.csv for each of the five usernames we used.  

-{username}\_captured.csv contains details on how many tweets we saw in between each limit notice, how many we missed and how long the interval was

-{username}\_stats.csv contains connection statistics for our runs - see experiment_outcomes.R for the headers of the different columns

-{username}\_tweets.csv contains the tweet_id, the position metric for that tweet and a timestamp.

If you want the full data, you can just pull down the tweets that have the given ids in the file and stuff them into a mongodb.  Then you can run the analysis that we did for RQ3


