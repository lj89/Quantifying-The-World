#setwd('C:/Users/danie/Documents/GitHub/Quantifying-The-World/Case Study 2')
library(XML)
ubase = "http://www.cherryblossom.org/"

womenURLs = 
  c("results/1999/cb99f.html", 
    "results/2000/Cb003f.htm", 
    "results/2001/oof_f.html",
    "results/2002/ooff.htm", 
    "results/2003/CB03-F.HTM",
    "results/2004/womennet.htm", 
    "results/2005/womennet.htm", 
    "results/2006/womennet.htm", 
    "results/2007/women.htm", 
    "results/2008/women.htm", 
    "results/2009/09cucb-F.htm",
    "results/2010/2010cucb10m-f.htm", 
    "results/2011/2011cucb10m-f.htm",
    "results/2012/2012cucb10m-f.htm")

urls = paste(ubase, womenURLs, sep="")

extractResTable =

  function(url = "http://www.cherryblossom.org/results/2009/09cucb-F.htm",
           year = 1999, sex = "female", file = NULL)
  {
    doc = htmlParse(url, encoding="UTF-8")
    #doc = htmlParse(url) # uncomment if running on mac
    
    if (year == 2000) {
      ff = getNodeSet(doc, "//font")
      txt = xmlValue(ff[[4]])
      els = strsplit(txt, "\r\n")[[1]]
    }
    
    else if (year == 1999 & sex == "female") {
      pres = getNodeSet(doc, "//pre")
      txt = xmlValue(pres[[1]])
      els = strsplit(txt, "\n")[[1]]   
    }
    else {
      pres = getNodeSet(doc, "//pre")
      txt = xmlValue(pres[[1]])
      els = strsplit(txt, "\r\n")[[1]]   
    } 
    
    if (is.null(file)) return(els)
    # Write the lines as a text file.
    writeLines(els, con = file)
  }

years = 1999:2012
womenTables = mapply(extractResTable, url = urls, year = years)

# womenTables <- list()
# for(i in 1:length(years)){
#   womenTables[[i]] <- try(extractResTable(url=urls[i], year=years[i]))
# }

womenTables = mapply(extractResTable, url = urls, year = years)
names(womenTables) = years
sapply(womenTables, length)


#### Confirmation that the 1999 and other years have consistent formatting
womenTables$'1999'[1:10]
womenTables[[2]][1:10]

#### Save the outputs to R data
save(womenTables, file = "CBWomenTextTables.rda")

#### Save the outputs to text files to stay in sync with the book
# first3 = substr(womenTables[[14]], 1,3)
#  which(first3 == "===")

els=womenTables[[14]]
eqIndex = grep("^===", els)

spacerRow = els[eqIndex]
headerRow = els[eqIndex - 1]
headerRow = tolower(headerRow)
ageStart = regexpr("ag", headerRow)
body = els[ -(1:eqIndex) ]
age = substr(body, start = ageStart, stop = ageStart + 1)
blankLocs = gregexpr(" ", spacerRow)
searchLocs = c(0, blankLocs[[1]])

Values = mapply(substr, list(body),
                start = searchLocs[ -length(searchLocs)] + 1,
                stop = searchLocs[ -1 ] - 1)

findColLocs = function(spacerRow) {
  spaceLocs = gregexpr(" ", spacerRow)[[1]]
  rowLength = nchar(spacerRow)
  
  if (substring(spacerRow, rowLength, rowLength) != " ")
    return( c(0, spaceLocs, rowLength + 1))
  else return(c(0, spaceLocs))
}

selectCols = function(colNames, headerRow, searchLocs)
  {
  sapply(colNames,
         function(name, headerRow, searchLocs)
           {
           startPos = regexpr(name, headerRow)[[1]]
           if (startPos == -1)
             return( c(NA, NA) )
           
           index = sum(startPos >= searchLocs)
           c(searchLocs[index] + 1, searchLocs[index + 1])
           #c(searchLocs[index] + 1, searchLocs[index + 1] - 1)
           },
         headerRow = headerRow, searchLocs = searchLocs )
  } 


