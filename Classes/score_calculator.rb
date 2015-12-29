class ScoreCalculator
  require 'yaml'

  attr_accessor :stocks, :data_table, :args, :result

  def initialize(data_table, args)
    @data_table = data_table
    @args = args
    @result = []
    @stocks = []
  end

  def assign_scores
    allocations = calculate_allocations
    data_table.all_industries.each do |industry|
      this_industry = []
      puts "Retreiving data for #{args[:period]} for #{industry}..."
      array = data_table.subset({
      industry: industry,
      period: args[:period],
      cap_floor: args[:market_cap_floor],
      cap_ceiling: args[:market_cap_ceiling] })
      array.each { |element| this_industry << element.attributes }
      
      this_industry = assign_earnings_yield_scores(this_industry)
      this_industry = assign_total_scores(this_industry)
      for i in 0..(allocations[industry] - 1) do 
        result << this_industry[i]
      end
    end
    result
  end

  private

  def calculate_allocations
    input = YAML.load_file('industry_allocations.yml')
    result = {}
    input.each { |industry, percentage| result[industry] = (args[:position_count] * (percentage / 100)).floor }
    position_total = result.map {|k, v| v}.inject { |sum, x| sum + x }
    if position_total < args[:position_count]
      to_add = args[:position_count] - position_total
      largest_allocation = result.map { |k, v| v }.max
      key_to_update = result.select{ |k,v| v == largest_allocation }.first[0]
      result[key_to_update] += to_add
    end
    result
  end

  def assign_earnings_yield_scores(list)
    list.sort_by { |h| h["earnings_yield"] }.each_with_index{ |v, i| v["ey_score"] = i + 1 }
  end

  def assign_total_scores(list)
    list.each { |stock| stock["total_score"] = stock["ey_score"] }
    list.sort_by! { |h| h["total_score"] }
  end
end
