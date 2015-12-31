class ScoreCalculator
  require 'yaml'
  attr_accessor :data_table, :args, :result
  attr_reader :weights

  def initialize(data_table, args)
    @data_table = data_table
    @args = args
    @result = []
    @weights = args[:weights]
  end

  def assign_scores
    allocations = calculate_allocations
    data_table.all_industries.each do |industry|
      @entire_industry = []
      array = data_table.subset({
                industry: industry,
                period: args[:period],
                cap_floor: args[:market_cap_floor],
                cap_ceiling: args[:market_cap_ceiling],
                range_52_cap: args[:range_52_cap] })
      array.each { |element| @entire_industry << element.attributes }
      
      assign_earnings_yield_scores
      assign_52_week_range_scores
      assign_ocf_yield_scores
      assign_total_scores

      for i in 0..(allocations[industry] - 1) do 
        if @entire_industry[i] == nil
          raise "Cannot find enough stocks in #{industry} during #{args[:period]}. Try to extend the market cap range."
        else
          result << @entire_industry[i]
        end
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

  def assign_earnings_yield_scores
    @entire_industry.sort_by { |h| h['earnings_yield'] }.each_with_index{ |v, i| v['ey_score'] = i + 1 }
  end

  def assign_52_week_range_scores
    @entire_industry.sort_by { |h| h['range_52'] }.each_with_index{ |v, i| v['52_range_score'] = i + 1 }
  end

  def assign_ocf_yield_scores
    @entire_industry.sort_by { |h| h['ocf_3yr_yield'] }.each_with_index{ |v, i| v['ocf_yield_score'] = i + 1 }
  end

  def assign_total_scores
    @entire_industry.each { |stock| stock['total_score'] =
      stock['ey_score'] * @weights['earnings_yield'] +
      stock['52_range_score'] * @weights['52_week_range'] +
      stock['ocf_yield_score'] * @weights['ocf_3yr_yield'] }
    @entire_industry.sort_by! { |h| h['total_score'] }
  end
end
