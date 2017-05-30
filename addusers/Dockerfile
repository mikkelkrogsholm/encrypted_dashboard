FROM mikkelkrogsholm/rstudio

COPY mkusers.sh .
COPY users.csv .

RUN chmod 777 /mkusers.sh

RUN /mkusers.sh

RUN deluser --remove-home rstudio