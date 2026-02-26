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
  # Ping
  event.respond 'nerd pong'
end

=begin
Guess today/yesterday/tomorrow all grab the daily Wordle relative to what day it currently is.
Essentially, the bot wants to get the answer in order to actually compare the answer to something. If you want
  to modify the code so that it simply sends the answer to the chat, be my guest LMAO.
Call !guess_(specify day) to get the bot to attempt to solve the Wordle.
=end

bot.command :guess_today do |_event|
  today = Date.today
  answer = wordle_grab(today)
  _event << play_game(answer)
end

bot.command :guess_yesterday do |_event|
  yesterday = Date.today - 1
  answer = wordle_grab(yesterday)
  _event << play_game(answer)
end

bot.command :guess_tomorrow do |_event|
  tomorrow = Date.today + 1
  answer = wordle_grab(tomorrow)
  _event << play_game(answer)
end

=begin
Grabs the current URL where the day's Wordle is stored.
Returns the solution of the puzzle
=end
def wordle_grab(day)
  url_str = "https://www.nytimes.com/svc/wordle/v2/#{day}.json"
  uri = URI(url_str)
  response = Net::HTTP.get(uri)
  result = JSON.parse(response)
  result["solution"]
end

=begin
Helper function to automatically pick a random 5-letter word to guess.
=end
def rand_guess
  seed = Random.new_seed
  rand_num = Random.new(seed)
  guess_num = rand_num.rand(1..10657)
  grab_word(guess_num)
end

def grab_word(index=10657)
  db = SQLite3::Database.new($wordlist_filepath)
  db.execute("SELECT * FROM words WHERE rowid = ?", index).first.first
end

=begin
Main game loop.
Gets fed the answer from one of the three commands and loops guess queries until it runs out of chances.
Intended return is the best guess prepended by "I tried []", but still testing other things
=end
def play_game(answer_str)
  answer = answer_str.chars
  answer.reverse.reduce([]) { |acc, el| [el, acc] }
  compared = nil

  (1..6).each { |i|
    puts "YIPEEEEE #{i}"
    guess = rand_guess.chars
    guess.reverse.reduce([]) { |acc, el| [el, acc] }
    compared = prolog_query answer, guess
    if compared == %w[g g g g g]
      break
    end
  }
  "I tried #{compared}"
end

=begin
Contains the entire ruleset for determining if a guess is correct.
Currently tinkering with it to learn PROLOG in the first place.
=end
def prolog_query(answer, guess)
  c = RubyProlog::Core.new
  c.instance_eval do
    likes[answer, guess].fact
    likes[guess, answer].fact
    mylist[['g','y','y','g','y']].fact

    friends[:X, :Y] << [likes[:X,:Y], likes[:Y,:X]]
    #^test code to make sure ruby-prolog works^

    #string_comp[:X,:Y] <<
    #  []
  end
  #c.query { friends[guess, :Answer]}
  c.query{mylist[:X]}
end

# Run the bot
bot.run

if __FILE__ == $0

end