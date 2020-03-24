# COVID-19
#
# Estimación de los parametros de una exponecial y el factor de crecimiento
# También para los casos de cont  acto directo
#
# Fuente @msalnacion 
#

require(dplyr)
require(readr)
require(lubridate)
cor <- read_csv("/home/leonardo/Academicos/GitProjects/covid19/coronavirus_ar.csv")
cor <- cor %>% mutate(fecha=ymd(fecha), dias =as.numeric( fecha - min(fecha))) 

#
# OJO, los casos en estudio = ? comunitarios no estan acumulados
#

require(ggplot2)

# g0 <- ggplot(cor,aes(x=dias,y=casos)) + geom_point() + theme_bw() + geom_smooth(method="glm",family=gaussian(link="log")) 
# g1 <- g0 + expand_limits(x=c(0,240))+
#   geom_smooth(method="glm",family=gaussian(link="log"),
#               fullrange=TRUE)
# 1. linear growth: RICE(t) = R0 + r • TIME
# 2. exponential growth: RICE(t) = R0 • e^-(r • TIME)
# 3. restricted growth: RICE(t) = MAX - (MAX - R0) • e^-(r • MAX • TIME)
# 4. logistic growth: RICE(t) = (MAX • R0) / ( R0 + (MAX - R0) • e^-(r • MAX • TIME) )

# Comparación de distintos modelos utilizando el criterio de Akaike (lineal y exponencial nomas)
#
expmdl <- lm(log(casos)~ dias,data=cor)
summary(expmdl)
linmdl <- lm(casos~ dias,data=cor)
summary(linmdl)
AIC(linmdl,expmdl)

# Ajuste no-lineal del los parametros del modelo exponencial
#
model <- nls(casos ~ alpha * exp(beta * dias) , data = cor, start=list(alpha=0.6,beta=0.4))

# Extraigo los coeficientes para ponerlos en el gráfico
#
a <- round(coef(model)[1],2)
b <- round(coef(model)[2],2)
summary(model)

# Prediccion hasta 31/03
#
predexp <-data.frame(pred=predict(model,newdata=data.frame(dias=0:26))) %>% mutate(dias=0:26, fecha=min(cor$fecha)+dias)
predexp
#cor <-  bind_cols(cor, predexp)

# Casos totales
#
ggplot(cor, aes(x = fecha, y = casos) ) +
  geom_point() +
#  geom_ribbon( aes(ymin = lwr, ymax = upr), alpha = .15) +
  geom_line(data=predexp, aes(x=fecha,y = pred), size = .5, color= "blue") + 
  labs(title = bquote("Argentina casos ="* .(a)* e^(dias ~ .(b)))) + theme_bw() + annotate(geom="text",x=ymd("20200330"), y=1, label="Fuente @msalnacion\n by @larysar",color="red",size=2) + scale_y_log10()


# Growth Factor para casos totales
#
cor <- cor %>% mutate(delta=casos-lag(casos),deltaPrev=lag(delta),growthFactor= delta/deltaPrev)

ggplot(cor %>% filter(dias>3),aes(x=dias,y=growthFactor)) + geom_point() + theme_bw() + stat_smooth(method=lm,se=FALSE) +   labs(title = bquote("Growth Factor=" ~ Delta* N[t] / Delta* N[t-1] ))  + theme_bw() + annotate(geom="text", x=5, y=8, label="Fuente @msalnacion\n by @larysar",color="red",size=2)

#
# Contactos e Importados Comunitarios by group usando tidyverse
#
require(tidyr)
cor1 <- cor %>% mutate(comunitarios=cumsum(comunitarios), importados=casos-contactos-comunitarios) %>% gather(tipo,N,casos:comunitarios,importados) %>% filter(tipo %in% c("contactos","importados","comunitarios")) %>% mutate(N = ifelse(N==0,NA,N))

ggplot(cor1 ,aes(x=dias,y=N,color=tipo)) + geom_point() + theme_bw() + stat_smooth(method=lm,se=F) + scale_y_log10() + scale_color_viridis_d()

ggplot(cor1,aes(x=dias,y=N,color=tipo)) + geom_point() + theme_bw() + scale_color_viridis_d() + scale_color_viridis_d() + scale_y_log10() + ylab("Casos")

mod <- cor1 %>% filter(N>0) %>% group_by(tipo) %>% do(mod=nls(N~ alpha*exp(dias*beta),start=c(alpha=1.4,beta=0.5),data=.) )
mod  %>% do(data.frame(
  var = names(coef(.$mod)),
  coef(summary(.$mod)))
)
newdat <- data.frame(dias = 0:26)
library(tidyverse)  
predexp <- cor1 %>%
  group_by(tipo) %>%
  nest %>%
  mutate(mod  = purrr::map(.x = data, .f = ~ nls(N~ alpha*exp(dias*beta),start=c(alpha=1.4,beta=0.5),data=.))) %>%
  mutate(pred = purrr::map(.x = mod, ~ predict(., newdat))) %>% 
  select(tipo,pred) %>% unnest %>% cbind(newdat = newdat) %>% mutate(fecha = min(cor1$fecha)+dias)


ggplot(cor1,aes(x=fecha,y=N,color=tipo)) + geom_point() + theme_bw() + scale_color_viridis_d() + scale_color_viridis_d() + scale_y_log10() + ylab("Casos") + geom_line(data=predexp, aes(x=fecha,y = pred,color=tipo), size = .5) 
ggsave("/home/leonardo/Academicos/GitProjects/covid19/coronaArComparacion.jpg")

