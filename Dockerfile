FROM ubuntu:14.04

# Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential nodejs npm git curl libpq-dev postgresql-client software-properties-common

# Install MRI ruby and bundler
RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update
RUN apt-get install -y ruby2.1 ruby2.1-dev
RUN gem install bundler --no-ri --no-rdoc

# Create application directory, group and user, and set permissions
RUN mkdir -p %%app_home%%
RUN groupadd -g %%gid%% appuser
RUN useradd -u %%gid%% -g appuser -d %%app_home%% -s /sbin/nologin appuser
RUN chown -R appuser:appuser %%app_home%%
RUN usermod -aG sudo appuser
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set container user and directory
USER appuser
WORKDIR %%app_home%%

# Set up bundler
COPY Gemfile %%app_home%%/Gemfile
RUN sudo bundle install

CMD ["rails", "server"]
