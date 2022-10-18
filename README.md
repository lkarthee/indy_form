
# Indy Forms

Forms can be simplified using IndyForm. A form can be implemented in just couple of lines.

```elixir
  use IndyForm.FormComponent, context: Context

  form_component(form_key, create_action, update_action, opts)
```

- `form_key`: is your schema name. This is used for finding the form in the params.
- `create_action`: can be an `atom` or `list of atoms`. This is used to determine what action should be performed - create or update.
- `update_action`: can be an `atom` or `list of atoms`. This is used to determine what action should be performed - create or update.
`create_action` or `update_action` values can be directly mapped to socket.assigns.live_action values. 
- `opts`: `change_listeners` can be enabled by passing it through `opts`

```elixir
  form_component(name, form_key, create_action, update_action, change_listeners: true)
```

A complete example which reduces around 50 lines of boilerplate code `form component` to 3 just lines:

```elixir
defmodule UserForm do
  alias IndyFormSample.Accounts, as: Context

  use IndyForm.FormComponent, context: Context

  form_component("user", :new, :edit)
end
```

or can be writen in verbose 7 lines if you prefer this way:
```elixir
defmodule UserForm do
  alias IndyFormSample.Accounts, as: Context

  use IndyForm.FormComponent, context: Context

  @form_key "user"
  @create_action :new
  @edit_action :edit

  form_component(@form_key, @create_action, @edit_action)
end
```

Design goals of this library :
 - less code injection through macros.
 - less magic and more explicit configuration.
 - flexibility to override everything to perform one off customizations.
 - reduce boilerplate code in application.

You can read docs about [forms](docs/forms.md) and [contexts](docs/context.md).

And browse sample code here - https://github.com/lkarthee/indy_form_sample
