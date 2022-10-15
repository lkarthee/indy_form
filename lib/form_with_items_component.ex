defmodule IndyForm.FormWithItemsComponent do
  use Phoenix.Component
  import Phoenix.LiveView

  defmacro __using__(context: module) do
    quote do
      import IndyForm.FormWithItemsComponent
      
      def cast_func(), do: &unquote(module).cast_row/2
      
      def change_func(), do: &unquote(module).change_row/2

      def create_func(), do: &unquote(module).create_row/2

      def update_func(), do: &unquote(module).update_row/2

      def on_init(socket), do: socket

      def on_change(socket, _change), do: socket

      def on_delete_item(socket, _type), do: socket

      def on_delete_item(socket, _type, _row), do: socket

      def transform_form(_socket, params), do: params

      def transform_form_func(), do: &transform_form/2

      def on_init_func(), do: &on_init/1
      
      def on_change_func(), do: &on_change/2

      def delete_item_row_func(_type) do
        raise ArgumentError, message: "delete_item_row_func/1 should be overridden."
      end

      def get_item_row_func(_type) do
        raise ArgumentError, message: "get_item_row_func/1 should be overridden."
      end

      def on_delete_item_func(), do: &on_delete_item/2

      def on_delete_item_param_func(), do: &on_delete_item/3

      defoverridable [
        cast_func: 0,
        change_func: 0, 
        create_func: 0, 
        update_func: 0, 
        on_init: 1,
        on_change: 2, 
        on_delete_item: 2,
        on_delete_item: 3,
        transform_form: 2, 
        get_item_row_func: 1,
        delete_item_row_func: 1
      ]
    end
  end

  defmacro form_component(name, form_key, create_action, update_action) do
    quote do
      @impl true
      def update(assigns, socket) do
        change_func = change_func()
        on_init_func = on_init_func()
        socket = IndyForm.FormWithItemsComponent.update(assigns, socket, change_func, on_init_func)
        {:ok, socket}
      end

      @impl true
      def handle_event(event_name, params, socket) do
        socket = 
          case event_name do
            "validate" ->
              form_key = unquote(form_key)
              form_params = params[form_key]
              change_func = change_func()
              cast_func = cast_func()
              on_change_func = on_change_func()
              IndyForm.FormComponent.validate(form_params, socket, cast_func, change_func, on_change_func)

            "save" ->
              name = unquote(name)
              form_key = unquote(form_key)
              form_params = params[form_key]
              transform_form_func = transform_form_func()
              form_params = transform_form_func.(socket, form_params)
              
              create_func = create_func() 
              update_func = update_func()
              create_action = unquote(create_action)
              update_action = unquote(update_action)
              IndyForm.FormComponent.apply_crud_action(
                socket, 
                form_params, 
                name, 
                create_action, 
                update_action, 
                create_func, 
                update_func
              )
              
            "show_delete_item_popup" ->
              IndyForm.FormWithItemsComponent.show_delete_item_popup(params, socket)

            "close_delete_item_popup" ->
              IndyForm.FormWithItemsComponent.close_delete_item_popup(params, socket)

            "delete_item" ->
              get_item_row_func =  get_item_row_func(socket.assigns.delete_item_type)
              delete_item_row_func = delete_item_row_func(socket.assigns.delete_item_type)
              on_delete_item_func = on_delete_item_func()
              on_delete_item_param_func = on_delete_item_param_func()
              IndyForm.FormWithItemsComponent.delete_item(
                  params, 
                  socket, 
                  get_item_row_func, 
                  delete_item_row_func,
                  on_delete_item_func,
                  on_delete_item_param_func
                )

            _ ->
              socket
              # on_event(event_name, params, socket)
              
          end
        {:noreply, socket}
      end
    end
  end

  def default_transform_form(_socket, params), do: params

  def update(%{row: row} = assigns, socket, change_func, on_init_func) do
    assigns
    |> IndyForm.FormComponent.update(socket, change_func, on_init_func)
    |> assign(:show_delete_item_popup, false)
  end

  def show_delete_item_popup(params, socket) do
    socket
    |> assign(:show_delete_item_popup, true)
    |> assign(:delete_item_id, params["id"])
    |> assign(:delete_item_type, params["type"])
  end

  def close_delete_item_popup(_params, socket) do
    socket
    |> assign(:show_delete_item_popup, false)
    |> assign(:delete_item_id, nil)
    |> assign(:delete_item_type, nil)
  end

  def delete_item(_params, socket, get_item_row_func, delete_item_row_func, on_delete_item_func, on_delete_item_param_func) do
    item_row = get_item_row_func.(socket.assigns.delete_item_id)
    result = delete_item_row_func.(item_row)
    delete_item_type = socket.assigns.delete_item_type

    socket
    |> assign(:show_delete_item_popup, false)
    |> assign(:delete_item_id, nil)
    |> assign(:delete_item_type, nil)
    |> on_delete_item_func.(delete_item_type)
    |> on_delete_item_param_func.(delete_item_type, item_row)
  end
end
