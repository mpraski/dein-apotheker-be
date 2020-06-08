# Set the required arguments
ARG APP=app
ARG PORT=8080
ARG UID=1000
ARG MIX_ENV=prod
ARG PROJECT=dein_apotheker

# ---- COMPILE ----
FROM elixir:1.10-alpine as builder

LABEL maintainer="marcin.praski@live.com"

ARG MIX_ENV
ARG APP
ARG PROJECT

ENV LANG C.UTF-8

# Install hex and rebar
RUN mix do \
    local.hex --force, \
    local.rebar --force, \
    deps.get --only $MIX_ENV

RUN mkdir /$APP
WORKDIR /$APP

# Copy over all the necessary application files and directories
COPY dein-apotheker-scenarios ./dein-apotheker-scenarios
COPY config ./config
COPY apps ./apps
COPY mix.exs .
COPY mix.lock .
COPY Makefile .

# Fetch the application dependencies and build the application
RUN apk add --update make && make build MIX_ENV=$MIX_ENV

# ---- PACKAGE ----
FROM alpine:3.11

ARG MIX_ENV
ARG APP
ARG PORT
ARG UID

RUN apk add --update ncurses-libs

RUN adduser -D -u $UID -h /$APP $APP
WORKDIR /$APP

COPY --from=builder /$APP/_build/$MIX_ENV/rel/$PROJECT .
RUN chown -R $APP: /$APP
USER $APP

EXPOSE $PORT

ENTRYPOINT ["dein_apotheker/bin/dein_apotheker"]
