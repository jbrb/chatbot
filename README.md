# Chatbot

## About
This repository contains the source code for a chatbot that fetches information about cryptocurrency coins upon user's request and sends back the data of the requested cryptocurrency coin through Facebook Pages. This chatbot is powered by CoinGecko and Facebook's Messenger API.

## Setup

- Must have a live facebook app and subscribed page in order to receive webhook events.
- Add your WEBHOOK_TOKEN and FB_ACCESS_TOKEN (page access token) in docker-compose.yml file. 
- Start the server via docker-compose up.

## Technologies / Packages Used
- Elixir / Phoenix for the web application
- ETS for storing user's first name used in welcome message and user's choice of lookup (coin name or ID)
- Timex for formatting timestamp of coin price history
- Mox for defining a mock for the external APIs used
- HTTPoison for HTTP client
- CoinGecko API for cryptocurrency data
- Messenger API for creating the flow between user and bot

## File Structure
### Bot Implementation
lib/chatbot (Bot Implementation)\
└─ chatbot_ets.ex - <sub> Genserver module to start ETS tables for user info and user lookup </sub>\
└─ application.ex - <sub> Starts ChatbotEts module in app supervisor </sub>\
<br>
lib/chatbot_web (Bot Implementation)\
├─ controllers\
│  &emsp; └── webhook_controller.ex - <sub> Endpoints for verify webhook token and webhook events from the user </sub>\
├─ services\
│  &emsp; ├─── http_adapter.ex - <sub> HTTP  module used by FacebookApi and CoingeckoApi modules. </sub> \
│  &emsp; ├─── facebook \
│  &emsp;&emsp;&emsp;&emsp;&emsp; └── facebook_api.ex - <sub> Calls Facebook API for user information and sending bot replies </sub>  \
│  &emsp; ├─── coingecko \
│  &emsp;&emsp;&emsp;&emsp;&emsp; └── coingecko_api.ex - <sub> Calls Coingecko API for search, get by id and market chart </sub>  \
├─ utils \
│  &emsp; └── payload_builder.ex - <sub> Builds payload for bot's reply</sub> \
│  &emsp; └── webhook_handler.ex - <sub> Handle facebook's webhook event to establish bot flow and send bot replies </sub>


### Tests
Most of the tests except payload builder uses Mox for HTTP calls (coingecko and facebook) since calling the Facebook API is the last part of the flow.

test/chatbot_web (Bot Implementation)\
├─ controllers\
│  &emsp; └── webhook_controller_test.exs\
├─ services\
│  &emsp; ├─── facebook \
│  &emsp;&emsp;&emsp;&emsp;&emsp; └── facebook_api_test.exs \
│  &emsp; ├─── coingecko \
│  &emsp;&emsp;&emsp;&emsp;&emsp; └── coingecko_api_test.exs \
├─ utils \
│  &emsp; └── payload_builder_test.exs  \
│  &emsp; └── webhook_handler_test.exs

## Test Coverage
![test_coverage](https://i.imgur.com/kSO7jjK.png)

## Bot Flow Demo
![bot_flow_demo](https://i.imgur.com/CX52IQf.gif)