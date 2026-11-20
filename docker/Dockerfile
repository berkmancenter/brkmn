# This Dockerfile supports multiple environments

ARG RUBY_VERSION=3.3.14-bookworm

FROM ruby:${RUBY_VERSION}

ARG APP_ENV=production
ARG APP_VERSION=3.1.5
ARG BUILD_IMAGE
ARG USERNAME=brkmn
ARG USER_UID=1000
ARG USER_GID=$USER_UID

WORKDIR /root

# Install NVM and Node.js
ARG NODE_VERSION=22.20.0
ENV NVM_DIR=/usr/local/nvm
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
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

# Install the browser and its matching driver for system specs.
RUN if [ "$APP_ENV" = "test" ]; then \
      apt-get install -y --no-install-recommends chromium chromium-driver; \
    fi

WORKDIR /app

# Retrieve application code
COPY . .
RUN if [ "$BUILD_IMAGE" = "true" ]; then \
      rm -rf ./{*,.*} \
      && wget https://github.com/berkmancenter/brkmn/archive/refs/tags/${APP_VERSION}.tar.gz \
      && tar -xzf ${APP_VERSION}.tar.gz --strip-components=1 \
      && rm ${APP_VERSION}.tar.gz; \
    fi

# Create a user, and a folder to be able to create a .bash_history
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir -p /home/$USERNAME/hist \
    && chown -R $USERNAME:$USERNAME /app /home/$USERNAME/hist

# Passwordless sudo only in development and test images, the production app
# user must not be able to become root.
RUN if [ "$APP_ENV" != "production" ]; then \
      echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
      && chmod 0440 /etc/sudoers.d/$USERNAME; \
    fi

# System wide tools, installed as root. Then the gem folder goes to the app
# user, bundle install runs as that user.
RUN npm install --global yarn
RUN gem update --system
RUN gem install mailcatcher \
    && chown -R $USERNAME:$USERNAME /usr/local/bundle

USER $USERNAME

# Install node modules
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Install and cache gems
RUN bundle install

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Code mounted as a volume
WORKDIR /app
COPY docker/entrypoint.sh /usr/bin/brkmn-entrypoint

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
ENTRYPOINT ["brkmn-entrypoint"]
CMD ["sh", "-c", "./bin/rails server"]
