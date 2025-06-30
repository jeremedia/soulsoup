class DashboardController < ApplicationController
  def index
    @total_souls = Soul.count
    @active_incarnations = Incarnation.active.count
    @total_incarnations = Incarnation.count
    @total_experience = Incarnation.sum(:total_experience)
    @average_grace = Soul.average(:current_grace_level) || 0
    @recent_incarnations = Incarnation.includes(:soul)
                                     .order(created_at: :desc)
                                     .limit(10)
  end

  def souls
    @souls = Soul.includes(:incarnations)
                 .order(current_grace_level: :desc, total_incarnations: :desc)
                 .limit(100)
  end

  def incarnations
    @incarnations = Incarnation.includes(:soul)
    
    # Apply filters
    @incarnations = @incarnations.where(ended_at: nil) if params[:status] == "active"
    @incarnations = @incarnations.where.not(ended_at: nil) if params[:status] == "ended"
    @incarnations = @incarnations.where(forge_type: params[:forge_type]) if params[:forge_type].present?
    
    # Apply sorting
    case params[:sort]
    when "created_at_asc"
      @incarnations = @incarnations.order(created_at: :asc)
    when "experience_desc"
      @incarnations = @incarnations.order(total_experience: :desc, created_at: :desc)
    when "duration_desc"
      @incarnations = @incarnations.order(Arel.sql("EXTRACT(EPOCH FROM (COALESCE(ended_at, NOW()) - created_at)) DESC"))
    else
      @incarnations = @incarnations.order(created_at: :desc)
    end
    
    # Calculate stats before pagination
    @stats = {
      total: @incarnations.count,
      active: @incarnations.where(ended_at: nil).count,
      average_duration: calculate_average_duration(@incarnations),
      total_experience: @incarnations.sum(:total_experience)
    }
    
    # Paginate
    @incarnations = @incarnations.page(params[:page]).per(25)
  end
  def soul
    Rails.logger.info "Soul action called with params[:id] = #{params[:id]}"

    # Handle both numeric ID and soul_id
    @soul = if params[:id].to_s.match?(/^soul-/)
              Soul.find_by!(soul_id: params[:id])
            else
              Soul.find(params[:id])
            end

    Rails.logger.info "Found soul: #{@soul.soul_id}"

    @incarnations = @soul.incarnations.order(created_at: :desc).limit(20)
    @relationships = @soul.soul_relationships.includes(:related_soul)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Soul not found: #{e.message}"
    raise
  end
  private
  
  def calculate_average_duration(incarnations)
    durations = incarnations.where.not(ended_at: nil).pluck(:created_at, :ended_at)
    return 0 if durations.empty?
    
    total_minutes = durations.sum { |start, finish| (finish - start) / 60.0 }
    (total_minutes / durations.length).round
  end
  

end