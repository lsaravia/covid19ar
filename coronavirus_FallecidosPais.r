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
require(wbstats)

coun <- wb_cachelist$countries
filter(coun, grepl("Korea",country))
pop_data <- wb(indicator = "SP.POP.TOTL", country=c("ARG","BRA","US","ESP", "ITA","CHL"),startdate = 2018, enddate = 2018) %>% dplyr::select(country,value) %>% mutate(value=value/1000000,country=ifelse(country=="United States", "US", country))

umbral <- 10

corg <- read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv") 
corg <- corg %>% rename(country="Country/Region",province="Province/State")  %>% filter( country %in% pop_data$country)

cor1 <- corg %>% gather(date,N,5:ncol(corg) ) %>% arrange(country) %>% mutate(casosdia = N - lag(N)) %>%  filter(N>umbral, casosdia>0 ) %>% group_by(country) %>% mutate(fecha=mdy(date), dias =as.numeric( fecha - min(fecha)))

cor1 <- cor1 %>% inner_join(pop_data) %>% mutate(Npmill = N/value)

require(ggrepel)
cor1 <- cor1 %>% group_by(country) %>% mutate(lbl=ifelse(row_number()==n(), as.character(round(Npmill,2)),""))
ggplot(cor1,aes(x=dias,y=Npmill,color=country,label=lbl)) + geom_point() + theme_bw() + scale_color_viridis_d()  + ylab("Fallecidos por millon") + geom_line( size = .5) + geom_label_repel() +  
  annotate("text",x=30, y=0.01, label=paste0("Fuente https://systems.jhu.edu/research/public-health/ncov/\n by @larysar al ",max(cor1$fecha)),color="red",size=2) + theme(legend.position=c(0.15,0.8)) + scale_y_log10()
ggsave("/home/leonardo/Academicos/GitProjects/covid19/coronaGlobalFallecidosLog.jpg",width=8,height=6,units="in",dpi=600)

ggplot(cor1,aes(x=dias,y=casosdia,color=country,label=lbl)) + geom_point() + theme_bw() + scale_color_viridis_d()  + ylab("Fallecidos por día") + geom_line( size = .5) + geom_label_repel() +  annotate("text",x=30, y=10, label="Fuente https://systems.jhu.edu/research/public-health/ncov/\n by @larysar",color="red",size=2) + theme(legend.position=c(0.15,0.8)) 

# 
# Comparacion Casos GLobales Tasa de crecimiento vs Casos Totales 
#

corg <- read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv") 
pop_data <- tibble::add_case(pop_data, country="Korea, South")
corg <- corg %>% rename(country="Country/Region",province="Province/State")  %>% filter( country %in% pop_data$country)
require(tidyr)


# Umbral de casos a partir de los cuales se calcula la curva
#
umbral <- 100

cor1 <- corg %>% gather(date,N,5:ncol(corg) ) %>% arrange(country) %>% mutate(casosdia = N - lag(N)) %>%  filter(N>umbral, casosdia>0 ) %>% group_by(country) %>% mutate(fecha=mdy(date), dias =as.numeric( fecha - min(fecha))) 

# Para argentina usa los datos de @minsal 
#
cor1 <- bind_rows( cor1, cor %>% filter(casos>umbral) %>%dplyr::select(casos,casosdia,fecha) %>% mutate(country="Argentina",dias =as.numeric( fecha - min(fecha))) %>% rename(N=casos))

require(ggplot2)

ggplot(cor1, aes(x = N, y = casosdia, colour=country) ) + scale_y_log10() +  scale_x_log10() + 
  geom_point() +  theme_bw() +  guides(fill=FALSE) + scale_color_viridis_d() + geom_line() + xlab("Casos Totales") + ylab( "Casos por Día") + 
  annotate("text",x=1850, y=10, label="Fuente https://systems.jhu.edu/research/public-health/ncov/\n by @larysar",color="red",size=2) + theme(legend.position="bottom")
ggsave("/home/leonardo/Academicos/GitProjects/covid19/coronaGlobalNuevosVsTotales.jpg",width=6,height=6,units="in",dpi=600)

