require 'pry'
require 'date'
require 'json'
load 'helpers.rb'
Dir["Classes/*.rb"].each { |file| load file }

case ARGV[0]
when 'output_only'
  ReportPrinter.new(JSON.parse(File.read('result.txt'))).generate
when 'pause'
  binding.pry
else
  data_table = PriceTable.new(debug: ARGV[0] == 'debug')
  begin
    params = ARGV[0] == 'debug' ? engine_params_hardcoded : engine_params
    results = Engine.new(data_table, params).perform
    File.open("result.txt", "w") { |file| file.write(results.to_json) }
    puts 'JSON results saved to result.txt.'
    filename = ReportPrinter.new(results).generate
    puts "Full report saved to #{filename}."
    puts '--------------------------------------------------------'
  end until !another_run?(ARGV[0])
end
