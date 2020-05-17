defmodule Chat.Question.Message do
  @enforce_keys [:id, :leads_to, :comments]

  defstruct id: nil,
            leads_to: nil,
            comments: []
end
