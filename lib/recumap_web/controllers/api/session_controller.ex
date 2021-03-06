defmodule RecumapWeb.API.SessionController do
  use RecumapWeb, :controller

  alias RecumapWeb.APIAuthPlug
  alias Plug.Conn

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.authenticate_user(user_params)
    |> case do
      {:ok, conn} ->
        json(conn, %{
          data: %{
            token: conn.private[:api_access_token],
            renewal_token: conn.private[:api_renewal_token]
          }
        })

      {:error, conn} ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid email or password"}})
    end
  end

  @spec renew(Conn.t(), map()) :: Conn.t()
  def renew(conn, _params) do
    config = Pow.Plug.fetch_config(conn)

    conn
    |> APIAuthPlug.renew(config)
    |> case do
      {conn, nil} ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid token"}})

      {conn, _user} ->
        json(conn, %{
          data: %{
            token: conn.private[:api_access_token],
            renewal_token: conn.private[:api_renewal_token]
          }
        })
    end
  end

  @spec delete(Conn.t(), map()) :: Conn.t()
  def delete(conn, _params) do
    conn
    |> Pow.Plug.delete()
    |> json(%{data: %{}})
  end

  def me(conn, _params) do
    case Pow.Plug.current_user(conn) do
      nil ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid token"}})

      user ->
        json(conn, %{
          data: %{
            id: user.id,
            name: user.name,
            email: user.email,
            inserted_at: user.inserted_at,
            updated_at: user.updated_at
          }
        })
    end
  end
end
