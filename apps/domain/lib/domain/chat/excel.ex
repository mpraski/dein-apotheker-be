defmodule Chat.Excel do
  @excel Xlsxir

  def ext, do: ".xltx"

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
