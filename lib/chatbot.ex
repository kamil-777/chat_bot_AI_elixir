defmodule Chatbot do
  alias Chatbot.Client

  def run(args) do
    case parse_args(args) do
      {:list} ->
        Client.list_models()
        |> IO.inspect(label: "Dostępne modele:")

      {:show, model} ->
        case Client.show_model(model) do
          {:ok, details} ->
            IO.inspect(details, label: "Szczegóły modelu:")

          {:error, reason} ->
            IO.puts("Błąd podczas pobierania szczegółów modelu: #{reason}")
        end

      {:pull, model} ->
        case Client.pull_model(model) do
          {:ok, _} ->
            IO.puts("Udało się spullować model.")

          {:error, reason} ->
            IO.puts("Błąd przy pullowaniu modelu: #{reason}")
        end

      {:model, model} ->
        IO.puts("Połączono z modelem #{model}")

      {:prompt, model, prompt} ->
        case Client.ask_model(model, prompt) do
          {:ok, response} ->
            update_history(%{prompt: prompt, response: response})
            IO.puts("Odpowiedź: #{response}")

          {:error, reason} ->
            IO.puts("Błąd podczas generowania odpowiedzi: #{reason}")
        end

      {:history} ->
        history()
        |> IO.inspect(label: "Historia interakcji")

      :unknown ->
        IO.puts("Nieznana komenda. Proszę spróbować później.")
    end
  end

  defp parse_args(["--list"]), do: {:list}
  defp parse_args(["--show", model]), do: {:show, model}
  defp parse_args(["--pull", model]), do: {:pull, model}
  defp parse_args(["--model", model]), do: {:model, model}
  defp parse_args(["--model", model, "--prompt", prompt]), do: {:prompt, model, prompt}
  defp parse_args(["--history"]), do: {:history}
  defp parse_args(_), do: :unknown

  def start do
    Agent.start_link(fn -> [] end, name: :history)
  end

  def history do
    Agent.get(:history, fn history -> history end)
  end

  defp update_history(entry) do
    Agent.update(:history, &([entry | &1]))
  end
end
