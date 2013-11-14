get_data_from_directory <- function(glob_str){
  began <- F
  for(f in Sys.glob(glob_str)){
    if (!began){
      dat <- fread(f, header=F)
      dat$name <- str_replace(basename(f),".csv","")
      began <- T
    } else {
      tmp <- fread(f,header=F)
      tmp$name <- str_replace(basename(f),".csv","")
      dat <- rbind(dat,tmp)
    }
  }
  return(dat)
  
}

get_bootstrap_samples <- function(dat, expr, nsamples=1000){ 
  nrows <- nrow(dat)
  sapply(1:nsamples,function(i){
    samp <- sample.int(nrows,nrows,replace=T)
    dat[samp,eval(expr),]
  })
}