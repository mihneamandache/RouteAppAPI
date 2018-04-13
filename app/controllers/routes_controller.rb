class RoutesController < ApplicationController
  def create
    @route = Route.new(route_params)

    if @route.save
      render json: {:route_id => @route.id}
    else
      render json: "Error"
    end
  end

  def configure
    @route = Route.find(params.require(:id))
    if @route.nil?
      render json: "Error, route not found"
    else
      to_render = @route.make_api_call(params[:travel_by], params[:adapt_to].to_i)
      to_render = {:error => to_render} if !to_render.is_a?(Array)
      render json: to_render
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
