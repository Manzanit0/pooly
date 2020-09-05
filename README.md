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

[0]: https://www.manning.com/books/the-little-elixir-and-otp-guidebook