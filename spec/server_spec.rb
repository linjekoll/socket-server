describe "requests", js: true, type: :request do
  let(:data) {
    {
      event: "this is a random event",
      next_station: 8998235,
      previous_station: 898345,
      arrival_time: 1318843870,
      alert_message: "oops!",
      line_id: 1,
      provider_id: 1,
      journey_id: 123123
    }
  }
  
  it "should be able to respond with data" do
    visit "/"
    
    within("#first-input") do
      fill_in "Line", with: "1"
      fill_in "Provider", with: "1"
    end

    click_button "Send"

    push(data) # Pushes data to beanstalk
    
    page.should have_content("this is a random event")
  end
end
