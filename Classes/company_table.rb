class CompanyTable
  attr_accessor :main_table, :size

  def initialize
    @main_table = {}
    @size = 0
  end

  def add(item)
    main_table[(item.cid).to_sym] = item
    @size += 1
  end

  def where(args)
    main_table[args[:cid].to_sym]
  end

  def all_industries
    main_table.map{|k, v| v.sector}.uniq - ['index']
  end

  def industry_subset(industry)
    main_table.select{ |k, v| v.sector == industry }.map{ |k, v| k.to_s }
  end
end
