defmodule Alpa.VCRCase do
  @moduledoc """
  Test case for tests that use VCR cassettes.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use ExVCR.Mock, adapter: ExVCR.Adapter.Finch
    end
  end

  setup do
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes")
    :ok
  end
end
