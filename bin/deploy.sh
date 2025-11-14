#!/bin/sh
cd front && gleam run -m lustre/dev build
cd ../back \
&& gleam export erlang-shipment
