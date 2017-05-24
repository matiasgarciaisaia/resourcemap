require 'spec_helper'

describe ImageGallery do
  it "uploads multiple logos" do
    binding.pry
    file = File.open('spec/fixtures/tracking_food.jpg')
    file2 = File.open('spec/fixtures/tracking_food.jpg')
    instance = ImageGallery.new
    instance.images = [file, file2]
    instance.save
    binding.pry
    puts "tu vieja"
  end
end
