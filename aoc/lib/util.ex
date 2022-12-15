defmodule AOCUtil do
  def manhattan({ax, ay}, {bx, by}), do: abs(ax - bx) + abs(ay - by)
end
