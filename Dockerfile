FROM docker:18-dind

MAINTAINER Kyle Squizzato: 'kyle.squizzato@docker.com'

WORKDIR /

COPY ./batch-fix-authorNamespace.sh /

ENTRYPOINT ["/bin/sh", "/batch-fix-authorNamespace.sh"]
