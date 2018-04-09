class RoutesController < ApplicationController
  def create
    @route = Route.new(route_params)

    if @route.save
      render json: @route.id
    else
      render json: "Error"
    end
  end

  def configure
    @route = Route.find(params.require(:id))
    if @route.nil?
      render json: "Error, route not found"
    else
      to_render = @route.make_api_call
      render xml: to_render
    end
  end

  def route_params
    params.require(:route).permit(
      locations_attributes: [
        :latitude,
        :longitude,
        :location_type
      ]
    )
  end
end
