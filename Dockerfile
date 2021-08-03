FROM gugod/perl-appbox:latest
ENV PORT=3000
EXPOSE $PORT
CMD ./bin/app.pl --port $PORT --environment=production
