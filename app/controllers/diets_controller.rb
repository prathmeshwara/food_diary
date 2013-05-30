class DietsController < ApplicationController
  before_filter :require_user
  before_filter :find_diet_by_id, only: [ :show, :destroy ]

  #GET /diets(.:format)
  def index
    @diets = Diet.order('created_at DESC').page(params[:page]).per(Kaminari.config.default_per_page)
  end

  #GET /diets/new(.:format)
  def new
    @diet = Diet.new
  end

  #POST /diets(.:format)
  def create
    diet = current_user.diets.create(params[:diet])
    redirect_to diet, notice: "Successfully logged the diet."
  end

  #GET  /diets/:id(.:format)
  def show
  end

  #GET  /diets/:id/edit(.:format)
  def edit
  end

  #PUT  /diets/:id(.:format)
  def update
  end

  #DELETE  /diets/:id(.:format)
  def destroy
    @diet.destroy
    redirect_to diets_path, notice: "Successfully removed the diet."
  end

  #DELETE /diets/delete_all(.:format)
  def destroy_all
    Diet.delete_all
    redirect_to diets_path, notice: "Successfully removed all diets."
  end

  private

  def find_diet_by_id
    @diet = Diet.find_by_id(params[:id])
  end

end
