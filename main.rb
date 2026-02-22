require 'discordrb'
require 'dotenv/load'
require 'ruby-prolog'
require 'date'
require 'net/http'
require 'uri'

# Initialize the bot with your application's token
#bot = Discordrb::Bot.new(token: ENV['DISCORD_BOT_TOKEN'], intents: :all)
bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_BOT_TOKEN'], prefix: '!'
# Register an event handler that listens for messages with the text "Ping!"
bot.message(with_text: 'nerd ping') do |event|
  # Respond in the same channel
  event.respond 'nerd pong'
end

bot.command :say do |_event, *args|
  args.join(' ')
end

bot.command :get_today do |_event|
  today = Date.today
  wordle_grab(today)
end

bot.command :get_yesterday do |_event|
  yesterday = Date.today - 1
  wordle_grab(yesterday)
end

bot.command :get_tomorrow do |_event|
  tomorrow = Date.today + 1
  wordle_grab(tomorrow)
end

def wordle_grab(day)
  url_str = "https://www.nytimes.com/svc/wordle/v2/#{day}.json"
  uri = URI(url_str)
  response = Net::HTTP.get(uri)
  result = JSON.parse(response)
  puts response
  puts result["solution"]
end
# Run the bot
bot.run

if __FILE__ == $0

end