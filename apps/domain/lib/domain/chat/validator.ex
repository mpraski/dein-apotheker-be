defmodule Chat.Validator do
  alias Chat.{Scenario, Answer, Question, Comment, Product, Util, Translator}

  def validate(%Scenario{} = scenario) do
    scenario
    |> validate_all([
      &validate_entry_point/1,
      &validate_exclusion/1,
      &validate_consistency/1,
      &validate_cases/1,
      &validate_products/1,
      &validate_default_translation/1
    ])
  end

  defp validate_all(_, []), do: :ok

  defp validate_all(scenario, [f | checks]) do
    case f.(scenario) do
      :ok -> scenario |> validate_all(checks)
      {:error, error} -> {:error, error}
    end
  end

  defp apply_validation(items, validator) when is_function(validator, 1) do
    with named <- items |> Enum.map(&Kernel.to_string/1),
         validated <- items |> Enum.map(validator) do
      Enum.zip(named, validated)
    end
  end

  defp validate_entry_point(%Scenario{
         start: start,
         questions: questions
       }) do
    if questions
       |> Enum.map(&Util.pluck(&1, :id))
       |> Enum.member?(start) do
      :ok
    else
      {:error, "#{start} is not a valid entrypoint"}
    end
  end

  defp validate_exclusion(%Scenario{} = scenario) do
    with validated <- apply_validation(scenario, &validate_exclusion/1) do
      case Util.any?(validated) do
        {i, true} -> {:error, "#{i} both leads to question and jumps to scenario"}
        _ -> :ok
      end
    end
  end

  defp validate_exclusion(%Answer.Single{leads_to: l, jumps_to: j}), do: l != nil and j != nil
  defp validate_exclusion(%Answer.Multiple{leads_to: l, jumps_to: j}), do: l != nil and j != nil
  defp validate_exclusion(_), do: false

  defp validate_consistency(%Scenario{questions: questions} = scenario) do
    question_ids =
      questions
      |> Enum.map(&Util.pluck(&1, :id))
      |> Util.index()

    with validated <- apply_validation(scenario, &validate_consistency(&1, question_ids)) do
      case Util.all?(validated) do
        {i, false} -> {:error, "#{i} doesn't lead to existing question"}
        _ -> :ok
      end
    end
  end

  defp validate_consistency(%Answer.Single{leads_to: id}, m), do: m |> Util.has_key?(id)
  defp validate_consistency(%Answer.Multiple{leads_to: id}, m), do: m |> Util.has_key?(id)
  defp validate_consistency(%Question.Prompt{leads_to: id}, m), do: m |> Util.has_key?(id)
  defp validate_consistency(%Question.Message{leads_to: id}, m), do: m |> Util.has_key?(id)
  defp validate_consistency(_, _), do: true

  defp validate_cases(%Scenario{questions: questions}) do
    with validated <- apply_validation(questions, &validate_cases/1) do
      case Util.all?(validated) do
        {i, false} -> {:error, "#{i} doesn't lead to existing question"}
        _ -> :ok
      end
    end
  end

  defp validate_cases(%Question.Multiple{decisions: decisions, answers: answers}) do
    decisions |> Enum.all?(&validate_cases(&1, answers |> Util.index()))
  end

  defp validate_cases(_), do: true

  defp validate_cases(%Answer.Multiple{case: :default}, _), do: true

  defp validate_cases(%Answer.Multiple{case: cases}, t) do
    cases |> Enum.all?(&Map.has_key?(t, &1))
  end

  defp validate_default_translation(%Scenario{translations: ts} = scenario) do
    with l <- Translator.default_language(),
         t <- ts |> Map.get(l),
         validated <- apply_validation(scenario, &validate_translation(&1, t)) do
      case Util.all?(validated) do
        {i, false} ->
          {:error, "#{i} is not translated in default language (#{l})"}

        _ ->
          :ok
      end
    end
  end

  defp validate_translation(%Scenario{translations: ts} = scenario) do
    validated =
      for {_, t} <- ts do
        scenario |> Enum.all?(&validate_translation(&1, t))
      end

    Enum.all?(validated)
  end

  defp validate_translation(%Question.Single{id: id}, t), do: t |> Map.has_key?(id)
  defp validate_translation(%Question.Multiple{id: id}, t), do: t |> Map.has_key?(id)
  defp validate_translation(%Question.Prompt{id: id}, t), do: t |> Map.has_key?(id)
  defp validate_translation(%Question.Message{}, _), do: true

  defp validate_translation(%Answer.Single{id: id}, t), do: t |> Map.has_key?(id)

  defp validate_translation(%Answer.Multiple{case: :default}, _), do: true

  defp validate_translation(%Answer.Multiple{case: cases}, t) do
    cases
    |> Enum.map(&Map.has_key?(t, &1))
    |> Enum.all?()
  end

  defp validate_translation(%Comment.Text{content: content}, t), do: t |> Map.has_key?(content)

  defp validate_translation(%Comment.Image{content: c, image: i}, t) do
    [c, i] |> Enum.all?(&Map.has_key?(t, &1))
  end

  defp validate_translation(%Comment.Product{}, _), do: true

  defp validate_translation(
         %Product{
           name: n,
           directions: d,
           explanation: e,
           image: i
         },
         t
       ) do
    [n, d, e, i] |> Enum.all?(&Map.has_key?(t, &1))
  end

  defp validate_translation(a, t) when is_binary(a), do: t |> Map.has_key?(a)

  defp validate_products(
         %Scenario{
           products: products
         } = scenario
       ) do
    product_ids =
      products
      |> Enum.map(&Util.pluck(&1, :id))
      |> Util.index()

    with validated <- apply_validation(scenario, &validate_product(&1, product_ids)) do
      case Util.all?(validated) do
        {i, false} -> {:error, "#{i} does not point to existing product"}
        _ -> :ok
      end
    end
  end

  defp validate_product(%Comment.Product{product: p}, ps), do: ps |> Map.has_key?(p)
  defp validate_product(_, _), do: true
end
