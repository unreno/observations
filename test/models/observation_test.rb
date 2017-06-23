require 'test_helper'

class ObservationTest < ActiveSupport::TestCase

	test "should create" do
		Observation.create
	end

	test "should birth_weight_birth_weight_group_check" do
		query = Observation.birth_weight_birth_weight_group_check
		actual = query.to_sql
		expected = "SELECT `observations`.`value` AS weight, `o2`.`value` AS wgroup, `o4`.`value` AS zip FROM `observations` LEFT OUTER JOIN `observations` `o2` ON `observations`.`chirp_id` = `o2`.`chirp_id` AND `o2`.`concept` = 'birth_weight_group' AND `o2`.`source_table` = 'births' LEFT OUTER JOIN `observations` `o4` ON `observations`.`chirp_id` = `o4`.`chirp_id` AND `o4`.`concept` = 'birth_zip' AND `o4`.`source_table` = 'births' WHERE `observations`.`concept` = 'birth_weight_grams' AND `observations`.`units` = 'grams' AND `observations`.`source_table` = 'births'"

		assert_equal actual, expected
	end

	test "should birth_xy(x,y)" do
		query = Observation.birth_xy( 'sex', 'birth_weight_group' )
		actual = query.to_sql
		expected = "SELECT `observations`.`value` AS x, `o2`.`value` AS y, COUNT(DISTINCT `observations`.`chirp_id`) AS count FROM `observations` LEFT OUTER JOIN `observations` `o2` ON `observations`.`chirp_id` = `o2`.`chirp_id` AND `o2`.`concept` = 'birth_weight_group' AND `o2`.`source_table` = 'births' WHERE `observations`.`concept` = 'sex' AND `observations`.`source_table` = 'births' GROUP BY `observations`.`value`, `o2`.`value`"
		assert_equal actual, expected
	end

end
