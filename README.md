
# Indy Forms

Forms can be simplified using IndyForm. A form can be implemented in just couple of lines.


```elixir
  use IndyForm.FormComponent, context: Context

  form_component(name, form_key, create_action, update_action, opts)
```

- `name`: is name of the form. This is to generate flash messages like "User has been created".
- `form_key`: is your schema name. This is used for finding the form in the params.
- `create_action`: can be an `atom` or `list of atoms`. This is used to determine what action should be performed - create or update.
- `update_action`: can be an `atom` or `list of atoms`. This is used to determine what action should be performed - create or update.
`create_action` or `update_action` values can be directly mapped to socket.assigns.live_action values. 
- `opts`: `change_listeners` can be enabled by passing it through `opts`

```
  form_component(name, form_key, create_action, update_action, change_listeners: true)
```

Read docs are [here](docs/forms.md)

Sample code at - https://github.com/lkarthee/indy_form_sample
