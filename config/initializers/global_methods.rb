
def outer(an_arel_table,an_arel_table_expression)
	Arel::Nodes::OuterJoin.new(an_arel_table,
		Arel::Nodes::On.new( an_arel_table_expression ))
end

def inner(an_arel_table,an_arel_table_expression)
	Arel::Nodes::InnerJoin.new(an_arel_table,
		Arel::Nodes::On.new( an_arel_table_expression ))
end

