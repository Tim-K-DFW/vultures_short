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
  result = {}

  print 'Market cap FLOOR in $mm (minimum 50, default 500) => '
  input = gets.chomp
  result['market_cap_floor'] = input == '' ? 500 : input.to_i

  print 'Market cap CEILING in $mm (minimum 50, default 10,000) => '
  input = gets.chomp
  result['market_cap_ceiling'] = input == '' ? 10000 : input.to_i

  print 'Number of stocks in portfolio (default 20) => '
  input = gets.chomp
  result['position_count'] = input == '' ? 20 : input.to_i

  print 'Initial balance in $ (default 1,000,000, no commas) => '
  input = gets.chomp
  result['initial_balance'] = input == '' ? 1000000 : input.to_i
  puts '--------------------------------------------------------'

  result['rebalance_frequency'] = 'monthly'
  result['start_date'] = '2005-01-01'
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
      'earnings_yield' => 0.5,
      '52_week_range' => 0.5 },
    '52_week_range_cap' => 1,
    debug: true }
end
