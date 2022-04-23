#!/bin/bash

# the directory containing the script file
dir="$(cd "$(dirname "$0")"; pwd)"
cd "$dir"


log()   { echo -e "\e[30;47m ${1^^} \e[0m ${@:2}"; }        # $1 uppercase background white
info()  { echo -e "\e[48;5;28m ${1^^} \e[0m ${@:2}"; }      # $1 uppercase background green
warn()  { echo -e "\e[48;5;202m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background orange
error() { echo -e "\e[48;5;196m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background red


# log $1 in underline then $@ then a newline
under() {
    local arg=$1
    shift
    echo -e "\033[0;4m${arg}\033[0m ${@}"
    echo
}

usage() {
    under usage 'call the Makefile directly: make dev
      or invoke this file directly: ./make.sh dev'
}

# run redis alpine docker image
redis() {
  docker run \
    --rm \
    --name redis \
    --publish 6379:6379 \
    redis:alpine
}

# run vote website using npm - dev mode (livereload + nodemon)
vote() {
  cd vote
  # https://unix.stackexchange.com/a/454554
  command npm install
  npx livereload . --wait 200 --extraExts 'njk' & \
    NODE_ENV=development \
    WEBSITE_PORT=4000 \
    REDIS_HOST=127.0.0.1 \
    npx nodemon --ext js,json,njk index.js
}

# run prometheus
prometheus() {
  # http://localhost:9090/graph?g0.expr=up_gauge&g0.tab=0&g0.stacked=0&g0.show_exemplars=0&g0.range_input=5m
  # http://localhost:9090/graph?g0.expr=up_gauge%20&g0.tab=0&g0.stacked=0&g0.show_exemplars=0&g0.range_input=5m&g1.expr=down_gauge&g1.tab=0&g1.stacked=0&g1.show_exemplars=0&g1.range_input=5m
  docker run \
      --network host \
      --volume $(pwd)/prometheus.yaml:/etc/prometheus/prometheus.yaml \
      prom/prometheus \
      --config.file=/etc/prometheus/prometheus.yaml
}


# run metrics server using npm
metrics() {
  cd metrics
  # https://unix.stackexchange.com/a/454554
  command npm install
  node server.js
}

# run grafana
grafana() {
  # http://localhost:3000
  docker run \
    --network host \
    --env GF_AUTH_BASIC_ENABLED=false \
    --env GF_AUTH_ANONYMOUS_ENABLED=true \
    --env GF_AUTH_ANONYMOUS_ORG_ROLE=Admin \
    grafana/grafana
}

# configure grafana
configure() {
  log add datasource
  curl http://localhost:3000/api/datasources \
    --header 'Content-Type: application/json' \
    --data '{ "name": "Prometheus", "type": "prometheus", "access": "proxy", "url": "http://localhost:9090", "basicAuth": false, "isDefault": true }'

  echo
  log add my-dashboard
  curl http://localhost:3000/api/dashboards/db \
      --header 'Content-Type: application/json' \
      --data @my-dashboard.json
  echo
}

# run the project using docker-compose (same as redis + vote + ...)
compose-dev() {
  export COMPOSE_PROJECT_NAME=k8s_adapter
  docker-compose \
      --file docker-compose.dev.yml \
      up \
      --remove-orphans \
      --force-recreate \
      --build \
      --no-deps 
}

# build the vote + metrics docker images
docker-build() {
  cd "$dir/vote"
  docker image build \
    --file Dockerfile.dev \
    --tag vote \
    .

  cd "$dir/metrics"
  docker image build \
    --file Dockerfile.dev \
    --tag metrics \
    .
}

# if `$1` is a function, execute it. Otherwise, print usage
# compgen -A 'function' list all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep $1)
[[ -n $FUNC ]] && { info execute $1; eval $1; } || usage;
exit 0
