defmodule Chatbot.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Agent do przechowywania historii
      %{
        id: :history,
        start: {Agent, :start_link, [fn -> [] end, [name: :history]]}
      },
      # Finch HTTP client
      {Finch, name: ChatbotFinch}
    ]

    opts = [strategy: :one_for_one, name: Chatbot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
