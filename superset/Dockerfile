FROM ubuntu:19.10

RUN apt-get update \
    && apt-get install -y --no-install-recommends gettext

ADD chart /tmp/chart
RUN cd /tmp && tar -czvf /tmp/kong.tar.gz chart

ENV WAIT_FOR_READY_TIMEOUT 1800
ENV TESTER_TIMEOUT 1800
