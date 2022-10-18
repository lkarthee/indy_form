defmodule IndyForm.FormComponent do
  use Phoenix.Component
  import Phoenix.LiveView

  defmacro __using__(context: module) do
    quote do
      import IndyForm.FormComponent

      def cast_func(), do: &unquote(module).cast_row/2
      
      def change_func(), do: &unquote(module).change_row/2

      def create_func(), do: &unquote(module).create_row/2

      def update_func(), do: &unquote(module).update_row/2

      def on_init(socket), do: socket

      def on_success(socket, _row), do: socket

      def on_error(socket, _changeset_or_error_tuple), do: socket

      def on_event(_event, _params, socket), do: socket

      def on_value_change(socket, _), do: socket

      def transform_form(_socket, params), do: params

      def transform_form_func(), do: &transform_form/2

      def on_value_change_func(), do: &on_value_change/2
      
      def on_init_func(), do: &on_init/1

      def on_error_func(), do: &on_error/2

      def on_success_func(), do: &on_success/2

      def on_event_func(), do: &on_event/3

      defoverridable [
        cast_func: 0,
        change_func: 0, 
        create_func: 0, 
        update_func: 0, 
        on_init: 1,
        on_success: 2,
        on_error: 2,
        on_event: 3,
        on_value_change: 2,
        transform_form: 2, 
      ]
    end
  end

  defmacro form_component(form_key, create_action, update_action, opts \\ []) do # name, 
    quote do
      @impl true
      def update(assigns, socket) do
        change_func = change_func()
        on_init_func = on_init_func()
        socket = IndyForm.FormComponent.update(assigns, socket, change_func, on_init_func)
        {:ok, socket}
      end

      @impl true
      def handle_event("validate", params, socket) do
        form_key = unquote(form_key)
        form_params = params[form_key]
        cast_func = cast_func()
        change_func = change_func()
        on_value_change_func = unquote(opts)[:change_listeners] && on_value_change_func()
        socket = 
          IndyForm.FormComponent.validate(form_params, socket, cast_func, change_func, on_value_change_func)
        {:noreply, socket}
      end

      @impl true
      def handle_event("save", params, socket) do
        form_key = unquote(form_key)
        form_params = params[form_key]
        transform_form_func = transform_form_func()
        form_params = transform_form_func.(socket, form_params)
        
        create_func = create_func() 
        update_func = update_func()
        on_error_func = on_error_func()
        on_success_func = on_success_func()
        create_action = unquote(create_action) 
        update_action = unquote(update_action)
        socket = 
          apply_crud_action(
            socket, 
            form_params, 
            create_action, 
            update_action, 
            create_func, 
            update_func,
            on_success_func,
            on_error_func
          )
        
        {:noreply, socket}
      end

      @impl true
      def handle_event(event, params, socket) do
        on_event_func = on_event_func()
        socket = on_event_func.(event, params, socket)
        {:noreply, socket}
      end
    end
  end

  def crud_action(socket, create_action, update_action) do
    action = socket.assigns.action
    socket_create_actions = socket.assigns[:create_action] && List.wrap(socket.assigns.create_action)
    socket_update_actions = socket.assigns[:update_action] && List.wrap(socket.assigns.update_action)
    create_actions = 
    cond do
      socket_create_actions != nil and  action in socket_create_actions ->
        :create

      is_list(create_action) and action in create_action ->
        :create

      create_action == action ->
        :create

      socket_update_actions != nil and  action in socket_update_actions ->
        :update

      is_list(update_action) and action in update_action ->
        :update

      update_action == action ->
        :update

      true ->
        raise ArgumentError, message: "invalid action  - socket.live.action is expected to match either `create_action` or `update_action`. Verify create_action, update_action arguments passed to form_component/4 macro are correct and `socket.live.action` matches one of them."
        
    end
  end

  def apply_crud_action(socket, form_params, create_action, update_action, create_func, update_func, on_success_func, on_error_func) do # name, 
    crud_action = crud_action(socket, create_action, update_action)
    case crud_action do
      :create ->
        # msg = "#{name} created successfully"
        IndyForm.FormComponent.create(form_params, socket, create_func, on_success_func, on_error_func) #, msg

      :update ->
        # msg = "#{name} update successfully"
        IndyForm.FormComponent.update(form_params, socket, update_func, on_success_func, on_error_func) #, msg

    end  
  end

  def update(%{row: row} = assigns, socket, change_func, on_init_func) do
    changeset = change_func.(row, %{})
    socket
    |> assign(assigns)
    |> assign(:changeset, changeset)
    |> assign(:prev_form_params, %{})
    |> on_init_func.()
  end

  def validate(nil, _, _) do
    raise ArgumentError, message: "invalid argument form_params - expected form_params to be a :map, got: `nil`. Verify form_key argument passed to form_component/4 macro is correct."
  end

  def validate(form_params, socket, cast_func, change_func, on_value_change_func) do
    orig_changeset = socket.assigns.changeset
    changeset =
      socket.assigns.row
      |> change_func.(form_params)
      |> Map.put(:action, :validate)
    socket = assign(socket, :changeset, changeset)
    if on_value_change_func == nil do
      socket
    else
      change = find_change(form_params, socket, orig_changeset, changeset, cast_func)
      # require Logger
      # Logger.info("change - #{inspect change}")
      socket = assign(socket, :prev_form_params, form_params)
      (change && on_value_change_func.(socket, change)) || socket
    end
  end

  def find_change(form_params, socket, orig_changeset, changeset, cast_func) do
    orig_errors = Enum.into(orig_changeset.errors, [])
    errors = Enum.into(changeset.errors, [])
    diff_errors = List.myers_difference(orig_errors, errors)
    
    # require Logger
    # Logger.info("orig_errors - #{inspect orig_errors}")
    # Logger.info("errors - #{inspect errors}")
    # Logger.info("diff_errors - #{inspect diff_errors}")
    change = 
      cond do
        diff_errors[:ins] == nil and diff_errors[:del] == nil ->
          find_change_in_changes(socket, orig_changeset, changeset)

        diff_errors[:ins] != nil and (length(diff_errors[:ins]) == 1) ->
          # Logger.info("invalid change? - new_error")
          [{key, _}] = diff_errors[:ins]
          changeset = cast_func.(socket.assigns.row, form_params)
          new_value = Ecto.Changeset.get_change(changeset, key)
          old_value = Ecto.Changeset.get_field(orig_changeset, key)
          {key, old_value, new_value}


        diff_errors[:del] != nil and (length(diff_errors[:del]) == 1) ->
          # Logger.info("invalid change?")
          [{key, _}] = diff_errors[:del]
          orig_changeset = cast_func.(socket.assigns.row, socket.assigns.prev_form_params || %{})
          new_value = Ecto.Changeset.get_field(changeset, key)
          old_value = Ecto.Changeset.get_field(orig_changeset, key)
          {key, old_value, new_value}

        true ->
          nil
      end

    # Logger.info("#### validate - change - #{inspect change}")
    change =
      if change == nil and diff_errors[:ins] == nil do
          # changed to original value?
          find_change_in_params(socket, orig_changeset, changeset)
      else 
        change
      end
  end

  def find_change_in_params(socket, orig_changeset, changeset) do
    orig_params = Enum.into(socket.assigns.prev_form_params || %{}, []) 
    params = Enum.into(changeset.params, [])
    diff = List.myers_difference(orig_params, params)
    # require Logger
    # Logger.info("orig_params - #{inspect orig_params}")
    # Logger.info("params - #{inspect params}")
    # Logger.info("diff params - #{inspect diff}")
    change = 
      cond do
        diff[:del] != nil and diff[:ins] != nil -> 
          [{key, new_value}] = diff[:ins]        
          [{key, old_value}] = diff[:del]
          key = String.to_existing_atom(key)
          old_value = Ecto.Changeset.get_change(orig_changeset, key)
          new_value = Ecto.Changeset.get_field(changeset, key)
          {key, old_value, new_value}

        true ->
          nil
      end
  end

  def find_change_in_changes(socket, orig_changeset, changeset) do
    orig_changes = Enum.into(orig_changeset.changes, [])
    changes = Enum.into(changeset.changes, [])
    diff = List.myers_difference(orig_changes, changes)

    # require Logger
    # Logger.info("find_change_in_changes - orig_changes - #{inspect orig_changes}")
    # Logger.info("find_change_in_changes - changes - #{inspect changes}")
    # Logger.info("find_change_in_changes - diff changes - #{inspect diff}")
    cond do
      diff[:ins] == nil and diff[:del] == nil ->
        nil

      diff[:ins] == nil and diff[:del] != nil and (length(diff[:del]) == 1) ->
        [{key, old_value}] = diff[:del]
        new_value = Ecto.Changeset.get_field(changeset, key)
        {key, old_value, new_value}

      diff[:del] == nil and diff[:ins] != nil and (length(diff[:ins]) == 1)  ->
        [{key, new_value}] = diff[:ins]
        old_value = Ecto.Changeset.get_field(orig_changeset, key)
        {key, old_value, new_value}

      diff[:del] != nil and diff[:ins] != nil and (length(diff[:del]) == 1) and (length(diff[:ins]) == 1) -> 
        [{key, new_value}] = diff[:ins]        
        [{key, old_value}] = diff[:del]
        {key, old_value, new_value}

      # true ->
      #   nil

    end    
  end  

  defp maybe_navigate(socket, navigate_to) do
    case navigate_to do
      {:navigate, opts} when is_list(opts) ->
        push_navigate(socket, opts)

      {:navigate, to} when is_binary(to)  ->
        push_navigate(socket, to: to)

      {:patch, opts} when is_list(opts) ->
        push_patch(socket, opts)

      {:patch, to} when is_binary(to)  ->
        push_patch(socket, to: to)

      {:redirect, opts} when is_list(opts) ->
        redirect(socket, opts)

      {:redirect, to} when is_binary(to) ->
        redirect(socket, to: to)

      _ ->
        socket

    end
  end

  defp maybe_invoke_on_success(socket, row, on_success_func) do
    on_success = socket.assigns[:on_success]
    result = 
      cond do 
        on_success == nil ->
          on_success_func.(socket, row)

        is_tuple(on_success) ->
          maybe_navigate(socket, on_success)

        on_success && is_function(on_success, 1) ->
          navigate_to = on_success.(row)
          maybe_navigate(socket, navigate_to)

        on_success && is_function(on_success, 2) ->
          on_success.(socket, row)

      end
    
  end

  defp maybe_invoke_on_error(socket, result, on_error_func) do
    on_error = socket.assigns[:on_error]
    cond do 
      on_error == nil ->
        on_error_func.(socket, result)

      is_tuple(on_error) ->
          maybe_navigate(socket, on_error)

      on_error && is_function(on_error, 1) ->
        navigate_to = on_error.(result)
        maybe_navigate(socket, navigate_to)

      on_error && is_function(on_error, 2) ->
        on_error.(socket, result)
    
    end
  end

  def create(form_params, socket, create_func, on_success_func, on_error_func) do
    row = socket.assigns.row
    result = create_func.(row, form_params)
    case result do
      {:ok, row} ->
        maybe_invoke_on_success(socket, result, on_success_func)
      
      {:error, %Ecto.Changeset{} = changeset} ->
        # require Logger
        # Logger.info("##changeset - #{inspect changeset}")
        socket
        |> assign(:changeset, changeset)
        |> maybe_invoke_on_error(changeset, on_error_func)

      _ ->
        maybe_invoke_on_error(socket, result, on_error_func)

    end
  end

  def update(form_params, socket, update_func, on_success_func, on_error_func) do
    row = socket.assigns.row
    result = update_func.(row, form_params)
    case result do
      {:ok, row} ->
        maybe_invoke_on_success(socket, row, on_success_func)

      {:error, %Ecto.Changeset{} = changeset} ->
        # require Logger
        # Logger.info("##changeset - #{inspect changeset}")
        socket
        |> assign(:changeset, changeset)
        |> maybe_invoke_on_error(changeset, on_error_func)

      _ ->
        maybe_invoke_on_error(socket, result, on_error_func)
        
    end
  end
end
