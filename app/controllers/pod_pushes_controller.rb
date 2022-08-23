class PodPushesController < ApplicationController
  def index
    @pushes = PodPush.last_pushes
  end

  def show
    @pp = JSON.pretty_generate(JSON.parse(PodPush.find(params[:id]).response))
  end
end
