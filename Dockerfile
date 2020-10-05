# ---- REQUIREMENTS ----
ARG APP=app
ARG PORT=8080
ARG MIX_ENV=prod
ARG PROJECT=dein_apotheker

# ---- COMPILE ----
FROM elixir:1.10-alpine as builder

LABEL maintainer="marcin.praski@live.com"

ARG MIX_ENV
ARG APP
ARG PROJECT

ENV LANG C.UTF-8

WORKDIR /$APP

# Copy over configuration that is
# is unlikely to change oftern
COPY mix.* ./
COPY config ./config
COPY apps/api/mix.exs ./apps/api/
COPY apps/chat/mix.exs ./apps/chat/

# Install hex, rebar and dependencies
RUN mix do \
    local.hex --force, \
    local.rebar --force, \
    deps.get --only $MIX_ENV, \
    deps.compile

# Copy over the code and scenario
COPY dein-apotheker-scenarios ./dein-apotheker-scenarios
COPY apps ./apps

# Build the application
RUN MIX_ENV=$MIX_ENV mix do compile, release

# ---- PACKAGE ----
FROM alpine:3.11

ARG MIX_ENV
ARG APP
ARG PORT

RUN apk add --no-cache ncurses-libs && rm -rf /var/cache/apk/*

USER nobody

WORKDIR /$APP

COPY --from=builder --chown=nobody:nobody /$APP/_build/$MIX_ENV/rel/$PROJECT .

EXPOSE $PORT

ENTRYPOINT ["dein_apotheker/bin/dein_apotheker"]
