# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.2
FROM ruby:${RUBY_VERSION}-slim

WORKDIR /app

# Install essential dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Copy entrypoint script
COPY bin/docker-entrypoint /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]

# Default command runs tests
CMD ["bundle", "exec", "rspec"]
