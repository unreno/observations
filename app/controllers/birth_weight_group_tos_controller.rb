class BirthWeightGroupTosController < ApplicationController

	def show
		@value = case params[:v]
			when 'prenatal' then 'Prenatal Care'
			when 'alcohol' then 'Alcohol Use'
			when 'drug_use' then 'Drug Use'
			when 'du_otc' then 'OTC Drug Use'
			when 'du_prscr' then 'Prescription Drug Use'
			when 'source_pay' then 'Source Pay'
			when 'tobacco' then 'Tobacco Use'
			when 'mom_age1' then "Mother's Age Group"
			when 'mom_race1' then "Mother's CDC Race"
			when 'momrace_ethnchs' then "Mother's race & ethnic NCHS"
			else params[:v]
		end
		@results = Observation.birth_weight_group_to params[:v]
	end

end
