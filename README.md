# Pooly

Simple worker-pooling application as described in [_The little Elixir & OTP
guidebook_][0]. The code has been adjusted to adhere to the newest Elixir
versions though.

Each commit contains a version of the application, starting from the most
barebones one and enhancing it over time.

To see `Pooly` in action, just spin up the REPL:

```sh
sh> iex -S mix
iex> Pooly.big_bang()
...
```

## Major differences compared to the guidebook

- Runs on Elixir 1.10 instead of 1.3.
- Usage of `DynamicSupervisor` instead of old `Supervisor` spec +
  `:simple_one_for_one` strategy.
- Usage of `Supervisor.child_spec/2` instead of `Supervisor.Spec.supervisor`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pooly` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pooly, "~> 0.1.0"}
  ]
end
```

[0]: https://www.manning.com/books/the-little-elixir-and-otp-guidebook