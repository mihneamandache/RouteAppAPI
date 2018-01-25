class RoutesController < ApplicationController
  def create
    @route = Route.new(route_params)

    if @route.save
      render json: @route.id
    else
      render json: "Error"
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