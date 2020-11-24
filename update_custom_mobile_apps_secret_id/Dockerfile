FROM ruby:2.5

ARG VAULT_ADDR
ARG VAULT_TOKEN

ENV VAULT_ADDR=${VAULT_ADDR}
ENV VAULT_TOKEN=${VAULT_TOKEN}
# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config

WORKDIR /usr/src/app

COPY Gemfile update-public-repos-token.txt ./
RUN bundle install

COPY . .

ENTRYPOINT ["ruby", "update_custom_mobile_apps_secret_id.rb"]