# 1: Ruby 2.7.0
FROM ruby:2.7.0-alpine

# 2: We'll set the application path as the working directory
WORKDIR /usr/src/app

# 3: We'll add the app's binaries path to $PATH, and set the environment name to 'production':
ENV PATH=/usr/src/app/bin:$PATH RAILS_ENV=production RACK_ENV=production

# 4 Add Puma
COPY config/puma.rb /usr/src/app/config/puma.rb

# 5: Expose the web port:
EXPOSE 3000

# ==================================================================================================
# 6:  Install dependencies:

# 6.1: Install the common runtime dependencies:
RUN apk update && apk upgrade && apk add curl curl-dev
RUN set -ex && apk add --no-cache --force libpq ca-certificates openssl mysql-client mariadb-dev imagemagick imagemagick-dev libxml2 libxslt libxml2-dev libxslt-dev build-base \
        libtool \
        autoconf \
        automake \
        jq \
	openssl nodejs tzdata git python python-dev gfortran py-pip build-base \
  gnutls-dev cmake
  #py-numpy@community
  # Bibliotecas que peguei na net para o minitest
  # irrlicht-dev libbz2 libpng-dev libjpeg-turbo-dev libxxf86vm-dev mesa-gl mesa-dev sqlite-dev libogg-dev libvorbis-dev openal-soft-dev freetype-dev

# 6.1.2 Install Pip Dependences
RUN pip install woopra

RUN rm -rf /var/cache/apk/*

# 6.2: Copy just the Gemfile & Gemfile.lock, to avoid the build cache failing whenever any other
# file changed and installing dependencies all over again - a must if your'e developing this
# Dockerfile...
ADD Gemfile* /usr/src/app/

# 6.3: Install build dependencies AND install/build the app gems:
RUN set -ex \
  && bundle install --without development test

# ==================================================================================================
# 7: Copy the rest of the application code, install nodejs as a build dependency, then compile the
# app assets, and finally change the owner of the code to 'nobody':
ADD . /usr/src/app
RUN set -ex \
  && mkdir -p /usr/src/app/tmp/cache \
  && mkdir -p /usr/src/app/tmp/pids \
  && mkdir -p /usr/src/app/tmp/sockets \
  #&& DATABASE_URL=?encoding=utf8 \
  # AMQP_URL=amqp://guest:guest@amqp:5672 TWITTER_API_KEY=SOME_KEY TWITTER_API_SECRET=SOME_SECRET \
  SECRET_KEY_BASE= \
  && rake assets:precompile RAILS_ENV=production \
  #&& chown -R nobody /usr/src/app

# ==================================================================================================
# 8: Set the container user to 'nobody':
# USER nobody

RUN bundle exec puma -p 3000 -C config/puma.rb
#CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