searchLocs = findColLocs(spacerRow)
ageLoc = selectCols("ag", headerRow, searchLocs)
ages = mapply(substr, list(body),
              start = ageLoc[1,], stop = ageLoc[2, ])

#summary(as.numeric(ages))

shortColNames = c("name", "home", "ag", "gun", "net", "time")
#Verify that age is consistent in all files
womenTables[[1]][1:5]
womenTables[[2]][1:5]
####WomenTables[[3]] has no header row####
womenTables[[3]][1:10]
womenTables[[4]][1:5]
womenTables[[5]][1:5]
womenTables[[6]][1:10]
womenTables[[7]][1:10]
womenTables[[8]][1:10]
womenTables[[9]][1:10]
womenTables[[10]][1:10]
womenTables[[11]][1:10]
womenTables[[12]][1:10]
womenTables[[13]][1:10]
womenTables[[14]][1:10]

locCols = selectCols(shortColNames, headerRow, searchLocs)

Values = mapply(substr, list(body), start = locCols[1, ],
                stop = locCols[2, ])

#class(Values)
colnames(Values) = shortColNames

extractVariables =
  function(file, varNames =c("name", "home", "ag", "gun",
                             "net", "time"))
    {
  
    eqIndex = grep("^===", file)
    spacerRow = file[eqIndex]
    headerRow = tolower(file[ eqIndex - 1 ])
    #blanks = grep("^[[:blank:]]*$", womenTables[['2005']])
    body = file[ -(1 : eqIndex) ]
    searchLocs = findColLocs(spacerRow)
    locCols = selectCols(varNames, headerRow, searchLocs)
    Values = mapply(substr, list(body), start = locCols[1, ],
                    stop = locCols[2, ])
    colnames(Values) = varNames
    
    invisible(Values) #Use invisible in place of return in a function when the returned output should not be printed.
  }

##Tee hee lets be clever
womenTables[[3]][1:3]<-womenTables[[4]][1:3]
womenResMat = lapply(womenTables[1:14], extractVariables)
length(womenResMat)
sapply(womenResMat, nrow) # looks good

#########################Data Cleansing#######################################
#age = sapply(womenResMat, function(x) as.numeric(x[ , 'ag']))
#boxplot(age, ylab = "Age", xlab = "Year")
#age<-as.numeric(womenResMat[['2012']][ , 'ag'])
#unique(age)
#boxplot(age, ylab = "Age", xlab = "Year")
#sapply(age, function(x) sum(is.na(x)))

###########Found that women data ages are not as terrible as the men's were.
###########We may want to lok at NAs in 2005 and a youngster in 2001
#i.e.
# sapply(age, function(x) sum(is.na(x)))
# 1999 2000 2001 2002 2003 2004 2005 2006 2007 
# 4    1    1    5    2    2   11    3    4 
# 2008 2009 2010 2011 2012 
# 0    4    2    0    0 

# only include variables needed for our analysis
createDF =
  function(Res, year, sex)
  {
    # Determine which time to use
    # useTime = if( !is.na(Res[1, 'net']) )
    #   Res[ , 'net']
    # else if( !is.na(Res[1, 'gun']) )
    #   Res[ , 'gun']
    # else
    #   Res[ , 'time']
    #runTime = convertTime(useTime)
    Results = data.frame(year = rep(year, nrow(Res)),
                         sex = rep(sex, nrow(Res)),
                         name = Res[ , 'name'],
                         home = Res[ , 'home'],
                         age = as.numeric(Res[, 'ag']),
                         #runTime = runTime,
                         stringsAsFactors = FALSE)
    invisible(Results)
  }

womenDF = mapply(createDF, womenResMat, year = 1999:2012,
               sex = rep("F", 14), SIMPLIFY = FALSE)

