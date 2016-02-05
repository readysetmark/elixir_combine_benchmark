# BenchmarkParsing

Quickly put-together parser for my price_db file to benchmark the Combine
parser combinator library.

## Usage

Get dependencies:

	mix deps.get

Using iex:

	iex -S mix

	> BenchmarkParsing.load_pricedb

Building an "executable":

	mix escript.build

	./benchmark_parsing

To time it (on a *nix OS):

	time ./benchmark_parsing


**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add benchmark_parsing to your list of dependencies in `mix.exs`:

        def deps do
          [{:benchmark_parsing, "~> 0.0.1"}]
        end

  2. Ensure benchmark_parsing is started before your application:

        def application do
          [applications: [:benchmark_parsing]]
        end

