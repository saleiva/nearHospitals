NearHospitals::Application.routes.draw do
  match '/search' => 'search#search'
end
