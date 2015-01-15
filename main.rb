require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

def make_cards
  @cards = []
  %w(Hearts Diamonds Clubs Spades).each do |suit|
    %w(2 3 4 5 6 7 8 9 10 Jack King Queen Ace).each do |card|
      @cards << [suit, card]
    end
  end
end

get '/' do
  if session[:username] == nil
    erb :get_name
  else
    redirect '/bet'
  end
end

post '/set_name' do
  if params[:username] == ''
    redirect '/'
  else
    session[:username] = params[:username]
    redirect '/bet'
  end
end

get '/bet' do
  erb :get_bet
end

post '/set_bet' do
  session[:wager] = params[:wager]
  redirect '/game'
end

get '/game' do
  make_cards
  session[:cards] = @cards.shuffle!
  erb :game
end

get '/start_over' do
  session.clear
  redirect '/'
end
