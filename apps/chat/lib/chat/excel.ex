defmodule Chat.Excel do
  @moduledoc """
  Excel encapsulates some excel-specific logic
  """

  @excel Xlsxir

  def ext, do: ".xlsx"

  def open_table(path) do
    @excel.multi_extract(path, 0)
  end

  def read_table(ref) do
    @excel.get_list(ref)
  end

  def close_table(ref) do
    @excel.close(ref)
  end
end
