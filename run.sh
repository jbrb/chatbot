#!/bin/sh
set -e

mix deps.get

mix test

mix phx.server