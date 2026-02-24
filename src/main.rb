require 'discordrb'
require 'sqlite3'
require 'dotenv/load'
require 'ruby-prolog'
require 'date'
require 'net/http'
require 'uri'

include RubyProlog

bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_BOT_TOKEN'], prefix: '!'
$wordlist_filepath = File.join(__dir__,"../text/wordle-allowed-guesses.db")

bot.message(with_text: 'nerd ping') do |event|
  # Respond in the same channel
  event.respond 'nerd pong'
end

bot.command :say do |_event, *args|
  args.join(' ')
end

bot.command :annoy_brian do |_event|
  _event.respond "ANNOY BRIAN ACTIVATE"
  _event.respond "@Brian"
end

bot.command :guess_today do |_event|
  today = Date.today
  answer = wordle_grab(today)
  prolog_query(answer)
end

bot.command :guess_yesterday do |_event|
  yesterday = Date.today - 1
  answer = wordle_grab(yesterday)
  prolog_query(answer)
end

bot.command :guess_tomorrow do |_event|
  tomorrow = Date.today + 1
  answer = wordle_grab(tomorrow)
  prolog_query(answer)
end

def wordle_grab(day)
  url_str = "https://www.nytimes.com/svc/wordle/v2/#{day}.json"
  uri = URI(url_str)
  response = Net::HTTP.get(uri)
  result = JSON.parse(response)
  result["solution"]
end

def rand_guess
  seed = Random.new_seed
  rand_num = Random.new(seed)
  guess_num = rand_num.rand(1..10657)
  random_guess = grab_word(guess_num)
end

def grab_word(index=10657)
  db = SQLite3::Database.new($wordlist_filepath)
  db.execute("SELECT * FROM words WHERE rowid = ?", index).first.first
end

def prolog_query(pre_answer)
  guess = rand_guess.chars
  guess.reverse.reduce([]) { |acc, el| [el, acc] }
  answer = pre_answer.chars
  answer.reverse.reduce([]) { |acc, el| [el, acc] }
  c = RubyProlog::Core.new
  c.instance_eval do
    likes['John', guess].fact
    likes[guess, 'John'].fact

    friends[:X, :Y] << [likes[:X,:Y], likes[:Y,:X]]
  end
  c.query { friends['John', :Friends]}
end

# Run the bot
bot.run

if __FILE__ == $0

end