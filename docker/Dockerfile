# This Dockerfile supports multiple environments

ARG RUBY_VERSION=3.3.3

FROM ruby:${RUBY_VERSION}

ARG APP_ENV=production
ARG NODE_VERSION=22.9.0

# Set environment variables
ENV APP_ENV=${APP_ENV}
ENV NVM_DIR=/usr/local/nvm
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Container user and group
ARG USERNAME=brkmn
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# DB credentials (these can be overridden at runtime)
ENV DATABASE_USERNAME=brkmn_${APP_ENV}
ENV DATABASE_PASSWORD=so_wow_much_secure
ENV DATABASE_DB_NAME=brkmn_${APP_ENV}
ENV DATABASE_HOST=db
ENV DATABASE_PORT=5432

# Rails specific
ENV RAILS_ENV=${APP_ENV}
ENV RAILS_DISABLE_SSL=true
ENV RAILS_LOG_LEVEL=error

# SMTP settings
ENV SMTP_ADDRESS=
ENV SMTP_PORT=
ENV SMTP_DOMAIN=
ENV SMTP_USERNAME=
ENV SMTP_PASSWORD=

WORKDIR /root

# Install NVM and Node.js
RUN mkdir $NVM_DIR
RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# Install system dependencies
RUN apt-get update && apt-get install -y \
    tzdata git build-essential patch ruby-dev zlib1g-dev liblzma-dev default-jre \
    sudo vim nano tmux wget

# Install Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt-get install -y ./google-chrome-stable_current_amd64.deb

WORKDIR /app
RUN git clone https://github.com/berkmancenter/brkmn.git .

# Create a user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

RUN sudo chown -R $USERNAME:$USERNAME /app
RUN cp /app/.env.sample /app/.env.${APP_ENV}
RUN sed -i "s/development/${APP_ENV}/g" /app/.env.${APP_ENV}

# Install node modules
RUN npm install --global yarn
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Install and cache gems
RUN sudo gem update --system
RUN bundle install
RUN sudo gem install mailcatcher

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets
RUN if [ "$APP_ENV" = "production" ]; then \
  SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile; \
fi

# To be able to create a .bash_history
WORKDIR /home/brkmn/hist
RUN sudo chown -R $USERNAME:$USERNAME /home/brkmn/hist

# Code mounted as a volume
WORKDIR /app
COPY docker/entrypoint.sh /usr/bin/brkmn-entrypoint

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
ENTRYPOINT ["brkmn-entrypoint"]
CMD ["sh", "-c", "./bin/rails server"]
