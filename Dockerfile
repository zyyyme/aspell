FROM alpine

RUN apk add --no-cache \
      aspell \
      aspell-lang \
      aspell-de \
      aspell-en \
      aspell-fr \
      aspell-ru \
      aspell-uk \
      ruby

COPY entry.rb /
ENTRYPOINT ["/entry.rb"]
