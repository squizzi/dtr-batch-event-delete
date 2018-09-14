FROM docker:18-dind

MAINTAINER Kyle Squizzato: 'kyle.squizzato@docker.com'

WORKDIR /

COPY ./batch-delete-events.sh /

ENTRYPOINT ["/bin/sh", "/batch-delete-events.sh"]
