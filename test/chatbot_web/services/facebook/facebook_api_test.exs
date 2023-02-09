defmodule ChatbotWeb.Services.Facebook.FacebookApiTest do
  use ExUnit.Case

  import Mox

  alias ChatbotWeb.Services.Facebook.FacebookApi
  alias ChatbotWeb.Utils.PayloadBuilder

  describe "send_message test" do
    test "returns {:ok, body} for valid request" do
      psid = "test_user_id"
      payload = PayloadBuilder.text_template(psid, "Hello, World!")

      HttpAdapterMock
      |> expect(:post, fn _url, _body ->
        {:ok,
         %{
           body: %{recipient_id: psid, message_id: "some test id"},
           status_code: 200
         }}
      end)

      assert {:ok, result} = FacebookApi.send_message(payload)
      assert result.recipient_id == psid
    end

    test "returns {:error, body} for invalid payload request" do
      psid = "test_user_id"
      payload = PayloadBuilder.text_template(psid, "Hello, World!")

      HttpAdapterMock
      |> expect(:post, fn _url, _body ->
        {:ok,
         %{
           body: %{error: %{message: "Invalid payload."}},
           status_code: 400
         }}
      end)

      assert {:error, result} = FacebookApi.send_message(payload)
      assert result.error == %{message: "Invalid payload."}
    end
  end

  describe "get_user_information test" do
    test "returns {:ok, body} for valid requests" do
      psid = "test_user_id"
      first_name = "John"

      HttpAdapterMock
      |> expect(:get, fn _url ->
        {:ok,
         %{
           body: %{id: psid, first_name: "John"},
           status_code: 200
         }}
      end)

      assert {:ok, result} = FacebookApi.get_user_information(psid)
      assert result.first_name == first_name
      assert result.id == psid
    end

    test "handle {:error, error} match for handle_response" do
      HttpAdapterMock
      |> expect(:get, fn _url ->
        {:error,
         %{
           body: %{error: "Something went wrong."},
           status_code: 500
         }}
      end)

      assert {:error, _error} = FacebookApi.get_user_information("psid")
    end
  end
end
