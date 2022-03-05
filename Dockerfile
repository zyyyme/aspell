FROM alpine:3.15

RUN apk add --no-cache \
      aspell~=0.60.8 \
      aspell-lang~=0.60.8 \
      aspell-de~=20161207 \
      aspell-en~=2020.12.07 \
      aspell-fr~=0.50 \
      aspell-ru~=0.99f7 \
      aspell-uk~=1.4.0 \
      ruby~=3.0.3

COPY entry.rb /

ENTRYPOINT ["/entry.rb"]
