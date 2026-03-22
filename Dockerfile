FROM docker.io/library/perl:5.42
ADD --chmod=755 https://git.io/cpm /usr/local/bin/cpm

WORKDIR /app

COPY cpanfile .

RUN cpm install --show-build-log-on-failure -g && \
    rm -rf /root/.perl-cpm /root/.cpanm

COPY . .

ENV PORT=3000
EXPOSE $PORT
CMD ./bin/app.pl --port $PORT --environment=production
