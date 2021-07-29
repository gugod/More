FROM gugod/perl-busybox:latest
WORKDIR /app
COPY . /app
RUN cpm install --show-build-log-on-failure -g && \
    rm -rf /root/.perl-cpm

ENV PORT=3000
EXPOSE $PORT
CMD ./bin/app.pl --port $PORT --environment=production
