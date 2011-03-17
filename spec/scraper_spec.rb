# encoding: UTF-8
require 'spec_helper'
require 'scraper'

describe 'Al Hospital scraper' do

  after(:all) do
    begin
      CartoDB::Connection.drop_table 'near_hospitals_test'
    rescue Exception => e
    end
  end

  it 'should get all hospital data from www.juntadeandalucia.es' do
    expect{ CartoDB::Connection.table 'near_hospitals_test'}.to raise_error(CartoDB::CartoError, /Not found/)
    Scraper.go!

    table = CartoDB::Connection.table 'near_hospitals_test'
    table.should_not be_nil
    records = CartoDB::Connection.records table.name

    records.total_rows.should be == 1
    records.rows.should have(1).item
    records.rows.first.should include({
      :cartodb_id        => 1,
      :name              => 'Hospital Torrecárdenas',
      :description       => nil,
      :latitude          => 36.861999,
      :longitude         => -2.440701,
      :address           => 'Paraje Torrecárdenas s/n, Almería, Almería, 04009',
      :emergency_contact => "902 50 50 61",
      :website           => 'http://www.juntadeandalucia.es/servicioandaluzdesalud/htorrecardenas'
    })
  end
end