defmodule ElixirJwt do
  @secret "7efa0ff3eae67b21ac8fdb0b127e1748de087acd81086b38145e904cc7717f2bee86f1755305eaef0a2b6d095686e40b13ebe437c001b28a2a86ed20f510b433"
  @nonce "abcdef"
  @company_id 123
  @user_id 456
  @subdomain "ujet.co"
  @issuer "UJET"
  @company %{id: @company_id, subdomain: @subdomain}
  @user %{id: @user_id, nonce: @nonce, company_id: @company.id}
  @time_now 1586389735
  @time_week_from_now 1586994535
  @jws %{ "alg" => "HS256", "typ" => "JWT" }
  @jwk %{ "k" => :jose_base64url.encode(@secret) , "kty" => "oct"}
  @ruby_jwt "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0NTYsImNvbXBhbnlfaWQiOjEyMywic3ViZG9tYWluIjoidWpldC5jbyIsIm5vbmNlIjoiYWJjZGVmIiwidHlwZSI6InVzZXIiLCJleHAiOjE1ODY5OTQ1MzUsImlzcyI6IlVKRVQiLCJpYXQiOjE1ODYzODk3MzV9.RglmPqiO7SeAnHX1jc1o6wgNWLPal9Bp6lgI3ujNw0A"
  @moduledoc """
  Documentation for ElixirJwt.
  """
  def encode(payload) do
    JOSE.JWT.sign(@jwk, @jws, payload) |> JOSE.JWS.compact
  end

  def user_token(user, company) do
    encode(
      %{
         company_id: company.id,
         exp: @time_week_from_now,
         iat: @time_now,
         iss: @issuer,
         nonce: user.nonce,
         subdomain: company.subdomain,
         type: "user",
         user_id: user.id
       }
    )
  end

  def decode(jwt) do
     case JOSE.JWT.verify(@jwk, {%{alg: :jose_jws_alg_hmac}, jwt}) do
       {true, %JOSE.JWT{ fields: payload}, _} -> {:ok, payload}
       error -> error
     end
  end

  def user() do
    @user
  end

  def company() do
    @company
  end

  def fetch_company(id) do
    if id == @company_id do
      @company
    else
      nil
    end
  end

  def fetch_user(id) do
    if id == @user_id do
      @user
    else
      nil
    end
  end

  def ruby_jwt() do
    @ruby_jwt
  end
end

ruby_jwt = ElixirJwt.ruby_jwt()
user = ElixirJwt.user()
company = ElixirJwt.company()
{metadata, elixir_jwt} = ElixirJwt.user_token(user, company)
{:ok, ruby_payload} = ElixirJwt.decode(ruby_jwt)
{:ok, elixir_payload} = ElixirJwt.decode(elixir_jwt)

 IO.puts("ruby jwt: " <> ruby_jwt)
 IO.puts("elixir jwt: " <> elixir_jwt)
 IO.puts("ruby payload: " <>  Kernel.inspect(ruby_payload))
 IO.puts("elixir payload: " <>  Kernel.inspect(elixir_payload))
