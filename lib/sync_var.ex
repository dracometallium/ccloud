defmodule SyncVar do
use GenServer

@moduledoc """
# SyncVar help
"""

def get(name) do
  GenServer.call(name, {:get})
end

def get_state(name) do
  GenServer.call(name, {:get_state})
end

def set(name, val) do
  GenServer.call(name, {:set, val})
end

def update(name, fun) do
  GenServer.call(name, {:update, fun})
end

def inc(name) do
  GenServer.call(name, {:update, fn x -> x + 1 end}, 25000)
end

def dec(name) do
  GenServer.call(name, {:update, fn x -> x - 1 end})
end

def init(opts) do
  {:ok, opts[:val]}
end

def start_link(opts) do
  GenServer.start_link(__MODULE__, opts, name: opts[:name])
end

def handle_call({:get_state}, _from, state) do
  {:reply, state, state}
end

def handle_call({:get}, _from, state) do
  {:reply, state, state}
end

def handle_call({:set, nval}, _from, _state) do
  nstate = nval
  {:reply, nstate, nstate}
end

def handle_call({:update, fun}, _from, state) do
  nstate = fun.(state)
  {:reply, nstate, nstate}
end

end
