# Forms

Forms can be simplified using IndyForm. A form can be implemented in just couple of lines.

```elixir
  use IndyForm.FormComponent, context: Context

  form_component(name, form_key, create_action, update_action)
```

- `name`: is name of the form. This is to generate flash messages like "User has been created".
- `form_key`: is your schema name. This is used for finding the form in the params.
- `create_action`: can be an `atom` or `list of atoms`. This is used to determine what action should be performed - create or update.
- `update_action`: can be an `atom` or `list of atoms`. This is used to determine what action should be performed - create or update.

## Under the hood

First step of using `form_component` is using the `IndyForm.FormComponent` module.

```elixir
  use IndyForm.FormComponent, context: Context
```

The following lines are inserted in the module with `use IndyForm.FormComponent`. Please note `Context` is the context file which encapsulates the business logic like `Accounts` context which deals with `user` schema.

```elixir
  import IndyForm.FormComponent

  def cast_func(), do: &Context.cast_row/2
  
  def change_func(), do: &Context.change_row/2

  def create_func(), do: &Context.create_row/2

  def update_func(), do: &Context.update_row/2

  def on_value_change(socket, _), do: socket
  
  def on_init(socket), do: socket

  def transform_form(_socket, params), do: params

  defoverridable [
    on_value_change: 2,
    transform_form: 2, 
    change_func: 0, 
    create_func: 0, 
    update_func: 0, 
    on_init: 1 
  ]

  # and some more code to implement `:live_component` functions.
```

We can override each function based on our requirements. Lets look at each one of them.

### `on_init(socket)`

`on_init/1` is invoked at the end of function implementing `update/2` of `:live_component`.

You can override to assign some variables, etc. It expects a `socket` to be returned.

```elixir
  def on_init(socket) do
    show_phone? = show_phone?(socket.assigns.row.contact_me)
    show_email? = show_email?(socket.assigns.row.contact_me)
    socket
    |> assign(:show_phone, show_phone?)
    |> assign(:show_email, show_email?)
  end
```
### `on_value_change(socket, {key, old_value, new_value})`

`on_value_change/2` is invoked when there is a change is detected in field while handling `validate` event.

`key` is an atom - which is field name defined in your form.

You can override to handle changes in form happening without writing a single line of javascript. 

```elixir
  # handle changes relating to field :contact_me
  def on_value_change(socket, {:contact_me, _old_value, new_value}) do
    show_phone? = show_phone?(new_value)
    show_email? = show_email?(new_value)

    socket
    |> assign(:show_phone, show_phone?)
    |> assign(:show_email, show_email?)
  end

  # needed for handling changes not relating to our fields of interest
  def on_value_change(socket, _), do: socket
``` 

### `transform_form(_socket, params)`

`transform_form/2` is invoked while handling `save` event on the form. 

You can override `transform` to transform `attrs` or data coming from form submission. You can set a field or change a field, etc.

Typical use case is to set a calculated field or hidden field based on user's input.

### `cast_func()`

`cast_func` returns a function which can cast a row without triggering validations. `cast_func` is invoked for determining changes to invoke `on_value_change/2`, . This is needed due to limitations in `Ecto.Changeset`.

You can supply your own cast function by overriding the function in your FormComponent file.

`cast_func` is invoked while handling `validate` event on `:live_component`.

### `change_func()`

`change_func` returns a function which can cast data and apply validations. `change_func` is invoked while handling `validate` event on `:live_component`.

You can supply your own change function by overriding the function in your FormComponent file.

`change_func` is invoked while handling `validate` event on `:live_component`.


### `create_func()`

`create_func` returns a function which can create a row. `create_func` is invoked while handling `save` event on `:live_component`.

You can supply your own create function by overriding the function in your FormComponent file.

`create_func` is invoked while handling `validate` event on `:live_component`.

### `update_func()`

`update_func` returns a function which can cast data and apply validations. `update_func` is invoked while handling `save` event on `:live_component`.

You can supply your own update function by overriding the function in your FormComponent file.

`update_func` is invoked while handling `validate` event on `:live_component`.


## Types of forms

There are two types forms:
 
 - Simple form
 - Form with line items

### Simple Form

Simple form can be implemented by using `IndyForm.FormComponent`.

```elixir
  use IndyForm.FormComponent, context: Context
```

Then adding `form_component`. You can see full example here.

```elixir
defmodule UserForm do
  alias IndyFormSample.Accounts, as: Context

  use IndyForm.FormComponent, context: Context

  @name "User"
  @form_key "user"
  @create_action :new
  @edit_action :edit

  form_component(@name, @form_key, @create_action, @edit_action)
end
```

### Form With Line Items

A form with line items has a form with atleast one set of line items. This is an extension of simple form.
This has a delete confirmation popup for deleting a line item.


Form with line items can be implemented by using `IndyForm.FormWithItemsComponent`.

```elixir
  use IndyForm.FormWithItemsComponent, context: Context
```

```elixir
  def on_delete_item(socket, _type) do
    item_rows = Context.all_rows()
    assign(socket, :item_rows, item_rows)
  end

  def delete_item_row_func(_type) do
    &Context.delete_row/1
  end

  def get_item_row_func(_type) do
    &Context.get_row/1
  end
```
