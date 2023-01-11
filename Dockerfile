FROM ruby:2.7.1

RUN apt-get update \
    && apt-get -y install git build-essential patch ruby-dev zlib1g-dev liblzma-dev vim nano tmux nodejs npm

RUN npm install --global yarn

RUN mkdir /app
WORKDIR /app

COPY . .
RUN bundle install

CMD (while true; do sleep 1; done;)
