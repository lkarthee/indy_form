# Context File

Indy Form library expects a context to define four functions `cast_row/2`, `change_row/2`, `create_row/2` and `update_row/2`. If a context module does not define these four functions or your are following a different naming convention, you can override relevant functions of `IndyForm.FormComponent` and plugin your functions.

```elixir
defmodule Context do
  def cast_row(row, attrs \\ %{})
  def change_row(row, attrs \\ %{})
  def create_row(row, attrs \\ %{})
  def update_row(user, attrs)
end
```
### `cast_row/2`
`cast_row/2` casts data into changeset. This should only cast without performing any validations. This function is needed for changes allowed by `Ecto.Changeset.cast/2` but rejected by validation functions. This function is used by `on_value_change/2`.

```elixir
  def change_row(%User{} = row, attrs \\ %{}) do
    User.changeset(row, attrs)
  end
```

### `change_row/2`

`change_row/2` casts and validates data into changeset.

```elixir
  def cast_row(%User{} = row, attrs \\ %{}) do
    User.cast(row, attrs)
  end
```

### `create_row/2`

`create_row/2` creates a row.

```elixir
  def create_row(%User{} = row, attrs \\ %{}) do
    row
    |> User.changeset(attrs)
    |> Repo.insert()
  end
```

### `update_row/2`

`update_row/2` creates a row.

```elixir
  def update_row(%User{} = row, attrs) do
    row
    |> User.changeset(attrs)
    |> Repo.update()
  end
```

### Full Example

#### User model file

```elixir
defmodule YourApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :age, :integer
    field :gender, :string
    field :name, :string

    timestamps()
  end

  @fields [:name, :age, :gender]
  @required_fields [:name, :age, :gender]

  @doc false
  def cast(user, attrs), do: Ecto.Changeset.cast(user, attrs, @fields)

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
```

#### Account Context file
```elixir
defmodule YourAppWeb.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias YourAppWeb.Repo

  alias YourAppWeb.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_rows()
      [%User{}, ...]

  """
  def list_rows do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_row!(123)
      %User{}

      iex> get_row!(456)
      ** (Ecto.NoResultsError)

  """
  def get_row!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_row(%{field: value})
      {:ok, %User{}}

      iex> create_row(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_row(%User{} = row, attrs \\ %{}) do
    row
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_row(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_row(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_row(%User{} = row, attrs) do
    row
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_row(user)
      {:ok, %User{}}

      iex> delete_row(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_row(%User{} = row) do
    Repo.delete(row)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> cast_row(row)
      %Ecto.Changeset{data: %User{}}

  """
  def cast_row(%User{} = row, attrs \\ %{}) do
    User.cast(row, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_row(row)
      %Ecto.Changeset{data: %User{}}

  """
  def change_row(%User{} = row, attrs \\ %{}) do
    User.changeset(row, attrs)
  end
end
```