FROM ruby:2.7.1

RUN mkdir /app
WORKDIR /app

COPY . .
RUN bundle install

CMD (while true; do sleep 1; done;)
