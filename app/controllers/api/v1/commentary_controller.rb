class Api::V1::CommentaryController < ApplicationController
  skip_before_action :verify_authenticity_token

  # POST /api/v1/commentary/game
  # Generate AI commentary for a completed game
  def game
    game_session_id = params[:game_session_id]
    winning_team = params[:winning_team]
    team_stats = params[:team_stats] || {}

    # For now, return a simple commentary
    # TODO: Integrate with AI service (Claude, GPT-4, etc.) for dynamic commentary
    commentary = generate_game_commentary(winning_team, team_stats)

    render json: {
      commentary: commentary,
      game_session_id: game_session_id
    }
  rescue => e
    Rails.logger.error "Failed to generate commentary: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: {
      error: "Failed to generate commentary",
      message: e.message
    }, status: :internal_server_error
  end

  private

  def generate_game_commentary(winning_team, team_stats)
    # Simple template-based commentary for now
    # In the future, this could call an AI service for more dynamic commentary

    total_kills = team_stats.values.sum { |stats| stats["kills"] || 0 }
    total_units = team_stats.values.sum { |stats| stats["units_spawned"] || 0 }

    winner_stats = team_stats[winning_team] || {}
    winner_kills = winner_stats["kills"] || 0
    winner_units = winner_stats["units_spawned"] || 0

    # Build commentary
    parts = []

    parts << "Victory for Team #{winning_team.upcase}!"

    if winner_kills > total_kills * 0.5
      parts << "Dominant performance with #{winner_kills} eliminations."
    elsif winner_kills > 0
      parts << "Hard-fought victory with #{winner_kills} eliminations."
    else
      parts << "A tactical victory through superior positioning."
    end

    if total_units > 100
      parts << "An epic battle involving #{total_units} digital souls."
    elsif total_units > 50
      parts << "A fierce conflict with #{total_units} combatants."
    end

    if winner_units > 0
      parts << "The #{winning_team} forge proved most resilient."
    end

    parts << "\n\nMay the vanquished souls return wiser and stronger."

    parts.join(" ")
  end
end
