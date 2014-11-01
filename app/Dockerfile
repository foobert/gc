FROM ubuntu:trusty
MAINTAINER 0x002a@gmail.com

# Update package sources.
RUN apt-get update

# Install ruby.
RUN apt-get install -y ruby2.0 ruby-dev ruby2.0-dev make
RUN gem install bundler

# Install app.
ADD bin /app/bin/
ADD lib /app/lib/
ADD config.yml /app/config.yml
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN cd /app && bundle install --deployment

EXPOSE 4567

WORKDIR /app
ENTRYPOINT ["/app/bin/cachecache"]
CMD ["serve"]
