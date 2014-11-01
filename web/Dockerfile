FROM ubuntu:trusty
MAINTAINER 0x002a@gmail.com

# Update package sources.
RUN apt-get update

# Install ruby.
RUN apt-get install -y ruby2.0 ruby-dev ruby2.0-dev make
RUN gem install bundler

# Install nodejs
RUN apt-get install -y nodejs

# Install jekyll
RUN gem install jekyll

# Install app.
ADD . /web

EXPOSE 4000

WORKDIR /web
ENTRYPOINT ["jekyll"]
CMD ["serve"]
