require 'test_helper'

class ObservationsControllerTest < ActionDispatch::IntegrationTest
	setup do
		@observation = observations(:one)
	end

	test "should get index" do
		get observations_url
		assert_response :success
	end

	test "should get new" do
		get new_observation_url
		assert_response :success
	end

	test "should create observation" do
		assert_difference('Observation.count') do
			post observations_url, params: { observation: { chirp_id: @observation.chirp_id, concept: @observation.concept, downloaded_at: @observation.downloaded_at, ended_at: @observation.ended_at, imported_at: @observation.imported_at, provider_id: @observation.provider_id, raw: @observation.raw, source_id: @observation.source_id, source_schema: @observation.source_schema, source_table: @observation.source_table, started_at: @observation.started_at, units: @observation.units, value: @observation.value } }
		end

		assert_redirected_to observation_url(Observation.last)
	end

	test "should show observation" do
		get observation_url(@observation)
		assert_response :success
	end

	test "should get edit" do
		get edit_observation_url(@observation)
		assert_response :success
	end

	test "should update observation" do
		patch observation_url(@observation), params: { observation: { chirp_id: @observation.chirp_id, concept: @observation.concept, downloaded_at: @observation.downloaded_at, ended_at: @observation.ended_at, imported_at: @observation.imported_at, provider_id: @observation.provider_id, raw: @observation.raw, source_id: @observation.source_id, source_schema: @observation.source_schema, source_table: @observation.source_table, started_at: @observation.started_at, units: @observation.units, value: @observation.value } }
		assert_redirected_to observation_url(@observation)
	end

	test "should destroy observation" do
		assert_difference('Observation.count', -1) do
			delete observation_url(@observation)
		end

		assert_redirected_to observations_url
	end
end
