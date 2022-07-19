# ExBanking

## Approach notes
- `User` processes are accountable for distributing calls between `Account`s
- `Account` stores value of funds in given `currency` for user of given `name`
- multiple instances of `Account` for every `User` allow for load distribution because operations on various `Account`s do not impact each other
- `User` and `Account` are referenced with help of `Registry`
- new actions could be easily added with help of `Action` modules
- Request throttling is done with help of `ExBanking.RequestThrottler` module using `ETS` with a public table for every user instance. Thought of using `Process.info`, but it was misbehaving for this particular task

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_banking` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_banking, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_banking>.

