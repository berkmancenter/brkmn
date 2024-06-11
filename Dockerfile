FROM ruby:3.3.2

RUN apt-get update \
    && apt-get -y install git build-essential patch ruby-dev zlib1g-dev liblzma-dev vim nano tmux

# Install node
RUN mkdir /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 12.22.12
RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
RUN npm install --global yarn

RUN mkdir /app
WORKDIR /app

COPY . .
RUN gem update --system
RUN bundle update --bundler
RUN bundle install

CMD (while true; do sleep 1; done;)
