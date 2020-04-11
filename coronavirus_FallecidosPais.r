# 
# Comparacion Casos GLobales Fallecidos totales y por dia  
#
# Fuente:  Johns Hopkins University Center for Systems Science and Engineering.
#          https://systems.jhu.edu/research/public-health/ncov/
#
#


require(dplyr)
require(readr)
require(lubridate)
require(tidyr)
require(ggplot2)
cor <- read_csv("/home/leonardo/Downloads/total-daily-covid-deaths.csv")

cor <- cor  %>% mutate(fecha=ymd(fecha), dias =as.numeric( fecha - min(fecha))) 
#

umbral <- 10

corg <- read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv") 
corg <- corg %>% rename(country="Country/Region",province="Province/State")  %>% filter( country %in% c("US","Italy","Spain", "Brazil", "Argentina"))

cor1 <- corg %>% gather(date,N,5:ncol(corg) ) %>% arrange(country) %>% mutate(casosdia = N - lag(N)) %>%  filter(N>umbral, casosdia>0 ) %>% group_by(country) %>% mutate(fecha=mdy(date), dias =as.numeric( fecha - min(fecha)))

require(ggrepel)
cor1 <- cor1 %>% group_by(country) %>% mutate(lbl=ifelse(row_number()==n(), as.character(N),""))
ggplot(cor1,aes(x=dias,y=N,color=country,label=lbl)) + geom_point() + theme_bw() + scale_color_viridis_d()  + ylab("Fallecidos") + geom_line( size = .5) + geom_label_repel() +  annotate("text",x=30, y=10, label="Fuente https://systems.jhu.edu/research/public-health/ncov/\n by @larysar",color="red",size=2) + theme(legend.position=c(0.15,0.8)) + scale_y_log10()


ggplot(cor1,aes(x=dias,y=casosdia,color=country,label=lbl)) + geom_point() + theme_bw() + scale_color_viridis_d()  + ylab("Fallecidos por día") + geom_line( size = .5) + geom_label_repel() +  annotate("text",x=30, y=10, label="Fuente https://systems.jhu.edu/research/public-health/ncov/\n by @larysar",color="red",size=2) + theme(legend.position=c(0.15,0.8)) 
