class GamesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:start, :guess, :reset]

  def menu
  end

  def start
    difficulty = params[:difficulty] || 'NORMAL'
    setup_game(difficulty)
    redirect_to games_play_path
  end

  def index
    answer_id = session[:answer_player_id]
    if answer_id.nil? || Player.find_by(id: answer_id).nil?
      redirect_to root_path
      return
    end

    @answer_player = Player.find_by(id: answer_id)
    current_guesses = session[:guesses] || []
    @guesses = Player.where(id: current_guesses).index_by(&:id).values_at(*current_guesses).compact
    @revealed_hints = session[:revealed_hints] || {}
    @players = Player.order(:name)
    @game_won = @guesses.last&.id == @answer_player&.id
    @player_revealed = session[:is_revealed] || false
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
    redirect_to games_play_path
  end

  def reset
    difficulty = session[:difficulty] || 'NORMAL'
    setup_game(difficulty)
    redirect_to games_play_path
  end

  def hint
    answer_id = session[:answer_player_id]
    answer_player = Player.find_by(id: answer_id)
    requested_attribute = params[:attribute]

    session[:revealed_hints] ||= {}

    hint_value = case requested_attribute
                  when 'name'        then answer_player.name
                  when 'nationality' then answer_player.nationality
                  when 'club'        then answer_player.club
                  when 'position'    then answer_player.position
                  when 'height'      then "#{answer_player.height}cm"
                  when 'foot'        then answer_player.preferred_foot
                  when 'age'         then answer_player.age
                  else
                    "?"
                  end

    session[:revealed_hints][requested_attribute] = hint_value
    
    redirect_to games_play_path
  end

  def reveal
    session[:is_revealed] = true
    redirect_to games_play_path
  end

  private

  def setup_game(difficulty)
    session[:difficulty] = difficulty
    
    tier_map = {
      'EASY' => ['S'],
      'NORMAL' => ['A'],
      'HARD' => ['B'],
      'VERY HARD' => ['C'],
      'EXTREME' => ['D', 'Unranked']
    }
    
    target_tiers = tier_map[difficulty] || ['A']
    
    possible_players = Player.all.select { |p| target_tiers.include?(p.tier) }
    possible_players = Player.all if possible_players.empty?
    
    answer_id = possible_players.sample&.id
    
    session[:answer_player_id] = answer_id
    session[:guesses] = []
    session[:revealed_hints] = {}
    session[:is_revealed] = false
  end
end