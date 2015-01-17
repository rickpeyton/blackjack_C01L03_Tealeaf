require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

def make_cards
  @cards = []
  # %w(Clubs Hearts Spades Diamonds).each do |suit|
  #   %w(Ace 2 3 4 5 6 7 8 9 10 Jack King Queen).each do |card|
  #     @cards << [suit, card]
  #   end
  # end
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
  session[:player_turn] = true
  session[:game_over] = false
  session[:message] = ''
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
      break if total <= 21
      total -= 10
    end

    total
  end
end

def bust
  session[:game_over] = true
  session[:message] = "#{session[:username]} busts! Dealer wins"
  session[:user_money] -= session[:wager]
end

def dealer_bust
  session[:game_over] = true
  session[:message] = "Dealer busts! #{session[:username]} wins"
  session[:user_money] += session[:wager]
end

def player_blackjack
  session[:game_over] = true
  session[:message] = "#{session[:username]} hits Blackjack!"
  session[:user_money] += (session[:wager] * 1.5).to_i
end

def dealer_blackjack
  session[:game_over] = true
  session[:message] = "Dealer hits Blackjack! #{session[:username]} loses"
  session[:user_money] -= session[:wager]
end

def pick_winner
  session[:game_over] = true
  if hand_total(session[:player_hand]) == hand_total(session[:dealer_hand])
    session[:message] = "Push. #{session[:username]} receives his bet back"
  elsif hand_total(session[:player_hand]) > hand_total(session[:dealer_hand])
    session[:message] = "#{session[:username]} wins $#{session[:wager]}!"
    session[:user_money] += session[:wager]
  else
    session[:message] = "Dealer wins! #{session[:username]} loses $#{session[:wager]}"
    session[:user_money] -= session[:wager]
  end
end

def dealer_turn
  session[:show_dealer_hand] = true
  while hand_total(session[:dealer_hand]) < 17
    session[:dealer_hand] << session[:cards].pop
  end
  if hand_total(session[:dealer_hand]) > 21
    dealer_bust
  elsif hand_total(session[:dealer_hand]) == 21
    dealer_blackjack
  else
    pick_winner
  end
end

get '/' do
  if session[:username]
    redirect '/bet'
  else
    erb :get_name
  end
end

post '/' do
  if params[:username] == ''
    @error = 'You must enter a name'
    erb :get_name
  else
    session[:username] = params[:username]
    session[:user_money] = 500
    redirect '/bet'
  end
end

get '/bet' do
  erb :get_bet
end

post '/bet' do
  if params[:wager].to_i > 0 && params[:wager].to_i <= session[:user_money]
    session[:wager] = params[:wager].to_i
    redirect '/game'
  else
    @error = "Your wager must be > 0 and less than $#{session[:user_money]}.00"
    erb :get_bet
  end
end

post '/player_turn' do
  if params[:player_move] == 'hit'
    session[:player_hand] << session[:cards].pop
    if hand_total(session[:player_hand]) > 21
      bust
    elsif hand_total(session[:player_hand]) == 21
      player_blackjack
    end
    redirect '/game'
  elsif params[:player_move] == 'stay'
    session[:player_turn] = false
    dealer_turn
    redirect '/game'
  end
end

post '/play_again' do
  if params[:play_again] == 'yes'
    session[:cards] = nil
    redirect '/bet'
  else
    redirect '/game_over'
  end
end

get '/game_over' do
  erb :game_over
end

get '/game' do
  if session[:cards] == nil
    initialize_game
    player_blackjack if hand_total(session[:player_hand]) == 21
  end
  if session[:user_money] > 0
    erb :game
  else
    redirect '/game_over'
  end
end

get '/start_over' do
  session.clear
  redirect '/'
end
