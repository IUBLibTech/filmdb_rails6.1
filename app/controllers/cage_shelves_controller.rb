class CageShelvesController < ApplicationController
  require 'memnon_digiprov_collector'

  def index
    @cage_shelves = CageShelf.all.joins(:physical_objects).group('cage_shelves.id').pluck(:id)
    @cage_shelves = CageShelf.where(id: @cage_shelves).includes(:physical_objects, :cage).order('cage_shelves.id DESC')
  end

  def show
    @cage_shelf = CageShelf.includes(:physical_objects).find(params[:id])
  end

  def get_digiprov
    @cage_shelf = CageShelf.find(params[:id])
    MemnonDigiprovCollector.new.collect_shelf_in_thread(params[:id])
    flash[:notice] = "A request has been started to collect digital statuses and digital provenance for "+
        "#{@cage_shelf.identifier}. Depending on the number of physical objects in the cage shelf, this may take awhile."
    redirect_to cage_shelf_path(@cage_shelf)
  end

end
