require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_HIT_TO = 17
INITIAL_POT_AMOUNT = 500

def make_cards
  @cards = []
  @cards = %w(Clubs Hearts Spades Diamonds).product(
             %w(Ace 2 3 4 5 6 7 8 9 10 Jack King Queen))
end

def deal_4_cards
  session[:dealer_hand] << session[:cards].pop
  session[:player_hand] << session[:cards].pop
  session[:dealer_hand] << session[:cards].pop
  session[:player_hand] << session[:cards].pop
  session[:show_dealer_hand] = false
end

def initialize_game
  make_cards
  session[:cards] = @cards.shuffle!
  session[:dealer_hand] = []
  session[:player_hand] = []
  deal_4_cards
end

helpers do
  def card_image(card)
    card[0].downcase + '_' + card[1].downcase + '.jpg'
  end

  def hand_total(cards)
    values = cards.map{ |card| card[1] }
    total = 0
    values.each do |value|
      if value == 'Ace'
        total += 11
      else
        total += (value.to_i == 0 ? 10 : value.to_i)
      end
    end

    # Correct for Aces
    values.select{ |value| value == 'Ace'}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total
  end

  def winner!(message)
    @show_play_again_buttons = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>You won!</strong> #{message}"
    if hand_total(session[:player_hand]) == BLACKJACK_AMOUNT
      session[:user_money] += (session[:wager] * 1.5).to_i
    else
      session[:user_money] += session[:wager].to_i
    end
  end

  def loser!(message)
    @show_play_again_buttons = true
    @show_hit_or_stay_buttons = false
    @error = "<strong>You lost...</strong> #{message}"
    session[:user_money] -= session[:wager].to_i
  end

  def tie!(message)
    @show_play_again_buttons = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>Push...</strong> #{message}"
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:username]
    redirect '/bet'
  else
    erb :get_name
  end
end

post '/' do
  validate_name = /^[^a-zA-Z]{1}|[^a-zA-Z\s]/
  if params[:username].empty? || (params[:username] !~ validate_name) == false
    @error = 'Name must start with a letter and contain only letters and spaces.'
    halt erb :get_name
  end
  session[:username] = params[:username]
  session[:user_money] = INITIAL_POT_AMOUNT
  redirect '/bet'
end

get '/bet' do
  erb :get_bet
end

post '/bet' do
  validate_wager = /^[^1-9]{1}|[^0-9]/
  if params[:wager].to_i < 1 ||
       params[:wager].to_i > session[:user_money] ||
       (params[:wager] !~ validate_wager) == false
    @error = "Your wager be a whole number greater than 0 and less than $#{session[:user_money]}"
    halt erb :get_bet
  end
  session[:wager] = params[:wager].to_i
  redirect '/game'
end

get '/game_over' do
  erb :game_over
end

get '/game' do
  initialize_game
  if hand_total(session[:player_hand]) == BLACKJACK_AMOUNT
    winner!("#{session[:username]} was dealt Blackjack.")
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_hand] << session[:cards].pop
  player_total = hand_total(session[:player_hand])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:username]} has Blackjack.")
    halt erb :game
  elsif player_total > BLACKJACK_AMOUNT
    loser!("#{session[:username]} busted with #{player_total}")
    halt erb :game
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  @success = "#{session[:username]} stays at #{hand_total(session[:player_hand])}"
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:show_dealer_hand] = true
  @show_hit_or_stay_buttons = false
  dealer_total = hand_total(session[:dealer_hand])
  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer has Blackjack.")
    halt erb :game
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busts with #{dealer_total}")
    halt erb :game
  elsif dealer_total < DEALER_HIT_TO
    @show_dealer_hit_button = true
  else
    redirect '/game/compare'
  end

  erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_hand] << session[:cards].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player = hand_total(session[:player_hand])
  dealer = hand_total(session[:dealer_hand])
  user = session[:username]
  if player == dealer
    tie!("#{user} and Dealer both stayed at #{player}.")
  elsif player > dealer
    winner!("#{user} stayed at #{player} and Dealer stayed at #{dealer}.")
  else
    loser!("Dealer stayed at #{dealer} and #{user} stayed at #{player}.")
  end
  erb :game
end

get '/start_over' do
  session.clear
  redirect '/'
end
