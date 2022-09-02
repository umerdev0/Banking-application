# frozen_string_literal: true

class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :unprocessable_entity

  def render_errors(record)
    render status: :unprocessable_entity,
           json: { errors: record.errors.full_messages.presence || ['Failed to perform this action!'] }
  end

  private

  def unprocessable_entity(exception)
    render json: { errors: exception.message }, status: :unprocessable_entity
  end
end
