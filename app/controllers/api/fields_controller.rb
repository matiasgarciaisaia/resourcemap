class Api::FieldsController < ApplicationController
  before_filter :authenticate_api_user!

  def index
    render json: collection.visible_layers_for(current_user)
  end
end
