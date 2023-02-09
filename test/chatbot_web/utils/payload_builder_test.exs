defmodule ChatbotWeb.Utils.PayloadBuilderTest do
  use ExUnit.Case, async: true

  alias ChatbotWeb.Utils.PayloadBuilder

  test "get_started_payload should return 3 templates" do
    templates = PayloadBuilder.get_started_payload("psid", "user_name")

    assert Enum.count(templates) == 3
  end

  test "get_started_payload's first element should welcome the user" do
    name = "John"
    templates = PayloadBuilder.get_started_payload("psid", name)
    assert %{message: %{text: welcome_message}} = Enum.at(templates, 0)
    assert String.contains?(welcome_message, "Welcome")
    assert String.contains?(welcome_message, name)
  end

  test "not_found_payload should have text element with message no results of the search term" do
    search_keyword = "NoneCoin"
    [text_template, _button_template] = PayloadBuilder.not_found_payload("psid", search_keyword)

    assert text_template.message.text == "No results matching for #{search_keyword}"
  end

  test "top_coins_payload return should be a list of elements depending on how many coins data" do
    coins_data =
      Enum.map(1..5, fn num ->
        %{id: "#{num}", thumb: "#{num}", symbol: "#{num}", name: "#{num}"}
      end)

    template = PayloadBuilder.top_coins_payload("psid", coins_data)

    assert Enum.count(coins_data) == Enum.count(template.message.attachment.payload.elements)
  end

  test "after_lookup_payload text element content should contain credits to the API Provider (CoinGecko)" do
    template = PayloadBuilder.after_lookup_payload("psid")

    assert String.contains?(template.message.attachment.payload.text, "powered by CoinGecko")
  end
end
