FROM ubuntu:artful

RUN apt-get update && apt-get -y upgrade && apt-get install -y libssl-dev ca-certificates make gcc wget

RUN wget https://mirror.racket-lang.org/installers/6.10/racket-6.10-src-builtpkgs.tgz

RUN tar xfz racket-6.10-src-builtpkgs.tgz

RUN cd racket-6.10/src && ./configure --prefix=/usr/local && make && make install

RUN /usr/local/bin/raco pkg install --auto argo

COPY *.rkt *.html /app/