sapply(womenDF, function(x) sum(is.na(x$age)))
cbWomenDF = do.call(rbind, womenDF)

# verify that NAs introduced by coersion are ok
badAgeIndex = which(is.na(cbWomenDF$age))
resMatTest = do.call(rbind,womenResMat)
resMatTest[badAgeIndex,] # they all originally had blank or invalid values for age

#document records with missing ages
missingAges<-cbWomenDF[is.na(cbWomenDF$age),]
#missingAges

#Remove records with missing ages
cbWomenDF=cbWomenDF[! is.na(cbWomenDF[,5]),]

# confirm data frame is in a good format
str(cbWomenDF)
summary(cbWomenDF)
colSums(is.na(cbWomenDF))

save(cbWomenDF, file = "cbWomen.rda")

#####################################
#########Visualizations##############

# can begin here by loading full, clean data frame
#load(file="cbWomen.rda")

library(RColorBrewer) 
ls("package:RColorBrewer")
Blues = brewer.pal(9, "Blues")[8] 
BluesA = paste(Blues, "14", sep = "") 

#Jitter amount = .5 will randomly add/subtract to make ages not overlap so much
plot(jitter(cbWomenDF$age, amount = 0.5) ~ year, data = cbWomenDF, xlab = "Year", ylab = "Age",col=Purples8A )

smoothScatter(y = cbWomenDF$age, x = cbWomenDF$year,
               xlab = "Year", ylab = "Age")

boxplot(cbWomenDF$age~cbWomenDF$year, ylab = "Age", xlab = "Year")

#To see how well the simple linear model captures the relationship (or not)
lmAge = lm(cbWomenDF$year ~ cbWomenDF$age, data = cbWomenDF) 
lmAge$coefficients
summary(lmAge)


age1999 = cbWomenDF[ cbWomenDF$year == 1999, "age" ]
age2010 = cbWomenDF[ cbWomenDF$year == 2010, "age" ]
age2012 = cbWomenDF[ cbWomenDF$year == 2012, "age" ]

qqplot(age1999, age2012, pch = 19, cex = 0.5, 
       ylim = c(10,90), xlim = c(10,90), 
       xlab = "1999 Ages",
       ylab = "2012 Ages", 
       main = "Figure 1. Quantile Comparisons of Female Age for the 1999 and 2012 races"
)
abline(a =0, b = 1, col="red", lwd = 2)

qqplot(age1999, age2010, pch = 19, cex = 0.5, 
       ylim = c(10,90), xlim = c(10,90), 
       xlab = "1999 Ages",
       ylab = "2010 Ages", 
       main = "Figure 2. Quantile Comparisons of Female Age for the 1999 and 2010 races"
)
abline(a =0, b = 1, col="red", lwd = 2)

qqplot(age2010, age2012, pch = 19, cex = 0.5, 
       ylim = c(10,90), xlim = c(10,90), 
       xlab = "2010 Ages",
       ylab = "2012 Ages", 
       main = "Figure 3. Quantile Comparisons of Female Age for the 2010 and 2012 races"
)
abline(a =0, b = 1, col="red", lwd = 2)

library(ggplot2)

ggplot(cbWomenDF, aes(sample = cbWomenDF$age, colour = factor(cbWomenDF$year))) +
  stat_qq() +
  stat_qq_line()

p <- ggplot(cbWomenDF, aes(factor(cbWomenDF$year), cbWomenDF$age))

#p + geom_violin(fill = "#c3d3eb", colour = "#c3d3eb") + geom_jitter(height = .5, width = 0, aes(color='#9db7de', size = .25))

p + geom_violin(fill = "#c3d3eb", colour = "#c3d3eb")+
  geom_point(color='#9db7de', size = .25) +
  xlab("Race Year") + ylab("Age") +
  geom_boxplot(width=.25)
  

