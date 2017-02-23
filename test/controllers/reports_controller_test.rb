require 'test_helper'

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get montly_birth_counts" do
    get reports_montly_birth_counts_url
    assert_response :success
  end

end
