FROM mikkelkrogsholm/rstudio

COPY mkusers.sh
COPY user.csv

RUN chmod 777 /mkusers.sh

RUN /mkusers.sh