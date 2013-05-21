require 'spec_helper' 

describe "check_events_activity" do 
 
  it "should check events activity", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for(@user)
    layer = create_layer_for (collection)
    field = create_field_for (layer)
    login_as (@user)
    visit collections_path
    click_link ('Activity')
    sleep 3
    page.save_screenshot 'TabActivity'
    page.should have_content ('Activity')
    find(:xpath, "//div[@class='tabsline']/table/tbody/tr[2]/td[2]/span[2]").click
    sleep 5
    page.should have_no_content ('mina@gutkowski.com')
    sleep 5
    find(:xpath, "//div[@class='tabsline']/table/tbody/tr[2]/td[2]/span[1]").click
    sleep 10
    page.has_content? ('mina@gutkowski.com')        
    sleep 2
    page.save_screenshot 'Check_events_activity.png'
  end
end