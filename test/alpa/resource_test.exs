defmodule Alpa.ResourceTest do
  use ExUnit.Case, async: true

  # Define a minimal model for testing
  defmodule TestModel do
    @type t :: %__MODULE__{id: String.t(), name: String.t()}
    defstruct [:id, :name]

    def from_map(map) when is_map(map) do
      %__MODULE__{
        id: map["id"],
        name: map["name"]
      }
    end
  end

  # Full CRUD resource
  defmodule FullResource do
    use Alpa.Resource,
      base_path: "/v2/things",
      model: Alpa.ResourceTest.TestModel,
      operations: [:list, :get, :create, :update, :delete]
  end

  # List + get only
  defmodule ReadOnlyResource do
    use Alpa.Resource,
      base_path: "/v2/widgets",
      model: Alpa.ResourceTest.TestModel,
      operations: [:list, :get],
      id_field: :widget_id
  end

  # Data client resource
  defmodule DataResource do
    use Alpa.Resource,
      base_path: "/v1beta1/screener/stocks",
      model: Alpa.ResourceTest.TestModel,
      operations: [:list],
      client: :data
  end

  describe "full CRUD resource" do
    test "defines list/0 and list/1" do
      assert function_exported?(FullResource, :list, 0)
      assert function_exported?(FullResource, :list, 1)
    end

    test "defines get/1 and get/2" do
      assert function_exported?(FullResource, :get, 1)
      assert function_exported?(FullResource, :get, 2)
    end

    test "defines create/1" do
      assert function_exported?(FullResource, :create, 1)
    end

    test "defines update/2" do
      assert function_exported?(FullResource, :update, 2)
    end

    test "defines delete/1 and delete/2" do
      assert function_exported?(FullResource, :delete, 1)
      assert function_exported?(FullResource, :delete, 2)
    end
  end

  describe "read-only resource" do
    test "defines list/0 and list/1" do
      assert function_exported?(ReadOnlyResource, :list, 0)
      assert function_exported?(ReadOnlyResource, :list, 1)
    end

    test "defines get/1 and get/2" do
      assert function_exported?(ReadOnlyResource, :get, 1)
      assert function_exported?(ReadOnlyResource, :get, 2)
    end

    test "does not define create/1" do
      refute function_exported?(ReadOnlyResource, :create, 1)
    end

    test "does not define update/2" do
      refute function_exported?(ReadOnlyResource, :update, 2)
    end

    test "does not define delete/1" do
      refute function_exported?(ReadOnlyResource, :delete, 1)
    end
  end

  describe "data client resource" do
    test "defines list/0 and list/1" do
      assert function_exported?(DataResource, :list, 0)
      assert function_exported?(DataResource, :list, 1)
    end

    test "does not define get" do
      refute function_exported?(DataResource, :get, 1)
    end
  end

  describe "compile-time validation" do
    test "raises on invalid operations" do
      assert_raise ArgumentError, ~r/Invalid operations/, fn ->
        defmodule BadResource do
          use Alpa.Resource,
            base_path: "/v2/bad",
            model: Alpa.ResourceTest.TestModel,
            operations: [:list, :explode]
        end
      end
    end
  end
end
