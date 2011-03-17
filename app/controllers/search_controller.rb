class SearchController < ApplicationController
  def index
    records = CartoDB::Connection.records "near_hospitals_#{Rails.env}"
    @hospitals = records.rows
  end
end
