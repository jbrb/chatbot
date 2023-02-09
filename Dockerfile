FROM elixir:1.14.3-otp-24

RUN apt-get update
RUN apt-get install --yes build-essential inotify-tools

# Install Phoenix packages
RUN mix local.hex --force && \
    mix archive.install hex phx_new --force && \
    mix local.rebar --force

# Install node
RUN apt-get update -y && apt-get install -y build-essential git nodejs npm curl \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
  && apt-get install -y nodejs

WORKDIR /app
EXPOSE 4000