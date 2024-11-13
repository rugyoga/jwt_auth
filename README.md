Trying to generate the same JWT from ruby and elixir.

To run the ruby, do:

```ruby
ruby auth_token.rb
```
it'll generate a JWT

or pass a JWT and it'll consume it and convert it.

```ruby
ruby auth_token.rb <JWT string>
```

Similarly for elixir, do:

```elixir
mix deps.get
mix run
```
