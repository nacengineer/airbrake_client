defmodule Airbrake.Utils do
  @moduledoc false

  @filtered_value "[FILTERED]"

  # For filtering params and headers.
  def filter(input, nil) do
    input
  end

  def filter(map, filtered_attributes) when is_map(map) do
    Enum.into(map, %{}, &filter_key_value(&1, filtered_attributes))
  end

  def filter(list, filtered_attributes) when is_list(list) do
    Enum.map(list, &filter(&1, filtered_attributes))
  end

  def filter(other, _filtered_attributes) do
    other
  end

  def filter_key_value({k, v}, filtered_attributes) do
    if Enum.member?(filtered_attributes, k),
      do: {k, @filtered_value},
      else: {k, filter(v, filtered_attributes)}
  end
end
