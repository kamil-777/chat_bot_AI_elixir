defmodule Chatbot.Client do
  require Logger

  @base_url "http://127.0.0.1:11434/api"

  # Pobierz listę dostępnych modeli
  def list_models do
    case get("/tags") do
      {:ok, %{"models" => models}} -> {:ok, models}
      {:error, reason} -> {:error, "Błąd przy wyświetlaniu modeli: #{reason}"}
    end
  end

  # Pokaż szczegóły konkretnego modelu
  def show_model(model) do
    payload = %{"name" => model}

    case post("/show", payload) do
      {:ok, details} -> {:ok, details}
      {:error, reason} -> {:error, "Błąd przy sprawdzaniu modelu: #{reason}"}
    end
  end

  # Pobierz model na serwer
  def pull_model(model) do
    payload = %{"name" => model}

    case post("/pull", payload) do
      {:ok, response} ->
        # Split response by newline and decode each JSON object
        response
        |> String.split("\n", trim: true)
        |> Enum.map(&Jason.decode!/1)
        |> Enum.each(&IO.inspect(&1, label: "Status pullowania"))
        {:ok, "Model spulowany prawidłowo."}

      {:error, reason} ->
        {:error, "Błąd przy pullowaniu modelu: #{reason}"}
    end
  end


  # Wygeneruj odpowiedź na podstawie promptu
  def ask_model(model, prompt) do
    payload = %{
      "model" => model,
      "prompt" => prompt,
      "stream" => false
    }

    case post("/generate", payload) do
      {:ok, %{"response" => response}} -> {:ok, response}
      {:ok, %{"choices" => [%{"text" => text} | _]}} -> {:ok, text}
      {:error, reason} -> {:error, "Błąd przy generowaniu odpowiedzi: #{reason}"}
    end
  end

  # Prywatna funkcja GET
  defp get(endpoint) do
    url = @base_url <> endpoint

    case Finch.build(:get, url) |> Finch.request(ChatbotFinch) do
      {:ok, %Finch.Response{status: 200, body: body}} when body != "" ->
        parse_response(body)

      {:ok, %Finch.Response{status: 200}} ->
        {:error, "Otrzymano pustą odpowiedź."}

      {:ok, %Finch.Response{status: status}} ->
        {:error, "Błąd HTTP: #{status}"}

      {:error, %Mint.TransportError{reason: reason}} ->
        {:error, "Błąd z połączeniem: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "Niespodziewany błąd: #{inspect(reason)}"}
    end
  end

  # Prywatna funkcja POST
  defp post(endpoint, payload) do
    url = @base_url <> endpoint
    headers = [{"Content-Type", "application/json"}]

    case Finch.build(:post, url, headers, Jason.encode!(payload)) |> Finch.request(ChatbotFinch) do
      {:ok, %Finch.Response{status: 200, body: body}} when body != "" ->
        parse_response(body)

      {:ok, %Finch.Response{status: 200}} ->
        {:ok, "Prośba udana, lecz odpowiedź jest pusta."}

      {:ok, %Finch.Response{status: status, body: body}} ->
        {:error, "HTTP #{status}: #{body}"}

      {:error, %Mint.TransportError{reason: reason}} ->
        {:error, "Błąd z połączeniem: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "Niespoedziewany błąd: #{inspect(reason)}"}
    end
  end

  # Parsowanie odpowiedzi z serwera
  defp parse_response(body) do
    case Jason.decode(body) do
      {:ok, json} -> {:ok, json}
      _ -> {:ok, body} # Jeśli to nie JSON, zwróć surowy tekst
    end
  end
end
