class SearchController < ApplicationController
  def index
    @hospitals = []
    if request.xhr? && params[:lat].present? && params[:lon].present?
      records = CartoDB::Connection.records "near_hospitals_#{Rails.env}"
      @hospitals = records.rows
      render :partial => 'hospitals' and return
    end
  end
end
