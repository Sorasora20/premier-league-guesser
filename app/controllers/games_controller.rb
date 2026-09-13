class GamesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:guess, :reset]

  def index
    # Initialize game state if not present
    answer_id = session[:answer_player_id]
    if answer_id.nil? || Player.find_by(id: answer_id).nil?
      # Pick a random player
      answer_id = Player.order("RANDOM()").first&.id
      session[:answer_player_id] = answer_id
      session[:guesses] = []
    end

    @answer_player = Player.find_by(id: answer_id)
    current_guesses = session[:guesses] || []
    @guesses = Player.where(id: current_guesses).index_by(&:id).values_at(*current_guesses).compact
    @players = Player.order(:name)
    @game_won = @guesses.last&.id == @answer_player&.id
  end

  def guess
    player = Player.find_by(name: params[:player_name])
    if player
      current_guesses = session[:guesses] || []
      current_guesses << player.id unless current_guesses.include?(player.id)
      session[:guesses] = current_guesses
    else
      flash[:alert] = "Player not found."
    end
    redirect_to root_path
  end

  def reset
    session[:answer_player_id] = nil
    session[:guesses] = []
    redirect_to root_path
  end
end
