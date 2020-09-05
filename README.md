# Pooly

Simple worker-pooling application as described in [_The little Elixir & OTP
guidebook_][0] with some modifications.

## Supervision tree

This is the kind of supervision tree that's spinned up when `Pooly` is started:

```
                                --------------------
                                | Pooly.Supervisor |
                                --------------------
                                          |
                            -----------------------------
                            |                           |
                    ----------------        -------------------------
                    | Pooly.Server |        | Pooly.PoolsSupervisor |
                    ----------------        -------------------------
                                               |                |
                          ------------------------            ------------------------
                          | Pooly.PoolSupervisor |            | Pooly.PoolSupervisor |
                          ------------------------            ------------------------
                            |                 |                           |
            --------------------------   --------------------            ...
            | Pooly.WorkerSupervisor |   | Pooly.PoolServer |
            --------------------------   --------------------
            |             |         |
        ----------   ----------  ----------
        | Worker |   | Worker |  | Worker |
        ----------   ----------  ----------
```

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