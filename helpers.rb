def load_data(args = nil)
  filename = (args && args[:debug]) ? 'data_short.marsh' : 'data.marsh'
  puts '--------------------------------------------------------'    
  puts 'Loading data...'
  start_time = Time.now
  result = Marshal.load File.open(filename, 'rb').read
  puts "Data loaded! Time spent: #{(Time.now - start_time).round(2)} seconds."
  puts 'Industy map added.'
  puts '--------------------------------------------------------'
  result
end

def time_back(ending_period, increment)
  if increment == :year
    ending_period.gsub(/^\d{4}/, (ending_period[0..3].to_i - 1).to_s)
  elsif increment == :month
    if ending_period[5..6] == '01'
      "#{(ending_period[0..3].to_i - 1).to_s}-12-#{ending_period[8..9]}"
    else
      "#{ending_period[0..4]}#{"%02d" % (ending_period[5..6].to_i - 1).to_s}#{ending_period[7..9]}"
    end
  end
end

def standard_deviation(arg)
  mean = arg.inject{|sum,x| sum + x } / arg.size.to_f
  (arg.inject(0){|sum,x| sum + ((x-mean) ** 2) } / arg.size) ** 0.5
end

def another_run?(arg)
  if arg == 'debug'
    false
  else
    $stdout.sync = true
    print 'Another run? ("y" for yes) => '
    gets.chomp == 'y'
  end
end

def comma_separated(num)
  num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

def engine_params
  $stdout.sync = true
  result = YAML.load_file('params.yml')

  print "Market cap FLOOR in $mm (ENTER to keep #{result['market_cap_floor']}) => "
  input = gets.chomp
  result['market_cap_floor'] = input.to_i unless input == ''

  print "Market cap CEILING in $mm (ENTER to keep #{result['market_cap_ceiling']}) => "
  input = gets.chomp
  result['market_cap_ceiling'] = input.to_i unless input == ''

  print "Number of stocks in portfolio (ENTER to keep #{result['position_count']}) => "
  input = gets.chomp
  result['position_count'] = input.to_i unless input == ''

  print "Initial balance in $ (ENTER to keep #{result['initial_balance']}) => "
  input = gets.chomp
  result['initial_balance'] = input.to_i unless input == ''

  print "Weight for Earnings Yield (-1 to 1; ENTER to keep #{result['weights']['earnings_yield']}) => "
  input = gets.chomp
  result['weights']['earnings_yield'] = input.to_f unless input == ''

  print "Weight for % of 52-week range (-1 to 1; ENTER to keep #{result['weights']['52_week_range']}) => "
  input = gets.chomp
  result['weights']['52_week_range'] = input.to_f unless input == ''

  print "Weight for 3-year OCF yield (-1 to 1; ENTER to keep #{result['weights']['ocf_3yr_yield']}) => "
  input = gets.chomp
  result['weights']['ocf_3yr_yield'] = input.to_f unless input == ''

  puts '--------------------------------------------------------'
  File.open('params.yml', 'w') {|f| f.write result.to_yaml }
  result
end

def engine_params_hardcoded
  { 'market_cap_floor'  => 100,
    'market_cap_ceiling'  => 200,
    'position_count'  => 20,
    'initial_balance'  => 1000000,
    'rebalance_frequency'  => 'monthly',
    'start_date'  => '2005-01-01',
    'weights' => {
      'earnings_yield' => -1,
      '52_week_range' => 0,
      'ocf_3yr_yield' => 0 },
    '52_week_range_cap' => 1,
    debug: true }
end
