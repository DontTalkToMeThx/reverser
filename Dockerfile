FROM ruby:3.1.2-alpine

WORKDIR /app

# TODO: use node provided corepack when available
RUN apk --no-cache add \
  tzdata build-base git \
  nodejs npm \
  postgresql-client libpq-dev \
  vips \
  ffmpeg \
  && npm install -g corepack

RUN corepack prepare yarn@3.2.3 --activate

RUN git config --global --add safe.directory /app

COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn install

COPY Gemfile Gemfile.lock ./
RUN gem i bundler:2.3.22 foreman && BUNDLE_IGNORE_CONFIG=true bundle install

RUN solargraph download-core \
  && bundle exec yard gems \
  && solargraph bundle

RUN echo "IRB.conf[:USE_AUTOCOMPLETE] = false" > ~/.irbrc

CMD foreman start
